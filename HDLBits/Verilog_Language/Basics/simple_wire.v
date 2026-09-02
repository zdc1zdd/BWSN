// ===== HDLBits: Wire =====
// 题目:造一个 1 输入 1 输出的 module,行为像一根导线
// 核心:assign 是"连续赋值",相当于一根永久的物理导线
// 注意:assign 有方向,out 被驱动,in 不能反过来驱动

module top_module( input in, output out );
    assign out = in;
endmodule