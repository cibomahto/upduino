module chip (
    output DMX_OUT,
    output TP_0,
    output TP_1,
    output TP_2,
);

    wire clock;
    wire reset;

    // Configure the clock for 48 MHz operation (TODO: Seems like 24MHz?)
	SB_HFOSC u_hfosc (
       	.CLKHFPU(1'b1),
       	.CLKHFEN(1'b1),
        .CLKHF(clock)
    );
//    defparam u_hfosc.CLKHF_DIV = 2'b01; // 00: 48MHz 01: 24MHz 10: 12MHz 11: 6MHz
    defparam u_hfosc.CLKHF_DIV = "0b00";

    // TODO: Hardware reset line
    assign reset = 0;

    assign TP_0 = 0;
    assign TP_1 = 0;
    assign TP_2 = 0;


    dmx_out my_dmx_out(
        .clock(clock),
        .reset(reset),
        .dmx_out(DMX_OUT)
    );
endmodule
