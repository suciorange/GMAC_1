`default_nettype none

// Asynchronous FIFO with Gray-code pointer synchronization.
module async_fifo #(
    parameter integer DATA_WIDTH = 8,
    parameter integer ADDR_BITS  = 4
) (
    // Write interface
    input  wire                     wclk,
    input  wire                     wrstn,
    input  wire                     wvalid,
    output wire                     wready,
    input  wire [DATA_WIDTH-1:0]    wdata,
    output wire                     full,
    // Read interface
    input  wire                     rclk,
    input  wire                     rrstn,
    output wire                     rvalid,
    input  wire                     rready,
    output reg  [DATA_WIDTH-1:0]    rdata,
    output wire                     empty
);

    localparam integer DEPTH = (1 << ADDR_BITS);

    // Storage
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Binary and Gray pointers include an extra bit for full/empty detection
    reg [ADDR_BITS:0] wptr_bin;
    reg [ADDR_BITS:0] rptr_bin;
    reg [ADDR_BITS:0] wptr_gray;
    reg [ADDR_BITS:0] rptr_gray;

    // Synchronized pointers
    reg [ADDR_BITS:0] wptr_gray_sync1;
    reg [ADDR_BITS:0] wptr_gray_sync2;
    reg [ADDR_BITS:0] rptr_gray_sync1;
    reg [ADDR_BITS:0] rptr_gray_sync2;

    // Gray conversion functions
    function [ADDR_BITS:0] bin2gray;
        input [ADDR_BITS:0] bin;
        begin
            bin2gray = (bin >> 1) ^ bin;
        end
    endfunction

    function [ADDR_BITS:0] gray2bin;
        input [ADDR_BITS:0] gray;
        integer i;
        begin
            gray2bin[ADDR_BITS] = gray[ADDR_BITS];
            for (i = ADDR_BITS-1; i >= 0; i = i - 1) begin
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
            end
        end
    endfunction

    // Write pointer and memory update
    wire write_en = wvalid && wready;
    wire [ADDR_BITS:0] wptr_bin_next  = wptr_bin + (write_en ? 1'b1 : 1'b0);
    wire [ADDR_BITS:0] wptr_gray_next = bin2gray(wptr_bin_next);

    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            wptr_bin  <= {ADDR_BITS+1{1'b0}};
            wptr_gray <= {ADDR_BITS+1{1'b0}};
        end else begin
            if (write_en) begin
                mem[wptr_bin[ADDR_BITS-1:0]] <= wdata;
            end
            wptr_bin  <= wptr_bin_next;
            wptr_gray <= wptr_gray_next;
        end
    end

    // Read pointer and data update
    wire read_en = rvalid && rready;
    wire [ADDR_BITS:0] rptr_bin_next  = rptr_bin + (read_en ? 1'b1 : 1'b0);
    wire [ADDR_BITS:0] rptr_gray_next = bin2gray(rptr_bin_next);

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            rptr_bin  <= {ADDR_BITS+1{1'b0}};
            rptr_gray <= {ADDR_BITS+1{1'b0}};
            rdata     <= {DATA_WIDTH{1'b0}};
        end else begin
            if (read_en) begin
                rdata <= mem[rptr_bin[ADDR_BITS-1:0]];
            end
            rptr_bin  <= rptr_bin_next;
            rptr_gray <= rptr_gray_next;
        end
    end

    // Synchronize pointers across clock domains
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rptr_gray_sync1 <= {ADDR_BITS+1{1'b0}};
            rptr_gray_sync2 <= {ADDR_BITS+1{1'b0}};
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wptr_gray_sync1 <= {ADDR_BITS+1{1'b0}};
            wptr_gray_sync2 <= {ADDR_BITS+1{1'b0}};
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Full and empty detection
    assign full  = (wptr_gray_next == {~rptr_gray_sync2[ADDR_BITS:ADDR_BITS-1], rptr_gray_sync2[ADDR_BITS-2:0]});
    assign empty = (rptr_gray_next == wptr_gray_sync2);

    assign wready = ~full;
    assign rvalid = ~empty;

endmodule

`default_nettype wire
