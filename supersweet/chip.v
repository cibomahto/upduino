module chip (
    input LED_CS,
    input LED_SCK,
    input LED_MOSI,
    output LED_MISO,

    output DATA_1,
    output CLOCK_1,
    output DATA_2,
    output CLOCK_2,
    output DATA_3,
    output CLOCK_3,
    output DATA_4,
    output CLOCK_4,
    output DATA_5,
    output CLOCK_5,
    output DATA_6,
    output CLOCK_6,
    output DATA_7,
    output CLOCK_7,
    output DATA_8,
    output CLOCK_8,
    output DATA_9,
    output CLOCK_9,
    output DATA_10,
    output CLOCK_10,

    output RGB0,
    output RGB1,
    output RGB2,

    input DMX_IN,
    output DMX_OUT,
);

    localparam ADDRESS_BUS_WIDTH = 14;
    localparam OUTPUT_COUNT = 4;

    // For Teddy Lo Waking Life
    localparam OUT_1_WORDS = (112*3*8); // 112 LEDs = 336 16-bit channels/board, and 8 boards.
    localparam OUT_2_WORDS = (112*3*8);
    localparam OUT_3_WORDS = (112*3*4);
    localparam OUT_4_WORDS = (8*8*3/2); // Extra 8x8 matrix of WS2812 LEDs

    localparam OUT_1_OFFSET = 0;
    localparam OUT_2_OFFSET = OUT_1_OFFSET + OUT_1_WORDS;
    localparam OUT_3_OFFSET = OUT_2_OFFSET + OUT_2_WORDS;
    localparam OUT_4_OFFSET = OUT_3_OFFSET + OUT_3_WORDS;

    wire clk;
    wire rst;

    assign rst = 0; // TODO: Hardware reset input

    // Configure the HFOSC
	SB_HFOSC u_hfosc (
       	.CLKHFPU(1'b1),
       	.CLKHFEN(1'b1),
        .CLKHF(clk)
    );
    defparam u_hfosc.CLKHF_DIV = "0b01"; // 00: 48MHz, 01: 24MHz, 10: 12MHz, 11: 6MHz

    wire [15:0] spi_data;
    wire [(ADDRESS_BUS_WIDTH-1):0] spi_word_address;
    wire spi_write_strobe;

    spi_in spi_in_1(
        .cs(LED_CS),
        .sck(LED_SCK),
        .mosi(LED_MOSI),
        .miso(LED_MISO),

        .clk(clk),
        .data(spi_data),
        .address(spi_word_address),
        .write_strobe(spi_write_strobe)
    );
    defparam spi_in_1.ADDRESS_BUS_WIDTH = ADDRESS_BUS_WIDTH;

    wire [(ADDRESS_BUS_WIDTH-1):0] read_address_1;
    wire read_strobe_1;
    wire read_finished_strobe_1;

    wire [15:0] read_data;

    wire start_read_strobe_1;

    icnd2110_out icnd2110_out_1(
        .clk(clk),
        .rst(rst),
       
        .read_address(read_address_1),
        .read_strobe(read_strobe_1),
        .read_data(read_data),
        .read_finished_strobe(read_finished_strobe_1),

        .data_out(DATA_1),
        .clock_out(CLOCK_1),

        .start_read_strobe(start_read_strobe_1),
    );
    defparam icnd2110_out_1.ADDRESS_BUS_WIDTH = ADDRESS_BUS_WIDTH;
    defparam icnd2110_out_1.WORD_COUNT = OUT_1_WORDS;
    defparam icnd2110_out_1.START_ADDRESS = OUT_1_OFFSET;

    wire [(ADDRESS_BUS_WIDTH-1):0] read_address_2;
    wire read_strobe_2;
    wire read_finished_strobe_2;

    icnd2110_out icnd2110_out_2(
        .clk(clk),
        .rst(rst),
        
        .read_address(read_address_2),
        .read_strobe(read_strobe_2),
        .read_data(read_data),
        .read_finished_strobe(read_finished_strobe_2),

        .data_out(DATA_2),
        .clock_out(CLOCK_2),
    );
    defparam icnd2110_out_2.ADDRESS_BUS_WIDTH = ADDRESS_BUS_WIDTH;
    defparam icnd2110_out_2.WORD_COUNT = OUT_2_WORDS;
    defparam icnd2110_out_2.START_ADDRESS = OUT_2_OFFSET;


    wire [1:0] state;

    sram_bus sram_bus_1(
        .clk(clk),
        .rst(rst),

        .write_address(spi_word_address),
        .write_data(spi_data),
        .write_strobe(spi_write_strobe),

        .read_address_1(read_address_1),
        .read_strobe_1(read_strobe_1),
        .read_finished_strobe_1(read_finished_strobe_1),

        .read_address_2(read_address_2),
        .read_strobe_2(read_strobe_2),
        .read_finished_strobe_2(read_finished_strobe_2),

        .read_data(read_data),

        .state(state),
    );
    defparam sram_bus_1.ADDRESS_BUS_WIDTH = ADDRESS_BUS_WIDTH;


    // Debug outputs
    assign DATA_3 = spi_write_strobe;
    assign CLOCK_3 = read_strobe_1;
    assign DATA_5 =  read_finished_strobe_1;
    assign CLOCK_5 = read_strobe_2;
    assign DATA_7 =  read_finished_strobe_2;
    assign CLOCK_7 = state[1];
    assign DATA_9 = state[0];
    assign CLOCK_9 = start_read_strobe_1;

    // Configure DMX as passthrough
    assign DMX_OUT = DMX_IN;

    // LEDs do nothing
    assign RGB0 = 0;
    assign RGB1 = 1;
    assign RGB2 = 0;

    // Stub disabled outputs
    assign DATA_4 = 0;
    assign CLOCK_4 = 0;
    assign DATA_6 = 0;
    assign CLOCK_6 = 0;
    assign DATA_8 = 0;
    assign CLOCK_8 = 0;
    assign DATA_10 = 0;
    assign CLOCK_10 = 0;


endmodule
