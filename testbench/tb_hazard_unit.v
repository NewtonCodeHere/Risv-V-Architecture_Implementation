`timescale 1ns / 1ps
`include "../rtl/common/defines.vh"

module tb_hazard_unit;

    reg  [4:0] id_ex_rs1;
    reg  [4:0] id_ex_rs2;
    reg  [4:0] ex_mem_rd;
    reg        ex_mem_reg_write;
    reg  [4:0] mem_wb_rd;
    reg        mem_wb_reg_write;
    reg  [4:0] ex_mem_rs2;
    reg        ex_mem_mem_write;
    reg  [4:0] if_id_rs1;
    reg  [4:0] if_id_rs2;
    reg  [6:0] if_id_opcode;
    reg  [4:0] id_ex_rd;
    reg        id_ex_mem_read;
    reg        branch_jump_taken;

    wire [1:0] forward_a;
    wire [1:0] forward_b;
    wire       forward_dmem_data;
    wire       pc_write;
    wire       if_id_write;
    wire       if_id_flush;
    wire       id_ex_flush;

    integer errors = 0;

    hazard_unit uut (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .ex_mem_rs2(ex_mem_rs2),
        .ex_mem_mem_write(ex_mem_mem_write),
        .if_id_rs1(if_id_rs1),
        .if_id_rs2(if_id_rs2),
        .if_id_opcode(if_id_opcode),
        .id_ex_rd(id_ex_rd),
        .id_ex_mem_read(id_ex_mem_read),
        .branch_jump_taken(branch_jump_taken),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .forward_dmem_data(forward_dmem_data),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush)
    );

    initial begin
        // Defaults
        id_ex_rs1 = 0; id_ex_rs2 = 0;
        ex_mem_rd = 0; ex_mem_reg_write = 0;
        mem_wb_rd = 0; mem_wb_reg_write = 0;
        ex_mem_rs2 = 0; ex_mem_mem_write = 0;
        if_id_rs1 = 0; if_id_rs2 = 0; if_id_opcode = 7'b0;
        id_ex_rd = 0; id_ex_mem_read = 0;
        branch_jump_taken = 0;

        $display("========================================");
        $display("Starting Hazard Unit Testbench");
        $display("========================================");

        // Test 1: EX Hazard Forwarding (EX/MEM to EX)
        #5;
        id_ex_rs1 = 5'd2;
        ex_mem_rd = 5'd2;
        ex_mem_reg_write = 1;
        #1;
        if (forward_a !== `FWD_MEM) begin
            $display("[FAIL] EX Hazard Forwarding A mismatch: expected 2'b10, got %b", forward_a);
            errors = errors + 1;
        end else begin
            $display("[PASS] EX to EX Forwarding A verified (forward_a = 2'b10)");
        end

        // Test 2: MEM Hazard Forwarding (MEM/WB to EX)
        ex_mem_rd = 5'd3; // No longer matches rs1
        mem_wb_rd = 5'd2;
        mem_wb_reg_write = 1;
        #1;
        if (forward_a !== `FWD_WB) begin
            $display("[FAIL] MEM Hazard Forwarding A mismatch: expected 2'b01, got %b", forward_a);
            errors = errors + 1;
        end else begin
            $display("[PASS] MEM to EX Forwarding A verified (forward_a = 2'b01)");
        end

        // Test 3: Load-Use Hazard Detection
        id_ex_rs1 = 0; ex_mem_reg_write = 0; mem_wb_reg_write = 0;
        id_ex_mem_read = 1;
        id_ex_rd = 5'd4;
        if_id_opcode = `OPCODE_R_TYPE;
        if_id_rs1 = 5'd4;
        #1;
        if (pc_write !== 1'b0 || if_id_write !== 1'b0 || id_ex_flush !== 1'b1) begin
            $display("[FAIL] Load-Use hazard stall signals incorrect");
            errors = errors + 1;
        end else begin
            $display("[PASS] Load-Use Hazard correctly detected: pc_write=0, if_id_write=0, id_ex_flush=1");
        end

        // Test 4: Branch / Control Hazard Flush
        id_ex_mem_read = 0;
        branch_jump_taken = 1;
        #1;
        if (if_id_flush !== 1'b1 || id_ex_flush !== 1'b1 || pc_write !== 1'b1) begin
            $display("[FAIL] Branch flush signals incorrect");
            errors = errors + 1;
        end else begin
            $display("[PASS] Branch / Jump flush verified: if_id_flush=1, id_ex_flush=1");
        end

        $display("========================================");
        if (errors == 0)
            $display("Hazard Unit Testbench PASSED ALL TESTS!");
        else
            $display("Hazard Unit Testbench FAILED with %0d errors", errors);
        $display("========================================");
        $finish;
    end

endmodule
