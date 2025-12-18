`timescale 1ns/1ps
`default_nettype none

module tb_mac_top;
    // Clocks and reset
    logic sys_clk = 1'b0;
    logic sys_rstn = 1'b0;
    logic gmii_tx_clk_tb = 1'b0;
    logic gmii_rx_clk = 1'b0;

    // Plusarg-controlled speed
    string speed_str = "1G";
    real   tx_half_period_ns = 4.0; // default 1G => 8ns period

    // DUT <-> host stream interfaces
    logic [7:0] tx_axis_tdata;
    logic       tx_axis_tvalid;
    logic       tx_axis_tlast;
    logic       tx_axis_tready;

    logic [7:0] rx_axis_tdata;
    logic       rx_axis_tvalid;
    logic       rx_axis_tlast;
    logic       rx_axis_tready;

    // GMII signals
    wire  gmii_tx_clk;
    wire [7:0] gmii_txd;
    wire gmii_tx_en;
    wire gmii_tx_er;
    logic [7:0] gmii_rxd;
    logic       gmii_rx_dv;
    logic       gmii_rx_er;

    // Dump control
    bit enable_dump;

    // Clock generation
    always #5 sys_clk = ~sys_clk; // 100 MHz system clock

    initial begin
        if ($value$plusargs("SPEED=%s", speed_str)) begin
            $display("[TB] SPEED plusarg set to %s", speed_str);
        end else begin
            $display("[TB] SPEED plusarg not found, default to 1G");
        end

        case (speed_str)
            "1G":   tx_half_period_ns = 4.0;   // 125 MHz
            "100M": tx_half_period_ns = 20.0;  // 25 MHz
            "10M":  tx_half_period_ns = 200.0; // 2.5 MHz
            default: tx_half_period_ns = 4.0;
        endcase

        forever begin
            #(tx_half_period_ns) gmii_tx_clk_tb = ~gmii_tx_clk_tb;
            gmii_rx_clk = gmii_tx_clk_tb;
        end
    end

    // Reset deassert after 200ns
    initial begin
        sys_rstn = 1'b0;
        #(200);
        sys_rstn = 1'b1;
        $display("[TB] Deasserted reset at %0t", $time);
    end

    // GMII RX idle inputs
    always_comb begin
        gmii_rxd   = 8'h00;
        gmii_rx_dv = 1'b0;
        gmii_rx_er = 1'b0;
    end

    // Instantiate DUT
    mac_top dut (
        .sys_clk       (sys_clk),
        .sys_rstn      (sys_rstn),
        .tx_axis_tdata (tx_axis_tdata),
        .tx_axis_tvalid(tx_axis_tvalid),
        .tx_axis_tlast (tx_axis_tlast),
        .tx_axis_tready(tx_axis_tready),
        .rx_axis_tdata (rx_axis_tdata),
        .rx_axis_tvalid(rx_axis_tvalid),
        .rx_axis_tlast (rx_axis_tlast),
        .rx_axis_tready(rx_axis_tready),
        .gmii_tx_clk   (gmii_tx_clk),
        .gmii_txd      (gmii_txd),
        .gmii_tx_en    (gmii_tx_en),
        .gmii_tx_er    (gmii_tx_er),
        .gmii_rx_clk   (gmii_rx_clk),
        .gmii_rxd      (gmii_rxd),
        .gmii_rx_dv    (gmii_rx_dv),
        .gmii_rx_er    (gmii_rx_er)
    );

    // Stimulus and checks
    initial begin
        rx_axis_tready = 1'b0;
        tx_axis_tdata  = '0;
        tx_axis_tvalid = 1'b0;
        tx_axis_tlast  = 1'b0;
        enable_dump    = 0;

        if ($value$plusargs("DUMP=%0d", enable_dump)) begin
            if (enable_dump) begin
                $display("[TB] Enabling FSDB dump");
                $fsdbDumpfile("sim/out/wave.fsdb");
                $fsdbDumpvars(0, tb_mac_top);
            end
        end

        wait (sys_rstn == 1'b1);
        @(posedge sys_clk);
        rx_axis_tready = 1'b1;

        byte payload[$];
        int payload_len = 46;
        for (int i = 0; i < payload_len; i++) begin
            payload.push_back(byte'(i[7:0]));
        end

        $display("[TB] Sending frame with %0d-byte payload at %s", payload.size(), speed_str);
        send_frame(payload);
        $display("[TB] Frame send complete at %0t", $time);

        wait_for_tx_and_check();

        #1000;
        $display("[TB] Simulation complete at %0t", $time);
        $finish;
    end

    // Task to send a frame over AXI-stream
    task automatic send_frame(input byte payload[]);
        int unsigned idx;
        idx = 0;
        while (idx < payload.size()) begin
            @(posedge sys_clk);
            if (sys_rstn) begin
                if (tx_axis_tready) begin
                    tx_axis_tdata  <= payload[idx];
                    tx_axis_tvalid <= 1'b1;
                    tx_axis_tlast  <= (idx == payload.size() - 1);
                    idx++;
                end else begin
                    tx_axis_tvalid <= tx_axis_tvalid;
                    tx_axis_tlast  <= tx_axis_tlast;
                end
            end
        end
        @(posedge sys_clk);
        tx_axis_tvalid <= 1'b0;
        tx_axis_tlast  <= 1'b0;
    endtask

    // Monitor GMII TX for preamble/SFD and length
    task automatic wait_for_tx_and_check;
        byte header_bytes[8];
        int data_count;

        @(posedge gmii_tx_clk);
        wait (gmii_tx_en == 1'b1);
        $display("[TB] Detected gmii_tx_en high at %0t", $time);

        for (int i = 0; i < 8; i++) begin
            @(posedge gmii_tx_clk);
            if (!gmii_tx_en) begin
                $fatal(1, "gmii_tx_en deasserted before preamble/SFD done");
            end
            header_bytes[i] = gmii_txd;
        end

        for (int i = 0; i < 7; i++) begin
            if (header_bytes[i] !== 8'h55) begin
                $fatal(1, "Preamble byte %0d mismatch: got %02x", i, header_bytes[i]);
            end
        end
        if (header_bytes[7] !== 8'hD5) begin
            $fatal(1, "SFD mismatch: got %02x", header_bytes[7]);
        end
        $display("[TB] Preamble/SFD check passed");

        data_count = 0;
        while (gmii_tx_en) begin
            @(posedge gmii_tx_clk);
            if (!gmii_tx_en) begin
                break;
            end
            data_count++;
        end

        $display("[TB] Observed %0d data/FCS bytes after SFD", data_count);
        if (data_count < 64) begin
            $fatal(1, "Data+FCS length too short: %0d", data_count);
        end
    endtask
endmodule

`default_nettype wire
