parameter PWM_CHANNELS = 8;

module chip (
    input DIN,
    
//    input CIN,
    output CIN,     // TODO: For debugging
    output DO,
    output CO,

	output EN_IN_1,
	output EN_IN_2,
	output EN_IN_3,
	output EN_IN_4,
	output EN_IN_5,
	output EN_IN_6,
	output EN_IN_7,
	output EN_IN_8,
	output OE,

    output TP_1,
    output TP_2,
    output TP_3,
    output TP_4,
    output TP_5,
    output TP_7,

    // For SPI flash: not used in this design
    input ICE_MISO,
    input ICE_MOSI,
    input ICE_SCK,
    input ICE_SS,
);

    wire clock;
    wire reset;

//    // PWM value memory
    reg [15:0] values [(PWM_CHANNELS-1):0];
    initial begin
        $readmemh("values.list", values);
    end

    // PWM output wires
    wire [(PWM_CHANNELS-1):0] outputs;
    assign EN_IN_1 = ~outputs[7];
    assign EN_IN_2 = ~outputs[6];
    assign EN_IN_3 = ~outputs[5];
    assign EN_IN_4 = ~outputs[4];
    assign EN_IN_5 = ~outputs[3];
    assign EN_IN_6 = ~outputs[2];
    assign EN_IN_7 = ~outputs[1];
    assign EN_IN_8 = ~outputs[0];

    // PWM output enable
    assign OE = 0;

    // For testing (unused)
    assign TP_1 = 0;
    assign TP_2 = 0;
    assign TP_3 = 0;
    assign TP_4 = 0;
    assign TP_5 = 0;
    assign TP_7 = 0;

    assign CIN = DIN;

    //assign DO = 0;
    //assign CO = 0;

    // TODO: Hardware reset line
    assign reset = 0;

    // Configure the clock for 24 MHz operation
    // TODO: Nextpnr says we can't hit 48MHz?
	SB_HFOSC u_hfosc (
       	.CLKHFPU(1'b1),
       	.CLKHFEN(1'b1),
        .CLKHF(clock)
    );
//    defparam u_hfosc.CLKHF_DIV = "0b00";    // 48 MHz
    defparam u_hfosc.CLKHF_DIV = "0b01";    // 24 MHz
//    defparam u_hfosc.CLKHF_DIV = "0b10";    // 12 MHz
//    defparam u_hfosc.CLKHF_DIV = "0b11";    // 6 MHz

    wire [7:0] dmx_data;
    wire [8:0] dmx_channel;
    wire dmx_write_strobe;

    dmx_in my_dmx_in(
        .clock(clock),
        .reset(reset),
        .dmx_in(DIN),
        .dmx_out(DO),
        .data(dmx_data),
        .channel(dmx_channel),
        .write_strobe(dmx_write_strobe),
        .debug(CO),
    );

    reg [15:0] lut_8_to_16 [255:0];
    initial begin
        $readmemh("lut_8_to_16_pow_1.80.list", lut_8_to_16);
    end

    always @(posedge clock)
    begin
        if(dmx_write_strobe) begin
            // Assign DMX channels 0-7 to the upper bits of the PWM values
            if(dmx_channel < PWM_CHANNELS) begin
                values[dmx_channel[2:0]] <= lut_8_to_16[dmx_data];
            end
        end
    end
/*
    pwm_out my_pwm_out(
        .clock(clock),
        .reset(reset),
        .v0(values[0]),
        .v1(values[1]),
        .v2(values[2]),
        .v3(values[3]),
        .v4(values[4]),
        .v5(values[5]),
        .v6(values[6]),
        .v7(values[7]),
        .o0(outputs[0]),
        .o1(outputs[1]),
        .o2(outputs[2]),
        .o3(outputs[3]),
        .o4(outputs[4]),
        .o5(outputs[5]),
        .o6(outputs[6]),
        .o7(outputs[7])
    );
*/

    generate
        genvar i;
        for (i=0; i<(PWM_CHANNELS); i=i+1) begin
            pwm_channel i_pwm_channel(
               .clock(clock),
               .reset(reset),
               .value(values[i]),
               .out(outputs[i]),
            );
        end
    endgenerate
endmodule
