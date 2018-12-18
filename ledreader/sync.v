module sync_ss(
    input clk,
    input reset,
    input async_in,
    output synch_out);

    reg meta;
    reg synch_out_reg;

    assign synch_out = synch_out_reg;

always @(posedge clk)
    if (reset) begin
        meta <= 1'b0;
        synch_out_reg <= 1'b0;
    end
    else begin
        meta <= async_in;
        synch_out_reg <= meta;
    end

endmodule
