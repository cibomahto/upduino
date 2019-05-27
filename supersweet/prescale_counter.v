
module prescale_counter #(
    parameter PRESCALER_BITS = 1,
    parameter COUNTER_BITS = 16,
) (
    input clk,
    input rst,

    input [(PRESCALER_BITS-1):0] prescaler_preset,
    input [(COUNTER_BITS-1):0] counter_preset,

    output reg counter_toggle,
);

    reg [(PRESCALER_BITS-1):0] prescaler;
    reg [(COUNTER_BITS-1):0] counter;

    always @(posedge clk) begin
        if(rst) begin
            counter <= counter_preset;
            prescaler <= prescaler_preset;

            counter_toggle <= 0;
        end
        else begin
            prescaler <= prescaler - 1;

            if(prescaler == 0) begin
                prescaler <= prescaler_preset;

                counter <= counter - 1;

                if(counter == 0) begin
                    counter <= counter_preset;
                    counter_toggle <= ~counter_toggle;
                end
            end
        end
    end

endmodule
