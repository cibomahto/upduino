
parameter BYTECOUNT = (3*4*6);

module chip (
        input   WS2812_IN_0,
	output  LED_R,
	output	LED_G,
	output  LED_B,
        output  SPI_C_0,
        output  SPI_D_0,
        output  SPI_C_1,
        output  SPI_D_1,
        output  SPI_C_2,
        output  SPI_D_2,
        output  SPI_C_3,
        output  SPI_D_3,
        output  SPI_C_4,
        output  SPI_D_4,
        output  SPI_C_5,
        output  SPI_D_5,
        output  SPI_C_6,
        output  SPI_D_6,
        output  SPI_C_7,
        output  SPI_D_7,

        output  DEBUG_0,
        output  DEBUG_1,
        output  DEBUG_2,
        output  DEBUG_3,
        output  DEBUG_4,
        output  DEBUG_5,
        output  DEBUG_6,
        output  DEBUG_7,
        output  DEBUG_8,
        output  DEBUG_9,
        output  DEBUG_10,
        output  DEBUG_11,
        output  DEBUG_12,
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

	blink my_blink (
		.clk(clk),
		.rst(0),
    		.led_r(led_r),
    		.led_g(led_g),
    		.led_b(led_b)
	);

	assign LED_R = led_r;
	assign LED_G = led_g;
	assign LED_B = led_b;

        wire [12:0] debug;

        assign DEBUG_0 = debug[0];
        assign DEBUG_1 = debug[1];
        assign DEBUG_2 = debug[2];
        assign DEBUG_3 = debug[3];
        assign DEBUG_4 = debug[4];
        assign DEBUG_5 = debug[5];
        assign DEBUG_6 = debug[6];
        assign DEBUG_7 = debug[7];
        assign DEBUG_8 = debug[8];
        assign DEBUG_9 = debug[9];
        assign DEBUG_10 = debug[10];
        assign DEBUG_11 = debug[11];
        assign DEBUG_12 = debug[12];

        icnd2110 my_icnd_0(
                .clk(halfclock[0]),
                .rst(0),
                .bytecount(BYTECOUNT),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .in_input(WS2812_IN_0),
                .spi_c(SPI_C_0),
                .spi_d(SPI_D_0),
                .start_flag(),
                .in_debug(debug)
        );
        assign SPI_C_1 = 0;
        assign SPI_D_1 = 0;
        assign SPI_C_2 = 0;
        assign SPI_D_2 = 0;
        assign SPI_C_3 = 0;
        assign SPI_D_3 = 0;
        assign SPI_C_4 = 0;
        assign SPI_D_4 = 0;
        assign SPI_C_5 = 0;
        assign SPI_D_5 = 0;
        assign SPI_C_6 = 0;
        assign SPI_D_6 = 0;
        assign SPI_C_7 = 0;
        assign SPI_D_7 = 0;

/*
        icnd2110 my_icnd_1(
                .clk(halfclock[0]),
                .rst(0),
                .bytecount(BYTECOUNT),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_1),
                .spi_d(SPI_D_1),
                .start_flag()
        );

        icnd2110 my_icnd_2(
                .clk(halfclock[0]),
                .rst(0),
                .bytecount(BYTECOUNT),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_2),
                .spi_d(SPI_D_2),
                .start_flag()
        );

        icnd2110 my_icnd_3(
                .clk(halfclock[0]),
                .rst(0),
                .bytecount(BYTECOUNT),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_3),
                .spi_d(SPI_D_3),
                .start_flag()
        )
;
        icnd2110 my_icnd_4(
                .clk(halfclock[0]),
                .rst(0),
                .bytecount(BYTECOUNT),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_4),
                .spi_d(SPI_D_4),
                .start_flag()
        );

        icnd2110 my_icnd_5(
                .clk(halfclock[0]),
                .rst(0),
                .bytecount(BYTECOUNT),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_5),
                .spi_d(SPI_D_5),
                .start_flag()
        );

        icnd2110 my_icnd_6(
                .clk(halfclock[0]),
                .rst(0),
                .bytecount(BYTECOUNT),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_6),
                .spi_d(SPI_D_6),
                .start_flag()
        );

        icnd2110 my_icnd_7(
                .clk(halfclock[0]),
                .rst(0),
                .bytecount(BYTECOUNT),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_7),
                .spi_d(SPI_D_7),
                .start_flag()
        );
*/

endmodule
