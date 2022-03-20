/*
    Author          : Jibreal Khan
    Contact         : Jibrealkhan1997@gmail.com
    Description     : TestBench for the MIPS 32 bit RISC-V processor.

*/

module MIPS_32_tb;
    reg clk1, clk2;                         // Only the clocks will be provided as inputs to the Processor.
    integer k;

    MIPS_32 mips(clk1,clk2);               // Instantiate the processor

    initial begin
        clk1 = 0;
        clk2 = 0;
        repeat(20) begin                    // Generating two-phase clock 
            #5 clk1 = 1; #clk1 = 0;
            #5 clk2 = 1; #clk2 = 0;
        end
    end

    initial begin                           // Initializing the Resgister bank and the Memory block
        
        for(k = 0; k < 31; k++)             // The for loop is used for the register bank alone
            mips.Reg[k] = k;
        
        // Storing instructions in the memory block. Instructions are in the Hex format.
        mips.Mem[0] = 32'h2801000a;         // ADDI R1, R0, R10
        mips.Mem[1] = 32'h28020014;         // ADDI R2, R0, 20
        mips.Mem[2] = 32'h28030019;         // ADDI R3, R0, 25
        mips.Mem[3] = 32'h0ce77800;         // OR R7, R7, R7 ---- Dummy Instruction
        mips.Mem[4] = 32'h0ce77800;         // OR R7, R7, R7 ---- Dummy Instruction
        mips.Mem[5] = 32'h00222000;         // ADD R4, R1, R2
        mips.Mem[6] = 32'h0ce77800;         // OR R7, R7, R7 ---- Dummy Instruction
        mips.Mem[7] = 32'h00832800;         // ADD R5, R4, R3
        mips.Mem[8] = 32'hfc000000;         // HALT

        // Initially setting all the flags to 0
        mips.HALTED = 0;
        mips.PC = 0;
        mips.TAKEN_BRANCH = 0;

        #280
        for(k = 0; k < 6; k++)
            $display("R%1d -----> %2d", k, mips.Reg[k]);
    end

    initial begin                           // Store the data in the following file.
        $dumpfile("MIPS_32bit_tb.vcd");
        $dumpvars(0, MIPS_32_tb);
        #300 $finish;
    end



endmodule