`default_nettype none

// Top-level module for MAC integration.
module mac_top (
    input  wire        sys_clk,
    input  wire        sys_rstn,
    // Simplified AXI-Stream transmit interface
    input  wire [7:0]  tx_axis_tdata,
    input  wire        tx_axis_tvalid,
    input  wire        tx_axis_tlast,
    output wire        tx_axis_tready,
    // Simplified AXI-Stream receive interface
    output wire [7:0]  rx_axis_tdata,
    output wire        rx_axis_tvalid,
    output wire        rx_axis_tlast,
    input  wire        rx_axis_tready,
    // GMII interface
    output wire        gmii_tx_clk,
    output wire [7:0]  gmii_txd,
    output wire        gmii_tx_en,
    output wire        gmii_tx_er,
    input  wire        gmii_rx_clk,
    input  wire [7:0]  gmii_rxd,
    input  wire        gmii_rx_dv,
    input  wire        gmii_rx_er
);

    // Control signals
    wire        cfg_tx_en;
    wire        cfg_rx_en;
    wire [1:0]  cfg_speed;
    wire        cfg_full_duplex;
    wire [47:0] cfg_mac_addr;

    // TX FIFO signals
    wire        tx_fifo_rd_valid;
    wire        tx_fifo_rd_ready;
    wire [7:0]  tx_fifo_rd_data;
    wire        tx_fifo_rd_last;

    // RX FIFO signals
    wire        rx_fifo_wr_valid;
    wire        rx_fifo_wr_ready;
    wire [7:0]  rx_fifo_wr_data;
    wire        rx_fifo_wr_last;

    wire        rx_fifo_rd_valid;
    wire        rx_fifo_rd_ready;
    wire [7:0]  rx_fifo_rd_data;
    wire        rx_fifo_rd_last;

    wire        rx_good;
    wire        rx_bad_crc;
    wire        rx_phy_err;
    wire        rx_overflow;

    // For now, derive GMII transmit clock from system clock.
    assign gmii_tx_clk = sys_clk;

    // Control and status registers
    csr_regs u_csr_regs (
        .sys_clk        (sys_clk),
        .sys_rstn       (sys_rstn),
        .cfg_tx_en      (cfg_tx_en),
        .cfg_rx_en      (cfg_rx_en),
        .cfg_speed      (cfg_speed),
        .cfg_full_duplex(cfg_full_duplex),
        .cfg_mac_addr   (cfg_mac_addr)
    );

    // Asynchronous transmit FIFO
    tx_fifo_async u_tx_fifo_async (
        .wclk      (sys_clk),
        .wrstn     (sys_rstn),
        .wvalid    (tx_axis_tvalid),
        .wready    (tx_axis_tready),
        .wdata     (tx_axis_tdata),
        .wlast     (tx_axis_tlast),
        .rclk      (gmii_tx_clk),
        .rrstn     (sys_rstn),
        .rvalid    (tx_fifo_rd_valid),
        .rready    (tx_fifo_rd_ready),
        .rdata     (tx_fifo_rd_data),
        .rlast     (tx_fifo_rd_last)
    );

    // Transmit engine
    tx_engine u_tx_engine (
        .gmii_tx_clk     (gmii_tx_clk),
        .rstn            (sys_rstn),
        .gmii_txd        (gmii_txd),
        .gmii_tx_en      (gmii_tx_en),
        .gmii_tx_er      (gmii_tx_er),
        .cfg_tx_en       (cfg_tx_en),
        .fifo_rd_valid   (tx_fifo_rd_valid),
        .fifo_rd_ready   (tx_fifo_rd_ready),
        .fifo_rd_data    (tx_fifo_rd_data),
        .fifo_rd_last    (tx_fifo_rd_last)
    );

    // Receive engine
    rx_engine u_rx_engine (
        .gmii_rx_clk     (gmii_rx_clk),
        .rstn            (sys_rstn),
        .gmii_rxd        (gmii_rxd),
        .gmii_rx_dv      (gmii_rx_dv),
        .gmii_rx_er      (gmii_rx_er),
        .cfg_rx_en       (cfg_rx_en),
        .cfg_speed       (cfg_speed),
        .cfg_full_duplex (cfg_full_duplex),
        .cfg_mac_addr    (cfg_mac_addr),
        .fifo_wr_valid   (rx_fifo_wr_valid),
        .fifo_wr_ready   (rx_fifo_wr_ready),
        .fifo_wr_data    (rx_fifo_wr_data),
        .fifo_wr_last    (rx_fifo_wr_last),
        .rx_good         (rx_good),
        .rx_bad_crc      (rx_bad_crc),
        .rx_phy_err      (rx_phy_err),
        .rx_overflow     (rx_overflow)
    );

    // Asynchronous receive FIFO
    rx_fifo_async u_rx_fifo_async (
        .wclk   (gmii_rx_clk),
        .wrstn  (sys_rstn),
        .wvalid (rx_fifo_wr_valid),
        .wready (rx_fifo_wr_ready),
        .wdata  (rx_fifo_wr_data),
        .wlast  (rx_fifo_wr_last),
        .rclk   (sys_clk),
        .rrstn  (sys_rstn),
        .rvalid (rx_fifo_rd_valid),
        .rready (rx_axis_tready),
        .rdata  (rx_fifo_rd_data),
        .rlast  (rx_fifo_rd_last)
    );

    // Map RX FIFO outputs to RX AXI-Stream interface
    assign rx_axis_tdata  = rx_fifo_rd_data;
    assign rx_axis_tvalid = rx_fifo_rd_valid;
    assign rx_axis_tlast  = rx_fifo_rd_last;
endmodule

`default_nettype wire
