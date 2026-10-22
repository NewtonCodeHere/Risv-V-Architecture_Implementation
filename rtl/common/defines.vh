`ifndef DEFINES_VH
`define DEFINES_VH

// ============================================================================
// RISC-V RV32I Processor Definitions
// Supported ISA: RV32I Base Integer Instruction Set
// ============================================================================

// ----------------------------------------------------------------------------
// 7-bit Major Opcodes (instr[6:0])
// ----------------------------------------------------------------------------
`define OPCODE_R_TYPE       7'b0110011  // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
`define OPCODE_I_TYPE       7'b0010011  // ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI
`define OPCODE_LOAD         7'b0000011  // LB, LH, LW, LBU, LHU
`define OPCODE_STORE        7'b0100011  // SB, SH, SW
`define OPCODE_BRANCH       7'b1100011  // BEQ, BNE, BLT, BGE, BLTU, BGEU
`define OPCODE_JAL          7'b1101111  // JAL
`define OPCODE_JALR         7'b1100111  // JALR
`define OPCODE_LUI          7'b0110111  // LUI
`define OPCODE_AUIPC        7'b0010111  // AUIPC
`define OPCODE_SYSTEM       7'b1110011  // ECALL, EBREAK, CSRs

// ----------------------------------------------------------------------------
// Funct3 Field Definitions
// ----------------------------------------------------------------------------
// R-Type and I-Type ALU funct3
`define FUNCT3_ADD_SUB      3'b000      // ADD / SUB / ADDI
`define FUNCT3_SLL          3'b001      // SLL / SLLI
`define FUNCT3_SLT          3'b010      // SLT / SLTI
`define FUNCT3_SLTU         3'b011      // SLTU / SLTIU
`define FUNCT3_XOR          3'b100      // XOR / XORI
`define FUNCT3_SRL_SRA      3'b101      // SRL / SRLI / SRA / SRAI
`define FUNCT3_OR           3'b110      // OR / ORI
`define FUNCT3_AND          3'b111      // AND / ANDI

// Branch funct3
`define FUNCT3_BEQ          3'b000
`define FUNCT3_BNE          3'b001
`define FUNCT3_BLT          3'b100
`define FUNCT3_BGE          3'b101
`define FUNCT3_BLTU         3'b110
`define FUNCT3_BGEU         3'b111

// Load funct3
`define FUNCT3_LB           3'b000
`define FUNCT3_LH           3'b001
`define FUNCT3_LW           3'b010
`define FUNCT3_LBU          3'b100
`define FUNCT3_LHU          3'b101

// Store funct3
`define FUNCT3_SB           3'b000
`define FUNCT3_SH           3'b001
`define FUNCT3_SW           3'b010

// ----------------------------------------------------------------------------
// Funct7 Field Definitions
// ----------------------------------------------------------------------------
`define FUNCT7_DEFAULT      7'b0000000
`define FUNCT7_ALT          7'b0100000  // SUB, SRA

// ----------------------------------------------------------------------------
// ALU Control Operation Codes (4 bits)
// ----------------------------------------------------------------------------
`define ALU_ADD             4'b0000
`define ALU_SUB             4'b0001
`define ALU_SLL             4'b0010
`define ALU_SLT             4'b0011
`define ALU_SLTU            4'b0100
`define ALU_XOR             4'b0101
`define ALU_SRL             4'b0110
`define ALU_SRA             4'b0111
`define ALU_OR              4'b1000
`define ALU_AND             4'b1001
`define ALU_PASS_B          4'b1010

// ----------------------------------------------------------------------------
// Main Control ALUOp Codes (2 bits)
// ----------------------------------------------------------------------------
`define ALU_OP_MEM          2'b00       // Load / Store / AUIPC (add offset)
`define ALU_OP_BRANCH       2'b01       // Branch comparisons
`define ALU_OP_R_I          2'b10       // R-type and I-type ALU arithmetic
`define ALU_OP_LUI          2'b11       // LUI pass immediate

// ----------------------------------------------------------------------------
// Writeback Source Multiplexer Selection (2 bits)
// ----------------------------------------------------------------------------
`define WB_ALU              2'b00       // ALU Result
`define WB_MEM              2'b01       // Data Memory Read Data
`define WB_PC_PLUS_4        2'b10       // Return Address PC + 4 (JAL, JALR)
`define WB_IMM              2'b11       // Direct Immediate (LUI)

// ----------------------------------------------------------------------------
// Forwarding Control Values (2 bits)
// ----------------------------------------------------------------------------
`define FWD_NONE            2'b00       // Use ID/EX register value
`define FWD_MEM             2'b10       // Forward from EX/MEM stage
`define FWD_WB              2'b01       // Forward from MEM/WB stage

`endif // DEFINES_VH
