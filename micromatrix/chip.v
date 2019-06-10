module chip (
    input   DMX_IN,

    output RS485_RE,
    output RS485_DE,

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

    localparam LED_BOARDS = 3;
    localparam OUTPUTS_PER_BOARD = 16;
    localparam LED_ROWS = 4;
    localparam LED_CHANNELS = (LED_BOARDS * OUTPUTS_PER_BOARD * LED_ROWS);

	wire clk;
    wire rst;
    wire led_r;
    wire led_g;
    wire led_b;

    wire start_flag;

    assign RS485_RE = 0;
    assign RS485_DE = 0;

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
endmodule
