module ws2812_out #(
    parameter WORD_COUNT = 1305,        // Number of LEDs supported / 2 
    parameter ADDRESS_BUS_WIDTH = 16,
    parameter DATA_BUS_WIDTH = 16,
) (
    input clk,
    input rst,

    input [(DATA_BUS_WIDTH):0] spi_data,
    input [(ADDRESS_BUS_WIDTH-1):0] spi_address,
    input spi_write_strobe,

    output reg data_out,
    output reg backup_out,
);
//    // Timings for a 48MHz clock
//    localparam BIT_HIGH_COUNT = 12;
//    localparam BIT_MED_COUNT = 35;
//    localparam BIT_LOW_COUNT = 12;
//    localparam DELAY_COUNT = 18000;

    // Timings for a 24MHz clock
    localparam BIT_HIGH_COUNT = 6;
    localparam BIT_MED_COUNT = 18;
    localparam BIT_LOW_COUNT = 6;
    localparam DELAY_COUNT = 9000;


    reg [15:0] values [(WORD_COUNT-1):0];
    initial begin
        $readmemh("ws2812_8x8_test.list", values);
    end

    // TODO: Make a memory bus, wire this module into it
    always @(posedge clk)
        if(spi_write_strobe)
            values[spi_address] <= spi_data;

    reg [2:0] state;
    reg [15:0] counter;         // TODO: Verify if lower count is ok

    reg [ADDRESS_BUS_WIDTH:0] word_index;      // Word we are currently clocking out
    reg [4:0] bit_index;        // Bit we are currently clocking out
    reg [15:0] val;             // Value of word we are currently clocking out

    always @(posedge clk)
    begin
        // TODO: implement WS2813 backup data signal
        backup_out = 0;

        if(rst) begin
            word_index <= 0;
            bit_index <= 15;
            state <= 0;
            data_out <= 0;
        end
        else begin
            data_out <= 0;
            counter <= counter + 1;

            case(state)
            0:  // Setup
            begin
                bit_index <= 15;
                state <= 1;

                counter <= 0;
                val <= values[word_index];
                word_index <= 1;
            end
            1:  // Bit High
            begin
                data_out <= 1;

                if(counter == BIT_HIGH_COUNT) begin
                    counter <= 0;
                    state <= state + 1;
                end
            end
            2:  // Bit Med
            begin
                data_out <= val[bit_index];

                if(counter == BIT_MED_COUNT) begin
                    counter <= 0;
                    state <= state + 1;
                end
            end
            3:  // Bit Low
            begin
                data_out <= 0;

                if(counter == BIT_LOW_COUNT) begin
                    counter <= 0;
                    state <= 1;

                    bit_index <= bit_index - 1;

                    if(bit_index == 0) begin
                        bit_index <= 15;
                        word_index <= word_index + 1;
                        val = values[word_index];    // TODO: Read this after we've incremented, for faster access

                        if(word_index == WORD_COUNT) begin      // Reached end of bytes, delay now
                            state <= state + 1;
                        end
                    end
                end
            end
            4:  // Delay
            begin
                data_out <= 0;
                
                if(counter == DELAY_COUNT) begin
                    word_index <= 0;

                    counter <= 0;
                    state <= 0;
                end
            end
            default:
                state <= 0;

            endcase
        end
    end
endmodule
