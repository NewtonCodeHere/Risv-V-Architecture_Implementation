# RISC-V RV32I Instruction Set Architecture Reference

This processor implements the standard **RV32I Base Integer Instruction Set** (32-bit architecture with 32 general-purpose registers `x0`–`x31`).

---

## 1. Instruction Formats

All RV32I instructions are 32 bits long and aligned on 4-byte boundaries.

```
Type      31                  25 24        20 19        15 14   12 11          7 6            0
R-type   |      funct7          |    rs2     |    rs1     | funct3 |     rd      |    opcode   |
I-type   |            imm[11:0]              |    rs1     | funct3 |     rd      |    opcode   |
S-type   |   imm[11:5]   |    rs2     |    rs1     | funct3 |  imm[4:0]   |    opcode   |
B-type   | imm[12|10:5]  |    rs2     |    rs1     | funct3 | imm[4:1|11] |    opcode   |
U-type   |                    imm[31:12]                       |     rd      |    opcode   |
J-type   |                imm[20|10:1|11|19:12]                |     rd      |    opcode   |
```

---

## 2. Implemented Instructions

### 2.1 R-Type Instructions (`opcode = 0110011`)
| Instruction | Funct3 | Funct7   | Description | Operation |
|---|---|---|---|---|
| `ADD`  | `000` | `0000000` | Addition | `R[rd] = R[rs1] + R[rs2]` |
| `SUB`  | `000` | `0100000` | Subtraction | `R[rd] = R[rs1] - R[rs2]` |
| `SLL`  | `001` | `0000000` | Shift Left Logical | `R[rd] = R[rs1] << R[rs2][4:0]` |
| `SLT`  | `010` | `0000000` | Set Less Than (signed) | `R[rd] = (R[rs1] < R[rs2]) ? 1 : 0` |
| `SLTU` | `011` | `0000000` | Set Less Than Unsigned | `R[rd] = (R[rs1] <u R[rs2]) ? 1 : 0` |
| `XOR`  | `100` | `0000000` | Bitwise Exclusive-OR | `R[rd] = R[rs1] ^ R[rs2]` |
| `SRL`  | `101` | `0000000` | Shift Right Logical | `R[rd] = R[rs1] >> R[rs2][4:0]` |
| `SRA`  | `101` | `0100000` | Shift Right Arithmetic | `R[rd] = R[rs1] >>> R[rs2][4:0]` |
| `OR`   | `110` | `0000000` | Bitwise OR | `R[rd] = R[rs1] \| R[rs2]` |
| `AND`  | `111` | `0000000` | Bitwise AND | `R[rd] = R[rs1] & R[rs2]` |

---

### 2.2 I-Type Integer Computational Instructions (`opcode = 0010011`)
| Instruction | Funct3 | Funct7/imm[11:5] | Description | Operation |
|---|---|---|---|---|
| `ADDI`  | `000` | — | Add Immediate | `R[rd] = R[rs1] + sext(imm)` |
| `SLTI`  | `010` | — | Set Less Than Imm (signed) | `R[rd] = (R[rs1] < sext(imm)) ? 1 : 0` |
| `SLTIU` | `011` | — | Set Less Than Imm Unsigned | `R[rd] = (R[rs1] <u sext(imm)) ? 1 : 0` |
| `XORI`  | `100` | — | Exclusive-OR Immediate | `R[rd] = R[rs1] ^ sext(imm)` |
| `ORI`   | `110` | — | OR Immediate | `R[rd] = R[rs1] \| sext(imm)` |
| `ANDI`  | `111` | — | AND Immediate | `R[rd] = R[rs1] & sext(imm)` |
| `SLLI`  | `001` | `0000000` | Shift Left Logical Imm | `R[rd] = R[rs1] << shamt[4:0]` |
| `SRLI`  | `101` | `0000000` | Shift Right Logical Imm | `R[rd] = R[rs1] >> shamt[4:0]` |
| `SRAI`  | `101` | `0100000` | Shift Right Arith Imm | `R[rd] = R[rs1] >>> shamt[4:0]` |

---

### 2.3 Load Instructions (`opcode = 0000011`)
| Instruction | Funct3 | Description | Operation |
|---|---|---|---|
| `LB`  | `000` | Load Byte (signed) | `R[rd] = sext(Mem8[R[rs1] + imm])` |
| `LH`  | `001` | Load Halfword (signed) | `R[rd] = sext(Mem16[R[rs1] + imm])` |
| `LW`  | `010` | Load Word | `R[rd] = Mem32[R[rs1] + imm]` |
| `LBU` | `100` | Load Byte Unsigned | `R[rd] = zext(Mem8[R[rs1] + imm])` |
| `LHU` | `101` | Load Halfword Unsigned | `R[rd] = zext(Mem16[R[rs1] + imm])` |

---

### 2.4 Store Instructions (`opcode = 0100011`)
| Instruction | Funct3 | Description | Operation |
|---|---|---|---|
| `SB` | `000` | Store Byte | `Mem8[R[rs1] + imm] = R[rs2][7:0]` |
| `SH` | `001` | Store Halfword | `Mem16[R[rs1] + imm] = R[rs2][15:0]` |
| `SW` | `010` | Store Word | `Mem32[R[rs1] + imm] = R[rs2][31:0]` |

---

### 2.5 Branch Instructions (`opcode = 1100011`)
| Instruction | Funct3 | Description | Condition |
|---|---|---|---|
| `BEQ`  | `000` | Branch Equal | `R[rs1] == R[rs2]` |
| `BNE`  | `001` | Branch Not Equal | `R[rs1] != R[rs2]` |
| `BLT`  | `100` | Branch Less Than (signed) | `R[rs1] <s R[rs2]` |
| `BGE`  | `101` | Branch Greater or Equal (signed) | `R[rs1] >=s R[rs2]` |
| `BLTU` | `110` | Branch Less Than Unsigned | `R[rs1] <u R[rs2]` |
| `BGEU` | `111` | Branch Greater or Equal Unsigned | `R[rs1] >=u R[rs2]` |

---

### 2.6 Upper Immediate & Jump Instructions
| Instruction | Opcode | Format | Description | Operation |
|---|---|---|---|---|
| `LUI`   | `0110111` | U-type | Load Upper Immediate | `R[rd] = imm << 12` |
| `AUIPC` | `0010111` | U-type | Add Upper Immediate to PC | `R[rd] = PC + (imm << 12)` |
| `JAL`   | `1101111` | J-type | Jump and Link | `R[rd] = PC + 4; PC = PC + imm` |
| `JALR`  | `1100111` | I-type | Jump and Link Register | `R[rd] = PC + 4; PC = (R[rs1] + imm) & ~1` |
