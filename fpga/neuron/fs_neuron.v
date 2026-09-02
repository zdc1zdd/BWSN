`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/25 15:34:41
// Design Name: 
// Module Name: fs_neuron
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


module fs_neuron #(
    parameter integer STEP_DIV = 5000000
)(
    input  wire clk,
    input  wire rst,
    output reg  spike,                 // 发火时脉冲一拍
    output wire signed [23:0] v_out
);
    // ---- 定点常数 (F=10)，全部 signed ----
    localparam signed [23:0] C004=41,  C5=5,     C140=143360, C_I=10240;
    localparam signed [23:0] C02=205,  C01=102,  C_c=-66560,  C_d=2048;
    localparam signed [23:0] THR=30720,VMIN=-92160, V0=-66560, U0=-13312;

    reg signed [23:0] V, U, inner;
    reg signed [47:0] sq;
    reg [2:0]  phase;
    reg running, fired;
    reg [31:0] divcnt;

    // ---- v 半步组合通路 ----
    wire signed [47:0] c004sq = C004 * sq;
    wire signed [47:0] t1     = c004sq >>> 20;
    wire signed [47:0] c5v    = C5 * V;
    wire signed [47:0] f      = t1 + c5v + C140 - U + C_I;
    wire signed [47:0] vn_raw = V + (f >>> 1);
    wire signed [23:0] vn = (vn_raw > THR)  ? THR  :
                            (vn_raw < VMIN) ? VMIN : vn_raw[23:0];

    // ---- u 更新组合通路 ----
    wire signed [47:0] c02v    = C02 * V;
    wire signed [23:0] inner_c = (c02v >>> 10) - U;
    wire signed [47:0] c01i    = C01 * inner;
    wire signed [47:0] u_upd   = U + (c01i >>> 10);

    always @(posedge clk) begin
        if (rst) begin
            V<=V0; U<=U0; phase<=0; running<=0; divcnt<=0;
            spike<=0; fired<=0; sq<=0; inner<=0;
        end else begin
            spike <= 0;                 // spike 默认0，只在发火那拍冒1
            if (!running) begin
                if (divcnt >= STEP_DIV-1) begin divcnt<=0; running<=1; phase<=0; end
                else divcnt <= divcnt + 1;
            end else case (phase)
                3'd0: begin sq <= V*V;  phase<=1; end            // 半步①平方
                3'd1: begin V  <= vn;   phase<=2; end            // 半步①累加+夹
                3'd2: begin sq <= V*V;  phase<=3; end            // 半步②平方
                3'd3: begin                                     // 半步②+判发火
                          if (vn >= THR) begin V<=THR; fired<=1; end
                          else           begin V<=vn;  fired<=0; end
                          phase<=4;
                      end
                3'd4: begin inner <= inner_c; phase<=5; end      // u 内层
                3'd5: begin                                     // u 更新 + 重置
                          if (fired) begin V<=C_c; U<=u_upd+C_d; spike<=1; end
                          else       begin        U<=u_upd;              end
                          running<=0; phase<=0;
                      end
                default: begin running<=0; phase<=0; end
            endcase
        end
    end
    assign v_out = V;
endmodule
