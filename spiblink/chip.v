
module chip (
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
        output  START_FLAG
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

        icnd2110 my_icnd_0(
                .clk(halfclock[0]),
                .rst(0),
                .chipcount(200),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_0),
                .spi_d(SPI_D_0),
                .start_flag(START_FLAG)
        );

        assign SPI_C_1 = 0;
        assign SPI_D_1 = 0;
        assign SPI_C_2 = 0;
        assign SPI_D_2 = 0;
        assign SPI_C_3 = 0;
        assign SPI_D_3 = 0;

/*
        icnd2110 my_icnd_1(
                .clk(halfclock[0]),
                .rst(0),
                .chipcount(200),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_1),
                .spi_d(SPI_D_1),
                .start_flag()
        );

        icnd2110 my_icnd_2(
                .clk(halfclock[0]),
                .rst(0),
                .chipcount(200),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_2),
                .spi_d(SPI_D_2),
                .start_flag()
        );

        icnd2110 my_icnd_3(
                .clk(halfclock[0]),
                .rst(0),
                .chipcount(200),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_3),
                .spi_d(SPI_D_3),
                .start_flag()
        );
*/
endmodule
