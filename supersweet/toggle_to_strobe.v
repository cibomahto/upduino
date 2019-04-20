module toggle_to_strobe(
    input clk,

    input toggle_in,
    output reg strobe_out,
);
    reg toggle_in_last;

    always @(posedge clk) begin
        toggle_in_last <= toggle_in;
        strobe_out <= 0;

        if(toggle_in != toggle_in_last)
            strobe_out <= 1;

    end

endmodule
