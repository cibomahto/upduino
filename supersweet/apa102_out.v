module apa102_out #(
    parameter ADDRESS_BUS_WIDTH = 16,       // Must be large enough to address WORD_COUNT
    parameter GLOBAL_BRIGHTNESS = 5'b11111,
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

    reg start_toggle_prev;
    reg [4:0] state;
    reg [10:0] counter;
    reg [10:0] delay_counter;

    reg [7:0] pages_remaining;          // Counter of how many pages are left to send
    reg [15:0] words_remaining;         // Counter of how many words are left to send
    reg [3:0] val_index;                // Counter from 0..15

    reg [23:0] data_buffer;              // buffer for storing data that will be repeated

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

        .divisor(clock_divisor),
        .clk_out(pixel_clock),
    );

    localparam STATE_START = 0;
    localparam STATE_WAIT_FOR_SYNC = 1;
    localparam STATE_START_FRAME = 2;
    localparam STATE_LED_HEADER = 3;
    localparam STATE_LED_DATA = 4;
    localparam STATE_REPEAT_HEADER = 5;
    localparam STATE_REPEAT_DATA = 6;
    localparam STATE_FRAME_END = 7;
    localparam STATE_DELAY = 8;

    always @(negedge pixel_clock) begin
        if(rst) begin
            state <= 0;

            data_out <= 0;
            clock_out <= 0;

            start_toggle_prev <= start_toggle;
            pages_remaining <= page_count;
            read_address <= start_address;
        end
        else begin
            data_out <= 0;
            clock_out <= 0;
            start_toggle_prev <= start_toggle;

            case(state)
            STATE_START:  // Wait for start
            begin
                counter <= 0;

                pages_remaining <= page_count - 1;
                read_address <= start_address;

                state <= STATE_WAIT_FOR_SYNC;
            end
            STATE_WAIT_FOR_SYNC:
            begin
                if(start_toggle != start_toggle_prev) begin
                    counter <= 0;
                    state <= STATE_START_FRAME;
                end
            end
            STATE_START_FRAME:  // Start Frame (32 bits of 0)
            begin
                counter <= counter +1;

                data_out <= 0;
                clock_out <= counter[0];
                
                if(counter == 0) begin
                    words_remaining <= word_count;
                    //read_address <= start_address;

                    // Make a bogus read to get the fifo started
                    read_fifo_toggle <= ~read_fifo_toggle;
                end

                if(counter == (32*2-1)) begin
                    // TODO: Fault if fifo is not full yet 
                    read_fifo_toggle <= ~read_fifo_toggle;

                    words_remaining <= words_remaining - 1;
                    read_address <= read_address + 1;
                    val_index <= 0;
                end

                if(counter == (32*2-1)) begin
                    state <= STATE_LED_HEADER;
                    counter <= 0;
                end
            end
            STATE_LED_HEADER:    // LED frame configuration (8 bits)
            begin
                counter <= counter +1;

                clock_out <= counter[0];
                
                case(counter[3:1])
                    0,1,2:
                        data_out <= 1;
                    default:
                        data_out <= 1;      // TODO: Global brightness adjustment
                endcase

                if(counter == (8*2 - 1)) begin
                    state <= STATE_LED_DATA;
                    counter <= 0;
                end
            end
            STATE_LED_DATA:  // BGR data
            begin
                counter <= counter + 1;

                data_out <= val[15 - val_index];
                clock_out <= counter[0];

                data_buffer[counter[6:1]] <= val[15 - val_index];

                if(counter[0] == 1) begin
                    if(counter == (24*2-1)) begin
                        counter <= 0;

                        if(double_pixel == 1)
                            state <= STATE_REPEAT_HEADER;
                        else if(words_remaining == 0)
                            state <= STATE_FRAME_END;
                        else
                            state <= STATE_LED_HEADER;
                    end

                    // TODO: Enforce somehow that we're outputting a multiple of 3 bytes
                    // Note that we transmit some junk on the last pixel if
                    // the words_remaining boundary isn't 24-bit aligned
                    if((val_index == 15) && (words_remaining != 0)) begin
                        read_fifo_toggle <= ~read_fifo_toggle;
    
                        words_remaining <= words_remaining - 1;
                        read_address <= read_address + 1;
                        val_index <= 0;
                    end
                    else begin
                        val_index <= val_index + 1;
                    end
                end
            end
            STATE_REPEAT_HEADER:    // LED frame configuration (8 bits)
            begin
                counter <= counter +1;

                clock_out <= counter[0];
                
                case(counter[3:1])
                    0,1,2:
                        data_out <= 1;
                    default:
                        data_out <= 1;      // TODO: Global brightness adjustment
                endcase

                if(counter == (8*2 - 1)) begin
                    state <= STATE_REPEAT_DATA;
                    counter <= 0;
                end
            end
            STATE_REPEAT_DATA:  // BGR data
            begin
                counter <= counter + 1;

                data_out <= data_buffer[counter[6:1]];
                clock_out <= counter[0];

                if(counter[0] == 1) begin
                    if(counter == (24*2-1)) begin
                        counter <= 0;

                        if(words_remaining == 0)
                            state <= STATE_FRAME_END;
                        else
                            state <= STATE_LED_HEADER;
                    end
                end
            end
            STATE_FRAME_END:  // Frame end (32 bits of 1)
            begin
                counter <= counter +1;

                data_out <= 1;
                clock_out <= counter[0];
                
                if(counter == (32*2 - 1)) begin
                    state <= STATE_DELAY;
                    counter <= 0;

                    delay_counter <= 0;
                end
            end
            STATE_DELAY:  // Delay
            begin
                if(pages_remaining == 1) begin
                    state <= STATE_START;
                    counter <= 0;
                end
                else begin
                    pages_remaining <= pages_remaining - 1;
                    state <= STATE_WAIT_FOR_SYNC;
                    counter <= 0;
                end
            end
            default:
            begin
                state <= STATE_START;
                counter <= 0;
            end
            endcase
        end
    end
endmodule

