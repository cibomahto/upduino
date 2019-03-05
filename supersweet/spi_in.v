module spi_in(
    // SPI bus connection. These are in the SCK clock domain.
    input cs,
    input sck,
    input mosi,
    output reg miso,

    // System bus connections. These are in the system clock domain.
    input clk,
    output reg [15:0] data,         // Data frame
    output reg [12:0] address,      // Address to write data frame
    output wire write_strobe        // Asserts for 1 system clock cycle when new data is ready
);

    reg [15:0] read_buffer;     // Buffer to read into (in CIN clock domain)
    reg write_strobe_flag;      // Toggle signal for read (in CIN clock domain)

    wire write_strobe_sync;      // write_strobe syncronzied to system clock domain
    reg write_strobe_sync_prev; // Value of write_strobe on previous system clock
    sync_ss din_sync_ss(clk, 0, write_strobe_flag, write_strobe_sync);   // Synchronize write_strobe to system clock

    assign write_strobe = (write_strobe_sync != write_strobe_sync_prev);

    always @(posedge clk) begin
        write_strobe_sync_prev = write_strobe_sync;
    end

    reg [5:0] bit_index;
    initial bit_index = 15;

    always @(posedge sck or posedge cs) begin
        // TODO: handle data out
        miso <= 0;

        if(cs) begin
            bit_index <= 15;
            address <= 13'b1111111111111;
        end
        else begin
            read_buffer[bit_index] <= mosi;

            if(bit_index == 0) begin
                bit_index <= 15;

                data <= {read_buffer[15:1], mosi};
                address <= address + 1;
                write_strobe_flag <= ~write_strobe_flag;
            end
            else begin
                bit_index <= bit_index - 1;
            end
        end
    end

/*
    reg Q;
    reg tmp;

    SR_latch_gate latch_cs(
        .S(cs),
        .R(tmp),
        .Q(Q),
        .Qbar( ),
    );

    always @(posedge sck) begin
        tmp <= 0;

        if(~cs) begin
            if(Q) begin
                tmp <= 1;

                read_buffer[15] <= mosi;

                bit_index <= 14;
                address <= 11'b11111111111;
            end
            else begin
                read_buffer[bit_index] <= mosi;

                if(bit_index == 0) begin
                    bit_index <= 15;

                    data <= {read_buffer[15:1], mosi};
                    address <= address + 1;
                    write_strobe_flag <= ~write_strobe_flag;
                end
                else begin
                    bit_index <= bit_index - 1;
                end
            end
        end
    end
*/
endmodule
