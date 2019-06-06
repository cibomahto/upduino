parameter PWM_CHANNELS = 8;

module chip (
    input DMX_IN,
    
    output DMX_OUT,

	output EN_IN_1,
	output EN_IN_2,
	output EN_IN_3,
	output EN_IN_4,
	output EN_IN_5,
	output EN_IN_6,
	output EN_IN_7,
	output EN_IN_8,
	output OE,

    output DMX_TX_IND,
    output DMX_RX_IND,

    // For SPI flash: not used in this design
    input ICE_MISO,
    input ICE_MOSI,
    input ICE_SCK,
    input ICE_SS,
);

    wire clk;
    wire rst;

    // PWM value memory
    reg [15:0] values [(PWM_CHANNELS-1):0];
    initial begin
        $readmemh("values.list", values);
    end

    // PWM output wires
    wire [(PWM_CHANNELS-1):0] outputs;
    assign EN_IN_1 = outputs[0];
    assign EN_IN_2 = outputs[1];
    assign EN_IN_3 = outputs[2];
    assign EN_IN_4 = outputs[3];
    assign EN_IN_5 = outputs[4];
    assign EN_IN_6 = outputs[5];
    assign EN_IN_7 = outputs[6];
    assign EN_IN_8 = outputs[7];

    // PWM output enable
    assign OE = 0;

    // TODO: Hardware reset line
    assign rst = 0;

    // TODO: Flash during reception
    assign DMX_TX_IND = 0;
    assign DMX_RX_IND = 0;

    // Configure the clock for 24 MHz operation
    // TODO: Nextpnr says we can't hit 48MHz?
	SB_HFOSC u_hfosc (
       	.CLKHFPU(1'b1),
       	.CLKHFEN(1'b1),
        .CLKHF(clk)
    );
    defparam u_hfosc.CLKHF_DIV = "0b00";    // 48 MHz
//    defparam u_hfosc.CLKHF_DIV = "0b01";    // 24 MHz
//    defparam u_hfosc.CLKHF_DIV = "0b10";    // 12 MHz
//    defparam u_hfosc.CLKHF_DIV = "0b11";    // 6 MHz

    wire [7:0] dmx_data;
    wire [8:0] dmx_channel;
    wire dmx_write_strobe;

    dmx_in my_dmx_in(
        .clk(clk),
        .rst(rst),

        .dmx_in(DMX_IN),
        .dmx_out(DMX_OUT),

        .data(dmx_data),
        .channel(dmx_channel),
        .write_strobe(dmx_write_strobe),
    );

    reg [15:0] lut_8_to_16 [255:0];
    initial begin
        $readmemh("lut_8_to_16_pow_1.80.list", lut_8_to_16);
    end

    always @(posedge clk)
    begin
        if(dmx_write_strobe) begin
            // Assign DMX channels 0-7 to the upper bits of the PWM values
            if(dmx_channel < PWM_CHANNELS) begin
                values[dmx_channel[2:0]] <= lut_8_to_16[dmx_data];
            end
        end
    end

    generate
        genvar i;
        for (i=0; i<(PWM_CHANNELS); i=i+1) begin
            pwm_channel i_pwm_channel(
               .clk(clk),
               .rst(rst),
               .value(values[i]),
               .out(outputs[i]),
            );
        end
    endgenerate
endmodule
