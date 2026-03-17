`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2026 03:09:20 PM
// Design Name: 
// Module Name: ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// Instantiation template:
// ALU my_alu(
//      .OP_1(x),
//      .OP_2(x),
//      .ALU_FUN(x),
//      .RESULT(x));
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ALU(
    input logic [31:0] OP_1,
    input logic [31:0] OP_2,
    input logic [3:0] ALU_FUN,
    output logic [31:0] RESULT
    );
    
    logic [4:0] shamt;
    assign shamt = OP_2[4:0]; // limits the shifts to the lower 5 bits
    
    always_comb begin
        RESULT = 32'hDEAD_BEEF;
        unique case (ALU_FUN)
            4'b0000: RESULT = OP_1 + OP_2;   // add
            4'b1000: RESULT = OP_1 - OP_2;   // sub
            4'b0110: RESULT = OP_1 | OP_2;   // or
            4'b0111: RESULT = OP_1 & OP_2;   // and
            4'b0100: RESULT = OP_1 ^ OP_2;  // xor
            4'b0101: RESULT = OP_1 >> shamt; // srl
            4'b0001: RESULT = OP_1 << shamt; // sll (LOGICAL)
            4'b1101: RESULT = $signed(OP_1) >>> shamt;  // sra (ARITHMETIC)
            4'b0010: RESULT = ($signed(OP_1) < $signed(OP_2)) ? 32'd1 : 32'd0; // slt (SIGNED)
            4'b0011: RESULT = (OP_1 < OP_2) ? 32'd1: 32'd0; // sltu (UNSIGNED)
            4'b1001: RESULT = OP_1; // lui
            
            default: RESULT = 32'hDEAD_BEEF;
        endcase
    end

endmodule
