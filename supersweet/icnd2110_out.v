module icnd2110_out #(
    parameter CHIP_COUNT = (28*8),
    parameter BUFFER_WIDTH = 9,
    parameter CFG_UP = 0,
    parameter CFG_PWM_WIDER = 1,
) (

    input clock,
    input reset,
    
    input [15:0] spi_data,
    input [12:0] spi_address,
    input spi_write_strobe,

    output reg data_out,
    output wire clock_out,
);
    localparam CHANNEL_COUNT = (CHIP_COUNT*12);

    // We have 28*4*3 = 336 channels per board,
    // and 336*8 = 2688 channels total
    reg [15:0] values [(CHANNEL_COUNT-1):0];

    // TODO: Make a memory bus, wire this module into it
    always @(posedge clock)
    begin
        if(spi_write_strobe) begin
            values[spi_address] <= spi_data;
        end
    end


    reg [3:0] state;
    reg [10:0] counter;

    reg [BUFFER_WIDTH:0] readindex;   // Current byte, but it is offset from 0..11
    reg [2:0] subchip_byte;           // Counter from 0..5

    reg [15:0] val;                   // 16-bit output value from memory

    assign clock_out = !clock;        // Off by 1/2 phase?


    always @(posedge clock)
        if(reset) begin
            state <= 0;
            data_out <= 0;

            val <= 0;
        end
        else begin
            data_out <= 0;

            case(state)
            // Many states here:
            // 0. wait for start
            0:
                // TODO: implement start signal
                begin
                    state <= 1;
                    counter <= 0;

                    readindex <= 5;
                    subchip_byte <= 0;
                end
            // 1. start (128 bits of 1)
            1:
                begin
                    data_out <= 1;

                    counter <= counter +1;
                    
                    if(counter == 127) begin
                        state <= state + 1;
                        counter <= 0;
                    end
                end
            // 2. blank (16 bits of 0)
            2,4,6,8:
                begin
                    counter <= counter +1;
                    
                    if(counter == 15) begin
                        state <= state + 1;
                        counter <= 0;
                    end
                end
            // 3. reg (16 bit register value)
            3:
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
                        val <= values[readindex];

                        // Count in sequence:
                        // 5,4,3,2,1,0,11,10,9,8,7,6,15,14,13,12,11, ...
                        if(subchip_byte == 5) begin
                            subchip_byte <= 0;
                            readindex <= readindex + 11;
                        end
                        else begin
                            subchip_byte <= subchip_byte + 1;
                            readindex <= readindex - 1;
                        end
                    end
                end

            // 4. blank (16 bits of 0)
            // for n chips:
            // 5.  chip x, out5-out0 (16 x 6 bits)
            5, 7:
                begin
                    // Here:
                    // counter[3:0] is the bit output (0-15)
                    // counter[6:4] is output (5-0) if in state 5, or output (11-6) if in state 7.
                    counter <= counter + 1;

                    data_out <= val[15 - counter[3:0]];

                    if(counter[3:0] == 15) begin
                        val <= values[readindex];

                        if(subchip_byte == 5) begin
                            subchip_byte <= 0;
                            readindex <= readindex + 11;
                        end
                        else begin
                            subchip_byte <= subchip_byte + 1;
                            readindex <= readindex - 1;
                        end
                    end

                    if(counter == (16*6-1)) begin
                        counter <= 0;

                        if(state == 5) begin
                            state <= state + 1;
                        end
                        else begin
                            if(readindex < CHANNEL_COUNT)
                                state <= 4;
                            else
                                state <= state + 1;
                        end
                    end
                end

            // 6.  blank
            // 7.  chip x, out11-out6 (16 x 6 bits)
            // 8.  blank
            // 9. frame end (145 bits of 1)
            9:
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



/*

    reg [3:0] state;
    reg [10:0] counter;

    reg [7:0] chipIndex;        // Chip we are currently clocking out
    reg [5:0] outp;             // Current ICND channel (0-11)

    //assign clock_out = !clock;  // Off by 1/2 phase?   
    assign clock_out = clock;

    reg [15:0] currentValue;

    always @(posedge clock)
        if(reset) begin
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
