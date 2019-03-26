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

    localparam ADDRESS_BUS_WIDTH = 13;

    wire clk;
    wire rst;

    wire pll_clock;
    wire pll_locked;


    // TODO: Hardware reset line
    assign rst = 0;
    //assign rst = !pll_locked;

    // Configure the HFOSC
	SB_HFOSC u_hfosc (
       	.CLKHFPU(1'b1),
       	.CLKHFEN(1'b1),
        .CLKHF(clk)
    );
    defparam u_hfosc.CLKHF_DIV = "0b01"; // 00: 48MHz, 01: 24MHz, 10: 12MHz, 11: 6MHz

    /*
    pll my_pll(
        .clock_in(clk),
        .clock_out(pll_clock),
        .locked(pll_locked),
    );
    */


    wire [15:0] spi_data;
    wire [ADDRESS_BUS_WIDTH:0] spi_word_address;
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


    localparam OUTPUT_COUNT = 4;

    localparam OUT_1_WORDS = (112*3*8); // 112 LEDs = 336 16-bit channels/board, and 8 boards.
    localparam OUT_2_WORDS = (112*3*8);
    localparam OUT_3_WORDS = (112*3*4);
    localparam OUT_4_WORDS = (8*8*3/2); // Extra 8x8 matrix of WS2812 LEDs

    localparam OUT_1_OFFSET = 0;
    localparam OUT_2_OFFSET = OUT_1_OFFSET + OUT_1_WORDS;
    localparam OUT_3_OFFSET = OUT_2_OFFSET + OUT_2_WORDS;
    localparam OUT_4_OFFSET = OUT_3_OFFSET + OUT_3_WORDS;

    reg [(OUTPUT_COUNT-1):0] output_write_strobes;
    reg [ADDRESS_BUS_WIDTH:0] output_addresses [(OUTPUT_COUNT-1):0];

    always @(posedge clk) begin

        output_write_strobes <= 0;

        output_addresses[0] <= (spi_word_address - OUT_1_OFFSET);
        output_addresses[1] <= (spi_word_address - OUT_2_OFFSET);
        output_addresses[2] <= (spi_word_address - OUT_3_OFFSET);
        output_addresses[3] <= (spi_word_address - OUT_4_OFFSET);

        if(spi_write_strobe) begin
            if(spi_word_address < (OUT_1_OFFSET + OUT_1_WORDS))
                output_write_strobes[0] <= 1;
            else if(spi_word_address < (OUT_2_OFFSET + OUT_2_WORDS))
                output_write_strobes[1] <= 1;
            else if(spi_word_address < (OUT_3_OFFSET + OUT_3_WORDS))
                output_write_strobes[2] <= 1;
            else if(spi_word_address < (OUT_4_OFFSET + OUT_4_WORDS))
                output_write_strobes[3] <= 1;
        end
    end

//    assign DATA3 = spi_write_strobe;
//    assign CLOCK3 = out_1_write_strobe;
//    assign DATA4 = out_2_write_strobe;


/*
//    reg [15:0] ram_data_in;
//    reg [13:0] ram_addr;
    wire [15:0] ram_data_out;
//    reg ram_cs;

    SB_SPRAM256KA ramfn_inst1(
        .DATAIN(spi_data),
        .ADDRESS({1'b0,spi_address}),
        .MASKWREN( 4'b1111),
        .WREN(1'b1),
        .CHIPSELECT(spi_write_strobe),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(ram_data_out)
    );
*/

    wire [15:0] val;
    wire sob;

    icnd2110_out icnd2110_out_1(
        .clk(clk),
        .rst(rst),
        
        .spi_data(spi_data),
        .spi_address(output_addresses[0]),
        .spi_write_strobe(output_write_strobes[0]),

        .data_out(DATA_1),
        .clock_out(CLOCK_1),
        .val(val),
        .sob(sob),
    );
    defparam icnd2110_out_1.WORD_COUNT = OUT_1_WORDS;
    defparam icnd2110_out_1.ADDRESS_BUS_WIDTH = ADDRESS_BUS_WIDTH;


    assign DATA_3 = sob;
    assign CLOCK_3 = val[4];
    assign DATA_5 =  val[3];
    assign CLOCK_5 = val[2];
    assign DATA_7 =  val[1];
    assign CLOCK_7 = val[0];

    icnd2110_out icnd2110_out_2(
        .clk(clk),
        .rst(rst),
        
        .spi_data(spi_data),
        .spi_address(output_addresses[1]),
        .spi_write_strobe(output_write_strobes[1]),

        .data_out(DATA_2),
        .clock_out(CLOCK_2),
    );
    defparam icnd2110_out_2.WORD_COUNT = OUT_2_WORDS;
    defparam icnd2110_out_2.ADDRESS_BUS_WIDTH = ADDRESS_BUS_WIDTH;

/*
    icnd2110_out icnd2110_out_3(
        .clk(clk),
        .rst(rst),
        
        .spi_data(spi_data),
        .spi_address(output_addresses[2]),
        .spi_write_strobe(output_write_strobes[2]),

        .data_out(DATA_3),
        .clock_out(CLOCK_3),
    );
    defparam icnd2110_out_3.WORD_COUNT = OUT_3_WORDS;
    defparam icnd2110_out_3.ADDRESS_BUS_WIDTH = ADDRESS_BUS_WIDTH;
*/
    ws2812_out ws2812_out_4(
        .clk(clk),
        .rst(rst),
        
        .spi_data(spi_data),
        .spi_address(output_addresses[3]),
        .spi_write_strobe(output_write_strobes[3]),

        .data_out(DATA_4),
        .backup_out(CLOCK_4),
    );
    defparam ws2812_out_4.WORD_COUNT = OUT_4_WORDS;
    defparam ws2812_out_4.ADDRESS_BUS_WIDTH = ADDRESS_BUS_WIDTH;

    // Configure DMX as passthrough
    assign DMX_OUT = DMX_IN;

    // Repeat outputs

//    assign DATA_2 = DATA_1;
//    assign CLOCK_2 = CLOCK_1;
//    assign DATA_5 = DATA_1;
//    assign CLOCK_5 = CLOCK_1;
    assign DATA_6 = DATA_1;
    assign CLOCK_6 = CLOCK_1;
//    assign DATA_7 = DATA_1;
//    assign CLOCK_7 = CLOCK_1;
    assign DATA_8 = DATA_1;
    assign CLOCK_8 = CLOCK_1;
    assign DATA_9 = DATA_1;
    assign CLOCK_9 = CLOCK_1;
    assign DATA_10 = DATA_1;
    assign CLOCK_10 = CLOCK_1;

    assign RGB0 = 0;
    assign RGB1 = 1;
    assign RGB2 = 0;

endmodule
