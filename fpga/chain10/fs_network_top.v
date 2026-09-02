`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/26 16:14:07
// Design Name: 
// Module Name: fs_network_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// Basys 3 顶层：把网络核接到板子上，用 10 颗 LED 看火在传
module fs_network_top #(
    parameter integer N = 10
)(
    input  wire clk,          // Basys3 100 MHz (引脚 W5)
    input  wire btnC,         // 中间按钮当复位
    output wire [15:0] led    // 16 颗 LED，我们用低 N 颗
);
    // ---- 慢 tick：约每 30 ms 推进一个 dt，让肉眼跟得上 ----
    localparam integer DIV = 3_000_000;   // 100MHz * 30ms
    reg [21:0] div_cnt = 0;
    reg tick = 0;
    always @(posedge clk) begin
        if (div_cnt == DIV-1) begin
            div_cnt <= 0;
            tick    <= 1'b1;      // 1 拍脉冲
        end else begin
            div_cnt <= div_cnt + 1;
            tick    <= 1'b0;
        end
    end

    wire [N-1:0] spk;
    fs_network_core #(.N(N), .W_FP(40960)) core(
        .clk(clk), .rst(btnC), .tick(tick), .spk(spk));

    // 低 N 颗 LED = 每个神经元本拍是否发火；其余熄灭
    assign led = {16{1'b0}};
endmodule
