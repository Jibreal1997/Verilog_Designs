/*
    Author          : Jibreal Khan
    Contact         : Jibrealkhan1997@gmail.com
    Description     : Design of a MIPS 64 bit RISC processor. The instruction set is limited. 
*/

module MIPS_64(clk1, clk2);
    input clk1, clk2;                                   // Two phased clock


    /*  
                        Register and Memory Declaration Stage

        Note: This is the register and memory declaration stage, the IR, PC and NPC
        registers across all stages are 32 bits , whereas the register containining the
        values of A, B , IMM and the output of the ALU are all going to be 64 bits. Additionally,
        the width of instruction memory block is 32 bits whereas the width of the register bank and 
        data memory is 64 bits.
    */

    // IF_ID stage registers
    reg [63:0] PC, IF_ID_IR, IF_ID_NPC;                 
    
    // ID_EX stage registers
    reg [63:0] ID_EX_IR, ID_EX_NPC;
    reg [63:0] ID_EX_A, ID_EX_B, ID_EX_IMM;             
    reg [2:0]  ID_EX_type;                              
    
    // EX_MEM stage registers
    reg [63:0] EX_MEM_IR;
    reg [63:0] EX_MEM_ALUout, EX_MEM_B;
    reg [2:0]  EX_MEM_type;
    reg        EX_MEM_cond;

    // MEM_WB stage registers 
    reg [63:0] MEM_WB_IR;
    reg [63:0] MEM_WB_ALUout, MEM_WB_LMD;
    reg [2:0]  MEM_WB_type;

    // Memory and Register banks
    reg [63:0] DATA_MEMORY [0:1023];                               // 1024 x 64 memory
    reg [31:0] INSTRUCTION_MEMORY [0:1023];                        // 1024 x 32 memory
    reg [63:0] REG_BANK [0:31];                                    //   32 x 64 memory      

    /*
                            Opcode and Type Declaration Stage
    
        Note: This is where the opcode for the various instructions are initialized
        This makes it simpler to look for instructions when using the case statements. 
        Additionally the use parameter keyword makes the design modifiable. The opcodes
        are 6 bits long. Addtitonally, the type of instructions are initialized.
    */

    // Opcode
    parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011,
          SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, LW=6'b001000,
          SW=6'b001001, ADDI=6'b001010, SUBI=6'b001011, SLTI=6'b001100,
          BNEQZ=6'b001101, BEQZ=6'b001110;
    
    // Type
    parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011,
          BRANCH=3'b100, HALT=3'b101;

    // Halt and branch taken 
    reg HALTED;
    reg TAKEN_BRANCH;

    /*
                                Stage 1: Instruction Fetch

        Note:  Start if not halt ,  check if branch or no branch and set the values for 
        PC, NPC and IR. In this stage the instruction is fetched from the program counter and
        stored into the IR register and the program counter is updated.
    */
    always@(posedge clk1) begin
        
        if(HALTED == 0) begin                                       // Only begin the stage if not Halted
            if(((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond == 1)) || ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0))) begin
                IF_ID_IR            <= #2 INSTRUCTION_MEMORY[EX_MEM_ALUout];
                TAKEN_BRANCH        <= #2 1'b1;                                     // Do these if branching is true.
                IF_ID_NPC           <= #2 EX_MEM_ALUout + 1;
                PC                  <= #2 EX_MEM_ALUout + 1;
            end
            else begin
                IF_ID_IR            <= #2 INSTRUCTION_MEMORY[PC];
                IF_ID_NPC           <= #2 PC + 1;
                PC                  <= #2 PC + 1;
            end
        end
    end

   /*
                                Stage 2: Instruction Decode

        Note:  Start if not halt , in this stage the instruction is read and appropriate
        values fromt the registers banks are selected. Additionally, the immediate values
        is sign extended to 64 bit. Lastly, values of NPC , IR and Imm are passed to the ID_EX
        registers.

        Furthermore, case statements are used to assign instruction types.
    */

    always@(posedge clk2) begin
        if(HALTED == 0) begin
            if(IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;               // If value of R0 is to be loaded, just put Zero
            else ID_EX_A <= REG_BANK[IF_ID_IR[25:21]];                  // rs

            if(IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0;               // If value of R0 is to be loaded, just put Zero
            else ID_EX_B <= REG_BANK[IF_ID_IR[20:16]];                  // rt

            ID_EX_NPC   <= #2 IF_ID_NPC;
            ID_EX_IR    <= #2 IF_ID_IR;
            ID_EX_IMM   <= #2 {{48{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}};   // Sign extending the IMM value to 64 bits
        end

        // Instruction Type
        case (IF_ID_IR[31:26])
            ADD, SUB, AND, OR, SLT, MUL :    ID_EX_type <= #2 RR_ALU;
            ADDI, SUBI, SLTI            :    ID_EX_type <= #2 RM_ALU;
            LW                          :    ID_EX_type <= #2 LOAD;
            SW                          :    ID_EX_type <= #2 STORE;
            BNEQZ,BEQZ                  :    ID_EX_type <= #2 BRANCH;
            HLT                         :    ID_EX_type <= #2 HALT;
            default                     :    ID_EX_type <= #2 HALT;   
        endcase
    end

   /*
                                Stage 3: Execute Stage

        Note: In this stage the ALU is used to perfrom various operations based on the 
        type of the instruciton. This involves using a case inside a case statement.
    */
    always@(posedge clk1) begin
        if(HALTED == 0) begin
            EX_MEM_type     <= #2 ID_EX_type;
            EX_MEM_IR       <= #2 ID_EX_IR;
            TAKEN_BRANCH    <= #2 0;

            case(ID_EX_type)                                    // Instruction type
                
                RR_ALU: begin                                                   // For RR type instructions
                    case(ID_EX_IR[31:26])                                       // Based on the Opcode
                        ADD     :    EX_MEM_ALUout  <= #2 ID_EX_A + ID_EX_B;
                        SUB     :    EX_MEM_ALUout  <= #2 ID_EX_A - ID_EX_B;
                        AND     :    EX_MEM_ALUout  <= #2 ID_EX_A & ID_EX_B;
                        OR      :    EX_MEM_ALUout  <= #2 ID_EX_A | ID_EX_B;
                        SLT     :    EX_MEM_ALUout  <= #2 ID_EX_A < ID_EX_B;
                        MUL     :    EX_MEM_ALUout  <= #2 ID_EX_A * ID_EX_B;
                        default :    EX_MEM_ALUout  <= #2 64'hxxxxxxxxxxxxxxxx;
                    endcase
                end

                RM_ALU: begin                                                   // For RM type instructions
                    case(ID_EX_IR[31:26])                                       // Based on the opcode
                        ADDI    :    EX_MEM_ALUout  <= #2 ID_EX_A + ID_EX_IMM;
                        SUBI    :    EX_MEM_ALUout  <= #2 ID_EX_A - ID_EX_IMM;
                        SLTI    :    EX_MEM_ALUout  <= #2 ID_EX_A < ID_EX_IMM;
                        default :    EX_MEM_ALUout  <= #2 64'hxxxxxxxxxxxxxxxx;  
                    endcase 
                end

                
                LOAD, STORE: begin                                           // For Load and Store type instructions
                    EX_MEM_ALUout <= #2 ID_EX_A + ID_EX_IMM;                // Calculate the address where data is to be stored or retrieved in Memory   
                    EX_MEM_B      <= #2 ID_EX_B;
                 end

                BRANCH:begin                                                // For Branch type instructions
                    EX_MEM_ALUout <= #2 ID_EX_NPC + ID_EX_IMM;              // Calculating the branching address
                    EX_MEM_cond   <= #2 (ID_EX_A == 0);
                end
            endcase
        end
    end

   /*
                                Stage 4: Memory Stage

        Note: In this stage , depending upon the type of the instruction , data is either put into
        of removed from the memory. This is also done using case statements.
    */

    always@(posedge clk2) begin
        if(HALTED == 0) begin
            MEM_WB_type <= EX_MEM_type;
            MEM_WB_IR   <= #2 EX_MEM_IR;

            case(EX_MEM_type)
                RR_ALU, RM_ALU      :   MEM_WB_ALUout <= #2 EX_MEM_ALUout;
                LOAD                :   MEM_WB_LMD    <= #2 DATA_MEMORY[EX_MEM_ALUout];
                STORE               :   if(TAKEN_BRANCH == 0) DATA_MEMORY[EX_MEM_ALUout] <= #2 EX_MEM_B;
            endcase
        end
    end

   /*
                                Stage 5: Write Back Stage

        Note: In this stage , depending upon the type of the instruction, data is 
        written back to the register bank.
    */

    always@(posedge clk1) begin
        if(TAKEN_BRANCH == 0) begin                       // Disable write if branch is taken
            case(MEM_WB_type)
                RR_ALU  :   REG_BANK[MEM_WB_IR[15:11]]  <= #2 MEM_WB_ALUout;        //rd
                RM_ALU  :   REG_BANK[MEM_WB_IR[20:16]]  <= #2 MEM_WB_ALUout;        //rt
                LOAD    :   REG_BANK[MEM_WB_IR[20:16]]  <= #2 MEM_WB_LMD;           //rt
                HALT    :   HALTED <= #2 1'b1;
            endcase
        end
    end
endmodule