// ============================================
// HDLBits: wire decl （声明并使用内部导线）
// ============================================
//
// 【题目说明】
//   4 输入 a b c d，2 输出 out / out_n。
//   电路：a&b 和 c&d 各进一个 AND 门，两个结果 OR 得到 out；
//        out 取反得到 out_n。
//
//     a ─┐AND─┐
//     b ─┘    ├─OR─┬─ out
//     c ─┐AND─┘    └─○─ out_n
//     d ─┘
//
// 【核心概念】
//   wire = 电路【内部】的中转导线（区别于对外的 input/output 引脚）。
//   AND 门的输出要先落在某根 wire 上，才能再送进 OR 门。
//   多条 assign 之间【没有先后顺序】：它们是同时成立的物理连接，
//   写的顺序可任意打乱，电路不变。这是硬件思维，不是程序执行。
//
//   语法糖：声明 wire 时可同时赋值：
//       wire w = a & b;   等价于   wire w;  assign w = a & b;
//
//   顶部的 `default_nettype none （HDLBits 自动加）会让【任何未声明
//   的信号直接报错】，防止把打字错误(如 wier)当成隐式 wire，是一层保护。
//
// 【易错点】
//   1. 中间信号必须先声明成 wire，再使用（本题训练目的就在此）。
//   2. 别漏掉第二个输出 out_n = ~out。
//   3. wire 名字自定，但前后必须一致（声明用 w，使用也得用 w）。
//   4. 别被"顺序"误导：assign out=... 写在 assign w=... 前面也完全合法。
// ============================================

`default_nettype none          // 未声明的信号一律报错（保护，防手滑打错名）

module top_module(
    input a,
    input b,
    input c,
    input d,
    output out,
    output out_n   );

    // 声明内部导线，并同时赋值（声明+assign 二合一的语法糖）
    wire aANDb = a & b;        // 第一个 AND 门的输出
    wire cANDd = c & d;        // 第二个 AND 门的输出
    wire or_wire = aANDb | cANDd;   // 两个 AND 结果送进 OR 门

    assign out   = or_wire;    // OR 的结果就是 out
    assign out_n = ~or_wire;   // out 取反得到 out_n

endmodule
