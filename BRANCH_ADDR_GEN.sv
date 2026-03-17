`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Nick Pearson
// 
// Create Date: 02/04/2026 05:24:56 PM
// Design Name: 
// Module Name: BRANCH_ADDR_GEN
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Attaches immediate value to instruction, which will be sent to pc mux
// Instantiation Template:
// BRANCH_ADDR_GEN BAG (
//        .J_type  (xx),
//        .B_type  (xx),
//        .I_type  (x),
//        .rs      (xx),
//        .PC      (xx),
//        .jal     (xx),
//        .branch  (xx),
//        .jalr    (xx)    
//    );
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BRANCH_ADDR_GEN(
    input logic [31:0] J_type,
    input logic [31:0] B_type,
    input logic [31:0] I_type,
    input logic [31:0] rs,
    input logic [31:0] PC,
    output logic [31:0] jal,
    output logic [31:0] branch,
    output logic [31:0] jalr
    );
    always_comb begin
    // Branch Immediate
    branch = PC + B_type;     //B-type imm sext
    // Jal immediate
    jal = PC + J_type;       //J-type imm sext
    // Jalr immediate
    jalr = (rs + I_type) & ~32'd1;  //PC ← (X[rs1] + sext(imm)) & ~1    
    end
endmodule
