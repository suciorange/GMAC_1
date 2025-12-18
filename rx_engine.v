`default_nettype none

// Receive engine implementing GMII frame detection, CRC verification, and FIFO writeout.
module rx_engine (
    input  wire        gmii_rx_clk,
    input  wire        rstn,
    input  wire [7:0]  gmii_rxd,
    input  wire        gmii_rx_dv,
    input  wire        gmii_rx_er,
    input  wire        cfg_rx_en,
    input  wire [1:0]  cfg_speed,
    input  wire        cfg_full_duplex,
    input  wire [47:0] cfg_mac_addr,
    output reg         fifo_wr_valid,
    input  wire        fifo_wr_ready,
    output reg  [7:0]  fifo_wr_data,
    output reg         fifo_wr_last,
    output reg         rx_good,
    output reg         rx_bad_crc,
    output reg         rx_phy_err,
    output reg         rx_overflow
);
    localparam [1:0]
        ST_IDLE     = 2'd0,
        ST_PREAMBLE = 2'd1,
        ST_DATA     = 2'd2;

    reg [1:0] state;
    reg [7:0] prev_data;
    reg       prev_valid;
    reg       gmii_rx_dv_d;

    wire dv_fall;
    assign dv_fall = gmii_rx_dv_d && !gmii_rx_dv;

    reg        crc_init;
    reg        crc_data_valid;
    reg [7:0]  crc_data;
    wire [31:0] crc_state;
    wire [31:0] crc_fcs;

    crc32_ethernet_byte u_crc32 (
        .clk        (gmii_rx_clk),
        .rstn       (rstn),
        .init       (crc_init),
        .data_valid (crc_data_valid),
        .data       (crc_data),
        .crc_state  (crc_state),
        .fcs        (crc_fcs)
    );

    always @(posedge gmii_rx_clk or negedge rstn) begin
        if (!rstn) begin
            state         <= ST_IDLE;
            prev_data     <= 8'h00;
            prev_valid    <= 1'b0;
            gmii_rx_dv_d  <= 1'b0;
            fifo_wr_valid <= 1'b0;
            fifo_wr_data  <= 8'h00;
            fifo_wr_last  <= 1'b0;
            rx_good       <= 1'b0;
            rx_bad_crc    <= 1'b0;
            rx_phy_err    <= 1'b0;
            rx_overflow   <= 1'b0;
            crc_init      <= 1'b0;
            crc_data_valid<= 1'b0;
            crc_data      <= 8'h00;
        end else begin
            gmii_rx_dv_d   <= gmii_rx_dv;
            fifo_wr_valid  <= 1'b0;
            fifo_wr_last   <= 1'b0;
            crc_init       <= 1'b0;
            crc_data_valid <= 1'b0;
            crc_data       <= 8'h00;
            rx_good        <= 1'b0;
            rx_bad_crc     <= 1'b0;

            if (gmii_rx_er) begin
                rx_phy_err <= 1'b1;
            end

            case (state)
                ST_IDLE: begin
                    prev_valid  <= 1'b0;
                    rx_overflow <= 1'b0;
                    if (cfg_rx_en && gmii_rx_dv) begin
                        state      <= ST_PREAMBLE;
                        rx_phy_err <= 1'b0;
                    end
                end

                ST_PREAMBLE: begin
                    if (!gmii_rx_dv) begin
                        state <= ST_IDLE;
                    end else if (gmii_rxd == 8'hD5) begin
                        crc_init <= 1'b1;
                        state    <= ST_DATA;
                    end else if (gmii_rxd != 8'h55) begin
                        state <= ST_IDLE;
                    end
                end

                ST_DATA: begin
                    if (!rx_overflow && prev_valid) begin
                        if (fifo_wr_ready) begin
                            fifo_wr_valid <= 1'b1;
                            fifo_wr_data  <= prev_data;
                            fifo_wr_last  <= dv_fall;
                            if (dv_fall) begin
                                prev_valid <= 1'b0;
                            end
                        end else begin
                            rx_overflow <= 1'b1;
                        end
                    end

                    if (gmii_rx_dv) begin
                        crc_data_valid <= 1'b1;
                        crc_data       <= gmii_rxd;
                        if (!rx_overflow) begin
                            prev_data  <= gmii_rxd;
                            prev_valid <= 1'b1;
                        end
                    end

                    if (dv_fall) begin
                        if (!rx_overflow && !gmii_rx_er && crc_state == 32'hDEBB20E3) begin
                            rx_good <= 1'b1;
                        end else begin
                            rx_bad_crc <= 1'b1;
                        end
                        state <= ST_IDLE;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end
endmodule

`default_nettype wire
