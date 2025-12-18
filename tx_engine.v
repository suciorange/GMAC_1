`default_nettype none

// Transmit engine implementing GMII framing with CRC/FCS generation.
module tx_engine (
    input  wire        gmii_tx_clk,
    input  wire        rstn,
    input  wire        cfg_tx_en,
    // FIFO interface
    input  wire        fifo_rd_valid,
    output wire        fifo_rd_ready,
    input  wire [7:0]  fifo_rd_data,
    input  wire        fifo_rd_last,
    // GMII outputs
    output reg  [7:0]  gmii_txd,
    output reg         gmii_tx_en,
    output wire        gmii_tx_er
);
    localparam [2:0]
        ST_IDLE     = 3'd0,
        ST_PREAMBLE = 3'd1,
        ST_SFD      = 3'd2,
        ST_DATA     = 3'd3,
        ST_PAD      = 3'd4,
        ST_FCS      = 3'd5,
        ST_IFG      = 3'd6;

    reg [2:0] state;
    reg [2:0] preamble_cnt;
    reg [6:0] data_len;
    reg [6:0] pad_remaining;
    reg [3:0] ifg_cnt;
    reg [1:0] fcs_idx;
    reg [31:0] fcs_shift;

    wire data_fire;
    assign data_fire     = fifo_rd_valid && fifo_rd_ready;
    assign fifo_rd_ready = (state == ST_DATA);
    assign gmii_tx_er    = 1'b0;

    reg        crc_init;
    reg        crc_data_valid;
    reg [7:0]  crc_data;
    wire [31:0] crc_state;
    wire [31:0] crc_fcs;

    crc32_ethernet_byte u_crc32 (
        .clk        (gmii_tx_clk),
        .rstn       (rstn),
        .init       (crc_init),
        .data_valid (crc_data_valid),
        .data       (crc_data),
        .crc_state  (crc_state),
        .fcs        (crc_fcs)
    );

    always @(posedge gmii_tx_clk or negedge rstn) begin
        if (!rstn) begin
            state          <= ST_IDLE;
            preamble_cnt   <= 3'd0;
            data_len       <= 7'd0;
            pad_remaining  <= 7'd0;
            ifg_cnt        <= 4'd0;
            gmii_txd       <= 8'h00;
            gmii_tx_en     <= 1'b0;
            fcs_idx        <= 2'd0;
            fcs_shift      <= 32'h0;
            crc_init       <= 1'b0;
            crc_data_valid <= 1'b0;
            crc_data       <= 8'h00;
        end else begin
            crc_init       <= 1'b0;
            crc_data_valid <= 1'b0;
            crc_data       <= 8'h00;

            case (state)
                ST_IDLE: begin
                    gmii_tx_en   <= 1'b0;
                    gmii_txd     <= 8'h00;
                    data_len     <= 7'd0;
                    pad_remaining<= 7'd0;
                    ifg_cnt      <= 4'd0;
                    preamble_cnt <= 3'd0;
                    fcs_idx      <= 2'd0;
                    if (cfg_tx_en && fifo_rd_valid) begin
                        crc_init <= 1'b1;
                        state    <= ST_PREAMBLE;
                    end
                end

                ST_PREAMBLE: begin
                    gmii_tx_en   <= 1'b1;
                    gmii_txd     <= 8'h55;
                    if (preamble_cnt == 3'd6) begin
                        preamble_cnt <= 3'd0;
                        state        <= ST_SFD;
                    end else begin
                        preamble_cnt <= preamble_cnt + 3'd1;
                    end
                end

                ST_SFD: begin
                    gmii_tx_en <= 1'b1;
                    gmii_txd   <= 8'hD5;
                    data_len   <= 7'd0;
                    state      <= ST_DATA;
                end

                ST_DATA: begin
                    if (data_fire) begin
                        gmii_tx_en     <= 1'b1;
                        gmii_txd       <= fifo_rd_data;
                        crc_data_valid <= 1'b1;
                        crc_data       <= fifo_rd_data;
                        data_len       <= data_len + 7'd1;
                        if (fifo_rd_last) begin
                            if (data_len + 7'd1 >= 7'd60) begin
                                fcs_idx <= 2'd0;
                                state   <= ST_FCS;
                            end else begin
                                pad_remaining <= 7'd60 - (data_len + 7'd1);
                                state         <= ST_PAD;
                            end
                        end
                    end else begin
                        gmii_tx_en <= 1'b0;
                        gmii_txd   <= 8'h00;
                    end
                end

                ST_PAD: begin
                    gmii_tx_en     <= 1'b1;
                    gmii_txd       <= 8'h00;
                    crc_data_valid <= 1'b1;
                    crc_data       <= 8'h00;
                    data_len       <= data_len + 7'd1;
                    if (pad_remaining <= 7'd1) begin
                        pad_remaining <= 7'd0;
                        fcs_idx       <= 2'd0;
                        state         <= ST_FCS;
                    end else begin
                        pad_remaining <= pad_remaining - 7'd1;
                    end
                end

                ST_FCS: begin
                    gmii_tx_en <= 1'b1;
                    gmii_txd   <= (fcs_idx == 2'd0) ? crc_fcs[7:0] : fcs_shift[7:0];
                    fcs_shift  <= {8'h00, (fcs_idx == 2'd0) ? crc_fcs[31:8] : fcs_shift[31:8]};
                    if (fcs_idx == 2'd3) begin
                        fcs_idx <= 2'd0;
                        ifg_cnt <= 4'd0;
                        state   <= ST_IFG;
                    end else begin
                        fcs_idx <= fcs_idx + 2'd1;
                    end
                end

                ST_IFG: begin
                    gmii_tx_en <= 1'b0;
                    gmii_txd   <= 8'h00;
                    if (ifg_cnt == 4'd11) begin
                        ifg_cnt <= 4'd0;
                        state   <= ST_IDLE;
                    end else begin
                        ifg_cnt <= ifg_cnt + 4'd1;
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
