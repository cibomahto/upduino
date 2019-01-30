/******************************************************************************
*                                                                             *
* Copyright 2016 myStorm Copyright and related                                *
* rights are licensed under the Solderpad Hardware License, Version 0.51      *
* (the “License”); you may not use this file except in compliance with        *
* the License. You may obtain a copy of the License at                        *
* http://solderpad.org/licenses/SHL-0.51. Unless required by applicable       *
* law or agreed to in writing, software, hardware and materials               *
* distributed under this License is distributed on an “AS IS” BASIS,          *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or             *
* implied. See the License for the specific language governing                *
* permissions and limitations under the License.                              *
*                                                                             *
******************************************************************************/

module blink(
    input clk,
    input rst,
    output led_r,
    output led_g,
    output led_b
);

        //reg [7:0] lut8 [255:0];
        //initial begin
        //    $readmemh("lut8.list", lut8);
        //end

        reg [15:0] lut16 [255:0];
        initial begin
            $readmemh("lut16.list", lut16);
        end


	reg [30:0] count;

        wire direction;         // Fade in/out direction
        wire [1:0] state;       // Current phase (fade r,g,b, or w)

        reg [2:0] leds;         // LED output states

        reg pwm_state;

        wire [15:0] correction;
        

        assign led_r = !leds[0];
        assign led_g = !leds[1];
        assign led_b = !leds[2];

        assign state = count[29:28];
        assign direction = count[27];

        assign correction = lut16[count[26:19]];

	always @(posedge clk)
	    if(rst) begin
                count <= 0;
            end
            else begin
                pwm_state <= 0;
                leds <= 0;

		        count <= count + 1;

                if(direction == 0) begin
                    if(correction > count[15:0])
                        pwm_state <= 1;
                end
                else begin
                    if(correction < count[15:0])
                        pwm_state <= 1;
                end

                case(state)
                0:
                    leds[0] <= pwm_state;
                1:
                    leds[1] <= pwm_state;
                2:
                    leds[2] <= pwm_state;
                3:
                    begin
                        leds[0] <= pwm_state;
                        leds[1] <= pwm_state;
                        leds[2] <= pwm_state;
                    end
        
                endcase
            end

endmodule
