`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/26 15:50:13
// Design Name: 
// Module Name: fs_network_core
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


// 时分复用 FS 网络核 -- v5：结构优化压短关键路径
//  · base=5V+140-U+I 在平方相并行预算(藏进乘法延迟阴影)
//  · fired 直接由 V 比出(与 VMIN 钳位并行)
// 数值与 simulate_chain_fp 完全一致
module fs_network_core #(
    parameter integer N = 10,
    parameter signed [31:0] W_FP = 40960
)(
    input wire clk, input wire rst, input wire tick,
    output reg [N-1:0] spk
);
    localparam signed [31:0] C140=143360, THR=30720, CRST=-66560,
                             DJMP=2048, VMIN=-92160, V0=-66560, U0=-13312, IEXT0=10240;

    reg signed [31:0] Vmem [0:N-1];
    reg signed [31:0] Umem [0:N-1];
    reg [N-1:0] spike_prev, spike_now;
    integer k;

    localparam S_IDLE=4'd0, S_LOAD=4'd1,
               S_H1A=4'd2, S_H1B=4'd3, S_H1C=4'd4,      // half#1: (sq&base), t1, vhalf
               S_H2A=4'd5, S_H2B=4'd6, S_H2C=4'd7,      // half#2
               S_H2E=4'd8,                               // 钳位/判阈/封顶
               S_UA=4'd9, S_UB=4'd10, S_COMMIT=4'd11;
    reg [3:0] state; reg [7:0] idx; reg cur_fired;

    reg signed [31:0] Vc, Uc, Ic;
    reg signed [47:0] sq;
    reg signed [31:0] basereg, t1, bv;

    // 平方(24x24)与 base 预算,同一相并行
    wire signed [23:0] Vmul    = Vc[23:0];
    wire signed [47:0] sq_now  = Vmul * Vmul;
    wire signed [31:0] base_now = 32'sd5*Vc + C140 - Uc + Ic;   // 不依赖 t1
    // (41*sq)>>20
    wire signed [53:0] p41     = 54'sd41 * sq;
    wire signed [31:0] t1_now  = p41 >>> 20;
    // vhalf = V + ((t1+base)>>1)  -- 只剩两路加 + 一路加
    wire signed [31:0] vadd_now = Vc + ((t1 + basereg) >>> 1);
    // 判阈与钳位并行(VMIN<THR 恒成立 → fired 直接看 V)
    wire fired_now            = (Vc >= THR);
    wire signed [31:0] vcap   = fired_now ? THR : ((Vc < VMIN) ? VMIN : Vc);
    // u 更新
    wire signed [31:0] bv_now = (32'sd205 * Vc) >>> 10;
    wire signed [31:0] du_now = (32'sd102 * (bv - Uc)) >>> 10;
    wire signed [31:0] unew   = Uc + du_now;

    function signed [31:0] current_of;
        input [7:0] i; reg signed [31:0] iext, isyn;
        begin
            iext = (i==0) ? IEXT0 : 32'sd0;
            isyn = ((i!=0) && spike_prev[i-1]) ? W_FP : 32'sd0;
            current_of = iext + isyn;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            for (k=0;k<N;k=k+1) begin Vmem[k]<=V0; Umem[k]<=U0; end
            spike_prev<={N{1'b0}}; spike_now<={N{1'b0}}; spk<={N{1'b0}};
            state<=S_IDLE; idx<=8'd0;
        end else case (state)
            S_IDLE: if (tick) begin idx<=8'd0; spike_now<={N{1'b0}}; state<=S_LOAD; end
            S_LOAD: begin Vc<=Vmem[idx]; Uc<=Umem[idx]; Ic<=current_of(idx); state<=S_H1A; end
            // half #1
            S_H1A: begin sq<=sq_now; basereg<=base_now; state<=S_H1B; end   // 并行
            S_H1B: begin t1<=t1_now;                    state<=S_H1C; end
            S_H1C: begin Vc<=vadd_now;                  state<=S_H2A; end
            // half #2
            S_H2A: begin sq<=sq_now; basereg<=base_now; state<=S_H2B; end
            S_H2B: begin t1<=t1_now;                    state<=S_H2C; end
            S_H2C: begin Vc<=vadd_now;                  state<=S_H2E; end
            S_H2E: begin Vc<=vcap; cur_fired<=fired_now; state<=S_UA; end
            // u 更新
            S_UA:  begin bv<=bv_now; state<=S_UB; end
            S_UB: begin
                if (cur_fired) begin Vmem[idx]<=CRST; Umem[idx]<=unew+DJMP; end
                else           begin Vmem[idx]<=Vc;   Umem[idx]<=unew;      end
                spike_now[idx]<=cur_fired;
                if (idx==N-1) state<=S_COMMIT;
                else begin idx<=idx+8'd1; state<=S_LOAD; end
            end
            S_COMMIT: begin spike_prev<=spike_now; spk<=spike_now; state<=S_IDLE; end
            default: state<=S_IDLE;
        endcase
    end
endmodule