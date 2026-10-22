# RISC-V Pipeline Hazard Test Program
# Tests RAW EX-EX, MEM-EX, Load-Use stall, Store forward, Branch flush

0x0000: addi x1, x0, 10           # 0x00a00093
0x0004: addi x2, x0, 20           # 0x01400113
0x0008: add  x3, x1, x2           # 0x002081b3
0x000c: sub  x4, x3, x1           # 0x40118233
0x0010: addi x5, x0, 5            # 0x00500293
0x0014: add  x6, x4, x3           # 0x00320333
0x0018: sw   x6, 0(x0)            # 0x00602023
0x001c: lw   x7, 0(x0)            # 0x00002383
0x0020: addi x8, x7, 100          # 0x06438413
0x0024: addi x9, x0, 77           # 0x04d00493
0x0028: sw   x9, 4(x0)            # 0x00902223
0x002c: lw   x10, 4(x0)           # 0x00402503
0x0030: beq  x9, x10, 8           # 0x00a48463
0x0034: addi x11, x0, 999         # 0x3e700593
0x0038: addi x11, x0, 1           # 0x00100593
0x003c: addi x31, x0, 123         # 0x07b00f93
0x0040: beq  x0, x0, 0            # 0x00000063
