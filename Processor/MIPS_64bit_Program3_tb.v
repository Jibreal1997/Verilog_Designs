module test2_MIPS_64_tb;
    reg clk1, clk2;
    integer k;

    MIPS_64 P1(clk1, clk2);
    
    initial begin
        clk1=0; clk2=0;
        repeat(50) begin                         // Generating a two phased clock
            #5 clk1 = 1; #5 clk1 = 0;                   
            #5 clk2 = 1; #5 clk2 = 0;
        end
    end

    initial begin
        for(k = 0; k < 31; k = k + 1) begin            // Intializing the register bank
            P1.REG_BANK[k] = k;
        end

        // Initializing the Instruction memory
        P1.INSTRUCTION_MEMORY[0] = 64'h00000000280a00c8;       //ADDI R10,R0,200
        P1.INSTRUCTION_MEMORY[1] = 64'h0000000028020001;       //ADDI R2,R0,1   
        P1.INSTRUCTION_MEMORY[2] = 64'h000000000e94a000;       //OR R20,R20,R20 ---- DUMMY
        P1.INSTRUCTION_MEMORY[3] = 64'h0000000021430000;       //LW R3,0(R10)
        P1.INSTRUCTION_MEMORY[4] = 64'h000000000e94a000;       //OR R20,R20,R20 ---- DUMMY
        P1.INSTRUCTION_MEMORY[5] = 64'h0000000014431000;       //Loop: MUL R2,R2,R3
        P1.INSTRUCTION_MEMORY[6] = 64'h000000002c630001;       //SUBI R3,R3,1
        P1.INSTRUCTION_MEMORY[7] = 64'h000000000e94a000;       //OR R20,R20,R20 ---- DUMMY
        P1.INSTRUCTION_MEMORY[8] = 64'h000000003460fffc;       //BNEQZ R3,Loop
        P1.INSTRUCTION_MEMORY[9] = 64'h000000002542fffe;       //SW R2,-2(R10)
        P1.INSTRUCTION_MEMORY[10] = 64'h00000000fc000000;       //HLT

        // Initializing the Data Memory
        P1.DATA_MEMORY[200]         = 7;                       // To find the factorial of 7

        P1.PC = 0;
        P1.HALTED = 0;
        P1.TAKEN_BRANCH = 0;

        #2000
        $display("DATA_MEMORY[200]: %2d \nDATA_MEMORY[198]: %6d", P1.DATA_MEMORY[200], P1.DATA_MEMORY[198]);
    end
endmodule