`timescale 1ns / 1ps
`include "../common/defines.vh"

module hazard_unit (
    // Forwarding inputs
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    input  wire [4:0]  ex_mem_rd,
    input  wire        ex_mem_reg_write,
    input  wire [4:0]  mem_wb_rd,
    input  wire        mem_wb_reg_write,
    
    // Store forwarding in MEM stage
    input  wire [4:0]  ex_mem_rs2,
    input  wire        ex_mem_mem_write,
    
    // Hazard detection inputs
    input  wire [4:0]  if_id_rs1,
    input  wire [4:0]  if_id_rs2,
    input  wire [6:0]  if_id_opcode,
    input  wire [4:0]  id_ex_rd,
    input  wire        id_ex_mem_read,
    input  wire        branch_jump_taken,
    
    // Forwarding outputs
    output reg  [1:0]  forward_a,
    output reg  [1:0]  forward_b,
    output reg         forward_dmem_data,
    
    // Pipeline control outputs (Stall / Flush)
    output reg         pc_write,
    output reg         if_id_write,
    output reg         if_id_flush,
    output reg         id_ex_flush
);

    // Determine if the instruction currently in ID stage uses rs1 and rs2
    wire id_uses_rs1 = (if_id_opcode == `OPCODE_R_TYPE)  ||
                       (if_id_opcode == `OPCODE_I_TYPE)  ||
                       (if_id_opcode == `OPCODE_LOAD)    ||
                       (if_id_opcode == `OPCODE_STORE)   ||
                       (if_id_opcode == `OPCODE_BRANCH)  ||
                       (if_id_opcode == `OPCODE_JALR);

    wire id_uses_rs2 = (if_id_opcode == `OPCODE_R_TYPE)  ||
                       (if_id_opcode == `OPCODE_STORE)   ||
                       (if_id_opcode == `OPCODE_BRANCH);

    // ------------------------------------------------------------------------
    // Forwarding Logic for ALU Operands in EX stage
    // ------------------------------------------------------------------------
    always @(*) begin
        // Forward A (rs1)
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = `FWD_MEM; // 2'b10
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = `FWD_WB;  // 2'b01
        end else begin
            forward_a = `FWD_NONE;// 2'b00
        end

        // Forward B (rs2)
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = `FWD_MEM; // 2'b10
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = `FWD_WB;  // 2'b01
        end else begin
            forward_b = `FWD_NONE;// 2'b00
        end
    end

    // Forwarding for Store data in MEM stage:
    // If instruction in MEM is Store and MEM/WB instruction writes to its rs2
    always @(*) begin
        if (ex_mem_mem_write && mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == ex_mem_rs2)) begin
            forward_dmem_data = 1'b1;
        end else begin
            forward_dmem_data = 1'b0;
        end
    end

    // ------------------------------------------------------------------------
    // Hazard Detection: Load-Use Hazard & Control Hazard (Branch / Jump Flush)
    // ------------------------------------------------------------------------
    wire load_use_hazard = id_ex_mem_read && (id_ex_rd != 5'd0) &&
                          ((id_uses_rs1 && (id_ex_rd == if_id_rs1)) ||
                           (id_uses_rs2 && (id_ex_rd == if_id_rs2)));

    always @(*) begin
        // Default: normal pipeline flow
        pc_write    = 1'b1;
        if_id_write = 1'b1;
        if_id_flush = 1'b0;
        id_ex_flush = 1'b0;

        if (branch_jump_taken) begin
            // Branch or Jump was taken: flush IF/ID and ID/EX to cancel speculative instructions
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
        end else if (load_use_hazard) begin
            // Load-Use stall: freeze PC and IF/ID, bubble ID/EX
            pc_write    = 1'b0;
            if_id_write = 1'b0;
            id_ex_flush = 1'b1;
        end
    end

endmodule
