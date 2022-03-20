module test2_MIPS_64_tb;
    reg clk1, clk2;
    integer k;

    MIPS_64 P1(clk1, clk2);
    
    initial begin
        clk1=0; clk2=0;
        repeat(100) begin                         // Generating a two phased clock
            #5 clk1 = 1; #5 clk1 = 0;                   
            #5 clk2 = 1; #5 clk2 = 0;
        end
    end

    initial begin
        for(k = 0; k < 31; k = k + 1) begin            // Intializing the register bank
            P1.REG_BANK[k] = k;
        end

        // Initializing the Instruction memory
        P1.INSTRUCTION_MEMORY[0] = 64'h0000000028010078;       //ADDI R1,R0,120
        P1.INSTRUCTION_MEMORY[1] = 64'h000000000c631800;       //OR R3,R3,R3   ----- DUMMY
        P1.INSTRUCTION_MEMORY[2] = 64'h0000000020220000;       //LW R2,0(R1)
        P1.INSTRUCTION_MEMORY[3] = 64'h000000000c631800;       //OR R3,R3,R3   ----- DUMMY
        P1.INSTRUCTION_MEMORY[4] = 64'h000000002842002d;       //ADDI R2,R2,45
        P1.INSTRUCTION_MEMORY[5] = 64'h000000000c631800;       //OR R3,R3,R3   ----- DUMMY
        P1.INSTRUCTION_MEMORY[6] = 64'h0000000024220001;       //SW R2,1(R1)
        P1.INSTRUCTION_MEMORY[7] = 64'h00000000fc000000;       //HLT

        // Initializing the Data Memory
        P1.DATA_MEMORY[120]         = 85;

        P1.PC = 0;
        P1.HALTED = 0;
        P1.TAKEN_BRANCH = 0;

        #500
        $display("DATA_MEMORY[120]: %4d \nDATA_MEMORY[121]: %4d", P1.DATA_MEMORY[120], P1.DATA_MEMORY[121]);
    end
endmodule