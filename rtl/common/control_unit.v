`timescale 1ns / 1ps
`include "defines.vh"

module control_unit (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg  [1:0] mem_to_reg,
    output reg        mem_read,
    output reg        mem_write,
    output reg        alu_src,
    output reg  [1:0] alu_op,
    output reg        branch,
    output reg        jump,
    output reg        jalr,
    output reg        auipc
);

    always @(*) begin
        // Default control signal assignments
        reg_write  = 1'b0;
        mem_to_reg = `WB_ALU;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        alu_op     = `ALU_OP_MEM;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        auipc      = 1'b0;

        case (opcode)
            `OPCODE_R_TYPE: begin
                reg_write  = 1'b1;
                mem_to_reg = `WB_ALU;
                alu_src    = 1'b0;      // rs2
                alu_op     = `ALU_OP_R_I;
            end

            `OPCODE_I_TYPE: begin
                reg_write  = 1'b1;
                mem_to_reg = `WB_ALU;
                alu_src    = 1'b1;      // immediate
                alu_op     = `ALU_OP_R_I;
            end

            `OPCODE_LOAD: begin
                reg_write  = 1'b1;
                mem_to_reg = `WB_MEM;
                mem_read   = 1'b1;
                alu_src    = 1'b1;      // immediate offset
                alu_op     = `ALU_OP_MEM;
            end

            `OPCODE_STORE: begin
                mem_write  = 1'b1;
                alu_src    = 1'b1;      // immediate offset
                alu_op     = `ALU_OP_MEM;
            end

            `OPCODE_BRANCH: begin
                alu_src    = 1'b0;      // rs2
                alu_op     = `ALU_OP_BRANCH;
                branch     = 1'b1;
            end

            `OPCODE_JAL: begin
                reg_write  = 1'b1;
                mem_to_reg = `WB_PC_PLUS_4;
                jump       = 1'b1;
            end

            `OPCODE_JALR: begin
                reg_write  = 1'b1;
                mem_to_reg = `WB_PC_PLUS_4;
                alu_src    = 1'b1;      // immediate offset
                alu_op     = `ALU_OP_MEM; // PC target = rs1 + imm
                jalr       = 1'b1;
            end

            `OPCODE_LUI: begin
                reg_write  = 1'b1;
                mem_to_reg = `WB_IMM;   // Or through ALU PASS_B
                alu_src    = 1'b1;
                alu_op     = `ALU_OP_LUI;
            end

            `OPCODE_AUIPC: begin
                reg_write  = 1'b1;
                mem_to_reg = `WB_ALU;
                alu_src    = 1'b1;      // immediate
                alu_op     = `ALU_OP_MEM; // ALU adds PC + imm
                auipc      = 1'b1;
            end

            default: begin
                // Maintain defaults (NOP / safe state)
            end
        endcase
    end

endmodule
