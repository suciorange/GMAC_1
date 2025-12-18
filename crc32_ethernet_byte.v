`default_nettype none

// Ethernet CRC32 calculator with byte-wide reflected input/output.
module crc32_ethernet_byte (
    input  wire        clk,
    input  wire        rstn,
    input  wire        init,
    input  wire        data_valid,
    input  wire [7:0]  data,
    output reg  [31:0] crc_state,
    output wire [31:0] fcs
);
    // Reflected polynomial 0xEDB88320
    wire [31:0] crc_next;
    assign crc_next[0]  = crc_state[24] ^ crc_state[30] ^ data[0] ^ data[6];
    assign crc_next[1]  = crc_state[24] ^ crc_state[25] ^ crc_state[30] ^ crc_state[31] ^ data[0] ^ data[1] ^ data[6] ^ data[7];
    assign crc_next[2]  = crc_state[24] ^ crc_state[25] ^ crc_state[26] ^ crc_state[30] ^ crc_state[31] ^ data[0] ^ data[1] ^ data[2] ^ data[6] ^ data[7];
    assign crc_next[3]  = crc_state[25] ^ crc_state[26] ^ crc_state[27] ^ crc_state[31] ^ data[1] ^ data[2] ^ data[3] ^ data[7];
    assign crc_next[4]  = crc_state[24] ^ crc_state[26] ^ crc_state[27] ^ crc_state[28] ^ crc_state[30] ^ data[0] ^ data[2] ^ data[3] ^ data[4] ^ data[6];
    assign crc_next[5]  = crc_state[24] ^ crc_state[25] ^ crc_state[27] ^ crc_state[28] ^ crc_state[29] ^ crc_state[30] ^ crc_state[31] ^ data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
    assign crc_next[6]  = crc_state[25] ^ crc_state[26] ^ crc_state[28] ^ crc_state[29] ^ crc_state[30] ^ crc_state[31] ^ data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6] ^ data[7];
    assign crc_next[7]  = crc_state[26] ^ crc_state[27] ^ crc_state[29] ^ crc_state[30] ^ crc_state[31] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[7];
    assign crc_next[8]  = crc_state[0] ^ crc_state[24] ^ crc_state[27] ^ crc_state[28] ^ crc_state[30] ^ data[0] ^ data[3] ^ data[4] ^ data[6];
    assign crc_next[9]  = crc_state[1] ^ crc_state[25] ^ crc_state[28] ^ crc_state[29] ^ crc_state[31] ^ data[1] ^ data[4] ^ data[5] ^ data[7];
    assign crc_next[10] = crc_state[2] ^ crc_state[24] ^ crc_state[26] ^ crc_state[29] ^ crc_state[30] ^ data[0] ^ data[2] ^ data[5] ^ data[6];
    assign crc_next[11] = crc_state[3] ^ crc_state[25] ^ crc_state[27] ^ crc_state[30] ^ crc_state[31] ^ data[1] ^ data[3] ^ data[6] ^ data[7];
    assign crc_next[12] = crc_state[4] ^ crc_state[26] ^ crc_state[28] ^ crc_state[31] ^ data[2] ^ data[4] ^ data[7];
    assign crc_next[13] = crc_state[5] ^ crc_state[27] ^ crc_state[29] ^ data[3] ^ data[5];
    assign crc_next[14] = crc_state[6] ^ crc_state[28] ^ crc_state[30] ^ data[4] ^ data[6];
    assign crc_next[15] = crc_state[7] ^ crc_state[24] ^ crc_state[29] ^ crc_state[31] ^ data[0] ^ data[5] ^ data[7];
    assign crc_next[16] = crc_state[8] ^ crc_state[24] ^ crc_state[25] ^ crc_state[30] ^ data[0] ^ data[1] ^ data[6];
    assign crc_next[17] = crc_state[9] ^ crc_state[25] ^ crc_state[26] ^ crc_state[31] ^ data[1] ^ data[2] ^ data[7];
    assign crc_next[18] = crc_state[10] ^ crc_state[24] ^ crc_state[26] ^ crc_state[27] ^ crc_state[30] ^ data[0] ^ data[2] ^ data[3] ^ data[6];
    assign crc_next[19] = crc_state[11] ^ crc_state[25] ^ crc_state[27] ^ crc_state[28] ^ crc_state[31] ^ data[1] ^ data[3] ^ data[4] ^ data[7];
    assign crc_next[20] = crc_state[12] ^ crc_state[26] ^ crc_state[28] ^ crc_state[29] ^ data[2] ^ data[4] ^ data[5];
    assign crc_next[21] = crc_state[13] ^ crc_state[27] ^ crc_state[29] ^ crc_state[30] ^ data[3] ^ data[5] ^ data[6];
    assign crc_next[22] = crc_state[14] ^ crc_state[28] ^ crc_state[30] ^ crc_state[31] ^ data[4] ^ data[6] ^ data[7];
    assign crc_next[23] = crc_state[15] ^ crc_state[29] ^ crc_state[31] ^ data[5] ^ data[7];
    assign crc_next[24] = crc_state[16] ^ crc_state[24] ^ crc_state[30] ^ data[0] ^ data[6];
    assign crc_next[25] = crc_state[17] ^ crc_state[25] ^ crc_state[31] ^ data[1] ^ data[7];
    assign crc_next[26] = crc_state[18] ^ crc_state[24] ^ crc_state[26] ^ data[0] ^ data[2];
    assign crc_next[27] = crc_state[19] ^ crc_state[25] ^ crc_state[27] ^ data[1] ^ data[3];
    assign crc_next[28] = crc_state[20] ^ crc_state[26] ^ crc_state[28] ^ data[2] ^ data[4];
    assign crc_next[29] = crc_state[21] ^ crc_state[27] ^ crc_state[29] ^ data[3] ^ data[5];
    assign crc_next[30] = crc_state[22] ^ crc_state[24] ^ crc_state[28] ^ crc_state[30] ^ data[0] ^ data[4] ^ data[6];
    assign crc_next[31] = crc_state[23] ^ crc_state[25] ^ crc_state[29] ^ crc_state[31] ^ data[1] ^ data[5] ^ data[7];

    assign fcs = ~crc_state;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            crc_state <= 32'hFFFF_FFFF;
        end else if (init) begin
            crc_state <= 32'hFFFF_FFFF;
        end else if (data_valid) begin
            crc_state <= crc_next;
        end
    end
endmodule

`default_nettype wire
