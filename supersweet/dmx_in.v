// A module for receiving a single DMX input
// 
// Notes on DMX signal:
// 1. Line is high when idle
// 2. Transmission starts by pulling line low to begin 'break' for minimum 92uS
//    (typical 176uS).
// 3. Next, pull line high to begin 'mark after break' for minimum 12uS, max
//    1M uS.
// 4. Slot 0 is 1 start bit 1'b0, 8 data bits equalling 8'b00000000, 2 stop
//    bits 2'b11. Each slot is 4uS.
// 5. An inter-frame delay of 0-? uS.
// 5. Up to 512 data slot bits, each with 1 start bit 1'b0, data 8'bxxxxxxxx,
//    2 stop bits 2'b11, and each seperated by an inter-frame delay.
// 6. Frame complete after 512 channels received, or when next 'break'
//    detected.
parameter MAX_CHANNEL_BITS = 8; // Max. number of channels supported = 2^(n+1)

parameter MINIMUM_BREAK_COUNT = 2200;       // Minimum clock cycles for break (92uS)
parameter MINIMUM_MAB_COUNT = 288;          // Minimum clock cycles for 'MAB' (12uS)
parameter BIT_COUNT = 96;                   // Clock cycles for a bit (4uS)


module dmx_in(
    input clock,                            // System clock (24 MHz?)
    input reset,                            // System reset

    input dmx_in,                           // DMX bit input

    output [7:0] data,                      // Data frame
    output [MAX_CHANNEL_BITS:0] channel,    // Address to write data frame
    output write_strobe,                    // Asserts for 1 system clock when data is ready to write
);

    reg [2:0] state;                        // Machine stat
    reg [12:0] count;                       // Counter
    reg [7:0] bit_index;                    // Current bit being read into the byte
    reg [7:0] read_byte;                    // Register for holding the current read byte
    reg last_dmx_sync;                      // Previous value of the dmx_sync input

    reg [MAX_CHANNEL_BITS:0] channel_reg;   // Buffered output channel
    reg [7:0] data_reg;                     // Buffered output data
    reg write_strobe_reg;                   // Buffer strobe
    assign channel = channel_reg;
    assign data = data_reg;
    assign write_strobe = write_strobe_reg;


    // Synch the DMX input to the system clock. The system clock shoud be much
    // faster than 250Kbs.
    wire dmx_sync;
    sync_ss in_sync(clock, reset, dmx_in, dmx_sync);

    wire polarity_flip;
    assign polarity_flip = (last_dmx_sync != dmx_sync);

    always @(posedge clock)
        if(reset) begin
            state <= 0;
            count <= 0;
            bit_index <= 0;
            read_byte <= 0;
            last_dmx_sync  <= 1;

            channel_reg <= 0;
            data_reg <= 0;
            write_strobe_reg <= 0;
        end
        else begin
            write_strobe_reg <= -1;

            count <= count + 1;
            last_dmx_sync <= dmx_sync;
            if (polarity_flip)
                count <= 0;

            case(state)
                0: // Idle
                begin

                end
                default: begin
                    count <= 0;
                    state <= 0;
                end
            endcase
        end
endmodule
