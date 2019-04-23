module spi_in #(
    parameter ADDRESS_BUS_WIDTH = 16,
    parameter DATA_BUS_WIDTH = 16,
) (
    // SPI bus connection. These are in the SCK clock domain.
    input cs,
    input sck,
    input mosi,
    output wire miso,

    // System bus connections. These are in the system clock domain.
    input clk,
    output reg [(DATA_BUS_WIDTH-1):0] data,         // Data frame
    output reg [(ADDRESS_BUS_WIDTH-1):0] address,      // Address to write data frame
    output wire write_strobe        // Asserts for 1 system clock cycle when new data is ready
);
    `include "functions.vh"

    // Buffer to read into (in CIN clock domain)
    reg [(DATA_BUS_WIDTH-1):0] read_buffer;

    // Toggle signal for read (in CIN clock domain)
    reg write_toggle;

    // Synchronize write_strobe to system clock
    sync_ss din_sync_ss(clk, 0, write_toggle, write_toggle_sync);

    // Convert the toggle to a strobe, in system clock domain
    toggle_to_strobe toggle_to_strobe_1(
        .clk(clk),
        .toggle_in(write_toggle_sync),
        .strobe_out(write_strobe),
    );

    reg [(clogb2(DATA_BUS_WIDTH)-1):0] bit_index;

    reg [1:0] state;

    assign miso = state[0];

    always @(posedge sck or posedge cs) begin
        // TODO: handle data out
//        miso <= 0;

        if(cs) begin
            bit_index <= (DATA_BUS_WIDTH-1);
            state <= 0;
        end
        else begin

            if(bit_index == 0) begin
                bit_index <= (DATA_BUS_WIDTH-1);

                case(state)
                    0:  // 1. Read address
                    begin
                        address <= {read_buffer[15:1], mosi};
                        state <= state + 1;
                    end
                    1:  // 2. Read first byte of data
                    begin
                        data <= {read_buffer[15:1], mosi};
                        write_toggle <= ~write_toggle;
                        state <= state + 1;
                    end
                    2:  // 2. Read data and increment address
                    begin
                        data <= {read_buffer[15:1], mosi};
                        address <= address + 1;
                        write_toggle <= ~write_toggle;
                    end
                endcase
            end
            else begin
                read_buffer[bit_index] <= mosi;

                bit_index <= bit_index - 1;
            end
        end
    end
endmodule
