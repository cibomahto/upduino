module matrix_out #(
    parameter BOARDS = 3,
    parameter ROWS = 4,
) (
    input clk,
    input rst,

    input [8:0] address_in,
    input [7:0] data_in,
    input write_strobe_in,

    output reg sdi,
    output reg dclk,
    output reg le,
    output reg gclk,
    output wire a,
    output wire b,
    output wire c,
    output wire d,
);
    localparam COLUMNS = BOARDS * 16;
    localparam BYTES_TOTAL = COLUMNS*ROWS;

    // LED value memory
    reg [15:0] values [(BYTES_TOTAL-1):0];
    // TODO: Clear this to 0

    reg [15:0] lut_8_to_16 [255:0];
    initial begin
        $readmemh("lut_8_to_16_pow_1.80.list", lut_8_to_16);
    end

    always @(posedge clk)
    begin
        if(write_strobe_in) begin
            values[address_in] <= lut_8_to_16[data_in];
        end
    end

    reg [4:0] state;            // State machine
    reg [20:0] counter;         // Counter for the state machine

    reg [3:0] row_address;      // Current row address (0-ROWS)
    reg [7:0] gclock_counter;   // Counter to synchronize row address with gclock

    reg [3:0] current_bit;      // Current bit plane being clocked out
    reg [7:0] current_column;   // Current column being clocked out
    reg [4:0] current_row;      // Current row being clocked out

    reg [15:0] value;                           // Output value
    wire [7:0] value_brightness = value[8:1];   // Current brightness
    wire [3:0] value_step = value[12:9];         // Current row/col

    assign a = row_address[3];
    assign b = row_address[2];
    assign c = row_address[1];
    assign d = row_address[0];

    wire [3:0] counter_row = counter[16:13];     // Current row
    wire [3:0] counter_col = counter[12:9];      // Current column
    wire [3:0] counter_board = counter[8:5];     // Current board
    wire [3:0] counter_bit = counter[4:1];       // Current bit of current LED

    wire [15:0] correction;

    reg [15:0] lut16 [255:0];
    initial begin
        $readmemh("lut16.list", lut16);
    end
    
    assign correction = lut16[value_brightness];

    localparam PREACTIVATE_CLOCKS = 14;
    localparam ENABLE_OUTPUTS_CLOCKS = 12;
    localparam VSYNC_CLOCKS = 3;

    localparam CONFIG_REG_1_DATA =
        ((ROWS-1)<<8)                       // Number of scan lines (0=1, ..., 31=32)
        | ((1)<<6)                          // Optimized mode under low gray (recommend 1)
        | ((3)<<4);                         // Accelerate fix 8 rate, send 138 GCLKs each line: set to 0x3

    localparam CONFIG_REG_1_LATCHES = 2+1*2;

    localparam CONFIG_REG_2_DATA =
        ((31)<<10)              // Pre-charge for ghosting reduction level (recommend R=31, G=28, B=23)
        | 32'h0200              // Current gain mode sleect (1=19*IGAIN/(Rext*256), 0=19*IGAIN/(REXT*1024))
        | ((8'hFF)<<1)          // Current gain adjust (IOUT=19*IGAIN/Rext*n, n set by REG2_I_DIV4N)
        | 32'h0001;

    localparam CONFIG_REG_2_LATCHES = 2+2*2;

    always @(posedge clk) begin
	    if(rst) begin
            gclk <= 0;
            state <= 0;

            counter <= 0;

            gclock_counter <= 0;
            row_address <= 0;

            value <= 0;
        end
        else begin
            gclk <= ~gclk;

            le <= 0;
            sdi <= 0;
            dclk <= 0;

            if(gclk == 1) begin
                gclock_counter <= gclock_counter + 1;
            end

            if(gclock_counter == 138) begin
                row_address <= row_address + 1;
                gclock_counter <= 0;
            end


            case(state)
            // 0. Preactivate
            0,2,4:
            begin
                counter <= counter + 1;

                // Send 1 pulse with latch low
                // Send 14 pulses with latch high
                // Send 1 pulse with latch low
                dclk <= counter[0];

                case(counter[4:1])
                0, 15:
                    le <= 0;
                default:
                    le <= 1;
                endcase
                
                if(counter == (2 + PREACTIVATE_CLOCKS*2 + 2) - 1) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            // 1. Write config register 1 to set scan mode
            1:
            begin
                counter <= counter + 1;

                dclk <= counter[0];

                sdi <= CONFIG_REG_1_DATA[15-counter_bit];

                if(counter > (16*BOARDS - CONFIG_REG_1_LATCHES)*2 - 1)
                    le <= 1;

                if(counter == (32*BOARDS - 1)) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end

            // 2. Preactivate
            // 3. Write config register 2 to set brightness
            3:
            begin
                counter <= counter + 1;

                dclk <= counter[0];

                sdi <= CONFIG_REG_2_DATA[15-counter_bit];

                if(counter > (16*BOARDS - CONFIG_REG_2_LATCHES)*2 - 1)
                    le <= 1;

                if(counter == (32*BOARDS-1)) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            // 4. Preactivate
            // 5. Send latches to enable all output channels
            5:
            begin
                counter <= counter + 1;

                // Send 1 pulse with latch low
                // Send 14 pulses with latch high
                // Send 1 pulse with latch low
                dclk <= counter[0];

                if ((counter > 1) &&  (counter < (2 + ENABLE_OUTPUTS_CLOCKS*2)))
                    le <= 1;
                
                if(counter == (2 + ENABLE_OUTPUTS_CLOCKS*2 + 2) - 1) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end

            // 6. Send data (1 chip * 16 rows * 16 cols * 16 bits per LED)
            6:
            begin
                counter <= counter + 1;

                dclk <= counter[0];

                // TODO: Send data from memory
                if((value_step == counter_row)
                    || (value_step == counter_col))
                    sdi <= correction[15-counter_bit];

                if((counter_board == 15) && (counter_bit == 15))
                    le <= 1;

                if(counter == (BOARDS*16*16*16*2 - 1)) begin
                    state <= state + 1;
                    counter <= 0;
                end

            end

            // 7. Wait 50 GCLK (TODO: Needed?)
            7:
            begin
                counter <= counter + 1;

                if(counter == 50) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            // 8. Send vsync with glcock disabled
            // (TODO: Sync to actual vsync event)
            8:
            begin
                counter <= counter + 1;

                gclk <= 0;

                // Send 1 pulse with latch low
                // Send 14 pulses with latch high
                // Send 1 pulse with latch low
                dclk <= counter[0];

                if ((counter > 1) &&  (counter < (2 + VSYNC_CLOCKS*2)))
                    le <= 1;
                
                if(counter == (2 + VSYNC_CLOCKS*2 + 2) - 1) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            // 9. Wait with GCLK disabled
            9:
            begin
                counter <= counter + 1;

                gclk <= 0;

                if(counter == 50) begin
                    state <= state + 1;
                    counter <= 0;

                    row_address <= 0;
                    gclock_counter <= 0;

                    value <= value + 1;
                end
            end

            default:
            begin
                state <=0;
                counter <=0;
            end

        endcase

        end
    end

endmodule
