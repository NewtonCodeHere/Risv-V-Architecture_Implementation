`timescale 1ns / 1ps
`include "../rtl/common/defines.vh"

module tb_alu;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [3:0]  alu_ctrl;
    wire [31:0] result;
    wire        zero;
    wire        less_than;
    wire        less_than_unsigned;

    integer errors = 0;

    alu uut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero),
        .less_than(less_than),
        .less_than_unsigned(less_than_unsigned)
    );

    task check_result;
        input [31:0] expected;
        input [127:0] op_name;
        begin
            #1;
            if (result !== expected) begin
                $display("[FAIL] %0s: a = 0x%08h, b = 0x%08h -> result = 0x%08h (expected 0x%08h)", 
                         op_name, a, b, result, expected);
                errors = errors + 1;
            end else begin
                $display("[PASS] %0s: a = 0x%08h, b = 0x%08h -> result = 0x%08h", 
                         op_name, a, b, result);
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display("Starting ALU Testbench Verification");
        $display("========================================");

        // ADD
        a = 32'd15; b = 32'd25; alu_ctrl = `ALU_ADD;
        check_result(32'd40, "ADD positive");

        a = 32'hFFFFFFFF; b = 32'd1; alu_ctrl = `ALU_ADD; // -1 + 1 = 0
        check_result(32'd0, "ADD overflow to 0");
        if (!zero) begin $display("[FAIL] Zero flag not set for 0 result"); errors = errors + 1; end

        // SUB
        a = 32'd50; b = 32'd20; alu_ctrl = `ALU_SUB;
        check_result(32'd30, "SUB positive");

        a = 32'd10; b = 32'd20; alu_ctrl = `ALU_SUB;
        check_result(-32'd10, "SUB negative result");

        // AND, OR, XOR
        a = 32'hF0F0AAAA; b = 32'h0F0FAAAA;
        alu_ctrl = `ALU_AND; check_result(32'h0000AAAA, "AND");
        alu_ctrl = `ALU_OR;  check_result(32'hFFFFAAAA, "OR");
        alu_ctrl = `ALU_XOR; check_result(32'hFFFF0000, "XOR");

        // SLL, SRL, SRA
        a = 32'hF0000001; b = 32'd4;
        alu_ctrl = `ALU_SLL; check_result(32'h00000010, "SLL");
        alu_ctrl = `ALU_SRL; check_result(32'h0F000000, "SRL");
        alu_ctrl = `ALU_SRA; check_result(32'hFF000000, "SRA (sign extended)");

        // SLT (signed) & SLTU (unsigned)
        a = -32'd10; b = 32'd5;
        alu_ctrl = `ALU_SLT;  check_result(32'd1, "SLT (-10 < 5)");
        alu_ctrl = `ALU_SLTU; check_result(32'd0, "SLTU (0xFFFFFFF6 < 5 is false)");

        // PASS_B
        a = 32'h12345678; b = 32'h87654321; alu_ctrl = `ALU_PASS_B;
        check_result(32'h87654321, "PASS_B");

        $display("========================================");
        if (errors == 0)
            $display("ALU Testbench PASSED ALL TESTS!");
        else
            $display("ALU Testbench FAILED with %0d errors", errors);
        $display("========================================");
        $finish;
    end

endmodule
