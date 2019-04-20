module srff(
    input clk,
    input rst,

	input r,
    input s,

	output reg q,
    output reg q1,
);

	always @(posedge clk)
        if(rst) begin
            q <= 1;
            q1 <= 1;
        end
        else begin
            case({s,r})
                {1'b0,1'b0}:
                begin
                    q=q;
                    q1=q1;
                end
		        {1'b0,1'b1}:
                begin
                    q=1'b0;
                    q1=1'b1;
                end
		        {1'b1,1'b0}:
                begin
                    q=1'b1;
                    q1=1'b0;
                end
		 
                {1'b1,1'b1}:
                begin
                    q=1'bx;
                    q=1'bx;
                end
	        endcase
	    end
endmodule
