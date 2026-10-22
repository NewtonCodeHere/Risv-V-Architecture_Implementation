`timescale 1ns / 1ps
`include "../rtl/common/defines.vh"

module tb_control_unit;

    reg  [6:0] opcode;
    reg  [1:0] alu_op;
    reg  [2:0] funct3;
    reg        funct7_5;

    wire       reg_write;
    wire [1:0] mem_to_reg;
    wire       mem_read;
    wire       mem_write;
    wire       alu_src;
    wire [1:0] ctrl_alu_op;
    wire       branch;
    wire       jump;
    wire       jalr;
    wire       auipc;
    wire [3:0] alu_ctrl;

    integer errors = 0;

    control_unit ctrl_uut (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .alu_op(ctrl_alu_op),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .auipc(auipc)
    );

    alu_control alu_ctrl_uut (
        .opcode(opcode),
        .alu_op(ctrl_alu_op),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .alu_ctrl(alu_ctrl)
    );

    initial begin
        $display("========================================");
        $display("Starting Control Unit Testbench");
        $display("========================================");

        // Test 1: R-Type ADD
        opcode = `OPCODE_R_TYPE; funct3 = `FUNCT3_ADD_SUB; funct7_5 = 1'b0; #1;
        if (reg_write !== 1'b1 || alu_src !== 1'b0 || alu_ctrl !== `ALU_ADD) begin
            $display("[FAIL] R-type ADD control signals invalid"); errors = errors + 1;
        end else begin
            $display("[PASS] R-type ADD decoded correctly (alu_ctrl = ALU_ADD, reg_write = 1)");
        end

        // Test 2: R-Type SUB
        opcode = `OPCODE_R_TYPE; funct3 = `FUNCT3_ADD_SUB; funct7_5 = 1'b1; #1;
        if (reg_write !== 1'b1 || alu_ctrl !== `ALU_SUB) begin
            $display("[FAIL] R-type SUB control signals invalid"); errors = errors + 1;
        end else begin
            $display("[PASS] R-type SUB decoded correctly (alu_ctrl = ALU_SUB)");
        end

        // Test 3: I-Type ADDI
        opcode = `OPCODE_I_TYPE; funct3 = `FUNCT3_ADD_SUB; funct7_5 = 1'b0; #1;
        if (reg_write !== 1'b1 || alu_src !== 1'b1 || alu_ctrl !== `ALU_ADD) begin
            $display("[FAIL] I-type ADDI control signals invalid"); errors = errors + 1;
        end else begin
            $display("[PASS] I-type ADDI decoded correctly (alu_src = 1, alu_ctrl = ALU_ADD)");
        end

        // Test 4: LOAD (LW)
        opcode = `OPCODE_LOAD; funct3 = `FUNCT3_LW; funct7_5 = 1'b0; #1;
        if (reg_write !== 1'b1 || mem_read !== 1'b1 || mem_to_reg !== `WB_MEM) begin
            $display("[FAIL] LOAD control signals invalid"); errors = errors + 1;
        end else begin
            $display("[PASS] LOAD (LW) decoded correctly (mem_read = 1, mem_to_reg = WB_MEM)");
        end

        // Test 5: STORE (SW)
        opcode = `OPCODE_STORE; funct3 = `FUNCT3_SW; funct7_5 = 1'b0; #1;
        if (reg_write !== 1'b0 || mem_write !== 1'b1 || alu_src !== 1'b1) begin
            $display("[FAIL] STORE control signals invalid"); errors = errors + 1;
        end else begin
            $display("[PASS] STORE (SW) decoded correctly (mem_write = 1, reg_write = 0)");
        end

        // Test 6: BRANCH (BEQ)
        opcode = `OPCODE_BRANCH; funct3 = `FUNCT3_BEQ; funct7_5 = 1'b0; #1;
        if (branch !== 1'b1 || reg_write !== 1'b0) begin
            $display("[FAIL] BRANCH control signals invalid"); errors = errors + 1;
        end else begin
            $display("[PASS] BRANCH (BEQ) decoded correctly (branch = 1, reg_write = 0)");
        end

        // Test 7: JAL
        opcode = `OPCODE_JAL; #1;
        if (jump !== 1'b1 || reg_write !== 1'b1 || mem_to_reg !== `WB_PC_PLUS_4) begin
            $display("[FAIL] JAL control signals invalid"); errors = errors + 1;
        end else begin
            $display("[PASS] JAL decoded correctly (jump = 1, mem_to_reg = WB_PC_PLUS_4)");
        end

        $display("========================================");
        if (errors == 0)
            $display("Control Unit Testbench PASSED ALL TESTS!");
        else
            $display("Control Unit Testbench FAILED with %0d errors", errors);
        $display("========================================");
        $finish;
    end

endmodule
