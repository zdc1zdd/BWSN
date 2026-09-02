`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/24 13:55:37
// Design Name: 
// Module Name: top_fs
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


module top_fs #(
    parameter integer STEP_DIV     = 5000000,   // 每秒 20 个 bio-step
    parameter integer FLASH_CYCLES = 10000000   // 发火闪 0.1 秒
)(
    input  wire clk,
    input  wire btnC,             // 中间按钮 = 复位
    output wire [15:0] led
);
    wire spike;
    wire signed [23:0] v_out;

    fs_neuron #(.STEP_DIV(STEP_DIV)) u_neuron (
        .clk(clk), .rst(btnC), .spike(spike), .v_out(v_out)
    );

    // 把 1 拍宽的 spike 拉长成肉眼可见的一闪
    reg [24:0] flash;
    always @(posedge clk) begin
        if (btnC)          flash <= 0;
        else if (spike)    flash <= FLASH_CYCLES;
        else if (flash!=0) flash <= flash - 1;
    end
    assign led[0]    = (flash != 0);
    // 加在 top_fs 里，替换掉 assign led[15:1]=15'b0;
    wire signed [23:0] vmv = v_out >>> 10;            // 约等于 mV
    wire signed [23:0] lvl = (vmv + 70) * 39 >>> 8;   // 约 0..15 的近似映射
    genvar i;
    generate for (i=1;i<16;i=i+1) begin: bar
        assign led[i] = (lvl > i);                   // 温度计式：越高亮越多
    end endgenerate
    
endmodule
