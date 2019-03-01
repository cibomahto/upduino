module pwm_channel(
    input clock,            // System clock
    input reset,            // System reset

    input [15:0] value,     // Target PWM value
    output out,             // PWM output bit
);

    reg [15:0] count;       // TODO: Share between PWM channels?

    reg out_reg;
    assign out = !out_reg;  // Inverted output

    always @(posedge clock)
        if(reset) begin
            count <= 0;
            out_reg <= 0;
        end
        else begin
            count <= count + 1;

            out_reg <= 0;

            if(count < value)
                out_reg <= 1;
        end
endmodule
