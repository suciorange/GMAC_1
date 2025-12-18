`default_nettype none

module rx_fifo_async #(
    parameter integer ADDR_BITS = 4
) (
    input  wire        wclk,
    input  wire        wrstn,
    input  wire        wvalid,
    output wire        wready,
    input  wire [7:0]  wdata,
    input  wire        wlast,
    input  wire        rclk,
    input  wire        rrstn,
    output wire        rvalid,
    input  wire        rready,
    output wire [7:0]  rdata,
    output wire        rlast,
    output wire        full,
    output wire        empty
);

    wire [8:0] fifo_wdata;
    wire [8:0] fifo_rdata;

    assign fifo_wdata = {wlast, wdata};

    async_fifo #(
        .DATA_WIDTH(9),
        .ADDR_BITS (ADDR_BITS)
    ) u_async_fifo (
        .wclk  (wclk),
        .wrstn (wrstn),
        .wvalid(wvalid),
        .wready(wready),
        .wdata (fifo_wdata),
        .full  (full),
        .rclk  (rclk),
        .rrstn (rrstn),
        .rvalid(rvalid),
        .rready(rready),
        .rdata (fifo_rdata),
        .empty (empty)
    );

    assign {rlast, rdata} = fifo_rdata;

endmodule

`default_nettype wire
