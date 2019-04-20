module fifo #(
    parameter DATA_WIDTH = 16,
) (
    input clk,
    input rst,

    output reg full,                    // 1 if the buffer is has data, 0 if it is empty
    output reg fault,                   // True if FIFO was overrun or underrun

    input write_strobe,                 // Write an address and data, marking the fifo full
    input [(DATA_WIDTH-1):0] write_data,    // Buffered data value

    input read_strobe,                  // Read the address and data, marking the fifo empty
    output reg [(DATA_WIDTH-1):0] read_data,    // Buffered data value
);

    reg [(DATA_WIDTH-1):0] data;    // Buffered data value

    always @(posedge clk) begin
        if(rst) begin
            full <= 0;
            fault <= 0;
        end
        else
            // Handle writes
            if(write_strobe) begin
                if(full)
                    fault <= 1;

                data <= write_data;
            end
           
            // Handle reads 
            if(read_strobe) begin
                if(~full)
                    fault <= 1;

                read_data <= data;
            end

            // Set the full signal
            if(write_strobe)
                full <= 1;
            else if(read_strobe)
                full <= 0;


        end

endmodule
