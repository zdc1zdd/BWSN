`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/03 16:24:19
// Design Name: 
// Module Name: blinky
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


module blinky #(parameter WIDTH = 25) (
    input clk,
    output led
    );
    
    reg [WIDTH-1:0] count = 0;
 
    assign led = count[WIDTH-1];
 
    always @ (posedge(clk)) count <= count + 1;

endmodule
