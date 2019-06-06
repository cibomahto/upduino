module chip (
    input   DMX_IN,

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

    output DEBUG_0,
    output DEBUG_1,
    output DEBUG_2,
    output DEBUG_3,
    output DEBUG_4,
    output DEBUG_5,
    output DEBUG_6,
    output DEBUG_7,
);

    localparam LED_COLS = 12;
    localparam LED_ROWS = 4;
    localparam CHANNELS_PER_LED = 4;
    localparam LED_CHANNELS = (LED_COLS * LED_ROWS * CHANNELS_PER_LED);

	wire clk;
    wire rst;
    wire led_r;
    wire led_g;
    wire led_b;

    wire start_flag;

    assign rst = 0;

    // Configure the clock for 24 MHz operation
    // TODO: Nextpnr says we can't hit 48MHz?
	SB_HFOSC u_hfosc (
       	.CLKHFPU(1'b1),
       	.CLKHFEN(1'b1),
        .CLKHF(clk)
    );
    defparam u_hfosc.CLKHF_DIV = "0b00";    // 48 MHz
//    defparam u_hfosc.CLKHF_DIV = "0b01";    // 24 MHz
//    defparam u_hfosc.CLKHF_DIV = "0b10";    // 12 MHz
//    defparam u_hfosc.CLKHF_DIV = "0b11";    // 6 MHz

    wire [8:0] dmx_address;
    wire [7:0] dmx_data;
    wire dmx_write_strobe;

    dmx_in #(
        .DMX_CHANNELS(LED_CHANNELS),
    )my_dmx_in(
        .clk(clk),
        .rst(rst),

        .dmx_in(DMX_IN),

        .address(dmx_address),
        .data(dmx_data),
        .write_strobe(dmx_write_strobe),
    );

    matrix_out matrix_out_1 (
        .clk(clk),
        .rst(0),

        .address_in(dmx_address),
        .data_in(dmx_data),
        .write_strobe_in(dmx_write_strobe),

        .sdi(SDI),
        .dclk(DCLK),
        .le(LE),
        .gclk(GCLK),
        .a(A),
        .b(B),
        .c(C),
        .d(D)
    );

    assign LED_R = 1;
    assign LED_B = 1;
    assign LED_G = 1;

    assign DEBUG_0 = SDI;
    assign DEBUG_1 = DCLK;
    assign DEBUG_2 = LE;
    assign DEBUG_3 = GCLK;
    assign DEBUG_4 = A;
    assign DEBUG_5 = B;
    assign DEBUG_6 = C;
    assign DEBUG_7 = D;

endmodule
