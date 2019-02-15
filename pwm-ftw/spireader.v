module spireader(
    input clock,
    input reset,
    input din,
    input cin,
    output dout,
    output cout,
    output [15:0] v0,
    output [15:0] v1,
    output [15:0] v2,
    output [15:0] v3,
    output [15:0] v4,
    output [15:0] v5,
    output [15:0] v6,
    output [15:0] v7
);
    reg [16:0] timeoutCount;

    reg [15:0] values [7:0];
    initial begin
        $readmemh("values.list", values);
    end

    wire         din_sync;
    wire         cin_sync;
    sync_ss din_sync_ss(clock, reset, din, din_sync);
    sync_ss cin_sync_ss(clock, reset, cin, cin_sync);

    assign v0 = values[0];
    assign v1 = values[1];
    assign v2 = values[2];
    assign v3 = values[3];
    assign v4 = values[4];
    assign v5 = values[5];
    assign v6 = values[6];
    assign v7 = values[7];

    reg dout_reg;
    reg cout_reg;

    assign dout = dout_reg;
    assign cout = cout_reg;

    reg [5:0] bitIndex;
    reg [3:0] wordIndex;

    reg cin_sync_prev;

    always @(posedge clock)
    begin
        cin_sync_prev <= cin_sync;

        //dout_reg <= din_sync;
        dout_reg <= 0;
        cout_reg <= cin_sync;

        // If we just got a clock, do the clock dance
        if((cin_sync == 1) && (cin_sync_prev == 0)) begin

            bitIndex <= bitIndex + 1;

            values[wordIndex][15-bitIndex] <= din_sync;

            if(bitIndex == 15) begin
                wordIndex <= wordIndex + 1;
                bitIndex <= 0;

                if(wordIndex == 7) begin
                    dout_reg <= 1;
                    wordIndex <= 0;
                end
            end
        end

        // Otherwise, see if we need to timeout

        /*
        count <= count + 9;

        if(count < 10) begin
            values[0] <= values[0] + 1;
            values[1] <= values[1] + 1;
            values[2] <= values[2] + 1;
            values[3] <= values[3] + 1;
            values[4] <= values[4] + 1;
            values[5] <= values[5] + 1;
            values[6] <= values[6] + 1;
            values[7] <= values[7] + 1;
        end
        */
    end

endmodule
