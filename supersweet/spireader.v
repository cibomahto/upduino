module spireader(
    input clock,
    input reset,
    input din,
    input cin,
    output dout,
    output cout,

    // Safe to consume from system clock domain:
    output [15:0] data,         // Data frame
    output [10:0] address,      // Address to write data frame
    output readStrobe           // Asserts for 1 system clock cycle when new data is ready
);

    reg [15:0] readBuffer;      // Buffer to read into (in CIN clock domain)
    reg readStrobe_flag;        // Toggle signal for read (in CIN clock domain)

    reg [15:0] outputBuffer;    // Buffered value, for reading across clock domain
    reg [10:0] outputAddress;   // Buffered address value, for reading across clock domain
    wire readStrobeSync;        // readStrobe syncronzied to system clock domain
    reg readStrobeSyncPrev;     // Value of readStrobe on previous system clock
    sync_ss din_sync_ss(clock, reset, readStrobe_flag, readStrobeSync);   // Synchronize readStrobe to system clock

    assign readStrobe = (readStrobeSync != readStrobeSyncPrev);

    reg [12:0] timeoutCounter;  // We want a timeout in the range of a few hundred uS.
    reg timeout;

    assign data = outputBuffer;
    assign address = outputAddress;

    // TODO
    assign dout = readStrobe;
    assign cout = (outputAddress == 0);

    reg [5:0] bitIndex;
    initial bitIndex = 15;

    reg timeoutPrev;

    always @(posedge cin)
    begin
        if(reset) begin
            bitIndex <= 15;
            outputAddress <= 11'b11111111111;
        end
        else begin
            timeoutPrev <= timeout;

            bitIndex <= bitIndex - 1;

            readBuffer[bitIndex] <= din;

            // TODO: unsafe clock domain for 'timeout'
            if((timeout != timeoutPrev) && (timeout == 1)) begin
                readBuffer[15] <= din;
                bitIndex <= 14;
                outputAddress <= 11'b11111111111;
            end
            else if(bitIndex == 0) begin
                outputBuffer <= readBuffer;
                outputAddress <= outputAddress + 1;
                bitIndex <= 15;

                readStrobe_flag <= ~readStrobe_flag;
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
            readStrobeSyncPrev <= readStrobeSync;

            timeoutCounter <= timeoutCounter + 1;
            timeout <= 0;

            if(readStrobe) begin
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
