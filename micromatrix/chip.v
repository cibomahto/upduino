
parameter BYTECOUNT = (112*3);

module chip (
        output  SDI,
        output  DCLK,
        output  LE,
        output  GCLK,
        output  A,
        output  B,
        output  C,
        output  D,

        output LED_R,
        output LED_G,
        output LED_B,
	);

	wire clk;
        wire led_r;
        wire led_g;
        wire led_b;

        wire start_flag;

        reg [1:0] halfclock;

        always @(posedge clk)
            halfclock <= halfclock + 1;

	SB_HFOSC u_hfosc (
        	.CLKHFPU(1'b1),
        	.CLKHFEN(1'b1),
        	.CLKHF(clk)
    	);

    assign LED_R = led_r;
    assign LED_B = led_g;
    assign LED_G = led_b;


	blink my_blink (
		.clk(clk),
		.rst(0),
    		.led_r(led_r),
    		.led_g(led_g),
    		.led_b(led_b)
	);

        wire [5:0] debug;
/*
        assign TP_1 = debug[0];
        assign TP_2 = debug[1];
        assign TP_3 = debug[2];
        assign TP_4 = debug[3];
        assign TP_5 = debug[4];
        assign TP_7 = debug[5];

        assign debug = 0;
*/
    matrix my_matrix (
        .clk(clk),
        .rst(0),
        .sdi(SDI),
        .dclk(DCLK),
        .le(LE),
        .gclk(GCLK),
        .a(A),
        .b(B),
        .c(C),
        .d(D)
    );

endmodule
