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

    output LED1,
    output LED2,
    output LED3,

    input DMX_IN,
    output DMX_OUT,
);

    `include "functions.vh"

    localparam COMMAND_WIDTH = 8;
    localparam ADDRESS_BUS_WIDTH = 16;
    localparam DATA_BUS_WIDTH = 16;
    localparam OUTPUT_COUNT = 3;

    localparam POV_PRESCALER_BITS = 1;
    localparam POV_COUNTER_BITS = 16;

    wire clk;
    wire rst;

    assign rst = 0; // TODO: Hardware reset input (?)

    // Output counts, in words
    reg [2:0] output_protocols [(OUTPUT_COUNT-1):0];
    reg [(ADDRESS_BUS_WIDTH-1):0] output_word_counts [(OUTPUT_COUNT-1):0];
    reg [(ADDRESS_BUS_WIDTH-1):0] output_start_addresses [(OUTPUT_COUNT-1):0];
    reg [1:0] output_clock_divisors [(OUTPUT_COUNT-1):0];
    reg [7:0] output_page_counts [(OUTPUT_COUNT-1):0];
    reg [(OUTPUT_COUNT-1):0] output_double_pixels;
    reg [(OUTPUT_COUNT-1):0] output_enables;

    initial begin
        $readmemh("output_word_counts.list", output_word_counts);
        $readmemh("output_start_addresses.list", output_start_addresses);
        $readmemh("output_clock_divisors.list", output_clock_divisors);
        $readmemh("output_page_counts.list", output_page_counts);
        output_double_pixels <= 10'b0000000000;
        output_enables <= 10'b0000000000;
    end


    // Configure the HFOSC
	SB_HFOSC #(
        .CLKHF_DIV("0b00"), // 00: 48MHz, 01: 24MHz, 10: 12MHz, 11: 6MHz
    ) u_hfosc (
       	.CLKHFPU(1'b1),
       	.CLKHFEN(1'b1),
        .CLKHF(clk)
    );

    /*
    reg pov_prescale_counter;
    reg [15:0] pov_counter;
    reg [15:0] pov_preset;
    initial begin
        pov_preset = 16'h0000;
    end

    reg pov_start_toggle;           // Start toggle signal

    always @(posedge clk) begin
        if(rst) begin
            pov_prescale_counter <= 0;
            pov_counter <= pov_preset;
        end
        else begin
            pov_prescale_counter <= pov_prescale_counter + 1;

           if(pov_prescale_counter == 0) begin
                pov_counter <= pov_counter - 1;

                if(pov_counter == 0) begin
                    pov_counter <= pov_preset;
                    pov_start_toggle <= ~pov_start_toggle;
                end
            end
        end
    end
    */


    reg [(POV_PRESCALER_BITS-1):0] pov_speed_prescaler;
    reg [(POV_COUNTER_BITS-1):0] pov_speed_counter;
    initial begin
        pov_speed_prescaler = 1;
        pov_speed_counter = 16'h0000;
    end

    wire pov_start_toggle;

    prescale_counter #(
        .PRESCALER_BITS(POV_PRESCALER_BITS),
        .COUNTER_BITS(POV_COUNTER_BITS),
    ) prescale_counter_1 (
        .clk(clk),
        .rst(rst),

        .prescaler_preset(pov_speed_prescaler),
        .counter_preset(pov_speed_counter),

        .counter_toggle(pov_start_toggle),
    );

    assign DATA_1 = pov_start_toggle;

    wire [(DATA_BUS_WIDTH-1):0] spi_data;
    wire [(ADDRESS_BUS_WIDTH-1):0] spi_word_address;
    wire spi_write_strobe;

    wire [11:0] reg_base;
    wire [3:0] reg_offset;
    assign reg_base = spi_word_address[15:4];
    assign reg_offset = spi_word_address[3:0];

    // Register Map
    //
    // The control registers are mapped into the device memory, starting at
    // 0xFF00:
    //
    // 0xFF00: Output enables
    // 0xFF01: POV speed count
    // 0xFF1n: Output n config register
    //         [15:12 reserved]
    //         [13:11 output protocol]
    //         [10:3 POV page count]
    //         [2 double-pixel mode]
    //         [1:0 clock divider]
    // 0xFF2n: Output n word count
    // 0xFF3n: Output n word start address


    // Map the configuration registers into memory
    always @(posedge clk) begin
        if(spi_write_strobe) begin
            if(spi_word_address == 16'hFF00)
                output_enables[(OUTPUT_COUNT-1):0] <= spi_data[(OUTPUT_COUNT-1):0];

            if(spi_word_address == 16'hFF01)
                pov_speed_counter[(POV_COUNTER_BITS-1):0] <= spi_data[(POV_COUNTER_BITS-1):0];

            if(reg_base == 12'hFF1) begin
                output_protocols[reg_offset] <= spi_data[13:11];
                output_page_counts[reg_offset] <= spi_data[10:3];
                output_double_pixels[reg_offset] <= spi_data[2];
                output_clock_divisors[reg_offset] <= spi_data[1:0];
            end

            if(reg_base == 12'hFF2)
                output_word_counts[reg_offset] <= spi_data;

            if(reg_base == 12'hFF3)
                output_start_addresses[reg_offset] <= spi_data;
        end
    end


    spi_in #(
        .ADDRESS_BUS_WIDTH(ADDRESS_BUS_WIDTH),
        .DATA_BUS_WIDTH(DATA_BUS_WIDTH),
        .COMMAND_WIDTH(COMMAND_WIDTH),
    ) spi_in_1(
        .cs(LED_CS),
        .sck(LED_SCK),
        .mosi(LED_MOSI),
        .miso(LED_MISO),

        .clk(clk),
        .data(spi_data),
        .address(spi_word_address),
        .write_strobe(spi_write_strobe)
    );

    // Connection array for the outputs
    wire [(ADDRESS_BUS_WIDTH-1):0] read_addresses [(OUTPUT_COUNT-1):0];
    wire [(OUTPUT_COUNT-1):0] read_requests;
    wire [(OUTPUT_COUNT-1):0] read_finished_strobes;

    // The data output from the ram is a shared bus
    wire [15:0] read_data;

    // And wire arrays to map to the outputs
    wire [(OUTPUT_COUNT-1):0] data_outputs;
    wire [(OUTPUT_COUNT-1):0] clock_outputs;

    generate
        genvar i;
        for (i=0; i<(OUTPUT_COUNT); i=i+1) begin
            //apa102_out #(
            //ws2812_out #(
            icnd2110_out #(
                .ADDRESS_BUS_WIDTH(ADDRESS_BUS_WIDTH),
            ) i_apa102_out (
                .clk(clk),
                //.rst(~output_enables[i]),
                .rst(0),

                //.protocol(output_protocols[i]),
                .word_count(output_word_counts[i]),
                .start_address(output_start_addresses[i]),
                .clock_divisor(output_clock_divisors[i]),
                .page_count(output_page_counts[i]),
                .double_pixel(output_double_pixels[i]),
                .start_toggle(pov_start_toggle),
       
                .read_address(read_addresses[i]),
                .read_request(read_requests[i]),
                .read_data(read_data),
                .read_finished_strobe(read_finished_strobes[i]),

                .data_out(data_outputs[i]),
                .clock_out(clock_outputs[i]),
            );
        end
    endgenerate


    wire [2:0] state;

    sram_bus #(
        .ADDRESS_BUS_WIDTH(ADDRESS_BUS_WIDTH),
        .OUTPUT_COUNT(OUTPUT_COUNT),
    ) sram_bus_1(
        .clk(clk),
        .rst(rst),

        .write_address(spi_word_address),
        .write_data(spi_data),
        .write_strobe(spi_write_strobe),

        .read_requests(read_requests),
        .read_finished_strobes(read_finished_strobes),
        .read_data(read_data),

        .read_address_0(read_addresses[0]),
        .read_address_1(read_addresses[1]),
        .read_address_2(read_addresses[2]),
//        .read_address_3(read_addresses[3]),
//        .read_address_4(read_addresses[4]),
//        .read_address_5(read_addresses[5]),
//        .read_address_6(read_addresses[6]),
//        .read_address_7(read_addresses[7]),
//        .read_address_8(read_addresses[8]),
//        .read_address_9(read_addresses[9]),

        .state(state),
    );

//    assign DATA_1 = data_outputs[0];
    assign DATA_2 = data_outputs[0];
//    assign DATA_3 = data_outputs[2];
    assign DATA_4 = data_outputs[1];
//    assign DATA_5 = data_outputs[4];
    assign DATA_6 = data_outputs[2];
//    assign DATA_7 = data_outputs[6];
//    assign DATA_8 = data_outputs[0];            // Fourth output mirrors the first
//    assign DATA_9 = data_outputs[8];
//    assign DATA_10 = data_outputs[9];

//    assign CLOCK_1 = clock_outputs[0];
    assign CLOCK_2 = clock_outputs[0];
//    assign CLOCK_3 = clock_outputs[2];
    assign CLOCK_4 = clock_outputs[1];
//    assign CLOCK_5 = clock_outputs[4];
    assign CLOCK_6 = clock_outputs[2];
//    assign CLOCK_7 = clock_outputs[6];
//    assign CLOCK_8 = clock_outputs[0];
//    assign CLOCK_9 = clock_outputs[8];
//    assign CLOCK_10 = clock_outputs[9];


//    assign DATA_1 = 0;
    assign DATA_3 = 0;
    assign DATA_5 = 0;
    assign DATA_7 = 0;
    assign DATA_8 = 0;
    assign DATA_9 = 0;
    assign DATA_10 = 0;

    assign CLOCK_1 = 0;
    assign CLOCK_3 = 0;
    assign CLOCK_5 = 0;
    assign CLOCK_7 = 0;
    assign CLOCK_8 = 0;
    assign CLOCK_9 = 0;
    assign CLOCK_10 = 0;

    // Configure DMX as passthrough
    assign DMX_OUT = DMX_IN;

    // LEDs do nothing
    assign LED1 = ~output_enables[0];
    assign LED2 = ~output_enables[1];
    assign LED3 = ~output_enables[2];

endmodule
