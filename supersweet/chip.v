module chip (
    input LED_CS,
    input LED_SCK,
    input LED_MOSI,
    output LED_MISO,

    output DATA1,
//    output CLOCK1,
    output DATA2,
    output CLOCK2,
    output DATA3,
    output CLOCK3,
    output DATA4,
    output CLOCK4,
);

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
    wire [12:0] spi_word_address;
    wire spi_write_strobe;

    spi_in my_spi_in(
        .cs(LED_CS),
        .sck(LED_SCK),
        .mosi(LED_MOSI),
        .miso(LED_MISO),

        .clk(clk),
        .data(spi_data),
        .address(spi_word_address),
        .write_strobe(spi_write_strobe)
    );


    localparam OUT_1_WORDS = 1305;
    localparam OUT_2_WORDS = (28*12);

    reg out_1_write_strobe;
    reg out_2_write_strobe;
    reg [12:0] out_1_address;
    reg [12:0] out_2_address;

    reg trash;

    always @(posedge clk) begin

        out_1_write_strobe <= 0;
        out_2_write_strobe <= 0;
        trash <= 0;

        out_1_address <= spi_word_address;
        out_2_address <= (spi_word_address - OUT_1_WORDS);

        if(spi_write_strobe) begin
            if(spi_word_address < OUT_1_WORDS)
                out_1_write_strobe <= 1;
            else if(spi_word_address < (OUT_1_WORDS + OUT_2_WORDS))
                out_2_write_strobe <= 1;
            else
                trash <= 1;
        end
    end

//    assign DATA3 = spi_write_strobe;
//    assign CLOCK3 = out_1_write_strobe;
//    assign DATA4 = out_2_write_strobe;
//    assign CLOCK4 = trash;
    assign DATA3 =  out_2_write_strobe;
    assign CLOCK3 = out_2_address[12];
    assign DATA4 =  out_2_address[1];
    assign CLOCK4 = out_2_address[0];


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

    ws2812_out ws2812_out_1(
        .clk(clk),
        .rst(rst),
        
        .spi_data(spi_data),
        .spi_address(out_1_address),
        .spi_write_strobe(out_1_write_strobe),

        .data_out(DATA1),
    );

    icnd2110_out icnd2110_out_2(
        .clk(clk),
        .rst(rst),
        
        .spi_data(spi_data),
        .spi_address(out_2_address),
        .spi_write_strobe(out_2_write_strobe),

        .data_out(DATA2),
        .clock_out(CLOCK2),
    );
endmodule
