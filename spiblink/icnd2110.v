module icnd2110(
    input clk,
    input rst,
    input [7:0] chipcount,
    input cfg_pwm_wider,        // Enhancement for low gray (1=enable)
    input cfg_up,               // Ghosting reduction (1=enable)
    output spi_c,
    output spi_d,
    output start_flag
);

    reg [3:0] state;     // Current state machine mode

    reg [10:0] counter;  // 8-bit step counter

    reg [7:0] chips;     // Number of ICND2110 chips present

    reg [9:0] val;       // PWM value (top 8 bits are significant)
    reg [5:0] outp;      // Current ICND channel (0-11)
    reg [7:0] pwm_val;

    wire [15:0] correction;

    reg data;
    reg start_flag_r;

    assign spi_c = clk;        // Off by 1/2 phase?   
    assign spi_d = data;
    assign start_flag = start_flag_r;

// The LUT takes the majority of our space, can we move it to a ram?
    correction_lut_16 corrector (
        .value(pwm_val),
        .corrected(correction)
    );

    always @(negedge clk)
        if(rst) begin
            state <= 0;
            data <= 0;

            val <= 0;
            outp <= 0;
        end
        else begin

            start_flag_r <= 0;
            data <= 0;

            if(val[9] == 0)
                pwm_val <= val[8:1];
            else
                pwm_val <= (255 - val[8:1]);

            case(state)
            // Many states here:
            // 0. wait for start
            0:
                // TODO: implement start signal
                begin
                    start_flag_r <= 1;
                    state <= 1;
                    counter <= 0;

                    chips <= chipcount;

                    val <= val + 1;     // output value counter

                    if(val == 0)
                        outp <= outp+1;

                    //if(outp > 11)
                    //    outp <= 0;

                    if(outp > 2)
                        outp <= 0;
                        
                end
            // 1. start (128 bits of 1)
            1:
                begin
                    data <= 1;

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
                            data <= cfg_pwm_wider;
                        12:
                            data <= cfg_up;
                        13,14,15:
                            data <= 1;
                        default:
                            data <= 0;
                    endcase

                    if(counter == 15) begin
                        state <= state + 1;
                        counter <= 0;
                    end
                end

            // 4. blank (16 bits of 0)
            // for n chips:
            // 5.  chip x, out5-out0 (16 x 6 bits)
            5, 7:
                begin
                    // Here, counter[3:0] is the bit output, and counter[6:4] is output (5-0) if in state 5, or output (11-6) if in state 7.
                    counter <= counter + 1;

//                    if(((state == 5) && (counter[6:4] == outp))
//                        || ((state == 7) && (counter[6:4] == (outp - 6)))) begin

                    if(counter[6:4] % 3  == outp) begin

                        case(counter[3:0])
                            0: data <= correction[15];
                            1: data <= correction[14];
                            2: data <= correction[13];
                            3: data <= correction[12];
                            4: data <= correction[11];
                            5: data <= correction[10];
                            6: data <= correction[9];
                            7: data <= correction[8];
                            8: data <= correction[7];
                            9: data <= correction[6];
                            10: data <= correction[5];
                            11: data <= correction[4];
                            12: data <= correction[3];
                            13: data <= correction[2];
                            14: data <= correction[1];
                            15: data <= correction[0];
                        endcase

                      end

                    if(counter == (16*6-1)) begin
                        counter <= 0;

                        if(state == 5) begin
                            state <= state + 1;
                        end
                        else begin
                            chips <= chips - 1;

                            if(chips > 0)
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
                    data <= 1;

                    counter <= counter +1;
                    
                    if(counter == 144) begin
//                        state <= state + 1;
                        state <= 0;
                        counter <= 0;
                    end
                end

            default:
                state <= 0;

            endcase
        end

endmodule
