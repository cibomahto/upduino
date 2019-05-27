`include "functions.vh"

module clock_divider #(
    parameter DIVIDER_BITS = 4,
) (
    input clk,
    input rst,

    input [(clogb2(DIVIDER_BITS)-1):0] divisor,
    output reg clk_out,
);
    reg [(DIVIDER_BITS - 1):0] clockdiv;

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
