`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Nick Pearson
// 
// Create Date: 02/04/2026 05:24:15 PM
// Design Name: 
// Module Name: IMMED_GEN
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Adjusts the immediate value according to the instruction type, outputs will be sent to IG module.
// Instantiation Template:
// IMMED_GEN IG (
//        .ir (xx),
//        .J_type_imm (xx),
//        .B_type_imm (xx),
//        .U_type_imm (xx),
//        .I_type_imm (xx),
//        .S_type_imm (xx)
//    );
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IMMED_GEN(
        input logic [31:7]ir,
        output logic [31:0]U_type_imm, I_type_imm, S_type_imm, J_type_imm, B_type_imm
    );
    always_comb begin
       // I-type immediate (addi, lw, etc.)
        I_type_imm = {{20{ir[31]}}, ir[31:20]};

        // S-type immediate (sw)
        S_type_imm = {{20{ir[31]}}, ir[31:25], ir[11:7]};

        // B-type immediate (branches)
        B_type_imm = {{19{ir[31]}},ir[31], ir[7],
                      ir[30:25], ir[11:8], 1'b0};

        // U-type immediate (lui, auipc)
        U_type_imm = {ir[31:12], 12'd0};

        // J-type immediate (jal)
        J_type_imm = {{11{ir[31]}}, ir[31], ir[19:12], ir[20],
                      ir[30:21], 1'b0};
    end
endmodule
