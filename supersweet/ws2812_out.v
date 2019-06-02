module ws2812_out #(
    parameter ADDRESS_BUS_WIDTH = 16,
) (
    input clk,
    input rst,

    input [15:0] word_count,            // Number of words in a page
    input [15:0] start_address,         // First address of first page to read from
    input [1:0] clock_divisor,          // Clock divider bits
    input [7:0] page_count,             // Number of POV pages
    input double_pixel,                 // If true, send every pixel value twice

    input start_toggle,                 // Start whenever this input toggles

    output reg [(ADDRESS_BUS_WIDTH-1):0] read_address,  // Address of word to read
    output wire read_request,                           // Flag to request a read
    input [15:0] read_data,                             // Incoming data
    input read_finished_strobe,                         // Strobe input to signal data ready

    output reg data_out,
    output reg clock_out,
);
    // Timings for a 48MHz clock
//    localparam BIT_HIGH_COUNT = 12;
//    localparam BIT_MED_COUNT = 35;
//    localparam BIT_LOW_COUNT = 12;
//    localparam DELAY_COUNT = 18000;

    // Timings for a 24MHz clock
    localparam BIT_HIGH_COUNT = 6;
    localparam BIT_MED_COUNT = 18;
    localparam BIT_LOW_COUNT = 6;
    localparam DELAY_COUNT = 9000;

    reg start_toggle_prev;

    reg [2:0] state;
    reg [15:0] counter;             // TODO: Verify if lower count is ok

    reg [15:0] words_remaining;     // Counter of how many words are left to send

    reg [4:0] bit_index;            // Bit we are currently clocking out

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

        //.divisor(clock_divisor),
        .divisor(2'b00),
        .clk_out(pixel_clock),
    );

    localparam STATE_START = 0;
    localparam STATE_WAIT_FOR_SYNC = 1;
    localparam STATE_PRE_READ = 2;
    localparam STATE_BIT_HIGH = 4;
    localparam STATE_BIT_MID = 5;
    localparam STATE_BIT_LOW = 6;
    localparam STATE_DELAY = 7;

    always @(posedge pixel_clock)
    begin
        // TODO: implement WS2813 backup data signal
        clock_out = 0;

        if(rst) begin
            state <= 0;

            data_out <= 0;
            clock_out <= 0;

            start_toggle_prev <= start_toggle;
            read_address <= start_address;

            bit_index <= 15;
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
                    bit_index <= 15;

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
                data_out <= val[bit_index];

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
                        if(words_remaining == 0)
                            state <= STATE_DELAY;
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
