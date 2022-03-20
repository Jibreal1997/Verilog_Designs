/*
    Author          : Jibreal Khan
    Contact         : Jibrealkhan1997@gmail.com
    Description     : Design of a MIPS 32 bit RISC-V processor. The instruction set is limited. 


*/

module MIPS_32(clk1,clk2);

input clk1, clk2;                                                   //Two phase clock


/*Creating the various latches between stages of the processor*/
reg [31:0] PC, IF_ID_IR, IF_ID_NPC;                                 // Instruction Fetch stage registers
reg [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_IMM;        // Instruction Decode stage registers
reg [31:0] EX_MEM_IR, EX_MEM_ALUout, EX_MEM_B;                      // Instruction Execute stage
reg [31:0] MEM_WB_IR, MEM_WB_ALUout, MEM_WB_LMD;                    // Memory Stage

reg EX_MEM_cond;                                                    // To store the branch condition true or false
reg [2:0] ID_EX_type, EX_MEM_type, MEM_WB_type;                     // 3 bit register type, to determine the type of instruction. 

/*Creating the memory and the register bank*/
reg [31:0] Reg [0:31];                                              // Register bank (32 x 32)
reg [31:0] Mem [0:1023];                                            // Memory (1024 x 32)

/*Defining the opcode for the instructions, the codes are 6 bits long*/
parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
          SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, LW=6'b001000,
          SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
          BNEQZ=6'b001101, BEQZ=6'b001110;
    
/*Defining the type of instructions*/
parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011,
          BRANCH=3'b100, HALT=3'b101;

reg HALTED;                                                         // Set after HLT instruction is completed in WB stage
reg TAKEN_BRANCH;                                                   // Required to disable instructions after branch

/* Instruction Fetch Stage (IF)*/
always@(posedge clk1) begin
    if(HALTED == 0) begin                                           // Only work if halt register was not set
        if(((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) || ((EX_MEM_IR[31:26] == BENQZ) && (EX_MEM_cond == 0))) begin         // Check is instruction was branching in the Execute Cycle              
            IF_ID_IR        <=  #2 Mem[EX_MEM_ALUout]                       //If Branching, set a different Instrution
            TAKEN_BRANCH    <=  #2 1'b1;
            IF_ID_NPC       <=  #2 EX_MEM_ALUout + 1;
            PC              <=  #2 EX_MEM_ALUout + 1;
        end
    else begin
        IF_ID_IR    <=  #2 Mem[PC];                                 // If there is no branch instruction in the Execute stage
        IF_ID_NPC   <=  #2 PC + 1;
        PC          <=  #2 PC + 1;
    end
    end
end

/* Stage 2: Instruction Decode Stage (ID)
     About: In this stage the appropritate values of rs , rt and Imm are selected from the register bank.
            If the Imm value is chosen, then it is first sign exteneded by 16 bits. 
            Furthermore, register values like NPC and IR are passed from the previous stage to the next stage.
            Lastly, case statements are used to alot the type of command to the type register */

always@(posedge clk2) begin
    if(HALTED == 0) begin
        
        if(IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;               // If zero , make zero.
        else ID_EX_A <= #2 Reg[IF_ID_IR[25:21]];                    // Figuring out the value of "rs" from the register bank.    
    
        if(IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0;               // If zero , make zero.
        else ID_EX_B <= #2 Reg[IF_ID_IR[20:16]];                    // Figuring out the value of "rt" from the register bank. 

        ID_EX_NPC   <= #2 IF_ID_NPC;                                
        ID_EX_IR    <= #2 IF_ID_IR;
        ID_EX_IMM   <= {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}}       // Sign extending the Imm value to 32 bit.
    
        // Case statements for instruction type
        case (IF_ID_IR[31:26])
            ADD,SUB,AND,OR,SLT,MUL  :     ID_EX_type <= #2 RR_ALU;
            ADDI,SUBI,SLTI          :     ID_EX_type <= #2 RM_ALU;
            LW                      :     ID_EX_type <= #2 LOAD;
            SW                      :     ID_EX_type <= #2 STORE;
            BNEQZ,BEQZ              :     ID_EX_type <= #2 BRANCH;
            HLT                     :     ID_EX_type <= #2 HALT;
            default                 :     ID_EX_type <= #2 HALT;        // Invalid opcode
        endcase

    end
end

/* Stage 3: Instruction Execute Stage (IE)
     About: So this is the ALU stage, Case statements inside case statements are used to perform functions on the input.
     type and IR regs are passed to the next stage */

always@(posedge clk1)
    if(HALTED == 0) begin
        EX_MEM_type  <= #2 ID_EX_type;
        EX_MEM_IR    <= #2 ID_EX_IR;
        TAKEN_BRANCH <= #2 0;

        case(ID_EX_type)                                                // This case is used for different types of instructions
            
            RR_ALU: begin                                               // For RR type instructions
                        case(ID_EX_IR[31:26])                           // Based on the opcode
                            ADD     :    EX_MEM_ALUout  <= #2 ID_EX_A + ID_EX_B;
                            SUB     :    EX_MEM_ALUout  <= #2 ID_EX_A - ID_EX_B;
                            AND     :    EX_MEM_ALUout  <= #2 ID_EX_A & ID_EX_B;
                            OR      :    EX_MEM_ALUout  <= #2 ID_EX_A | ID_EX_B;
                            SLT     :    EX_MEM_ALUout  <= #2 ID_EX_A < ID_EX_B;
                            MUL     :    EX_MEM_ALUout  <= #2 ID_EX_A * ID_EX_B;
                            default :    EX_MEM_ALUout  <= #2 32'hxxxxxxxx;
                        endcase
                     end
            
            RM_ALU: begin                                               // For RM type instructions
                        case(ID_EX_IR[31:26])                           // Based on the opcode
                            ADDI    :    EX_MEM_ALUout  <= #2 ID_EX_A + ID_EX_IMM;
                            SUBI    :    EX_MEM_ALUout  <= #2 ID_EX_A - ID_EX_IMM;
                            SLTI    :    EX_MEM_ALUout  <= #2 ID_EX_A < ID_EX_IMM;
                            default :    EX_MEM_ALUout  <= #2 32'hxxxxxxxx;  
                        endcase; 
                    end

            LOAD, STORE: begin                                           // For Load and Store type instructions
                            EX_MEM_ALUout <= #2 ID_EX_A + ID_EX_IMM;     // Calculate the address where data is to be stored or retrieved in Memory   
                            EX_MEM_B      <= #2 ID_EX_B;
                         end

            BRANCH:     begin                                            // For Branch type instructions
                            EX_MEM_ALUout <= #2 ID_EX_NPC + ID_EX_IMM;   // Calculating the branching address
                            EX_MEM_cond   <= #2 (ID_EX_A == 0);
                        end
        endcase
    end
end

/* Stage 4: Memory Stage
     About: This stafe also requires the use of case statements which check for the type of instructions.
            If it is RR or RM type then its contents are simply passed on. 
            If it is Load type data is taken from the memroy address.
            If it is store type data is stored into the memory address. */

always@(posedge clk2) begin
    if(HALTED == 0) begin
        MEM_WB_type <= #2 EX_MEM_type;
        MEM_WB_IR   <= #2 EX_MEM_IR;

        case(EX_MEM_type)
            RR_ALU, RM_ALU:                                     // Simple register to register data transfer happens for RR and RM type.
                    MEM_WB_ALUout   <= #2 EX_MEM_ALUout;
            LOAD:   MEM_WB_LMD      <= #2 Mem[EX_MEM_ALUout]    // Loading data from the memory, address is computed by the ALU.    
            STORE:  if( TAKEN_BRANCH == 0)                      // Disable Write
                        Mem[EX_MEM_ALUout] <= #2 EX_MEM_B;      // Write to the memory
        endcase
    end
end

/* Stage 5: Write Back Stage
     About: In this stage we are writing the data back to the register bank. 
            The approriate address to write to is selected via the case statements
            for different types of instructions */

always@(posedge clk1) begin
    if(TAKEN_BRANCH == 0)                                       // Disable write if branch taken
    case(MEM_WB_type)
        RR_ALU: Reg[MEM_WB_IR[15:11]]   <= #2 MEM_WB_ALUout;     // "rd"
        RM_ALU: Reg[MEM_WB_IR[20:16]]   <= #2 MEM_WB_ALUout;     // "rt"
        LOAD  : Reg[MEM_WB_IR[20:16]]   <= #2 MEM_WB_LMD;        // "rt"
        HALT  : HALTED <= #2 1'b1;
    endcase
end
endmodule