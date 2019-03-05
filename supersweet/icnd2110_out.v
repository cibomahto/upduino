module icnd2110_out #(
    // There are 28 chips per board, and 8 boards
    parameter CHIP_COUNT = (28),
    parameter INDEX_WIDTH = 12,    // Must be large enough to store CHIP_COUNT*12
    parameter CFG_UP = 0,
    parameter CFG_PWM_WIDER = 1,
) (
    input clk,
    input rst,
    
    input [15:0] spi_data,
    input [12:0] spi_address,
    input spi_write_strobe,

    output reg data_out,
    output wire clock_out,
);
    // Each chip has 12 output channels
    localparam CHANNEL_COUNT = (CHIP_COUNT*12);

    reg [15:0] values [(CHANNEL_COUNT-1):0];
    initial begin
        $readmemh("test_data16.list", values);
    end

    // TODO: Make a memory bus, wire this module into it
    always @(posedge clk)
        if(spi_write_strobe)
            values[spi_address] <= spi_data;

    reg [3:0] state;
    reg [10:0] counter;

    reg [INDEX_WIDTH:0] channel_index;   // Current byte, but it is offset from 0..11
    reg [2:0] subchip_byte;           // Counter from 0..5

    reg [15:0] val;                   // 16-bit output value from memory



    reg [2:0] clockdiv;
    always @(posedge clk)
        clockdiv <= clockdiv + 1;

    assign clock_out = clockdiv[0];

    always @(negedge clock_out) begin
        if(rst) begin
            state <= 0;
            data_out <= 0;

            val <= 0;
        end
        else begin
            data_out <= 0;

            case(state)
            0:  // 0. wait for start
            begin
                state <= state + 1;
                counter <= 0;

                channel_index <= 5;
                subchip_byte <= 0;
            end
            1:  // 1. start (128 bits of 1)
            begin
                data_out <= 1;

                counter <= counter +1;
                
                if(counter == 127) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            2,4,6,8:    // 2. blank (16 bits of 0)
            begin
                counter <= counter +1;
                
                if(counter == 15) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            3:  // 3. reg (16 bit register value)
            begin
                counter <= counter + 1;

                case(counter[3:0])
                    11:
                        data_out <= CFG_PWM_WIDER;
                    12:
                        data_out <= CFG_UP;
                    13,14,15:
                        data_out <= 1;
                    default:
                        data_out <= 0;
                endcase

                if(counter == 15) begin
                    state <= state + 1;
                    counter <= 0;

                    // Preload the first byte
                    val <= values[channel_index];

                    // Count in sequence:
                    // 5,4,3,2,1,0,11,10,9,8,7,6,15,14,13,12,11, ...
                    if(subchip_byte == 5) begin
                        subchip_byte <= 0;
                        channel_index <= channel_index + 11;
                    end
                    else begin
                        subchip_byte <= subchip_byte + 1;
                        channel_index <= channel_index - 1;
                    end
                end
            end

            // 4. blank (16 bits of 0)
            // for n chips:
            5, 7: // 5.  chip x, out5-out0 (16 x 6 bits)
            begin
                // Here:
                // counter[3:0] is the bit output (0-15)
                // counter[6:4] is output (5-0) if in state 5, or output (11-6) if in state 7.
                counter <= counter + 1;

                data_out <= val[15 - counter[3:0]];

                if(counter[3:0] == 15) begin
                    val <= values[channel_index];

                    if(subchip_byte == 5) begin
                        subchip_byte <= 0;
                        channel_index <= channel_index + 11;
                    end
                    else begin
                        subchip_byte <= subchip_byte + 1;
                        channel_index <= channel_index - 1;
                    end
                end

                if(counter == (16*6-1)) begin
                    counter <= 0;

                    if(state == 5) begin
                        state <= state + 1;
                    end
                    else begin
                        if(channel_index < CHANNEL_COUNT)
                            state <= 4;
                        else
                            state <= state + 1;
                    end
                end
            end
            // 6.  blank
            // 7.  chip x, out11-out6 (16 x 6 bits)
            // 8.  blank
            9:  // 9. frame end (145 bits of 1)
            begin
                data_out <= 1;

                counter <= counter +1;
                
                if(counter == 144) begin
                    state <= 0;
                    counter <= 0;
                end
            end
            default:
                state <= 0;

            endcase
        end
    end

/*

    reg [3:0] state;
    reg [10:0] counter;

    reg [7:0] chipIndex;        // Chip we are currently clocking out
    reg [5:0] outp;             // Current ICND channel (0-11)

    //assign clock_out = !clk;  // Off by 1/2 phase?   
    assign clock_out = clk;

    reg [15:0] currentValue;

    always @(posedge clk)
        if(rst) begin
            state <= 0;
            data_out <= 0;

            outp <= 0;
        end
        else begin

            data_out <= 0;

            case(state)
            0:  // 0. wait for start
            begin
                state <= 1;
                counter <= 0;

                chipIndex <= 0;
            end
            1:  // 1. start (128 bits of 1)
            begin
                data_out <= 1;

                counter <= counter +1;
                
                if(counter == 127) begin
                    state <= state + 1;
                    counter <= 0;

                    chipIndex <= chipIndex + 1;
                    currentValue <= values[chipIndex];
                end
            end
            2,4,6,8: // 2. blank (16 bits of 0)
            begin
                counter <= counter +1;
                
                if(counter == 15) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end
            3:  // 3. reg (16 bit register value)
            begin
                counter <= counter + 1;

                case(counter[3:0])
                    11:
                        data_out <= CFG_PWM_WIDER;
                    12:
                        data_out <= CFG_UP;
                    13,14,15:
                        data_out <= 1;
                    default:
                        data_out <= 0;
                endcase

                if(counter == 15) begin
                    state <= state + 1;
                    counter <= 0;
                end
            end

            // 4. blank (16 bits of 0)
            5, 7:   // 5.  for n chips: chip x, out5-out0 (16 x 6 bits)
            begin
                // Here, counter[3:0] is the bit output, and counter[6:4] is output (5-0)
                // if in state 5, or output (11-6) if in state 7.
                counter <= counter + 1;

                data_out <= currentValue[counter[3:0]];

                if(counter == (16*6-1)) begin
                    counter <= 0;

                    if(state == 5) begin
                        state <= state + 1;
                    end
                    else begin
                        chipIndex <= chipIndex + 1;
                        currentValue <= values[chipIndex];

                        if(chipIndex == CHIP_COUNT)
                            state <= state + 1;
                        else
                            state <= 4;
                    end
                end
            end

            // 6.  blank 
            // 7.  chip x, out11-out6 (16 x 6 bits)
            // 8.  blank
            9: // 9. frame end (145 bits of 1)
            begin
                data_out <= 1;

                counter <= counter +1;
                
                if(counter == 144) begin
                    state <= 0;
                    counter <= 0;
                end
            end

            default:
                state <= 0;

            endcase
        end
        */
endmodule
