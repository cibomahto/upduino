
module chip (
	output  LED_R,
	output	LED_G,
	output  LED_B,
        output  SPI_C_0,
        output  SPI_D_0,
        output  START_FLAG
	);

	wire clk;
        wire led_r;
        wire led_g;
        wire led_b;

        wire start_flag;

	SB_HFOSC u_hfosc (
        	.CLKHFPU(1'b1),
        	.CLKHFEN(1'b1),
        	.CLKHF(clk)
    	);
    defparam u_hfosc.CLKHF_DIV = "0b01"; // 00: 48MHz, 01: 24MHz, 10: 12MHz, 11: 6MHz

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
                .clk(clk),
                .rst(0),
                .chipcount(200),
                .cfg_pwm_wider(0),
                .cfg_up(1),
                .spi_c(SPI_C_0),
                .spi_d(SPI_D_0),
                .start_flag(START_FLAG)
        );

endmodule
