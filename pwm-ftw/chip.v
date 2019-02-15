module chip (
    input DIN,
    input CIN,
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
    input ICE_SS
);

    wire clock;
    wire reset;

    wire [15:0] spiData;
    wire [2:0] spiAddress;
    wire spiReadStrobe;

    reg [15:0] values [7:0];
    initial begin
        $readmemh("values.list", values);
    end

    wire [7:0] outputs;

    assign EN_IN_1 = ~outputs[0];
    assign EN_IN_2 = ~outputs[1];
    assign EN_IN_3 = ~outputs[2];
    assign EN_IN_4 = ~outputs[3];
    assign EN_IN_5 = ~outputs[4];
    assign EN_IN_6 = ~outputs[5];
    assign EN_IN_7 = ~outputs[6];
    assign EN_IN_8 = ~outputs[7];

    assign TP_1 = 0;
    assign TP_2 = 0;
    assign TP_3 = 0;
    assign TP_4 = 0;
    assign TP_5 = 0;
    assign TP_7 = 0;

    assign reset = 0;

    assign OE = 0;

	SB_HFOSC u_hfosc (
       	.CLKHFPU(1'b1),
       	.CLKHFEN(1'b1),
        .CLKHF(clock)
    );

    spireader my_spireader(
        .clock(clock),
        .reset(reset),
        .din(DIN),
        .cin(CIN),
        .dout(DO),
        .cout(CO),
        .data(spiData),
        .address(spiAddress),
        .readStrobe(spiReadStrobe)
    );

    always @(posedge clock)
    begin
        if(spiReadStrobe) begin
            values[spiAddress] <= spiData;
        end
    end


    pwm my_pwm(
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


endmodule
