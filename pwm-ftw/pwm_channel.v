module pwm_channel(
    input clk,              // System clock
    input rst,              // System reset

    input [15:0] value,     // Target PWM value
    output reg out,         // PWM output bit
);
    reg [15:0] count;

    always @(posedge clk)
        if(rst) begin
            count <= 0;
            out <= 0;
        end
        else begin
            count <= count + 1;

            if(count == 0)
                out <= 1;

            if(count == value)
                out <= 0;
        end
endmodule
