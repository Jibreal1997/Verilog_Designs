/*
    Author          : Jibreal Khan
    Contact         : Jibrealkhan1997@gmail.com
    Description     : TestBench for the MIPS 64 bit RISC processor. In this program
                      three numbers 10, 20 and 25 are added. The numbers are stored
                      in the processor registers and the result is also stored in the
                      processor registers.

*/

module test1_MIPS_64_tb;
    
    reg clk1, clk2;                                     // These are the inputs to the processor. 
    integer k;

    MIPS_64 P1(clk1, clk2);                             // This is the initialization of the module.

    initial begin                                       // Generating two-phase clock   
        clk1 = 0; clk2 = 0;
        repeat(20) begin                    
            #5 clk1 = 1; #5 clk1 = 0;
            #5 clk2 = 1; #5 clk2 = 0;
        end
    end   

    initial begin
        for(k = 0; k < 31; k = k + 1) P1.REG_BANK[k] = k;     // Initializing the register bank  
    
        P1.INSTRUCTION_MEMORY[0] =  64'h000000002801000a;        //ADDI R1,R0,10
        P1.INSTRUCTION_MEMORY[1] =  64'h0000000028020014;        //ADDI R2,R0,20
        P1.INSTRUCTION_MEMORY[2] =  64'h0000000028030019;        //ADDI R3,R0,25
        P1.INSTRUCTION_MEMORY[3] =  64'h000000000ce77800;        //OR R7,R7,R7   --- DUMMY
        P1.INSTRUCTION_MEMORY[4] =  64'h000000000ce77800;        //OR R7,R7,R7   --- DUMMY
        P1.INSTRUCTION_MEMORY[5] =  64'h0000000000222000;        //ADD R4,R1,R2
        P1.INSTRUCTION_MEMORY[6] =  64'h000000000ce77800;        //OR R7,R7,R7   --- DUMMY
        P1.INSTRUCTION_MEMORY[7] =  64'h0000000000832800;        //ADD R5,R4,R3
        P1.INSTRUCTION_MEMORY[8] =  64'h00000000fc000000;        //HLT

        P1.HALTED = 0;
        P1.PC = 0;
        P1.TAKEN_BRANCH = 0;

        #280
        for(k = 0; k < 6; k = k + 1) begin
            $display("R%1d - %2d", k, P1.REG_BANK[k]);
        end
    end

    initial begin
        #300 $finish;
    end
endmodule