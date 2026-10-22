`timescale 1ns / 1ps
`include "defines.vh"

module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);

    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            `OPCODE_I_TYPE,
            `OPCODE_LOAD,
            `OPCODE_JALR: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            `OPCODE_STORE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            `OPCODE_BRANCH: begin
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            `OPCODE_LUI,
            `OPCODE_AUIPC: begin
                imm = {instr[31:12], 12'b0};
            end

            `OPCODE_JAL: begin
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            default: begin
                imm = 32'b0;
            end
        endcase
    end

endmodule
