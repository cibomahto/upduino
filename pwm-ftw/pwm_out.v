module pwm_out(
    input clock,
    input reset,
    input [15:0] v0,
    input [15:0] v1,
    input [15:0] v2,
    input [15:0] v3,
    input [15:0] v4,
    input [15:0] v5,
    input [15:0] v6,
    input [15:0] v7,
    output o0,
    output o1,
    output o2,
    output o3,
    output o4,
    output o5,
    output o6,
    output o7,
);

	reg [15:0] count;

    reg [7:0] outputRegs;

    assign o0 = !outputRegs[0];
    assign o1 = !outputRegs[1];
    assign o2 = !outputRegs[2];
    assign o3 = !outputRegs[3];
    assign o4 = !outputRegs[4];
    assign o5 = !outputRegs[5];
    assign o6 = !outputRegs[6];
    assign o7 = !outputRegs[7];

    always @(posedge clock)
        if(reset) begin
            count <= 0;
            outputRegs <= 0;
        end
        else begin
            count <= count + 1;

            outputRegs <= 0;

            if(v0 > count[15:0])
                outputRegs[0] <= 1;
            if(v1 > count[15:0])
                outputRegs[1] <= 1;
            if(v2 > count[15:0])
                outputRegs[2] <= 1;
            if(v3 > count[15:0])
                outputRegs[3] <= 1;
            if(v4 > count[15:0])
                outputRegs[4] <= 1;
            if(v5 > count[15:0])
                outputRegs[5] <= 1;
            if(v6 > count[15:0])
                outputRegs[6] <= 1;
            if(v7 > count[15:0])
                outputRegs[7] <= 1;
        end
endmodule
