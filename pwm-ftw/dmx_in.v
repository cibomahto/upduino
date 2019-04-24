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

parameter CHANNEL_COUNT = 8;

parameter MINIMUM_BREAK_COUNT = ((4400-440));  // Minimum clock cycles for break (92uS)
parameter MINIMUM_MAB_COUNT = ((576-58));      // Minimum clock cycles for 'MAB' (12uS)
parameter BIT_COUNT = (192);                   // Clock cycles for a bit (4uS)


module dmx_in(
    input clk,                            // System clock (48 MHz?)
    input rst,                            // System reset

    input dmx_in,                           // DMX bit input
    output reg dmx_out,                     // Auto-addressing DMX output

    output reg [7:0] data,                  // Data frame
    output reg [MAX_CHANNEL_BITS:0] channel, // Address to write data frame
    output reg write_strobe,                // Asserts for 1 system clock when data is ready to write
);

    reg [3:0] state;                        // Machine stat
    reg [13:0] count;                       // Counter
    reg [MAX_CHANNEL_BITS:0] byte_index;    // Current channel being read 
    reg [7:0] bit_index;                    // Current bit being read into the byte
    reg [7:0] read_byte;                    // Register for holding the current read byte
    reg start_code;                         // If true, read this byte as a start code

    // Synch the DMX input to the system clock. The system clock shoud be much
    // faster than 250Kbs.
    wire dmx_sync;
    sync_ss in_sync(clk, rst, dmx_in, dmx_sync);

    always @(posedge clk)
        if(rst) begin
            state <= 0;
            count <= 0;
            byte_index <= 0;
            bit_index <= 0;
            read_byte <= 0;
            start_code <= 0;

            channel <= 0;
            data <= 0;
            write_strobe <= 0;

            dmx_out <= 0;
        end
        else begin
            count <= count + 1;

            write_strobe <= 0;

            case(state)
                0,1,2,3: // Pass thru DMX signal while waiting for idle, break, MAB
                begin
                    dmx_out <= dmx_sync;
                end
                4,5,6,7,8:
                begin
                    // Don't pass the data bytes that we want to consume
                    if((start_code == 1) || (byte_index > (CHANNEL_COUNT - 1)))
                        dmx_out <= dmx_sync;
                end
            endcase

            // If the line is held low for long enough, always count it as
            // a break, and reset the state machine.
            if((dmx_sync == 0) && (count == MINIMUM_BREAK_COUNT)) begin
                count <= 0;
                state <= 1;
            end
            else begin
                case(state)
                    0: // Idle
                    begin
                        // Nothing, need a break reset to get out of this state.
                        if(dmx_sync == 1) begin
                            count <= 0;
                        end
                    end
                    1: // Wait for a high transition, signaling start of MAB
                    begin
                        if(dmx_sync == 1) begin
                            count <= 0;
                            state <= state + 1;
                        end
                    end
                    2:  // Wait for minimum MAB
                    begin
                        if(count == MINIMUM_MAB_COUNT) begin
                            count <= 0;
                            state <= state + 1;
                        end
                        else if(dmx_sync == 0) begin
                            count <= 0;
                            state <= 0;
                        end
                    end
                    3:  // Wait for MAB end
                    begin
                        if(dmx_sync == 0) begin
                            count <= 0;
                            state <= state + 1;

                            channel <= 0;
                            read_byte <= 0;
                            byte_index <= 0;
                            bit_index <= 0;
                            start_code <= 1;
                        end
                    end
                    4:  // Wait 1/2 bit time, then sample start bit
                    begin
                        if(count == (BIT_COUNT*0.5)) begin
                            count <= (BIT_COUNT*0.5);
                            state <= 0;
                           
                            // If we got a valid start bit, continue to next
                            // bit sample.
                            if(dmx_sync == 0) begin
                                count <= 0;
                                state <= state + 1;
                            end
                            // (otherwise, go back to idle mode)
                        end
                    end
                    5:  // Sample data bits
                    begin
                        if(count == BIT_COUNT) begin
                            count <= 0;

                            read_byte[bit_index] <= dmx_sync;
                            bit_index <= bit_index + 1;

                            if(bit_index == 7) begin
                                state <= state + 1;

                            end
                        end
                    end
                    6: // Sample first stop bit
                    begin
                        if(count == BIT_COUNT) begin
                            count <= (BIT_COUNT*8.5);   // Set the counter to the start of this discarded bit
                            state <= 0;

                            if(dmx_sync == 1) begin
                                count <= 0;
                                state <= state + 1;
                            end
                        end
                    end
                    7: // Sample second stop bit
                    begin
                        if(count == BIT_COUNT) begin
                            count <= (BIT_COUNT*9.5);   // Set the counter to the start of this discarded bit
                            state <= 0;

                            if(dmx_sync == 1) begin
                                count <= 0;
                                state <= state + 1;

                                // If we just finished reading the start frame, check
                                // if it is valid (0)
                                if(start_code) begin
                                    start_code <= 0;

                                    if(read_byte != 8'h00) begin
                                        count <= 0;
                                        state <= 0;
                                    end
                                end
                                // Otherwise, store the channel and address,
                                // and strobe the output.
                                else begin
                                    data <= read_byte;
                                    channel <= byte_index;
                                    write_strobe <= 1;

                                    byte_index <= byte_index + 1;
                                end
                            end
                        end
                    end
                    8: // Wait for falling edge, to signal start of next byte
                    begin
                        if(dmx_sync == 0) begin
                            count <= 0;

                            state <= 4;

                            read_byte <= 0;
                            bit_index <= 0;
                        end
                    end

 
                    default:
                    begin
                        count <= 0;
                        state <= 0;
                    end
                endcase
            end
        end
endmodule
