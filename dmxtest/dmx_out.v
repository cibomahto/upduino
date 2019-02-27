// A module for transmitting a single DMX universe
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

parameter CHANNEL_COUNT = 8;

parameter MINIMUM_BREAK_COUNT = 4400;       // Minimum clock cycles for break (92uS)
parameter MINIMUM_MAB_COUNT = 576;          // Minimum clock cycles for 'MAB' (12uS)
parameter BIT_COUNT = 192;                  // Clock cycles for a bit (4uS)


module dmx_out(
    input clock,                            // System clock (48 MHz?)
    input reset,                            // System reset

    output dmx_out,                         // DMX bit output
);

    // Channel value memory
    reg [7:0] values [15:0];
    initial begin
        $readmemh("values.list", values);
    end

    reg [2:0] state;                        // Machine state
    reg [13:0] count;                       // Counter
    reg [4:0] channel_index;                   // Next byte to transmit
    reg [7:0] bit_index;                    // Current bit being transmitted
    reg [7:0] byte;                         // Register for holding the current byte being transmitted

    reg dmx_out_reg;
    assign dmx_out = dmx_out_reg;

    reg [18:0] valclock;

    always @(posedge clock)
    begin
        valclock <= valclock + 1;

        if(valclock == 0) begin
            values[0] <= values[0] + 1;
            values[1] <= values[1] + 1;
            values[2] <= values[2] + 1;
            values[3] <= values[3] + 1;
            values[4] <= values[4] + 1;
            values[5] <= values[5] + 1;
            values[6] <= values[6] + 1;
            values[7] <= values[7] + 1;
        end
    end


    always @(posedge clock)
        if(reset) begin
            state <= 0;
            count <= 0;
            bit_index <= 0;
            byte <= 0;
        end
        else begin
            count <= count + 1;

            dmx_out_reg <= 1;               // Line defaults to high when idle

            case(state)
                0: // Idle
                begin
                    // Transition to 'break'
                    count <= 0;
                    state <= state + 1;
                end
                1: // Transmit break
                begin
                    dmx_out_reg <= 0;

                    // After reaching break count, transition to MAB
                    if(count == MINIMUM_BREAK_COUNT) begin
                        count <= 0;
                        state <= state + 1;
                    end
                end
                2: // MAB
                begin
                    dmx_out_reg <= 1;

                    // After reaching MAB count, transition to slot 0
                    if(count == MINIMUM_MAB_COUNT) begin
                        count <= 0;
                        state <= state + 1;

                        byte <= 8'b00000000;      // TX 0 for the first frame
                        channel_index <= 0;    // Next byte to be transmitted
                    end
                end
                3: // Start bit
                begin
                    dmx_out_reg <= 0;

                    if(count == BIT_COUNT) begin
                        count <= 0;
                        state <= state + 1;

                        bit_index <= 0;
                    end
                end
                4: // bits
                begin
                    dmx_out_reg <= byte[bit_index];

                    if(count == BIT_COUNT) begin
                        count <= 0;

                        bit_index <= bit_index + 1;

                        if(bit_index == 7) begin
                            state <= state + 1;
                        end

                    end

                end

                5: // Stop bits
                begin
                    dmx_out_reg <= 1;

                    if(count == (BIT_COUNT*2)) begin
                        count <= 0;

                        byte = values[channel_index];
                        channel_index <= channel_index + 1;
                        state <= 3;

                        if(channel_index == CHANNEL_COUNT) begin
                            state <= state + 1;
                        end
                    end
                end

                default:
                begin
                    count <= 0;
                    state <= 0;
                end
            endcase
        end
endmodule
