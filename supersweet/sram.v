module sram_bus #(
    parameter ADDRESS_BUS_WIDTH = 16,
    parameter DATA_BUS_WIDTH = 16,
    parameter OUTPUT_COUNT = 10,
) (
    input rst,
    input clk,

    input [(ADDRESS_BUS_WIDTH-1):0] write_address,
    input [(DATA_BUS_WIDTH-1):0] write_data,
    input write_strobe,

    input [(OUTPUT_COUNT-1):0] read_requests,
    output reg [(OUTPUT_COUNT-1):0] read_finished_strobes,
    output reg [(DATA_BUS_WIDTH-1):0] read_data,

    // TODO: How to parameterize this?
    input [(ADDRESS_BUS_WIDTH-1):0] read_address_0,
    input [(ADDRESS_BUS_WIDTH-1):0] read_address_1,
    input [(ADDRESS_BUS_WIDTH-1):0] read_address_2,
    input [(ADDRESS_BUS_WIDTH-1):0] read_address_3,
//    input [(ADDRESS_BUS_WIDTH-1):0] read_address_4,
//    input [(ADDRESS_BUS_WIDTH-1):0] read_address_5,
//    input [(ADDRESS_BUS_WIDTH-1):0] read_address_6,
//    input [(ADDRESS_BUS_WIDTH-1):0] read_address_7,
//    input [(ADDRESS_BUS_WIDTH-1):0] read_address_8,
//    input [(ADDRESS_BUS_WIDTH-1):0] read_address_9,

    output reg [2:0] state,
);
    `include "functions.vh"

    localparam SRAM_COUNT = 4;

    reg [(ADDRESS_BUS_WIDTH-1):0] ram_address;
    reg [(DATA_BUS_WIDTH-1):0] ram_data_in;
    //wire [(DATA_BUS_WIDTH-1):0] ram_data_out;
    wire [(DATA_BUS_WIDTH-1):0] ram_data_out [(SRAM_COUNT-1):0];
    reg ram_wren;

    wire [(ADDRESS_BUS_WIDTH-1):0] read_addresses [(OUTPUT_COUNT-1):0];
    assign read_addresses[0] = read_address_0;
    assign read_addresses[1] = read_address_1;
    assign read_addresses[2] = read_address_2;
    assign read_addresses[3] = read_address_3;
//    assign read_addresses[4] = read_address_4;
//    assign read_addresses[5] = read_address_5;
//    assign read_addresses[6] = read_address_6;
//    assign read_addresses[7] = read_address_7;
//    assign read_addresses[8] = read_address_8;
//    assign read_addresses[9] = read_address_9;

    wire [1:0] ram_cs = ram_address[15:14];
    wire [13:0] ram_addr_low = ram_address[13:0];

    wire cs_0 = (ram_cs == 2'b00);
    wire cs_1 = (ram_cs == 2'b01);
    wire cs_2 = (ram_cs == 2'b10);
    wire cs_3 = (ram_cs == 2'b11);


    SB_SPRAM256KA ramfn_inst0(
        .DATAIN(ram_data_in),
        .ADDRESS(ram_addr_low),    // The ram is 16384 words long, so it needs 14 bits.
        .MASKWREN(4'b1111),
        .WREN(ram_wren),
        .CHIPSELECT(cs_0),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(ram_data_out[0]),
    );

    SB_SPRAM256KA ramfn_inst1(
        .DATAIN(ram_data_in),
        .ADDRESS(ram_addr_low),    // The ram is 16384 words long, so it needs 14 bits.
        .MASKWREN(4'b1111),
        .WREN(ram_wren),
        .CHIPSELECT(cs_1),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(ram_data_out[1]),
    );

    SB_SPRAM256KA ramfn_inst2(
        .DATAIN(ram_data_in),
        .ADDRESS(ram_addr_low),    // The ram is 16384 words long, so it needs 14 bits.
        .MASKWREN(4'b1111),
        .WREN(ram_wren),
        .CHIPSELECT(cs_2),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(ram_data_out[2]),
    );

    SB_SPRAM256KA ramfn_inst3(
        .DATAIN(ram_data_in),
        .ADDRESS(ram_addr_low),    // The ram is 16384 words long, so it needs 14 bits.
        .MASKWREN(4'b1111),
        .WREN(ram_wren),
        .CHIPSELECT(cs_3),
        .CLOCK(clk),
        .STANDBY(1'b0),
        .SLEEP(1'b0),
        .POWEROFF(1'b1),
        .DATAOUT(ram_data_out[3]),
    );

    // Must be large enough to hold OUTPUT_COUNT
    //reg [(clogb2(OUTPUT_COUNT))-1:0] last_read;
    reg [4:0] last_read;

    reg [2:0] last_state;
    reg [2:0] counter;

    localparam STATE_IDLE = 0;
    localparam STATE_WRITE = 1;
    localparam STATE_READ = 2;

    reg write_finished_strobe;
    wire write_pending;
    reg [(ADDRESS_BUS_WIDTH-1):0] write_address_cache;
    reg [(DATA_BUS_WIDTH-1):0] write_data_cache;

    srff flop(
        .clk(clk),
        .rst(rst),
        .s(write_strobe),
        .r(write_finished_strobe),
        .q(write_pending),
    );

    integer i;

    always @(posedge clk) begin
        if(rst) begin
            state <= STATE_IDLE;

            ram_address <= 0;
            ram_data_in <= 0;

            ram_wren <= 0;
        end
        else begin
            ram_wren <= 0;
            counter <= 0;

            write_finished_strobe <= 0;
            read_finished_strobes <= 0;

            last_state <= state;

            if(write_strobe) begin
                write_address_cache <= write_address;
                write_data_cache <=write_data;
            end

            case(state)
            STATE_IDLE:
            begin

                if(write_pending && (last_state != STATE_WRITE)) begin
                    ram_address <= write_address_cache;
                    ram_data_in <= write_data_cache;
    
                    state <= STATE_WRITE;
                end
                else if(read_requests != 0) begin
                    for(i = 0; i < OUTPUT_COUNT; i++) begin
                        if(read_requests[i] == 1) begin
                            ram_address <= read_addresses[i];
                            last_read <= i;
                            state <= STATE_READ;
                        end
                    end
                end

            end
            STATE_WRITE:
            begin
                counter <= counter + 1;

                if(counter == 1) begin
                    ram_wren <= 1;
                    write_finished_strobe <= 1;
                    state <= STATE_IDLE;
                end
            end
            STATE_READ:
            begin
                counter <= counter + 1;

                if(counter == 1) begin
                    read_data <= ram_data_out[ram_cs];
                    //read_data <= ram_data_out[ram_address[14]];

                    read_finished_strobes[last_read] <= 1;
                    state <= STATE_IDLE;
                end
            end
            default:
                state <= STATE_IDLE;
            endcase

        end
    end

endmodule
