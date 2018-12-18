module onewireled(
    input clk,
    input rst,
    input [11:0] bytecount,
    input [7:0] hightime,
    input [7:0] midtime,
    input [7:0] lowtime,
    output led_d
);

    reg data;

    reg [11:0] bytes;
    reg [2:0] bits;
    reg [3:0] state;

    reg [7:0] counter;
    reg [7:0] currentbyte;

    assign led_d = data;


    always @(posedge clk)
        if(rst) begin
            state <= 0;
            
            data <= 0;
        end
        else begin

            data <= 0;

            case(state)
            // 0: Wait for start
            0:
                // TODO: implement start signal
                begin
                    state <= 1;
                    counter <+ 0;

                    bytes <= bytecount;

                    // load data for first bit
                    currentbyte = bytes;  // TODO
                    bits <= 7;
                end
            // 2: High time
            1:
                begin
                    data <= 0;
                    
                    counter <= counter + 1;

                    if(counter == hightime) begin
                        state <= state + 1;
                        counter <= 0;
                    end
                end
            // 2: Medium time
            2:
                begin
                    data <= currentbyte[7];
                    
                    counter <= counter + 1;

                    if(counter == medtime) begin
                        state <= state + 1;
                        counter <= 0;

                        currentbyte <= (currentbyte << 1);
                        bits <= (bits - 1);
                    end
                end
            // 3: Low time
            3:
                begin
                    data <= 0;
                    
                    counter <= counter + 1;

                    if(counter == lowtime) begin
                        if(bits > 0) begin
                            state <= 1;
                            counter <= 0;
                        end
                        else if(bytes > 0) begin
                            state <= 1;
                        if( 
                    end
                end

        end

endmodule
