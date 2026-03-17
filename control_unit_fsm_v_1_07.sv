`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Ratner Surf Designs
// Engineer: James Ratner
// 
// Create Date: 01/07/2020 09:12:54 PM
// Design Name: 
// Module Name: top_level
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Control Unit Template/Starter File for RISC-V OTTER
//
//     //- instantiation template 
//     CU_FSM my_fsm(
//        .intr     (xxxx),
//        .clk      (xxxx),
//        .RST      (xxxx),
//        .opcode   (xxxx),   // ir[6:0]
//        .func3    (xxxx),  //ir[14:12]
//        .intr_valid(xxx),
//        .PC_WE    (xxxx),
//        .RF_WE    (xxxx),
//        .memWE2   (xxxx),
//        .memRDEN1 (xxxx),
//        .memRDEN2 (xxxx),
//        .csr_WE   (xxxx),
//        .int_taken(xxxx),
//        .mret_exec(xxxx),
//        .reset    (xxxx)   );
//   
// Dependencies: 
// 
// Revision  History:
// Revision 1.00 - File Created - 02-01-2020 (from other people's files)
//          1.01 - (02-08-2020) switched states to enum type
//          1.02 - (02-25-2020) made PS assignment blocking
//                              made rst output asynchronous
//          1.03 - (04-24-2020) added "init" state to FSM
//                              changed rst to reset
//          1.04 - (04-29-2020) removed typos to allow synthesis
//          1.05 - (10-14-2020) fixed instantiation comment (thanks AF)
//          1.06 - (12-10-2020) cleared most outputs, added commentes
//          1.07 - (12-27-2023) changed signal names 
// 
//////////////////////////////////////////////////////////////////////////////////

module CU_FSM(
    input intr,
    input clk,
    input RST,
    input [6:0] opcode,     // ir[6:0]
    input [2:0] func3,      // ir[14:12]
    input intr_valid,
    output logic PC_WE,
    output logic RF_WE,
    output logic memWE2,
    output logic memRDEN1,
    output logic memRDEN2,
    output logic csr_WE,
    output logic int_taken,
    output logic mret_exec,
    output logic reset
  );
    
    typedef  enum logic [2:0] {
       st_INIT,
	   st_FET,
       st_EX,
       st_WB,
       st_INTR
    }  state_type; 
    state_type  NS,PS; 
      
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
        CSR = 7'b1110011
    } opcode_t;
    
	opcode_t OPCODE;    //- symbolic names for instruction opcodes
     
	assign OPCODE = opcode_t'(opcode); //- Cast input as enum 
	//- datatype for func3Symbols tied to values
   typedef enum logic [2:0] {
        //CSR labels
        CSRRW = 3'b001,
        CSRRC = 3'b011,
        CSRRS = 3'b010,
        mret = 3'b000
   } func3_t;
   func3_t FUNC3; // define variable of new opcode type
    
   assign FUNC3 = func3_t'(func3); //- Cast input enum 

	//- state registers (PS)
	always @ (posedge clk)  
        if (RST == 1)
            PS <= st_INIT;
        else
            PS <= NS;

    always_comb
    begin
        NS = PS; //default NS              
        //- schedule all outputs to avoid latch
        PC_WE = 1'b0;    RF_WE = 1'b0;    reset = 1'b0;  
		memWE2 = 1'b0;     memRDEN1 = 1'b0;    memRDEN2 = 1'b0;
		int_taken = 1'b0;  mret_exec = 1'b0; csr_WE = 1'b0;
                   
        case (PS)

            st_INIT: //waiting state  
            begin
                reset = 1'b1;                    
                NS = st_FET; 
            end

            st_FET: //waiting state  
            begin
                memRDEN1 = 1'b1;           
                NS = st_EX; 
            end
              
            st_EX: //decode + execute
            begin
                if(intr_valid) begin
                    NS = st_INTR;
                end else begin
                    PC_WE = 1'b1;
                    case (OPCODE)
                        LOAD:  //compute addr and start data mem read
                           begin
                              memRDEN2 = 1'b1;
                              NS = st_WB;   //load needs extra cycle to write mem data to rd
                           end
                        
                        STORE:  //compute addr and write data to mem
                           begin
                              memWE2 = 1'b1;   //perform store
                              NS = st_FET;
                           end
                        
                        BRANCH:  //compare rs1 & rs2, maybe update PC
                           begin
                              RF_WE = 1'b0;
                              NS = st_FET;
                           end
                        
                        LUI:    //write U-imm to rd
                           begin
                              RF_WE = 1'b1;					      
                              NS = st_FET;
                           end
                        AUIPC:  // compute PC + U_imm, write to rd
                           begin
                               RF_WE = 1'b1;
                               NS = st_FET;
                           end
                        OP_RG3:  //ALU ap using rs1, rs2, writing result to rd
                           begin
                               RF_WE = 1'b1;
                               NS = st_FET;
                           end
                        OP_IMM:  // ALU op using rs1 and imm, write result to rd
                           begin 
                              RF_WE = 1'b1;	
                              NS = st_FET;
                           end
                        
                        JAL: //Update PC to jump target, write ret addr to rd
                           begin
                              RF_WE = 1'b1;
                              NS = st_FET;
                           end
                        JALR: //Update PC to (rs1+imm) & ~1, write ret addr to rd
                           begin
                               RF_WE = 1'b1;
                               NS = st_FET;
                           end
                        CSR: 
                            begin
                               if(func3 == 3'b000) begin
                                   mret_exec = 1'b1;
                                   PC_WE = 1'b1;
                                   NS = st_FET;
                               end else begin
                               RF_WE = 1'b1; //write rd with csr_RD
                               csr_WE = 1'b1; //write CSR
                               
                               NS = st_FET;
                            end
                            end
                        default:  
                           begin 
                              NS = st_FET;
                           end
                        
                    endcase
                    end
            end
               
            st_WB:
            begin
               RF_WE = 1'b1;
               NS = st_FET;
            end
            st_INTR:
            begin
                int_taken = 1'b1;
                PC_WE = 1'b1;
                NS = st_FET;
                
            end
            default: NS = st_INIT;
           
        endcase //- case statement for FSM states
    end
           
endmodule
