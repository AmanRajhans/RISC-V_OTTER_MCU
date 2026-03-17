`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////
// Company: Ratner Surf Designs
// Engineer: James Ratner
// 
// Create Date: 01/29/2019 04:56:13 PM
// Design Name: 
// Module Name: CU_DCDR
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies:
// 
// Instantiation Template:
//
// CU_DCDR my_cu_dcdr(
//   .br_eq     (xxxx), 
//   .br_lt     (xxxx), 
//   .br_ltu    (xxxx),
//   .opcode    (xxxx),    
//   .func7     (xxxx),    
//   .func3     (xxxx),    
//   .ALU_FUN   (xxxx),
//   .PC_SEL    (xxxx),
//   .srcA_SEL  (xxxx),
//   .srcB_SEL  (xxxx), 
//   .RF_SEL    (xxxx)   );
//
// 
// Revision:
// Revision 1.00 - Created (02-01-2020) - from Paul, Joseph, & Celina
//          1.01 - (02-08-2020) - removed  else's; fixed assignments
//          1.02 - (02-25-2020) - made all assignments blocking
//          1.03 - (05-12-2020) - reduced func7 to one bit
//          1.04 - (05-31-2020) - removed misleading code
//          1.05 - (12-10-2020) - added comments
//          1.06 - (02-11-2021) - fixed formatting issues
//          1.07 - (12-26-2023) - changed signal names
//
// Additional Comments:
// 
///////////////////////////////////////////////////////////////////////////

module CU_DCDR(
   input br_eq, 
   input br_lt, 
   input br_ltu,
   input int_taken,
   input [6:0] opcode,   //  ir[6:0]
   input func7,          //  ir[30]
   input [2:0] func3,    //  ir[14:12] 
   output logic [3:0] ALU_FUN,
   output logic [2:0] PC_SEL,
   output logic [1:0]srcA_SEL,
   output logic [2:0] srcB_SEL, 
   output logic [1:0] RF_SEL   );
    
   //- datatypes for RISC-V opcode types
   typedef enum logic [6:0] {
        LUI    = 7'b0110111,
        AUIPC  = 7'b0010111,
        JAL    = 7'b1101111,
        JALR   = 7'b1100111,
        BRANCH = 7'b1100011,
        LOAD   = 7'b0000011,
        STORE  = 7'b0100011,
        OP_IMM = 7'b0010011,
        OP_RG3 = 7'b0110011,
        CSR    = 7'b1110011
   } opcode_t;
   opcode_t OPCODE; //- define variable of new opcode type
    
   assign OPCODE = opcode_t'(opcode); //- Cast input enum 

   //- datatype for func3Symbols tied to values
   typedef enum logic [2:0] {
        //BRANCH labels
        BEQ = 3'b000,
        BNE = 3'b001,
        BLT = 3'b100,
        BGE = 3'b101,
        BLTU = 3'b110,
        BGEU = 3'b111
   } func3_t;    
   func3_t FUNC3; // define variable of new opcode type
    
   assign FUNC3 = func3_t'(func3); //- Cast input enum
   
       
   always_comb
   begin 
      //- schedule all values to avoid latch
      PC_SEL = 3'b000;  srcB_SEL = 3'b000; RF_SEL = 2'b00; 
      srcA_SEL = 2'b00;   ALU_FUN  = 4'b0000;
      if(int_taken) begin
        PC_SEL = 3'b100; //select mtvec
      end
      else begin
      case(OPCODE)
         LUI:  //rd = U-imm
         begin
            ALU_FUN = 4'b1001; //ld
            srcA_SEL = 2'b01; //choose U-imm
            RF_SEL = 2'b11;   //ALU output
         end
	     AUIPC:  //rd = PC + U-imm
	     begin
	        ALU_FUN = 4'b0000;  //add
            srcA_SEL = 2'b01;   //choose U-imm
            srcB_SEL = 3'b011;   //choose PC
            RF_SEL = 2'b11;     //ALU output
	     end
         JAL:  //rd = PC + 4 and PC = PC + J-imm
         begin //no need for ALU_FUN, srcB, srcA b/c IG and BAG compute JAL
            PC_SEL = 3'b011;   //jal
            RF_SEL = 2'b00;   //PC+4
		 end
		 JALR: //rd = PC + 4 and PC = (rs1 + I-imm) & ~1
		 begin //same as JAL, but PC_SEL jalr
		    PC_SEL = 3'b001; //jalr
		    RF_SEL = 2'b00; //PC+4
		 end
		 BRANCH:  //PC_next = PC + B-imm if condition met, else PC_next = PC + 4
		 begin
		    case(FUNC3)
		      3'b000: PC_SEL = br_eq ? 3'b010 : 3'b000; //if br_eq == 1 -> PC_SEL = 10, else -> PC_SEL = 00 for beq
		      3'b001: PC_SEL = ~br_eq ? 3'b010 : 3'b000; //if br_eq == 0 -> PC_SEL = 10, else -> PC_SEL = 00 for bneq
		      3'b100: PC_SEL = br_lt ? 3'b010 : 3'b000; //if br_lt == 1 -> PC_SEL = 10, else -> PC_SEL = 00 for blt
		      3'b101: PC_SEL = ~br_lt ? 3'b010 : 3'b000; //if br_lt == 0 -> PC_SEL = 10, else -> PC_SEL = 00 for bgt
		      3'b110: PC_SEL = br_ltu ? 3'b010 : 3'b000; //if br_ltu == 1 -> PC_SEL = 10, else -> PC_SEL = 00 for bltu
		      3'b111: PC_SEL = ~br_ltu ? 3'b010 : 3'b000; //if br_lt == 0 -> PC_SEL = 10, else -> PC_SEL = 00 for bgtu
		      default: PC_SEL = 3'b000;
		    endcase
		    
		 end
         LOAD: //rd = Mem[rs1 + I-imm]
         begin
            ALU_FUN = 4'b0000; //add
            srcA_SEL = 2'b00; //choose rs1
            srcB_SEL = 3'b001; //choose I-imm
            RF_SEL = 2'b10;   //choose mem out
         end
			
         STORE:  //Mem[rs1 + S-imm] = rs2
         begin
            ALU_FUN = 4'b0000; //add
            srcA_SEL = 2'b00; //choose rs1
            srcB_SEL = 3'b010; //choose S-type
         end
			
         OP_IMM:  //rd = rs1 (op) imm
         begin
            srcA_SEL = 2'b00; //choose rs1
            srcB_SEL = 3'b001; //choose I-type
            RF_SEL = 2'b11;  //ALU output
            case(FUNC3)
               3'b000: ALU_FUN = 4'b0000;  // instr: ADDI
               3'b001: ALU_FUN = 4'b0001;  //instr: SLLI
			   3'b010: ALU_FUN = 4'b0010;  //instr: SLTI
			   3'b011: ALU_FUN = 4'b0011;  //instr: SLTIU
			   3'b100: ALU_FUN = 4'b0100;  //instr: XORI
			   3'b101: //instr: SRLI or SRAI
                        if(func7) begin
                        ALU_FUN = 4'b1101;  //SRAI
                        end
                        else begin
                        ALU_FUN = 4'b0101; //SRLI
                        end
			   3'b110: ALU_FUN = 4'b0110;  //instr: ORI
			   3'b111: ALU_FUN = 4'b0111;  //instr: ANDI
               default: 
                   begin
                      srcA_SEL = 2'b00; //choose rs1
                      srcB_SEL = 3'b001; //choose I-type
                      RF_SEL = 2'b11;  //ALU output
                      ALU_FUN = 4'b0000;
                   end
               endcase
               end
         OP_RG3: //rd = rs1 (op) rs2
         begin
             PC_SEL = 3'b000; 
             srcA_SEL = 2'b00; //rs1
             srcB_SEL = 3'b000; //rs2
             RF_SEL = 2'b11; //ALU output
             case(FUNC3)
             3'b000: //instr: ADD or SUB
                if(!func7)
                    ALU_FUN = 4'b0000; //add
                else
                    ALU_FUN = 4'b1000; //sub
                    
             3'b001: ALU_FUN = 4'b0001;  //Instr: SLL
             3'b010: ALU_FUN = 4'b0010;  //Instr: SLT
             3'b011: ALU_FUN = 4'b0011;  //Instr: SLTU
             3'b100: ALU_FUN = 4'b0100;  //Instr: XOR
             3'b101: //Instr: SRL or SRA
                if(!func7)
                    ALU_FUN = 4'b0101; //SRL
                else
                    ALU_FUN = 4'b1101; //SRA
                    
             3'b110: ALU_FUN = 4'b0110;  //Instr: OR
             3'b111: ALU_FUN = 4'b0111;  //Instr: AND
             default: ALU_FUN = 4'b0000;
             endcase
         end
         CSR: 
         begin
            RF_SEL = 2'b01; //read
            case(func3)
                3'b001:  //csrrw: read write
                begin
                    srcA_SEL = 2'b00; //rs1
                    ALU_FUN = 4'b1001; //rd = rs1
                end
                3'b010: //csrrs: read set
                    //rd = csr | rs1
                begin
                    srcA_SEL = 2'b00; //rs1
                    srcB_SEL = 3'b100; //csr
                    ALU_FUN = 4'b0110; //or
                end
                3'b011: //csrrc: read clear
                    //rd = csr & ~rs1
                begin
                    srcA_SEL = 2'b10; //~rs1
                    srcB_SEL = 3'b100; //csr
                    ALU_FUN = 4'b0111; //and
                end
                3'b000: //mret
                begin
                    PC_SEL = 3'b101; //PC choose mepc
                end
                default: begin srcA_SEL = 2'b00;
                         srcB_SEL = 3'b000;
                         ALU_FUN = 4'b0000;
                         end
            endcase
         end
         default:
         begin
             PC_SEL = 3'b000; 
             srcB_SEL = 3'b000; 
             RF_SEL = 2'b00;
             srcA_SEL = 2'b00; 
             ALU_FUN = 4'b0000;
         end
      endcase
      end
   end

endmodule