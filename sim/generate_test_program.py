# RV32I Assembler & Simulator Verification Script
# Translates RV32I assembly instructions to machine code hex

def encode_r(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_i(imm, rs1, funct3, rd, opcode):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_s(imm, rs2, rs1, funct3, opcode):
    imm11_5 = (imm >> 5) & 0x7F
    imm4_0  = imm & 0x1F
    return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm4_0 << 7) | opcode

def encode_b(imm, rs2, rs1, funct3, opcode):
    imm12   = (imm >> 12) & 0x1
    imm10_5 = (imm >> 5) & 0x3F
    imm4_1  = (imm >> 1) & 0xF
    imm11   = (imm >> 11) & 0x1
    return (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm4_1 << 8) | (imm11 << 7) | opcode

def encode_u(imm, rd, opcode):
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | opcode

def encode_j(imm, rd, opcode):
    imm20   = (imm >> 20) & 0x1
    imm10_1 = (imm >> 1) & 0x3FF
    imm11   = (imm >> 11) & 0x1
    imm19_12= (imm >> 12) & 0xFF
    return (imm20 << 31) | (imm10_1 << 21) | (imm11 << 20) | (imm19_12 << 12) | (rd << 7) | opcode

# Opcodes
OP_R   = 0x33
OP_I   = 0x13
OP_L   = 0x03
OP_S   = 0x23
OP_B   = 0x63
OP_JAL = 0x6F
OP_JALR= 0x67
OP_LUI = 0x37
OP_AUIPC= 0x17

instructions = [
    # 0x00: addi x1, x0, 10
    ("addi x1, x0, 10", encode_i(10, 0, 0, 1, OP_I)),
    # 0x04: addi x2, x0, 20
    ("addi x2, x0, 20", encode_i(20, 0, 0, 2, OP_I)),
    # 0x08: add x3, x1, x2
    ("add x3, x1, x2", encode_r(0, 2, 1, 0, 3, OP_R)),
    # 0x0C: sub x4, x3, x1
    ("sub x4, x3, x1", encode_r(0x20, 1, 3, 0, 4, OP_R)),
    # 0x10: sll x5, x1, x1
    ("sll x5, x1, x1", encode_r(0, 1, 1, 1, 5, OP_R)),
    # 0x14: slt x6, x1, x2
    ("slt x6, x1, x2", encode_r(0, 2, 1, 2, 6, OP_R)),
    # 0x18: xor x7, x1, x2
    ("xor x7, x1, x2", encode_r(0, 2, 1, 4, 7, OP_R)),
    # 0x1C: or x8, x1, x2
    ("or x8, x1, x2", encode_r(0, 2, 1, 6, 8, OP_R)),
    # 0x20: and x9, x1, x2
    ("and x9, x1, x2", encode_r(0, 2, 1, 7, 9, OP_R)),
    # 0x24: sw x3, 0(x0)
    ("sw x3, 0(x0)", encode_s(0, 3, 0, 2, OP_S)),
    # 0x28: lw x10, 0(x0)
    ("lw x10, 0(x0)", encode_i(0, 0, 2, 10, OP_L)),
    # 0x2C: beq x3, x10, +8 (to 0x34)
    ("beq x3, x10, 8", encode_b(8, 10, 3, 0, OP_B)),
    # 0x30: addi x11, x0, 99 (should be skipped)
    ("addi x11, x0, 99", encode_i(99, 0, 0, 11, OP_I)),
    # 0x34: addi x11, x0, 1 (branch target)
    ("addi x11, x0, 1", encode_i(1, 0, 0, 11, OP_I)),
    # 0x38: jal x12, +8 (to 0x40)
    ("jal x12, 8", encode_j(8, 12, OP_JAL)),
    # 0x3C: addi x13, x0, 99 (should be skipped)
    ("addi x13, x0, 99", encode_i(99, 0, 0, 13, OP_I)),
    # 0x40: addi x13, x0, 2 (jump target)
    ("addi x13, x0, 2", encode_i(2, 0, 0, 13, OP_I)),
    # 0x44: lui x14, 0x12345
    ("lui x14, 0x12345", encode_u(0x12345, 14, OP_LUI)),
    # 0x48: auipc x15, 0 (should be 0x48)
    ("auipc x15, 0", encode_u(0, 15, OP_AUIPC)),
    # 0x4C: addi x31, x0, 42 (magic completion code)
    ("addi x31, x0, 42", encode_i(42, 0, 0, 31, OP_I)),
    # 0x50: beq x0, x0, 0 (infinite loop end)
    ("beq x0, x0, 0", encode_b(0, 0, 0, 0, OP_B))
]

with open("d:/Verilog RISC V Architecture/programs/test_program.hex", "w") as f_hex, \
     open("d:/Verilog RISC V Architecture/programs/test_program.asm", "w") as f_asm:
    f_asm.write("# RISC-V RV32I Test Program\n# Tests ALU, memory, branch, jump, lui, auipc\n\n")
    for pc_idx, (asm_line, code) in enumerate(instructions):
        f_hex.write(f"{code:08x}\n")
        f_asm.write(f"0x{pc_idx*4:04x}: {asm_line:<25} # 0x{code:08x}\n")

print(f"Generated {len(instructions)} instructions successfully.")
