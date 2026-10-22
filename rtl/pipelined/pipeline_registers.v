`timescale 1ns / 1ps
`include "../common/defines.vh"

// ============================================================================
// IF/ID Pipeline Register
// ============================================================================
module if_id_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        write_en,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus_4_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus_4_out,
    output reg  [31:0] instr_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out        <= 32'b0;
            pc_plus_4_out <= 32'b0;
            instr_out     <= 32'h00000013; // NOP
        end else if (flush) begin
            pc_out        <= 32'b0;
            pc_plus_4_out <= 32'b0;
            instr_out     <= 32'h00000013; // NOP (addi x0, x0, 0)
        end else if (write_en) begin
            pc_out        <= pc_in;
            pc_plus_4_out <= pc_plus_4_in;
            instr_out     <= instr_in;
        end
    end

endmodule

// ============================================================================
// ID/EX Pipeline Register
// ============================================================================
module id_ex_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,
    
    // Control inputs
    input  wire        reg_write_in,
    input  wire [1:0]  mem_to_reg_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        alu_src_in,
    input  wire [1:0]  alu_op_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire        jalr_in,
    input  wire        auipc_in,
    
    // Data inputs
    input  wire [31:0] pc_in,
    input  wire [31:0] pc_plus_4_in,
    input  wire [31:0] rs1_data_in,
    input  wire [31:0] rs2_data_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,
    input  wire [2:0]  funct3_in,
    input  wire        funct7_5_in,
    input  wire [6:0]  opcode_in,
    
    // Control outputs
    output reg         reg_write_out,
    output reg  [1:0]  mem_to_reg_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         alu_src_out,
    output reg  [1:0]  alu_op_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg         jalr_out,
    output reg         auipc_out,
    
    // Data outputs
    output reg  [31:0] pc_out,
    output reg  [31:0] pc_plus_4_out,
    output reg  [31:0] rs1_data_out,
    output reg  [31:0] rs2_data_out,
    output reg  [31:0] imm_out,
    output reg  [4:0]  rs1_out,
    output reg  [4:0]  rs2_out,
    output reg  [4:0]  rd_out,
    output reg  [2:0]  funct3_out,
    output reg         funct7_5_out,
    output reg  [6:0]  opcode_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= `WB_ALU;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            alu_src_out    <= 1'b0;
            alu_op_out     <= `ALU_OP_MEM;
            branch_out     <= 1'b0;
            jump_out       <= 1'b0;
            jalr_out       <= 1'b0;
            auipc_out      <= 1'b0;
            pc_out         <= 32'b0;
            pc_plus_4_out  <= 32'b0;
            rs1_data_out   <= 32'b0;
            rs2_data_out   <= 32'b0;
            imm_out        <= 32'b0;
            rs1_out        <= 5'b0;
            rs2_out        <= 5'b0;
            rd_out         <= 5'b0;
            funct3_out     <= 3'b0;
            funct7_5_out   <= 1'b0;
            opcode_out     <= 7'b0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            alu_src_out    <= alu_src_in;
            alu_op_out     <= alu_op_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            jalr_out       <= jalr_in;
            auipc_out      <= auipc_in;
            pc_out         <= pc_in;
            pc_plus_4_out  <= pc_plus_4_in;
            rs1_data_out   <= rs1_data_in;
            rs2_data_out   <= rs2_data_in;
            imm_out        <= imm_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            funct3_out     <= funct3_in;
            funct7_5_out   <= funct7_5_in;
            opcode_out     <= opcode_in;
        end
    end

endmodule

// ============================================================================
// EX/MEM Pipeline Register
// ============================================================================
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control inputs
    input  wire        reg_write_in,
    input  wire [1:0]  mem_to_reg_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    
    // Data inputs
    input  wire [31:0] alu_result_in,
    input  wire [31:0] write_data_in,
    input  wire [4:0]  rd_in,
    input  wire [4:0]  rs2_in,
    input  wire [2:0]  funct3_in,
    input  wire [31:0] pc_plus_4_in,
    input  wire [31:0] imm_in,
    
    // Control outputs
    output reg         reg_write_out,
    output reg  [1:0]  mem_to_reg_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    
    // Data outputs
    output reg  [31:0] alu_result_out,
    output reg  [31:0] write_data_out,
    output reg  [4:0]  rd_out,
    output reg  [4:0]  rs2_out,
    output reg  [2:0]  funct3_out,
    output reg  [31:0] pc_plus_4_out,
    output reg  [31:0] imm_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= `WB_ALU;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            alu_result_out <= 32'b0;
            write_data_out <= 32'b0;
            rd_out         <= 5'b0;
            rs2_out        <= 5'b0;
            funct3_out     <= 3'b0;
            pc_plus_4_out  <= 32'b0;
            imm_out        <= 32'b0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            alu_result_out <= alu_result_in;
            write_data_out <= write_data_in;
            rd_out         <= rd_in;
            rs2_out        <= rs2_in;
            funct3_out     <= funct3_in;
            pc_plus_4_out  <= pc_plus_4_in;
            imm_out        <= imm_in;
        end
    end

endmodule

// ============================================================================
// MEM/WB Pipeline Register
// ============================================================================
module mem_wb_reg (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control inputs
    input  wire        reg_write_in,
    input  wire [1:0]  mem_to_reg_in,
    
    // Data inputs
    input  wire [31:0] alu_result_in,
    input  wire [31:0] dmem_read_data_in,
    input  wire [4:0]  rd_in,
    input  wire [31:0] pc_plus_4_in,
    input  wire [31:0] imm_in,
    
    // Control outputs
    output reg         reg_write_out,
    output reg  [1:0]  mem_to_reg_out,
    
    // Data outputs
    output reg  [31:0] alu_result_out,
    output reg  [31:0] dmem_read_data_out,
    output reg  [4:0]  rd_out,
    output reg  [31:0] pc_plus_4_out,
    output reg  [31:0] imm_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out      <= 1'b0;
            mem_to_reg_out     <= `WB_ALU;
            alu_result_out     <= 32'b0;
            dmem_read_data_out <= 32'b0;
            rd_out             <= 5'b0;
            pc_plus_4_out      <= 32'b0;
            imm_out            <= 32'b0;
        end else begin
            reg_write_out      <= reg_write_in;
            mem_to_reg_out     <= mem_to_reg_in;
            alu_result_out     <= alu_result_in;
            dmem_read_data_out <= dmem_read_data_in;
            rd_out             <= rd_in;
            pc_plus_4_out      <= pc_plus_4_in;
            imm_out            <= imm_in;
        end
    end

endmodule
