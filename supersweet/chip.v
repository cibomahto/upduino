module chip (
    input LED_CS,
    input LED_SCK,
    input LED_MOSI,
    output LED_MISO,

    output DATA1,
//    output CLOCK1,
//    output DATA2,
//    output CLOCK2,
//    output DATA3,
//    output CLOCK3,
//    output DATA4,
//    output CLOCK4,
);

    wire clock;
    wire reset;

    // TODO: Hardware reset line
    assign reset = 0;

    // Configure the clock for 48 MHz operation (TODO: Seems like 24MHz?)
	SB_HFOSC u_hfosc (
       	.CLKHFPU(1'b1),
       	.CLKHFEN(1'b1),
        .CLKHF(clock)
    );
//    defparam u_hfosc.CLKHF_DIV = 2'b01; // 00: 48MHz 01: 24MHz 10: 12MHz 11: 6MHz
    defparam u_hfosc.CLKHF_DIV = "0b00";

    wire [15:0] spi_data;
    wire [10:0] spi_address;
    wire spi_write_strobe;

    spi_in my_spi_in(
        .cs(LED_CS),
        .sck(LED_SCK),
        .mosi(LED_MOSI),
        .miso(LED_MISO),

        .clock(clock),
        .data(spi_data),
        .address(spi_address),
        .write_strobe(spi_write_strobe)
    );

    ws2812_out my_ws2812_out(
        .clock(clock),
        .reset(reset),
        
        .spi_data(spi_data),
        .spi_address(spi_address),
        .spi_write_strobe(spi_write_strobe),

        .data(DATA1)
    );
endmodule
