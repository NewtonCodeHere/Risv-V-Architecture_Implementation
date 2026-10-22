`timescale 1ns / 1ps
`include "../common/defines.vh"

module rv32i_pipelined #(
    parameter RESET_PC      = 32'h00000000,
    parameter IMEM_DEPTH    = 1024,
    parameter DMEM_DEPTH    = 1024,
    parameter MEM_INIT_FILE = ""
)(
    input  wire        clk,
    input  wire        rst_n,

    // Debug & Monitor Outputs
    output reg  [31:0] pc_if,
    output wire [31:0] instr_if,
    output wire [31:0] pc_id,
    output wire [31:0] instr_id,
    output wire [31:0] pc_ex,
    output wire [31:0] alu_result_ex,
    output wire [31:0] alu_result_mem,
    output wire        reg_write_wb,
    output wire [4:0]  rd_wb,
    output wire [31:0] wb_data,
    
    // Pipeline status flags
    output wire        pipeline_stall,
    output wire        pipeline_flush
);

    // ========================================================================
    // 1. INSTRUCTION FETCH (IF) STAGE
    // ========================================================================
    wire        pc_write;
    wire        if_id_write;
    wire        if_id_flush;
    wire        id_ex_flush;
    
    wire        branch_jump_taken_ex;
    wire [31:0] branch_jump_target_ex;
    
    wire [31:0] pc_plus_4_if = pc_if + 32'd4;
    reg  [31:0] next_pc_if;

    always @(*) begin
        if (branch_jump_taken_ex)
            next_pc_if = branch_jump_target_ex;
        else
            next_pc_if = pc_plus_4_if;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_if <= RESET_PC;
        end else if (branch_jump_taken_ex) begin
            pc_if <= branch_jump_target_ex;
        end else if (pc_write) begin
            pc_if <= next_pc_if;
        end
    end

    instruction_memory #(
        .MEM_DEPTH(IMEM_DEPTH),
        .MEM_INIT_FILE(MEM_INIT_FILE)
    ) imem (
        .addr(pc_if),
        .instr(instr_if)
    );

    // IF/ID Pipeline Register
    wire [31:0] pc_plus_4_id;

    if_id_reg pipe_if_id (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(if_id_write),
        .flush(if_id_flush),
        .pc_in(pc_if),
        .pc_plus_4_in(pc_plus_4_if),
        .instr_in(instr_if),
        .pc_out(pc_id),
        .pc_plus_4_out(pc_plus_4_id),
        .instr_out(instr_id)
    );

    // ========================================================================
    // 2. INSTRUCTION DECODE (ID) STAGE
    // ========================================================================
    wire [6:0] opcode_id = instr_id[6:0];
    wire [4:0] rd_id     = instr_id[11:7];
    wire [2:0] funct3_id = instr_id[14:12];
    wire [4:0] rs1_id    = instr_id[19:15];
    wire [4:0] rs2_id    = instr_id[24:20];
    wire [6:0] funct7_id = instr_id[31:25];

    wire       reg_write_id;
    wire [1:0] mem_to_reg_id;
    wire       mem_read_id;
    wire       mem_write_id;
    wire       alu_src_id;
    wire [1:0] alu_op_id;
    wire       branch_id;
    wire       jump_id;
    wire       jalr_id;
    wire       auipc_id;

    control_unit ctrl_unit_id (
        .opcode(opcode_id),
        .reg_write(reg_write_id),
        .mem_to_reg(mem_to_reg_id),
        .mem_read(mem_read_id),
        .mem_write(mem_write_id),
        .alu_src(alu_src_id),
        .alu_op(alu_op_id),
        .branch(branch_id),
        .jump(jump_id),
        .jalr(jalr_id),
        .auipc(auipc_id)
    );

    wire [31:0] imm_id;
    imm_gen imm_generator_id (
        .instr(instr_id),
        .imm(imm_id)
    );

    wire [31:0] rs1_data_id;
    wire [31:0] rs2_data_id;

    register_file reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(reg_write_wb),
        .rs1_addr(rs1_id),
        .rs2_addr(rs2_id),
        .rd_addr(rd_wb),
        .rd_data(wb_data),
        .rs1_data(rs1_data_id),
        .rs2_data(rs2_data_id)
    );

    // ID/EX Pipeline Register
    wire        reg_write_ex;
    wire [1:0]  mem_to_reg_ex;
    wire        mem_read_ex;
    wire        mem_write_ex;
    wire        alu_src_ex;
    wire [1:0]  alu_op_ex;
    wire        branch_ex;
    wire        jump_ex;
    wire        jalr_ex;
    wire        auipc_ex;
    wire [31:0] pc_plus_4_ex;
    wire [31:0] rs1_data_ex;
    wire [31:0] rs2_data_ex;
    wire [31:0] imm_ex;
    wire [4:0]  rs1_ex;
    wire [4:0]  rs2_ex;
    wire [4:0]  rd_ex;
    wire [2:0]  funct3_ex;
    wire        funct7_5_ex;
    wire [6:0]  opcode_ex;

    id_ex_reg pipe_id_ex (
        .clk(clk),
        .rst_n(rst_n),
        .flush(id_ex_flush),
        .reg_write_in(reg_write_id),
        .mem_to_reg_in(mem_to_reg_id),
        .mem_read_in(mem_read_id),
        .mem_write_in(mem_write_id),
        .alu_src_in(alu_src_id),
        .alu_op_in(alu_op_id),
        .branch_in(branch_id),
        .jump_in(jump_id),
        .jalr_in(jalr_id),
        .auipc_in(auipc_id),
        .pc_in(pc_id),
        .pc_plus_4_in(pc_plus_4_id),
        .rs1_data_in(rs1_data_id),
        .rs2_data_in(rs2_data_id),
        .imm_in(imm_id),
        .rs1_in(rs1_id),
        .rs2_in(rs2_id),
        .rd_in(rd_id),
        .funct3_in(funct3_id),
        .funct7_5_in(funct7_id[5]),
        .opcode_in(opcode_id),
        .reg_write_out(reg_write_ex),
        .mem_to_reg_out(mem_to_reg_ex),
        .mem_read_out(mem_read_ex),
        .mem_write_out(mem_write_ex),
        .alu_src_out(alu_src_ex),
        .alu_op_out(alu_op_ex),
        .branch_out(branch_ex),
        .jump_out(jump_ex),
        .jalr_out(jalr_ex),
        .auipc_out(auipc_ex),
        .pc_out(pc_ex),
        .pc_plus_4_out(pc_plus_4_ex),
        .rs1_data_out(rs1_data_ex),
        .rs2_data_out(rs2_data_ex),
        .imm_out(imm_ex),
        .rs1_out(rs1_ex),
        .rs2_out(rs2_ex),
        .rd_out(rd_ex),
        .funct3_out(funct3_ex),
        .funct7_5_out(funct7_5_ex),
        .opcode_out(opcode_ex)
    );

    // ========================================================================
    // 3. EXECUTE (EX) STAGE
    // ========================================================================
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;
    wire        forward_dmem_data;

    reg  [31:0] forwarded_a;
    reg  [31:0] forwarded_b;

    // Forwarding Mux A
    always @(*) begin
        case (forward_a)
            `FWD_MEM: forwarded_a = alu_result_mem;
            `FWD_WB:  forwarded_a = wb_data;
            default:  forwarded_a = rs1_data_ex;
        endcase
    end

    // Forwarding Mux B
    always @(*) begin
        case (forward_b)
            `FWD_MEM: forwarded_b = alu_result_mem;
            `FWD_WB:  forwarded_b = wb_data;
            default:  forwarded_b = rs2_data_ex;
        endcase
    end

    // ALU Operand Selection
    wire [31:0] alu_operand_a = auipc_ex ? pc_ex : forwarded_a;
    wire [31:0] alu_operand_b = alu_src_ex ? imm_ex : forwarded_b;

    wire [3:0] alu_ctrl_ex;
    alu_control alu_ctrl_unit_ex (
        .opcode(opcode_ex),
        .alu_op(alu_op_ex),
        .funct3(funct3_ex),
        .funct7_5(funct7_5_ex),
        .alu_ctrl(alu_ctrl_ex)
    );

    wire zero_ex;
    wire less_than_ex;
    wire less_than_unsigned_ex;

    alu core_alu_ex (
        .a(alu_operand_a),
        .b(alu_operand_b),
        .alu_ctrl(alu_ctrl_ex),
        .result(alu_result_ex),
        .zero(zero_ex),
        .less_than(less_than_ex),
        .less_than_unsigned(less_than_unsigned_ex)
    );

    // Branch condition evaluation
    reg branch_cond_met_ex;
    always @(*) begin
        case (funct3_ex)
            `FUNCT3_BEQ:  branch_cond_met_ex = zero_ex;
            `FUNCT3_BNE:  branch_cond_met_ex = !zero_ex;
            `FUNCT3_BLT:  branch_cond_met_ex = less_than_ex;
            `FUNCT3_BGE:  branch_cond_met_ex = !less_than_ex;
            `FUNCT3_BLTU: branch_cond_met_ex = less_than_unsigned_ex;
            `FUNCT3_BGEU: branch_cond_met_ex = !less_than_unsigned_ex;
            default:      branch_cond_met_ex = 1'b0;
        endcase
    end

    wire branch_taken_ex = branch_ex & branch_cond_met_ex;
    assign branch_jump_taken_ex = branch_taken_ex | jump_ex | jalr_ex;

    // Target addresses
    wire [31:0] branch_target_ex = pc_ex + imm_ex;
    wire [31:0] jalr_target_ex   = (forwarded_a + imm_ex) & ~32'd1;

    assign branch_jump_target_ex = jalr_ex ? jalr_target_ex : branch_target_ex;

    // EX/MEM Pipeline Register
    wire       reg_write_mem;
    wire [1:0] mem_to_reg_mem;
    wire       mem_read_mem;
    wire       mem_write_mem;
    wire [31:0] write_data_mem;
    wire [4:0]  rd_mem;
    wire [4:0]  rs2_mem;
    wire [2:0]  funct3_mem;
    wire [31:0] pc_plus_4_mem;
    wire [31:0] imm_mem;

    ex_mem_reg pipe_ex_mem (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write_in(reg_write_ex),
        .mem_to_reg_in(mem_to_reg_ex),
        .mem_read_in(mem_read_ex),
        .mem_write_in(mem_write_ex),
        .alu_result_in(alu_result_ex),
        .write_data_in(forwarded_b),
        .rd_in(rd_ex),
        .rs2_in(rs2_ex),
        .funct3_in(funct3_ex),
        .pc_plus_4_in(pc_plus_4_ex),
        .imm_in(imm_ex),
        .reg_write_out(reg_write_mem),
        .mem_to_reg_out(mem_to_reg_mem),
        .mem_read_out(mem_read_mem),
        .mem_write_out(mem_write_mem),
        .alu_result_out(alu_result_mem),
        .write_data_out(write_data_mem),
        .rd_out(rd_mem),
        .rs2_out(rs2_mem),
        .funct3_out(funct3_mem),
        .pc_plus_4_out(pc_plus_4_mem),
        .imm_out(imm_mem)
    );

    // ========================================================================
    // 4. MEMORY (MEM) STAGE
    // ========================================================================
    wire [31:0] dmem_write_data_mem = forward_dmem_data ? wb_data : write_data_mem;
    wire [31:0] dmem_read_data_mem;

    data_memory #(
        .MEM_DEPTH(DMEM_DEPTH)
    ) dmem (
        .clk(clk),
        .rst_n(rst_n),
        .mem_read(mem_read_mem),
        .mem_write(mem_write_mem),
        .funct3(funct3_mem),
        .addr(alu_result_mem),
        .write_data(dmem_write_data_mem),
        .read_data(dmem_read_data_mem)
    );

    // MEM/WB Pipeline Register
    wire [1:0]  mem_to_reg_wb;
    wire [31:0] alu_result_wb;
    wire [31:0] dmem_read_data_wb;
    wire [31:0] pc_plus_4_wb;
    wire [31:0] imm_wb;

    mem_wb_reg pipe_mem_wb (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write_in(reg_write_mem),
        .mem_to_reg_in(mem_to_reg_mem),
        .alu_result_in(alu_result_mem),
        .dmem_read_data_in(dmem_read_data_mem),
        .rd_in(rd_mem),
        .pc_plus_4_in(pc_plus_4_mem),
        .imm_in(imm_mem),
        .reg_write_out(reg_write_wb),
        .mem_to_reg_out(mem_to_reg_wb),
        .alu_result_out(alu_result_wb),
        .dmem_read_data_out(dmem_read_data_wb),
        .rd_out(rd_wb),
        .pc_plus_4_out(pc_plus_4_wb),
        .imm_out(imm_wb)
    );

    // ========================================================================
    // 5. WRITE-BACK (WB) STAGE
    // ========================================================================
    reg [31:0] wb_data_mux;
    always @(*) begin
        case (mem_to_reg_wb)
            `WB_ALU:      wb_data_mux = alu_result_wb;
            `WB_MEM:      wb_data_mux = dmem_read_data_wb;
            `WB_PC_PLUS_4:wb_data_mux = pc_plus_4_wb;
            `WB_IMM:      wb_data_mux = imm_wb;
            default:      wb_data_mux = alu_result_wb;
        endcase
    end

    assign wb_data = wb_data_mux;

    // ========================================================================
    // HAZARD DETECTION & FORWARDING UNIT
    // ========================================================================
    hazard_unit hazard_ctrl (
        .id_ex_rs1(rs1_ex),
        .id_ex_rs2(rs2_ex),
        .ex_mem_rd(rd_mem),
        .ex_mem_reg_write(reg_write_mem),
        .mem_wb_rd(rd_wb),
        .mem_wb_reg_write(reg_write_wb),
        .ex_mem_rs2(rs2_mem),
        .ex_mem_mem_write(mem_write_mem),
        .if_id_rs1(rs1_id),
        .if_id_rs2(rs2_id),
        .if_id_opcode(opcode_id),
        .id_ex_rd(rd_ex),
        .id_ex_mem_read(mem_read_ex),
        .branch_jump_taken(branch_jump_taken_ex),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .forward_dmem_data(forward_dmem_data),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush)
    );

    // Pipeline status monitoring
    assign pipeline_stall = !pc_write;
    assign pipeline_flush = branch_jump_taken_ex;

endmodule
