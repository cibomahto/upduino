module mbi6120_out #(
    parameter ADDRESS_BUS_WIDTH = 16,
    parameter GCLK = 2'b00,
) (
    input clk,
    input rst,

    input [15:0] word_count,            // Number of data words (3 words per output)
    input [15:0] start_address,         // First address of first page to read from
    input [1:0] clock_divisor,          // Clock divider bits (unused)
    input [7:0] page_count,             // Number of POV pages (unused)
    input double_pixel,                 // If true, send every pixel value twice (unused)

    input start_toggle,                 // Start whenever this input toggles

    output reg [(ADDRESS_BUS_WIDTH-1):0] read_address,  // Address of word to read
    output wire read_request,                           // Flag to request a read
    input [15:0] read_data,                             // Incoming data
    input read_finished_strobe,                         // Strobe input to signal data ready

    output reg data_out,
    output reg clock_out,
);
    // Timings for a 24MHz clock (Tbit = 2uS, Tw= .2uS)
    localparam BIT_HIGH_COUNT = 4;
    localparam BIT_MED_COUNT = (48-2*4);
    localparam BIT_LOW_COUNT = 4;
    localparam BIT_GAP_HIGH_COUNT = (96-4);
    localparam DELAY_COUNT = 20400;

    // MBI6120 protocol
    //
    // # Timing
    // The MBI6120 is a single-wire protocol. The bit period Tbit ranges from
    // 1-10uS. The pulsewidth for an 'off' signal, Tw, is .08 - .25*Tbit uS. The
    // The pulsewidth for an 'on' signal is 1-Tw.
    // In addition, after every 36 bytes of data, two gap symbols must be
    // sent. The gap symbols have a period of 2*Tbit, with a pulsewidth of
    // 2*Tbit - Tw.
    // Finally, the input must be held low for 750uS before the start of each
    // packet.
    //
    // # Packet format
    // [HEADER][ICn data][ICn-1 data]...[IC2 data][IC1 data]
    //
    // # HEADER
    // The header section is 36 bits, followed by 2 gap symbols.
    //
    // bits     Description
    // [35:24]  H1: Preamble, 12 bits of '1'
    // [23:22]  don't care
    // [21:20]  GCLK selection:
    //              2'b00: 5.2MHz
    //              2'b01: 2.6MHz
    //              2'b10: 1.3MHz
    //              2'b11: 650kZh
    // [19:12]  Command:
    //              8'b00000000: Gray scale data
    //              8'b01010101: Software reset
    // [11:10]  don't care
    // [9:0]    Number of cascaded ICs (1-1024)
    //
    // # ICn data
    // Each data section is 36 bits, followed by 2 gap symbols.
    //
    // bits     Description
    // [35:24]  Output A grayscale data (12 bit)
    // [23:12]  Output B grayscale data (12 bit)
    // [11:0]   Output C grayscale data (12 bit)

    reg start_toggle_prev;

    reg [3:0] state;
    reg [14:0] counter;             // Needs to be able to hold DELAY_COUNT

    reg [15:0] words_remaining;     // Counter of how many words are left to send

    reg [5:0] bit_index;            // Bit we are currently clocking out

    reg read_fifo_toggle;
    wire read_fifo_strobe;

    toggle_to_strobe toggle_to_strobe_1(
        .clk(clk),
        .toggle_in(read_fifo_toggle),
        .strobe_out(read_fifo_strobe),
    );

    wire fifo_1_full;
    wire [15:0] val;

    fifo fifo_1(
        .clk(clk),
        .rst(rst),
        .full(fifo_1_full),

        .write_strobe(read_finished_strobe),
        .write_data(read_data),
        
        .read_strobe(read_fifo_strobe),
        .read_data(val),
    );

    assign read_request = ~fifo_1_full & ~rst;

    wire pixel_clock;
    clock_divider clock_divider_1(
        .clk(clk),
        .rst(rst),
        .divisor(2'b00),
        .clk_out(pixel_clock),
    );


    // TX 36 bits:
    //
    // [35:24]  H1: Preamble, 12 bits of '1'
    // [23:22]  don't care
    // [21:20]  GCLK selection:
    //              2'b00: 5.2MHz
    //              2'b01: 2.6MHz
    //              2'b10: 1.3MHz
    //              2'b11: 650kZh
    // [19:12]  Command:
    //              8'b00000000: Gray scale data
    //              8'b01010101: Software reset
    // [11:10]  don't care
    // [9:0]    Number of cascaded ICs (1-1024)
    wire [9:0] ic_count = word_count/2; // TODO: Needs to be /3, but thats expensive.
    wire [31:0] header_data = {12'b111111111111, 2'b00, GCLK, 8'b00000000, 2'b00, ic_count};
    reg header_tx;

    localparam STATE_START = 0;
    localparam STATE_WAIT_FOR_SYNC = 1;
    localparam STATE_PRE_READ = 2;
    localparam STATE_BIT_HIGH = 3;
    localparam STATE_BIT_MID = 4;
    localparam STATE_BIT_LOW = 5;
    localparam STATE_GAP_GAP = 6;
    localparam STATE_DELAY = 7;

    always @(posedge pixel_clock)
    begin
        clock_out = 0;

        if(rst) begin
            state <= 0;

            data_out <= 0;
            clock_out <= 0;

            start_toggle_prev <= start_toggle;

        end
        else begin
            data_out <= 0;

            case(state)
            STATE_START:
            begin
                counter <= 0;

                read_address <= start_address;

                state <= STATE_WAIT_FOR_SYNC;
            end
            STATE_WAIT_FOR_SYNC:
            begin
                counter <= counter + 1;

                if(start_toggle != start_toggle_prev) begin
                    counter <= 0;
                    state <= STATE_PRE_READ;
                end
            end
            STATE_PRE_READ:
            begin
                counter <= counter +1;

                if(counter == 0) begin
                    words_remaining <= word_count;

                    // Make a bogus read to get the fifo started
                    read_fifo_toggle <= ~read_fifo_toggle;
                end

                if(counter == (32*2-1)) begin
                    // TODO: Fault if fifo is not full yet 
                    read_fifo_toggle <= ~read_fifo_toggle;

                    words_remaining <= words_remaining - 1;
                    read_address <= read_address + 1;

                    header_tx <= 1;
                    bit_index <= 48;

                    state <= STATE_BIT_HIGH;
                    counter <= 0;
                end
            end
            STATE_BIT_HIGH:  // Bit High
            begin
                counter <= counter + 1;
                data_out <= 1;

                if(counter == BIT_HIGH_COUNT) begin
                    counter <= 0;
                    state <= STATE_BIT_MID;
                end
            end
            STATE_BIT_MID:  // Bit Mid
            begin
                counter <= counter + 1;

                if(header_tx == 1)
                    data_out <= header_data[bit_index];
                else
                    data_out <= val[bit_index[3:0]];

                if(counter == BIT_MED_COUNT) begin
                    counter <= 0;
                    state <= STATE_BIT_LOW;
                end
            end
            STATE_BIT_LOW:  // Bit Low
            begin
                counter <= counter + 1;
                data_out <= 0;

                if(counter == BIT_LOW_COUNT) begin
                    counter <= 0;
                    state <= STATE_BIT_HIGH;

                    bit_index <= bit_index - 1;

                    if(bit_index == 0) begin

                        if(words_remaining == 0) begin
                            state <= STATE_DELAY;
                        end
                        else if(header_tx == 1) begin
                            header_tx <= 0;

                            bit_index <= 15;
                        end
                        else begin
                            read_fifo_toggle <= ~read_fifo_toggle;
    
                            words_remaining <= words_remaining - 1;
                            read_address <= read_address + 1;
                            bit_index <= 15;
                        end
                    end
                end
            end
            STATE_DELAY:  // Delay
            begin
                counter <= counter + 1;
                data_out <= 0;
                
                if(counter == DELAY_COUNT) begin
                    counter <= 0;
                    state <= STATE_START;
                end
            end
            default:
                state <= STATE_START;

            endcase
        end
    end
endmodule
