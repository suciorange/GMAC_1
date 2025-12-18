`default_nettype none

// Simple CSR placeholder providing default configuration values.
module csr_regs (
    input  wire        sys_clk,
    input  wire        sys_rstn,
    output reg         cfg_tx_en,
    output reg         cfg_rx_en,
    output reg  [1:0]  cfg_speed,
    output reg         cfg_full_duplex,
    output reg  [47:0] cfg_mac_addr
);

    always @(posedge sys_clk or negedge sys_rstn) begin
        if (!sys_rstn) begin
            cfg_tx_en       <= 1'b1;
            cfg_rx_en       <= 1'b1;
            cfg_speed       <= 2'b10;
            cfg_full_duplex <= 1'b1;
            cfg_mac_addr    <= 48'h001122334455;
        end else begin
            cfg_tx_en       <= cfg_tx_en;
            cfg_rx_en       <= cfg_rx_en;
            cfg_speed       <= cfg_speed;
            cfg_full_duplex <= cfg_full_duplex;
            cfg_mac_addr    <= cfg_mac_addr;
        end
    end

endmodule

`default_nettype wire
