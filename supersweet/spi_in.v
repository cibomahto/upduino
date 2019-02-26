module spi_in(
    input clock,
    input reset,
    input din,
    input cin,
    output dout,
    output cout,

    // Safe to consume from system clock domain:
    output [15:0] data,         // Data frame
    output [10:0] address,      // Address to write data frame
    output write_strobe         // Asserts for 1 system clock cycle when new data is ready
);

    reg [15:0] read_buffer;     // Buffer to read into (in CIN clock domain)
    reg write_strobe_flag;      // Toggle signal for read (in CIN clock domain)

    reg [15:0] output_buffer;   // Buffered value, for reading across clock domain
    reg [10:0] output_address;  // Buffered address value, for reading across clock domain
    wire write_strobe_sync;      // write_strobe syncronzied to system clock domain
    reg write_strobe_sync_prev; // Value of write_strobe on previous system clock
    sync_ss din_sync_ss(clock, reset, write_strobe_flag, write_strobe_sync);   // Synchronize write_strobe to system clock

    assign write_strobe = (write_strobe_sync != write_strobe_sync_prev);

    reg [12:0] timeoutCounter;  // We want a timeout in the range of a few hundred uS.
    reg timeout;

    assign data = output_buffer;
    assign address = output_address;

    // TODO
    assign dout = write_strobe;
    assign cout = (output_address == 0);

    reg [5:0] bit_index;
    initial bit_index = 15;

    reg timeout_prev;

    always @(posedge cin)
    begin
        if(reset) begin
            bit_index <= 15;
            output_address <= 11'b11111111111;
        end
        else begin
            timeout_prev <= timeout;

            bit_index <= bit_index - 1;

            read_buffer[bit_index] <= din;

            // TODO: unsafe clock domain for 'timeout'
            if((timeout != timeout_prev) && (timeout == 1)) begin
                read_buffer[15] <= din;
                bit_index <= 14;
                output_address <= 11'b11111111111;
            end
            else if(bit_index == 0) begin
                output_buffer <= read_buffer;
                output_address <= output_address + 1;
                bit_index <= 15;

                write_strobe_flag <= ~write_strobe_flag;
            end
        end
    end

    always @(posedge clock)
    begin
        if(reset) begin
            timeoutCounter <= 0;
            timeout <= 0;
        end
        else begin
            // TODO: This probably glitches on reset
            write_strobe_sync_prev <= write_strobe_sync;

            timeoutCounter <= timeoutCounter + 1;
            timeout <= 0;

            if(write_strobe) begin
                timeoutCounter <= 0;
                timeout <= 0;
            end
            else if(timeoutCounter == 13'b1111111111111) begin
                timeoutCounter <= 13'b1111111111111;
                timeout <= 1;
            end
        end
    end

endmodule
