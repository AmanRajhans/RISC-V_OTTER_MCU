`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Aman Rajhans
// 
// Create Date: 01/25/2026 06:14:21 PM
// Design Name: 
// Module Name: OTTER_MCU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Top module for RISC-V OTTER MCU, every block is instantiated except the CSR module. Connects to the 
// wrapper module.
// Instantiation Template:
// OTTER_MCU my_otter(
//    .RST         (x),
//    .intr        (x),
//    .clk         (x),
//    .iobus_in    (x),
//    .iobus_out   (x), 
//    .iobus_addr  (x), 
//    .iobus_wr    (x)   );
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module OTTER_MCU(
    input RST,
    input intr,
    input clk,
    input [31:0]iobus_in,
    output [31:0]iobus_out,
    output [31:0]iobus_addr,
    output iobus_wr
);
    logic PC_WE;
    logic [2:0] PC_SEL;
    logic [31:0] ir, PC, PC_next;
    logic [31:0] I_type, S_type, B_type, U_type, J_type;
    logic [31:0] jal, branch, jalr;
    logic rst;
    logic memRDEN1, memRDEN2, memWE2;
    
    logic [31:0] PC_ir;
    logic [31:0] PC_plus4_ir;
    assign PC_plus4_ir = PC_ir + 32'd4;
    
    reg_nb #(.n(32)) PC_IR_REG (
        .data_in  (PC),
        .ld       (memRDEN1),   // latch PC during fetch
        .clk      (clk),
        .clr      (rst),
        .data_out (PC_ir)
    );
    
    reg_nb #(.n(32)) PC_REG (
        .data_in  (PC_next),
        .ld       (PC_WE),
        .clk      (clk),
        .clr      (rst),
        .data_out (PC)
    );
    
    logic [31:0]rs1, rs2, DOUT2;
    logic [31:0] result; //ALU result
    Memory OTTER_MEMORY (
        .MEM_CLK (clk),
        .MEM_RDEN1 (memRDEN1),
        .MEM_RDEN2 (memRDEN2),
        .MEM_WE2 (memWE2),
        .MEM_ADDR1 (PC[15:2]),
        .MEM_ADDR2 (result),
        .MEM_DIN2 (rs2),
        .MEM_SIZE (ir[13:12]),
        .MEM_SIGN (ir[14]),
        .IO_IN (iobus_in),
        .IO_WR (iobus_wr),
        .MEM_DOUT1 (ir),
        .MEM_DOUT2 (DOUT2)
        );

    IMMED_GEN IG (  //instantiate IG mod
        .ir (ir[31:7]),
        .J_type_imm (J_type),
        .B_type_imm (B_type),
        .U_type_imm (U_type),
        .I_type_imm (I_type),
        .S_type_imm (S_type)
    );
    
    BRANCH_ADDR_GEN BAG (  //instantiate BAG mod
        .J_type  (J_type),
        .B_type  (B_type),
        .I_type  (I_type),
        .rs      (rs1),
        .PC      (PC_ir),   //use old PC
        .jal     (jal),
        .branch  (branch),
        .jalr    (jalr)    
    );
    logic [31:0] mtvec, mepc;
    mux_8t1_nb #(.n(32)) PC_MUX ( //PC mux
        .SEL   (PC_SEL),
        .D0    (PC_plus4_ir),
        .D1    (jalr),
        .D2    (branch),
        .D3    (jal),
        .D4    (mtvec),
        .D5    (mepc),
        .D_OUT (PC_next)
    );
    
    logic [31:0]REG_mux;
    logic [1:0] RF_SEL;
    logic RF_WE;
    logic [31:0]csr_RD;
    mux_4t1_nb #(.n(32)) REG_MUX ( //reg file mux
        .SEL   (RF_SEL),
        .D0    (PC_plus4_ir),
        .D1    (csr_RD),
        .D2    (DOUT2),
        .D3    (result),
        .D_OUT (REG_mux)
    );
   
    RegFile my_regfile (
        .w_data (REG_mux),
        .clk    (clk), 
        .en     (RF_WE),
        .adr1   (ir[19:15]),
        .adr2   (ir[24:20]),
        .w_adr  (ir[11:7]),
        .rs1    (rs1), 
        .rs2    (rs2)  );
    
    
    logic [31:0]ALU_srcA;
    logic [1:0]srcA_SEL;
    mux_4t1_nb #(.n(32)) srcA ( //srcA mux for ALU
        .SEL   (srcA_SEL),
        .D0    (rs1),
        .D1    (U_type),
        .D2    (~rs1),
        .D_OUT (ALU_srcA)
    );
    logic [31:0]ALU_srcB;
    logic [2:0]srcB_SEL;
    mux_8t1_nb #(.n(32)) srcB ( //srcA mux for ALU
        .SEL   (srcB_SEL),
        .D0    (rs2),
        .D1    (I_type),
        .D2    (S_type),
        .D3    (PC_ir),   //use old PC
        .D4    (csr_RD),
        .D_OUT (ALU_srcB)
    );  
    logic [3:0] alu_fun;
    ALU my_alu(
      .OP_1(ALU_srcA),
      .OP_2(ALU_srcB),
      .ALU_FUN(alu_fun),
      .RESULT(result));
   
   logic csr_WE, int_taken, mret_exec, intr_valid;
   CU_FSM my_fsm(
        .intr     (intr),
        .clk      (clk),
        .RST      (RST),
        .opcode   (ir[6:0]),   // ir[6:0]
        .PC_WE    (PC_WE),
        .RF_WE    (RF_WE),
        .csr_WE   (csr_WE),
        .func3    (ir[14:12]),
        .intr_valid(intr_valid),
        .int_taken(int_taken),
        .mret_exec(mret_exec),
        .memWE2   (memWE2),
        .memRDEN1 (memRDEN1),
        .memRDEN2 (memRDEN2),
        .reset    (rst)   );
    logic br_eq, br_lt, br_ltu;
    BRANCH_COND_GEN myBCG(
       .rs1(rs1),
       .rs2(rs2),
       .br_eq(br_eq),
       .br_lt(br_lt),
       .br_ltu(br_ltu));
       
   CU_DCDR my_cu_dcdr(
       .br_eq     (br_eq), 
       .br_lt     (br_lt), 
       .br_ltu    (br_ltu),
       .opcode    (ir[6:0]),    
       .func7     (ir[30]),    
       .func3     (ir[14:12]),
       .int_taken (int_taken),   
       .ALU_FUN   (alu_fun),
       .PC_SEL    (PC_SEL),
       .srcA_SEL  (srcA_SEL),
       .srcB_SEL  (srcB_SEL), 
       .RF_SEL    (RF_SEL)   );
   
   logic csr_mie;
   CSR  my_csr (
    .CLK        (clk),
    .RST        (rst),
    .MRET_EXEC  (mret_exec),
    .INT_TAKEN  (int_taken),
    .ADDR       (ir[31:20]),
    .PC         (PC_ir),
    .WD         (result),
    .WR_EN      (csr_WE),
    .RD         (csr_RD),
    .CSR_MEPC   (mepc),
    .CSR_MTVEC  (mtvec),
    .CSR_MSTATUS_MIE (csr_mie)    );
   assign intr_valid = intr & csr_mie;
   assign iobus_addr = result; // result of ALU
   assign iobus_out = rs2;
   
endmodule
