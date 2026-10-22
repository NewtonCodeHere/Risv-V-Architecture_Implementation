# RV32I Pipeline Hazard Test Program Generator

from generate_test_program import encode_r, encode_i, encode_s, encode_b, OP_R, OP_I, OP_L, OP_S, OP_B

hazard_instrs = [
    # 0x00: Initialize registers
    ("addi x1, x0, 10", encode_i(10, 0, 0, 1, OP_I)),
    ("addi x2, x0, 20", encode_i(20, 0, 0, 2, OP_I)),
    
    # 0x08: EX-to-EX Hazard: x3 used immediately by next instruction
    ("add  x3, x1, x2", encode_r(0, 2, 1, 0, 3, OP_R)),     # x3 = 30
    ("sub  x4, x3, x1", encode_r(0x20, 1, 3, 0, 4, OP_R)), # x4 = 30 - 10 = 20 (EX-to-EX forward x3)
    
    # 0x10: MEM-to-EX Hazard: x3 used 2 cycles later
    ("addi x5, x0, 5",  encode_i(5, 0, 0, 5, OP_I)),
    ("add  x6, x4, x3", encode_r(0, 3, 4, 0, 6, OP_R)),     # x6 = 20 + 30 = 50 (MEM-to-EX forward x3, EX-to-EX forward x4)
    
    # 0x18: Load-Use Hazard: lw followed immediately by dependent instruction
    ("sw   x6, 0(x0)",  encode_s(0, 6, 0, 2, OP_S)),         # mem[0] = 50
    ("lw   x7, 0(x0)",  encode_i(0, 0, 2, 7, OP_L)),         # x7 = 50
    ("addi x8, x7, 100",encode_i(100, 7, 0, 8, OP_I)),      # x8 = 150 (Stalls 1 cycle for Load-Use, then forwards)
    
    # 0x24: Store Forwarding: dependent store data
    ("addi x9, x0, 77", encode_i(77, 0, 0, 9, OP_I)),       # x9 = 77
    ("sw   x9, 4(x0)",  encode_s(4, 9, 0, 2, OP_S)),         # mem[4] = 77 (EX-to-MEM forward)
    ("lw   x10, 4(x0)", encode_i(4, 0, 2, 10, OP_L)),       # x10 = 77
    
    # 0x30: Branch flush verification
    ("beq  x9, x10, 8", encode_b(8, 10, 9, 0, OP_B)),       # Branch taken to +8 (0x38)
    ("addi x11, x0, 999", encode_i(999, 0, 0, 11, OP_I)),   # Should be flushed!
    ("addi x11, x0, 1",   encode_i(1, 0, 0, 11, OP_I)),     # Target: x11 = 1
    
    # End flag
    ("addi x31, x0, 123", encode_i(123, 0, 0, 31, OP_I)),   # Completion code 123
    ("beq  x0, x0, 0",    encode_b(0, 0, 0, 0, OP_B))        # Infinite loop
]

with open("d:/Verilog RISC V Architecture/programs/hazard_test.hex", "w") as f_hex, \
     open("d:/Verilog RISC V Architecture/programs/hazard_test.asm", "w") as f_asm:
    f_asm.write("# RISC-V Pipeline Hazard Test Program\n# Tests RAW EX-EX, MEM-EX, Load-Use stall, Store forward, Branch flush\n\n")
    for pc_idx, (asm_line, code) in enumerate(hazard_instrs):
        f_hex.write(f"{code:08x}\n")
        f_asm.write(f"0x{pc_idx*4:04x}: {asm_line:<25} # 0x{code:08x}\n")

print(f"Generated {len(hazard_instrs)} hazard test instructions successfully.")
