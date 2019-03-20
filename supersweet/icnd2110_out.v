module icnd2110_out #(
    parameter WORD_COUNT = (336),
    parameter ADDRESS_BUS_WIDTH = 12,       // Must be large enough to address WORD_COUNT
    parameter CFG_UP = 0,
    parameter CFG_PWM_WIDER = 1,
) (
    input clk,
    input rst,
    
    input [15:0] spi_data,
    input [ADDRESS_BUS_WIDTH:0] spi_address,
    input spi_write_strobe,

    output reg data_out,
    output wire clock_out,
);
    reg [15:0] values [(WORD_COUNT-1):0];
    initial begin
        $readmemh("test_data16.list", values);
    end

    // TODO: Make a memory bus, wire this module into it
//    always @(posedge clk)
//        if(spi_write_strobe)
//            values[spi_address] <= spi_data;

    reg [3:0] state;
    reg [10:0] counter;

    reg [ADDRESS_BUS_WIDTH:0] word_index;   // Address of word we are currently clocking out
    reg [2:0] subchip_byte;              // Counter from 0..5

    reg [15:0] val;                      // 16-bit output value from memory

    reg [3:0] clockdiv;
    always @(posedge clk)
        clockdiv <= clockdiv + 1;

    assign clock_out = clockdiv[2];

    always @(negedge clock_out) begin
        if(rst) begin
            state <= 0;
            data_out <= 0;

            val <= 0;
        end
        else begin
            data_out <= 0;

            case(state)
            0:  // 0. wait for start
            begin
                state <= state + 1;
                counter <= 0;
            end
            1:  // 1. start (128 bits of 1)
            begin
                data_out <= 1;

                counter <= counter +1;
                
                if(counter == 127) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            2,4,6,8:    // 2. blank (16 bits of 0)
            begin
                counter <= counter +1;
                
                if(counter == 15) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            3:  // 3. reg (16 bit register value)
            begin
                counter <= counter + 1;

                case(counter[3:0])
                    11:
                        data_out <= CFG_PWM_WIDER;
                    12:
                        data_out <= CFG_UP;
                    13,14,15:
                        data_out <= 1;
                    default:
                        data_out <= 0;
                endcase

                // Pre-load the word index and subchip byte one cycle before
                // they are needed.
                if(counter == 14) begin
                    word_index <= 5;
                    subchip_byte <= 0;
                end

                if(counter == 15) begin
                    state <= state + 1;
                    counter <= 0;

                    // Preload the first byte
                    val <= values[word_index];
//                    val <= word_index;

                    // And calculate the next word and subchip byte indexes
                    word_index <= word_index - 1;
                    subchip_byte <= subchip_byte + 1;
                end
            end

            // 4. blank (16 bits of 0)
            // for n chips:
            5, 7: // 5.  chip x, out5-out0 (16 x 6 bits)
            begin
                // Here:
                // counter[3:0] is the bit output (0-15)
                // counter[6:4] is output (5-0) if in state 5, or output (11-6) if in state 7.
                //
                // counter: 11'b0000ooobbbb
                //                  1011111
                //
                counter <= counter + 1;

                data_out <= val[15 - counter[3:0]];

                if(counter[3:0] == 15) begin
                    val <= values[word_index];
//                    val <= word_index;

                    //  5, 4, 3, 2, 1, 0,11,10, 9, 8, 7, 6, - first chip
                    // 17,16,15,14,13,12,23,22,21,20,19,18, - second chip
                    if(subchip_byte == 5) begin
                        subchip_byte <= 0;
                        word_index <= word_index + 11;
                    end
                    else begin
                        subchip_byte <= subchip_byte + 1;
                        word_index <= word_index - 1;
                    end
                end

                if(counter[6:0] == (16*6-1)) begin
                    state <= state + 1;
                    counter <= 0;

                    if(state == 7) begin
                        if(word_index < WORD_COUNT)
                            state <= 4;
                    end
                end
            end
            // 6.  blank
            // 7.  chip x, out11-out6 (16 x 6 bits)
            // 8.  blank
            9:  // 9. frame end (145 bits of 1)
            begin
                data_out <= 1;

                counter <= counter +1;
                
                if(counter == 144) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            10: // 10. Delay after frame end (not in spec) (100 bits of 0)
            begin
                counter <= counter + 1;
                if(counter == 100) begin
                    state <= 0;
                    counter <= 0;
                end
            end
            default:
                state <= 0;

            endcase
        end
    end

endmodule
