module matrix_out #(
    parameter BOARDS = 2,
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
    localparam OUTPUTS_PER_BOARD = 16;
    localparam OUTPUTS_TOTAL = BOARDS*OUTPUTS_PER_BOARD*ROWS;

    // LED value memory
    reg [15:0] values [(OUTPUTS_TOTAL-1):0];
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

    reg [3:0] next_board;    // Current board being written to device
    reg [4:0] next_output;      // Current column being written to device
    reg [3:0] next_row;      // Current row being written to device
    reg [15:0] next_address;

    reg [3:0] row_address;      // Current row address (0-ROWS)
    reg [7:0] gclock_counter;   // Counter to synchronize row address with gclock

    reg [15:0] value;                           // Output value
    wire [7:0] value_brightness = value[8:1];   // Current brightness
    wire [3:0] value_step = value[12:9];         // Current row/col

    assign a = row_address[3];
    assign b = row_address[2];
    assign c = row_address[1];
    assign d = row_address[0];

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
    localparam GCLK_COUNTS = 138;

    localparam CONFIG_REG_1_DATA =
        ((ROWS-1)<<8)                       // Number of scan lines (0=1, ..., 31=32)
        | ((1)<<6)                          // Optimized mode under low gray (recommend 1)
        | ((3)<<4);                         // Accelerate fix 8 rate, send 138 GCLKs each line: set to 0x3

    localparam CONFIG_REG_1_LATCHES = (2 + 1*2);

    localparam CONFIG_REG_2_DATA =
        ((31)<<10)              // Pre-charge for ghosting reduction level (recommend R=31, G=28, B=23)
        | 32'h0200              // Current gain mode sleect (1=19*IGAIN/(Rext*256), 0=19*IGAIN/(REXT*1024))
        | ((8'hFF)<<1)          // Current gain adjust (IOUT=19*IGAIN/Rext*n, n set by REG2_I_DIV4N)
        | 32'h0001;

    localparam CONFIG_REG_2_LATCHES = (2 + 2*2);

    always @(posedge clk) begin
	    if(rst) begin
            gclk <= 0;
            state <= 0;

            counter <= 0;

            gclock_counter <= 0;
            row_address <= 0;
        end
        else begin
            gclk <= ~gclk;

            le <= 0;
            sdi <= 0;
            dclk <= 0;

            if(gclk == 1) begin
                gclock_counter <= gclock_counter + 1;

                if(gclock_counter == (GCLK_COUNTS - 1 - 4)) begin
                    row_address <= row_address + 1;
             
                    if(row_address == ROWS - 1)
                        row_address <= 0;
                end
             
                if(gclock_counter == (GCLK_COUNTS-1)) begin
                    gclock_counter <= 0;
                end
            end

            case(state)
            0:      // Setup
            begin
                state <= state + 1;
                counter <= 0;

                row_address <= 0;
                gclock_counter <= 0;

                //value <= value + 1;     // TODO: Delete me
            end
            1,3,5:  // Pre-activate
            begin
                counter <= counter + 1;

                // Send 1 pulse with latch low
                // Send 14 pulses with latch high
                // Send 1 pulse with latch low
                dclk <= counter[0];

                case(counter_bit)
                0, (PREACTIVATE_CLOCKS+1):
                    le <= 0;
                default:
                    le <= 1;
                endcase
                
                if(counter == ((PREACTIVATE_CLOCKS + 2) << 1) - 1) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            2:  // Write config register 1 to set scan mode
            begin
                counter <= counter + 1;
                dclk <= counter[0];

                sdi <= CONFIG_REG_1_DATA[15-counter_bit];

                if(counter > ((16*BOARDS - CONFIG_REG_1_LATCHES) << 1) - 1)
                    le <= 1;

                if(counter == (16*BOARDS << 1) - 1) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end

            // 3. Preactivate
            4:  // Write config register 2 to set brightness
            begin
                counter <= counter + 1;
                dclk <= counter[0];

                sdi <= CONFIG_REG_2_DATA[15-counter_bit];

                if(counter > ((16*BOARDS - CONFIG_REG_2_LATCHES) << 1) - 1)
                    le <= 1;

                if(counter == ((16*BOARDS << 1) - 1)) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end

            // 5. Preactivate
            6:  // Send latches to enable all output channels
            begin
                counter <= counter + 1;

                dclk <= counter[0];

                case(counter_bit)
                0, (ENABLE_OUTPUTS_CLOCKS + 1):
                    le <= 0;
                default:
                    le <= 1;
                endcase

                if(counter == ((ENABLE_OUTPUTS_CLOCKS + 2) << 1) - 2) begin
                    next_board <= 0;
                    next_output <= 0;
                    next_row <= 0;
                    next_address <= 0;
                end
                
                if(counter == ((ENABLE_OUTPUTS_CLOCKS + 2) << 1) - 1) begin
                    state <= state + 1;
                    counter <= 0;

                    value <= values[next_address];
                    next_board <= next_board + 1;
                    next_address <= next_address + OUTPUTS_PER_BOARD*ROWS;
                end
            end
            7:  // Send data (1 chip * 16 rows * 16 cols * 16 bits per LED)
            begin
                // Outer loop: rows
                //   Middle loop: columns
                //     Middler loop: boards
                //       Inner loop: bits

                counter <= counter + 1;

                dclk <= counter[0];

                sdi <= value[15 - counter_bit];

                if((next_board == (BOARDS)) && (counter_bit == 15))
                    le <= 1;

                if(counter[4:0] == 5'b11111) begin
                    counter <= 0;

                    value <= values[next_address];
                    next_board <= next_board + 1;
                    next_address <= next_address + OUTPUTS_PER_BOARD*ROWS;
                    
                    if(next_board == (BOARDS)) begin
                        next_board <= 0;

                        next_output <= next_output + 1;
                        next_address <= next_address - ((BOARDS) * OUTPUTS_PER_BOARD*ROWS) + 1;
                        
                        if(next_output == (OUTPUTS_PER_BOARD - 1)) begin
                            next_output <= 0;
                     
                            next_row <= next_row + 1;
                     
                            if(next_row == (ROWS-1)) begin
                                state <= state + 1;
                                counter <= 0;
                            end
                        end
                    end
                end
                
            end
            8:  // Wait 50 GCLK (TODO: Needed?)
            begin
                counter <= counter + 1;

                if(counter == 50) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            9:  // Wait for end of frame, to start VSYNC
            begin
                if((gclock_counter == (GCLK_COUNTS-1)) && (row_address == 0) && (gclk == 1)) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end

            10:  // Send vsync with glcock disabled
                // (TODO: Sync to actual vsync event)
            begin
                counter <= counter + 1;

                gclk <= 0;

                // Send 1 pulse with latch low
                // Send 14 pulses with latch high
                // Send 1 pulse with latch low
                dclk <= counter[0];

                case(counter_bit)
                0, (VSYNC_CLOCKS + 1):
                    le <= 0;
                default:
                    le <= 1;
                endcase
                
                if(counter == ((VSYNC_CLOCKS + 2) << 1) - 1) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end

            11: // Send 4 GCLKs
            begin
                counter <= counter + 1;

                gclk <= counter[0];

                if(counter[2:1] == 2'b11) begin
                    state <= 0;
                    counter <= 0;

                    gclock_counter <= 0;
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
