/*
// Example module for an easy-to-seperate dual port ram block:
module test (
        input clk, wen, ren, 
        input [7:0] waddr, raddr,
        input [31:0] wdata,
        output reg [31:0] rdata
);
        reg [31:0] mem [0:255];
        always @(posedge clk) begin
                if (wen)
                        mem[waddr] <= wdata;
                if (ren)
                        rdata <= mem[raddr];
        end
endmodule
*/

parameter BUFFER_WIDTH = (9);

module icnd2110(
    input clk,
    input rst,
    input [BUFFER_WIDTH:0] bytecount,
    input cfg_pwm_wider,        // Enhancement for low gray (1=enable)
    input cfg_up,               // Ghosting reduction (1=enable)

    input in_input,

    output spi_c,
    output spi_d,
    output start_flag,

    output [12:0] in_debug
);

    // Big memory for LED data
    reg [7:0] ledBuffer [(1<<BUFFER_WIDTH)-1:0];
    initial begin
        $readmemh("red.list", ledBuffer);
    end

    reg [15:0] lut16 [255:0];
    initial begin
        $readmemh("lut16.list", lut16);
    end

    reg [3:0] state;     // Current state machine mode

    reg [10:0] counter;  // 8-bit step counter

    reg [BUFFER_WIDTH:0] readindex;   // Current byte, but it is offset from 0..11
    reg [2:0] subchip_byte;  // Counter from 0..5

    reg [7:0] val;              // 8-bit output value from memory

    reg [15:0] correction;

    reg data;                   // state of the SPI data output pin
    reg start_flag_r;           // For debug: a start flag on a seperate pin

    assign spi_c = !clk;        // Off by 1/2 phase?
    assign spi_d = data;
    assign start_flag = start_flag_r;


// WS2812 input
    wire in_input;
    reg [1:0] in_state;
    reg [12:0] in_counter;

    reg [BUFFER_WIDTH:0] in_byteindex;
    reg [7:0] in_byte;
    reg [2:0] in_bitindex;
    reg in_bit_debug;
    reg state_change;


   /*
    * Synchronize the serial input to this clock domain
    */
    wire         in_input_sync;
    sync_ss in_sync(clk, rst, in_input, in_input_sync);

    assign in_debug[12:9] = in_byteindex[3:0];
    assign in_debug[8:4] = in_counter[4:0];
    assign in_debug[3] = in_bit_debug;
    assign in_debug[2:1] = in_state;
    assign in_debug[0] = state_change;

    parameter HIGHBIT_TICKS = 10;
    parameter RESET_TICKS = 7000;

    always @(posedge clk)
        if(rst) begin
            in_counter <= 0;
            in_state <= 0;
            in_byteindex <= 0;
            in_byte <= 0;
            in_bitindex <= 0;

            state_change <= 0;
            in_bit_debug <= 0;
        end
        else begin
            state_change <= 0;
            in_bit_debug <= 0;
            in_counter <= in_counter + 1;

            case(in_state)
            0:  // Idle
                begin
                    if(in_input_sync == 1) begin
                        in_bitindex = 0;
                        in_byteindex = 0;

                        in_counter <= 0;
                        in_state <= in_state + 1;
                        state_change <= 1;
                    end
                end
            1:  // High bit
                begin
                    in_bit_debug <= (in_counter > HIGHBIT_TICKS);

                    if(in_input_sync == 0) begin
                        in_byte[7 - in_bitindex] <= (in_counter > HIGHBIT_TICKS);
                        in_bitindex <= in_bitindex + 1;

                        if(in_bitindex == 7) begin
                            in_bitindex <= 0;
                            in_byteindex <= in_byteindex + 1;
                            ledBuffer[in_byteindex] <= in_byte;
                        end

                        in_counter <= 0;
                        in_state <= in_state + 1;
                        state_change <= 1;
                    end
                end
            2:  // Low bit
                begin
                    if(in_input_sync == 1) begin
                        in_counter <= 0;
                        in_state <= in_state - 1;
                        state_change <= 1;
                    end
                    else if(in_counter > RESET_TICKS) begin
                        in_counter <= 0;
                        in_state <= in_state + 1;
                        state_change <= 1;
                    end
                end
            3:  // End state
                begin
                    in_counter <= 0;
                    in_state <= 0;
                    state_change <= 1;
                end

            endcase
        end


// ICND2110 output
    always @(posedge clk)
        if(rst) begin
            state <= 0;
            data <= 0;

            val <= 0;
            correction <= 0;
        end
        else begin
            start_flag_r <= 0;
            data <= 0;

            case(state)
            // Many states here:
            // 0. wait for start
            0:
                // TODO: implement start signal
                begin
                    start_flag_r <= 1;
                    state <= 1;
                    counter <= 0;

                    readindex <= 5;
                    subchip_byte <= 0;
                end
            // 1. start (128 bits of 1)
            1:
                begin
                    data <= 1;

                    counter <= counter +1;
                    
                    if(counter == 127) begin
                        state <= state + 1;
                        counter <= 0;
                    end
                end
            // 2. blank (16 bits of 0)
            2,4,6,8:
                begin
                    counter <= counter +1;
                    
                    if(counter == 15) begin
                        state <= state + 1;
                        counter <= 0;
                    end
                end
            // 3. reg (16 bit register value)
            3:
                begin
                    counter <= counter + 1;

                    case(counter[3:0])
                        11:
                            data <= cfg_pwm_wider;
                        12:
                            data <= cfg_up;
                        13,14,15:
                            data <= 1;
                        default:
                            data <= 0;
                    endcase

                    if(counter == 15) begin
                        state <= state + 1;
                        counter <= 0;

                        // Preload the first byte
                        val <= ledBuffer[readindex];

                        // Count in sequence:
                        // 5,4,3,2,1,0,11,10,9,8,7,6,15,14,13,12,11, ...
                        if(subchip_byte == 5) begin
                            subchip_byte <= 0;
                            readindex <= readindex + 11;
                        end
                        else begin
                            subchip_byte <= subchip_byte + 1;
                            readindex <= readindex - 1;
                        end
                    end
                end

            // 4. blank (16 bits of 0)
            // for n chips:
            // 5.  chip x, out5-out0 (16 x 6 bits)
            5, 7:
                begin
                    // Here:
                    // counter[3:0] is the bit output (0-15)
                    // counter[6:4] is output (5-0) if in state 5, or output (11-6) if in state 7.
                    counter <= counter + 1;

                    data <= lut16[val][15 - counter[3:0]];

                    if(counter[3:0] == 15) begin
                        val <= ledBuffer[readindex];

                        if(subchip_byte == 5) begin
                            subchip_byte <= 0;
                            readindex <= readindex + 11;
                        end
                        else begin
                            subchip_byte <= subchip_byte + 1;
                            readindex <= readindex - 1;
                        end
                    end

                    if(counter == (16*6-1)) begin
                        counter <= 0;

                        if(state == 5) begin
                            state <= state + 1;
                        end
                        else begin
                            if(readindex < bytecount)
                                state <= 4;
                            else
                                state <= state + 1;
                        end
                    end
                end

            // 6.  blank
            // 7.  chip x, out11-out6 (16 x 6 bits)
            // 8.  blank
            // 9. frame end (145 bits of 1)
            9:
                begin
                    data <= 1;

                    counter <= counter +1;
                    
                    if(counter == 144) begin
                        state <= 0;
                        counter <= 0;
                    end
                end

            default:
                state <= 0;

            endcase
        end

endmodule
