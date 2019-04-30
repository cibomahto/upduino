module clock_divider #(
) (
    input clk,
    input rst,

    input [1:0] divisor,
    output reg clk_out,
);
    reg [3:0] clockdiv;

    always @(posedge clk) begin
//        if(rst) begin
//            clockdiv <= 0;
//            clk_out <= 0;
//        end
//        else begin
            clockdiv <= clockdiv + 1;
            clk_out <= clockdiv[divisor];
//        end
    end

endmodule
