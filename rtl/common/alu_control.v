`timescale 1ns / 1ps
`include "defines.vh"

module alu_control (
    input  wire [6:0] opcode,
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5,
    output reg  [3:0] alu_ctrl
);

    wire is_r_type = (opcode == `OPCODE_R_TYPE);

    always @(*) begin
        case (alu_op)
            `ALU_OP_MEM: begin
                // Loads, Stores, AUIPC all perform addition
                alu_ctrl = `ALU_ADD;
            end

            `ALU_OP_BRANCH: begin
                // Branch comparisons can use subtraction
                alu_ctrl = `ALU_SUB;
            end

            `ALU_OP_LUI: begin
                // Pass immediate through ALU
                alu_ctrl = `ALU_PASS_B;
            end

            `ALU_OP_R_I: begin
                case (funct3)
                    `FUNCT3_ADD_SUB: begin
                        // SUB is only for R-type with funct7[5]=1; ADDI is always ADD
                        if (is_r_type && funct7_5)
                            alu_ctrl = `ALU_SUB;
                        else
                            alu_ctrl = `ALU_ADD;
                    end
                    `FUNCT3_SLL:     alu_ctrl = `ALU_SLL;
                    `FUNCT3_SLT:     alu_ctrl = `ALU_SLT;
                    `FUNCT3_SLTU:    alu_ctrl = `ALU_SLTU;
                    `FUNCT3_XOR:     alu_ctrl = `ALU_XOR;
                    `FUNCT3_SRL_SRA: begin
                        // Both R-type (SRL/SRA) and I-type (SRLI/SRAI) use funct7[5]
                        if (funct7_5)
                            alu_ctrl = `ALU_SRA;
                        else
                            alu_ctrl = `ALU_SRL;
                    end
                    `FUNCT3_OR:      alu_ctrl = `ALU_OR;
                    `FUNCT3_AND:     alu_ctrl = `ALU_AND;
                    default:         alu_ctrl = `ALU_ADD;
                endcase
            end

            default: alu_ctrl = `ALU_ADD;
        endcase
    end

endmodule
