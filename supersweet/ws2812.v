module ws2812 (
    input clock,
    input reset,

    input [15:0] spiData,
    input [10:0] spiAddress,
    input spiReadStrobe,

    output data
);
    // We have a 30*29*3 = 2610 byte = 1305 word screen.
    reg [15:0] values [1304:0];

    reg [20:0] counter;
    reg [2:0] state;

    reg [12:0] wordIndex;       // Word we are currently clocking out
    reg [4:0] bitIndex;         // Bit we are currently clocking out
    reg [15:0] val;             // Value of word we are currently clocking out

    reg dataReg;
    assign data = dataReg;

    always @(posedge clock)
    begin
        if(spiReadStrobe) begin
            values[spiAddress] <= spiData;
        end
    end


    always @(posedge clock)
    begin
        if(reset) begin
            wordIndex <= 0;
            bitIndex <= 15;
            state <= 0;
            dataReg <= 0;
        end
        else begin
            dataReg <= 0;
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
                dataReg <= 1;

                if(counter == 12) begin
                    counter <= 0;
                    state <= state + 1;
                end
            end
            2:  // Bit Med
            begin
                dataReg <= val[bitIndex];

                if(counter == 35) begin
                    counter <= 0;
                    state <= state + 1;
                end
            end
            3:  // Bit Low
            begin
                dataReg <= 0;

                if(counter == 12) begin
                    counter <= 0;
                    state <= 1;

                    bitIndex <= bitIndex - 1;

                    if(bitIndex == 0) begin
                        bitIndex <= 15;
                        wordIndex <= wordIndex + 1;
                        val = values[wordIndex];    // TODO: Read this after we've incremented, for faster access

                        if(wordIndex == 1304) begin      // Reached end of bytes, delay now
                            state <= state + 1;
                        end
                    end
                end
            end
            4:  // Delay
            begin
                dataReg <= 0;
                
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
