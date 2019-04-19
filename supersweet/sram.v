module sram_bus #(
    parameter ADDRESS_BUS_WIDTH = 12,
    parameter DATA_BUS_WIDTH = 16,

) (
    input rst,
    input clk,

    input [(ADDRESS_BUS_WIDTH-1):0] write_address,
    input [(DATA_BUS_WIDTH-1):0] write_data,
    input write_strobe,

    input [(ADDRESS_BUS_WIDTH-1):0] read_address,
    input read_strobe,
    output wire [(DATA_BUS_WIDTH-1):0] read_data,
    output reg read_finished_strobe,
);

    reg [(ADDRESS_BUS_WIDTH-1):0] ram_address;
    wire [15:0] ram_data_out;
    reg ram_wren;
    reg ram_chipselect;

    SB_SPRAM256KA ramfn_inst1(
        .DATAIN(write_data),
        .ADDRESS(ram_address),
        .MASKWREN( 4'b1111),
        .WREN(ram_wren),
        .CHIPSELECT(ram_chipselect),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(read_data),
    );

endmodule
