# RISC-V RV32I Test Program
# Tests ALU, memory, branch, jump, lui, auipc

0x0000: addi x1, x0, 10           # 0x00a00093
0x0004: addi x2, x0, 20           # 0x01400113
0x0008: add x3, x1, x2            # 0x002081b3
0x000c: sub x4, x3, x1            # 0x40118233
0x0010: sll x5, x1, x1            # 0x001092b3
0x0014: slt x6, x1, x2            # 0x0020a333
0x0018: xor x7, x1, x2            # 0x0020c3b3
0x001c: or x8, x1, x2             # 0x0020e433
0x0020: and x9, x1, x2            # 0x0020f4b3
0x0024: sw x3, 0(x0)              # 0x00302023
0x0028: lw x10, 0(x0)             # 0x00002503
0x002c: beq x3, x10, 8            # 0x00a18463
0x0030: addi x11, x0, 99          # 0x06300593
0x0034: addi x11, x0, 1           # 0x00100593
0x0038: jal x12, 8                # 0x0080066f
0x003c: addi x13, x0, 99          # 0x06300693
0x0040: addi x13, x0, 2           # 0x00200693
0x0044: lui x14, 0x12345          # 0x12345737
0x0048: auipc x15, 0              # 0x00000797
0x004c: addi x31, x0, 42          # 0x02a00f93
0x0050: beq x0, x0, 0             # 0x00000063
