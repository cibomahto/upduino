module ws2812_out (
    input clock,
    input reset,

    input [15:0] spi_data,
    input [12:0] spi_address,
    input spi_write_strobe,

    output reg data,
);

    // We have a 30*29*3 = 2610 byte = 1305 word screen.
    reg [15:0] values [1304:0];
    initial begin
        $readmemh("test_data.list", values);
    end

    // TODO: Make a memory bus, wire this module into it
    always @(posedge clock)
    begin
        if(spi_write_strobe) begin
            values[spi_address] <= spi_data;
        end
    end


    reg [2:0] state;
    reg [20:0] counter;

    reg [12:0] wordIndex;       // Word we are currently clocking out
    reg [4:0] bitIndex;         // Bit we are currently clocking out
    reg [15:0] val;             // Value of word we are currently clocking out

    reg data;

    always @(posedge clock)
    begin
        if(reset) begin
            wordIndex <= 0;
            bitIndex <= 15;
            state <= 0;
            data <= 0;
        end
        else begin
            data <= 0;
            counter <= counter + 1;

            case(state)
            0:  // Setup
            begin
                bitIndex <= 15;
                state <= 1;

                counter <= 0;
                val <= values[wordIndex];
                wordIndex <= 1;
            end
            1:  // Bit High
            begin
                data <= 1;

                if(counter == 12) begin
                    counter <= 0;
                    state <= state + 1;
                end
            end
            2:  // Bit Med
            begin
                data <= val[bitIndex];

                if(counter == 35) begin
                    counter <= 0;
                    state <= state + 1;
                end
            end
            3:  // Bit Low
            begin
                data <= 0;

                if(counter == 12) begin
                    counter <= 0;
                    state <= 1;

                    bitIndex <= bitIndex - 1;

                    if(bitIndex == 0) begin
                        bitIndex <= 15;
                        wordIndex <= wordIndex + 1;
                        val = values[wordIndex];    // TODO: Read this after we've incremented, for faster access

                        if(wordIndex == 1305) begin      // Reached end of bytes, delay now
                            state <= state + 1;
                        end
                    end
                end
            end
            4:  // Delay
            begin
                data <= 0;
                
                if(counter == 18000) begin
                    wordIndex <= 0;

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
