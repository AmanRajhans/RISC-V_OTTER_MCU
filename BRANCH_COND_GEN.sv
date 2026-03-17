`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/22/2026 07:42:01 PM
// Design Name: 
// Module Name: BRANCH_COND_GEN
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Acts as a comparator, comparing rs1, and rs2 and outputs for eq, lt, and ltu to tell the decoder
// if a branch should be taken.
// 
// Instantiation Template:
// BRANCH_COND_GEN myBCG(
//     .rs1(x),
//     .rs2(x),
//     .br_eq(x),
//     .br_lt(x),
//     .br_ltu(x));
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BRANCH_COND_GEN(
        input [31:0] rs1, rs2,
        output br_eq, br_lt, br_ltu
    );
    assign br_ltu = rs1 < rs2;
    assign br_lt = $signed(rs1) < $signed(rs2);
    assign br_eq = (rs1 == rs2);
endmodule
