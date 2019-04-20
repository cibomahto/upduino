module sram_bus #(
    parameter ADDRESS_BUS_WIDTH = 12,
    parameter DATA_BUS_WIDTH = 16,

) (
    input rst,
    input clk,

    input [(ADDRESS_BUS_WIDTH-1):0] write_address,
    input [(DATA_BUS_WIDTH-1):0] write_data,
    input write_strobe,

    input [(ADDRESS_BUS_WIDTH-1):0] read_address_1,
    input read_strobe_1,
    output reg read_finished_strobe_1,

    input [(ADDRESS_BUS_WIDTH-1):0] read_address_2,
    input read_strobe_2,
    output reg read_finished_strobe_2,

    output reg [(DATA_BUS_WIDTH-1):0] read_data,

    output reg [1:0] state,
);

    reg [(ADDRESS_BUS_WIDTH-1):0] ram_address;
    reg [(DATA_BUS_WIDTH-1):0] ram_data_in;
    wire [15:0] ram_data_out;
    reg ram_wren;
    reg ram_chipselect;

    SB_SPRAM256KA ramfn_inst1(
        .DATAIN(ram_data_in),
        .ADDRESS(ram_address),
        .MASKWREN(4'b1111),
        .WREN(ram_wren),
        .CHIPSELECT(1'b1),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(ram_data_out),
    );

//    reg [1:0] state;

    localparam STATE_IDLE = 0;
    localparam STATE_WRITE_EXECUTE = 1;
    localparam STATE_READ_1_EXECUTE = 2;
    localparam STATE_READ_2_EXECUTE = 3;

    always @(posedge clk) begin
        if(rst) begin
            state <= STATE_IDLE;

            ram_address <= 0;
            ram_data_in <= 0;

            ram_wren <= 0;
            ram_chipselect <= 0;
        end
        else begin
            ram_wren <= 0;
            read_finished_strobe_1 <= 0;
            read_finished_strobe_2 <= 0;

            case(state)
            STATE_IDLE:
            begin
                // TODO: This will only catch a write strobe if we happen to be
                // idle when it comes in. Move this to a FIFO, and poll the FIFO
                // from here.
                if(write_strobe) begin
                    ram_address <= write_address;
                    ram_data_in <= write_data;
    
                    state <= STATE_WRITE_EXECUTE;
                end
                else if(read_strobe_1) begin
                    ram_address <= read_address_1;
                    state <= STATE_READ_1_EXECUTE;
                end
                else if(read_strobe_2) begin
                    ram_address <= read_address_2;
                    state <= STATE_READ_2_EXECUTE;
                end
            end
            STATE_WRITE_EXECUTE:
            begin
                ram_wren <= 1;
                state <= STATE_IDLE;
            end
            STATE_READ_1_EXECUTE:
            begin
                read_data <= ram_data_out;
                read_finished_strobe_1 <= 1;
                state <= STATE_IDLE;
            end
            STATE_READ_2_EXECUTE:
            begin
                read_data <= ram_data_out;
                read_finished_strobe_2 <= 1;
                state <= STATE_IDLE;
            end
            default:
                state <= STATE_IDLE;
            endcase

        end
    end

endmodule
