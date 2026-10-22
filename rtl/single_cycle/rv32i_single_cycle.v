`timescale 1ns / 1ps
`include "../common/defines.vh"

module rv32i_single_cycle #(
    parameter RESET_PC      = 32'h00000000,
    parameter IMEM_DEPTH    = 1024,
    parameter DMEM_DEPTH    = 1024,
    parameter MEM_INIT_FILE = ""
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // Debug & Monitor Outputs
    output reg  [31:0] pc,
    output wire [31:0] instr,
    output wire [31:0] alu_result,
    output wire [31:0] dmem_read_data,
    output wire        reg_write_out,
    output wire [4:0]  rd_addr_out,
    output wire [31:0] rd_data_out
);

    // ------------------------------------------------------------------------
    // Program Counter Logic
    // ------------------------------------------------------------------------
    reg  [31:0] next_pc;
    wire [31:0] pc_plus_4 = pc + 32'd4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= RESET_PC;
        end else begin
            pc <= next_pc;
        end
    end

    // ------------------------------------------------------------------------
    // Instruction Memory
    // ------------------------------------------------------------------------
    instruction_memory #(
        .MEM_DEPTH(IMEM_DEPTH),
        .MEM_INIT_FILE(MEM_INIT_FILE)
    ) imem (
        .addr(pc),
        .instr(instr)
    );

    // ------------------------------------------------------------------------
    // Instruction Fields
    // ------------------------------------------------------------------------
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

    // ------------------------------------------------------------------------
    // Control Unit
    // ------------------------------------------------------------------------
    wire       reg_write;
    wire [1:0] mem_to_reg;
    wire       mem_read;
    wire       mem_write;
    wire       alu_src;
    wire [1:0] alu_op;
    wire       branch;
    wire       jump;
    wire       jalr;
    wire       auipc;

    control_unit ctrl_unit (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .auipc(auipc)
    );

    // ------------------------------------------------------------------------
    // Immediate Generator
    // ------------------------------------------------------------------------
    wire [31:0] imm;

    imm_gen immediate_generator (
        .instr(instr),
        .imm(imm)
    );

    // ------------------------------------------------------------------------
    // Register File
    // ------------------------------------------------------------------------
    reg  [31:0] rd_data;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    register_file reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(reg_write),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // ------------------------------------------------------------------------
    // ALU Control & ALU
    // ------------------------------------------------------------------------
    wire [3:0]  alu_ctrl;
    wire        zero;
    wire        less_than;
    wire        less_than_unsigned;

    alu_control alu_ctrl_unit (
        .opcode(opcode),
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7_5(funct7[5]),
        .alu_ctrl(alu_ctrl)
    );

    // Operand A selection: PC for AUIPC, else rs1_data
    wire [31:0] alu_operand_a = auipc ? pc : rs1_data;
    // Operand B selection: immediate if alu_src is high, else rs2_data
    wire [31:0] alu_operand_b = alu_src ? imm : rs2_data;

    alu core_alu (
        .a(alu_operand_a),
        .b(alu_operand_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero),
        .less_than(less_than),
        .less_than_unsigned(less_than_unsigned)
    );

    // ------------------------------------------------------------------------
    // Branch Condition Evaluation
    // ------------------------------------------------------------------------
    reg branch_condition_met;

    always @(*) begin
        case (funct3)
            `FUNCT3_BEQ:  branch_condition_met = zero;
            `FUNCT3_BNE:  branch_condition_met = !zero;
            `FUNCT3_BLT:  branch_condition_met = less_than;
            `FUNCT3_BGE:  branch_condition_met = !less_than;
            `FUNCT3_BLTU: branch_condition_met = less_than_unsigned;
            `FUNCT3_BGEU: branch_condition_met = !less_than_unsigned;
            default:      branch_condition_met = 1'b0;
        endcase
    end

    wire branch_taken = branch & branch_condition_met;

    // ------------------------------------------------------------------------
    // Next PC Calculation
    // ------------------------------------------------------------------------
    wire [31:0] pc_branch = pc + imm;
    wire [31:0] pc_jalr   = (rs1_data + imm) & ~32'd1;

    always @(*) begin
        if (jalr) begin
            next_pc = pc_jalr;
        end else if (jump) begin
            next_pc = pc_branch;
        end else if (branch_taken) begin
            next_pc = pc_branch;
        end else begin
            next_pc = pc_plus_4;
        end
    end

    // ------------------------------------------------------------------------
    // Data Memory
    // ------------------------------------------------------------------------
    data_memory #(
        .MEM_DEPTH(DMEM_DEPTH)
    ) dmem (
        .clk(clk),
        .rst_n(rst_n),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .addr(alu_result),
        .write_data(rs2_data),
        .read_data(dmem_read_data)
    );

    // ------------------------------------------------------------------------
    // Write-Back Multiplexer
    // ------------------------------------------------------------------------
    always @(*) begin
        case (mem_to_reg)
            `WB_ALU:      rd_data = alu_result;
            `WB_MEM:      rd_data = dmem_read_data;
            `WB_PC_PLUS_4:rd_data = pc_plus_4;
            `WB_IMM:      rd_data = imm;
            default:      rd_data = alu_result;
        endcase
    end

    // ------------------------------------------------------------------------
    // Debug & Monitor Outputs
    // ------------------------------------------------------------------------
    assign reg_write_out = reg_write;
    assign rd_addr_out   = rd;
    assign rd_data_out   = rd_data;

endmodule
