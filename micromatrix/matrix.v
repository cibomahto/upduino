
module matrix(
    input clk,
    input rst,
    output sdi,
    output dclk,
    output le,
    output gclk,
    output a,
    output b,
    output c,
    output d,
);

    reg [4:0] state;            // State machine
    reg [15:0] counter;         // Counter for the state machine

    reg [3:0] rowAddress;       // Current row address (0-15)
    reg [7:0] gclockCounter;    // Counter to synchronize row address with gclock
    reg gclock;
    reg data;
    reg clock;
    reg latch;

    reg [16:0] value;            // Output value

    assign a = rowAddress[3];
    assign b = rowAddress[2];
    assign c = rowAddress[1];
    assign d = rowAddress[0];

    assign gclk = gclock;
    assign le = latch;
    assign sdi = data;
    assign dclk = clock;

    wire [3:0] counterBit = counter[4:1];
    wire [7:0] counterLED = counter[12:5];

    wire [15:0] correction;

    reg [15:0] lut16 [255:0];
    initial begin
        $readmemh("lut16.list", lut16);
    end
    
    assign correction = lut16[value[11:4]];


    localparam PREACTIVATE_CLOCKS = 14;
    localparam ENABLE_OUTPUTS_CLOCKS = 12;
    localparam VSYNC_CLOCKS = 3;

    localparam CONFIG_REG_1_DATA =
        ((15)<<8)       // Number of scan lines (0=1, ..., 31=32)
        | ((1)<<6)      // Optimized mode under low gray (recommend 1)
        | ((3)<<4);     // Accelerate fix 8 rate, send 138 GCLKs each line: set to 0x3

    localparam CONFIG_REG_1_LATCHES = 2+1*2;

    localparam CONFIG_REG_2_DATA =
        ((31)<<10)      // Pre-charge for ghosting reduction level (recommend R=31, G=28, B=23)
        | 32'h0200      // Current gain mode sleect (1=19*IGAIN/(Rext*256), 0=19*IGAIN/(REXT*1024))
        | ((8'hFF)<<1)  // Current gain adjust (IOUT=19*IGAIN/Rext*n, n set by REG2_I_DIV4N)
        | 32'h0001;

    localparam CONFIG_REG_2_LATCHES = 2+2*2;

	always @(posedge clk)
	    if(rst) begin
            gclock <= 0;
            state <= 0;

            counter <= 0;

            gclockCounter <= 0;
            rowAddress <= 0;

            value <= 0;
        end
        else begin
            gclock <= ~gclock;

            latch <= 0;
            data <= 0;
            clock <= 0;

            if(gclock == 1) begin
                gclockCounter <= gclockCounter + 1;
            end

            if(gclockCounter == 138) begin
                rowAddress <= rowAddress + 1;
                gclockCounter <= 0;
            end


            case(state)
            // 0. Preactivate
            0,2,4:
            begin
                counter <= counter + 1;

                // Send 1 pulse with latch low
                // Send 14 pulses with latch high
                // Send 1 pulse with latch low
                clock <= counter[0];

                if ((counter > 1) &&  (counter < (2 + PREACTIVATE_CLOCKS*2)))
                    latch <= 1;
                
                if(counter == (2 + PREACTIVATE_CLOCKS*2 + 2) - 1) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            // 1. Write config register 1 to set scan mode
            1:
            begin
                counter <= counter + 1;

                clock <= counter[0];

                data <= CONFIG_REG_1_DATA[15-counterBit];

                if(counter > (15-CONFIG_REG_1_LATCHES)*2+1)
                    latch <= 1;

                if(counter == 31) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end

            // 2. Preactivate
            // 3. Write config register 2 to set brightness
            3:
            begin
                counter <= counter + 1;

                clock <= counter[0];

                data <= CONFIG_REG_2_DATA[15-counterBit];

                if(counter > (15-CONFIG_REG_2_LATCHES)*2+1)
                    latch <= 1;

                if(counter == 31) begin
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
                clock <= counter[0];

                if ((counter > 1) &&  (counter < (2 + ENABLE_OUTPUTS_CLOCKS*2)))
                    latch <= 1;
                
                if(counter == (2 + ENABLE_OUTPUTS_CLOCKS*2 + 2) - 1) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end

            // 6. Send data (1 chip * 16 rows * 16 cols * 16 bits per LED)
            6:
            begin
                counter <= counter + 1;

                clock <= counter[0];

                // TODO: Send data from memory
                //if((counterLED > 15) && (counterLED < 32))
                if((value[15:12] == counterLED[3:0])
                    || (value[15:12] == counterLED[7:4]))
                    data <= correction[15-counterBit];

                if(counterBit == 15)
                    latch <= 1;

                if(counter == (16*16*16*2)) begin
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

                gclock <= 0;

                // Send 1 pulse with latch low
                // Send 14 pulses with latch high
                // Send 1 pulse with latch low
                clock <= counter[0];

                if ((counter > 1) &&  (counter < (2 + VSYNC_CLOCKS*2)))
                    latch <= 1;
                
                if(counter == (2 + VSYNC_CLOCKS*2 + 2) - 1) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            // 9. Wait with GCLK disabled
            9:
            begin
                counter <= counter + 1;

                gclock <= 0;

                if(counter == 50) begin
                    state <= state + 1;
                    counter <= 0;

                    rowAddress <= 0;
                    gclockCounter <= 0;

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

endmodule
