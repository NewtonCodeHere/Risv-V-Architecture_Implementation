# RISC-V RV32I Processor Architecture

This document details the architectural design, microarchitecture blocks, pipeline organization, and hazard mitigation strategies for the implemented RISC-V RV32I processors.

---

## 1. Top-Level Design Overview

Two complete core microarchitectures are implemented in synthesizable Verilog:
1. **`rv32i_single_cycle`**: An intuitive, unpipelined single-cycle processor where each instruction executes in exactly one clock cycle.
2. **`rv32i_pipelined`**: A high-performance 5-stage classic RISC pipeline (IF, ID, EX, MEM, WB) featuring full data forwarding, load-use hazard stalls, and branch/jump pipeline flushing.

---

## 2. Core Datapath Modules

### 2.1 Program Counter (PC) & Instruction Memory
- **Single-Cycle**: The PC updates on every active clock edge to either `PC + 4`, branch target (`PC + imm`), or jump target (`rs1 + imm`).
- **5-Stage Pipeline**: PC update is controlled by the `pc_write` enable signal from the Hazard Unit. When a load-use stall occurs, `pc_write` is deasserted, freezing the PC.

### 2.2 32-bit Arithmetic Logic Unit (ALU)
The ALU executes all arithmetic and logic instructions in RV32I:
- `ADD`, `SUB`
- `SLL`, `SRL`, `SRA` (arithmetic right shift preserves sign)
- `SLT` (signed comparison), `SLTU` (unsigned comparison)
- `XOR`, `OR`, `AND`
- `PASS_B` (passes operand B directly)
- Generates condition flags: `zero`, `less_than` (signed), and `less_than_unsigned`.

### 2.3 Register File (32 x 32-bit Registers)
- Dual asynchronous read ports (`rs1_data`, `rs2_data`).
- Single synchronous write port (`rd_addr`, `rd_data`, `reg_write`).
- **Register `x0`**: Hardwired permanently to `32'b0`. Writes to `x0` are discarded.
- **Internal Forwarding**: If the register currently addressed by `rs1` or `rs2` is simultaneously being written on the write port, the new write data is forwarded combinational-first, eliminating WB-to-ID structural hazard.

### 2.4 Immediate Generator (`imm_gen`)
Sign-extends immediate values across all instruction types:
- **I-type**: 12-bit signed immediate (`[31:20]`)
- **S-type**: 12-bit signed store immediate (`[31:25] | [11:7]`)
- **B-type**: 13-bit signed branch target offset (`[31] | [7] | [30:25] | [11:8] | 0`)
- **U-type**: 20-bit upper immediate shifted to bits `[31:12]`
- **J-type**: 21-bit signed jump target offset (`[31] | [19:12] | [20] | [30:21] | 0`)

### 2.5 Data Memory (`data_memory`)
Byte-addressable memory supporting:
- Word accesses: `LW`, `SW`
- Halfword accesses: `LH` (signed), `LHU` (unsigned), `SH`
- Byte accesses: `LB` (signed), `LBU` (unsigned), `SB`

---

## 3. 5-Stage Pipeline Organization

```
+------------+      +------------+      +------------+      +------------+      +------------+
|     IF     | ---> |     ID     | ---> |     EX     | ---> |    MEM     | ---> |     WB     |
| Fetch PC   |      | Decode     |      | Execute    |      | Memory     |      | Writeback  |
| & Instr    |      | Read Regs  |      | ALU / Br   |      | Read/Write |      | to Regs    |
+------------+      +------------+      +------------+      +------------+      +------------+
     |                    |                    |                   |                  |
   [IF/ID]              [ID/EX]              [EX/MEM]            [MEM/WB]             |
                                               |                   |                  |
                                               +====== Forwarding =+==================+
```

### Stage Breakdown:
1. **IF (Instruction Fetch)**:
   - Fetches 32-bit instruction from `instruction_memory`.
   - Computes `PC + 4`.
   - Pipeline register: `if_id_reg` (supports stall enable & synchronous flush).
2. **ID (Instruction Decode & Operand Fetch)**:
   - Decodes opcode, registers (`rs1`, `rs2`, `rd`), funct3, and funct7.
   - Generates control signals and sign-extended immediates.
   - Pipeline register: `id_ex_reg` (supports flush for bubbles and control hazards).
3. **EX (Execute & Address Computation)**:
   - Forwarding multiplexers select between registered values, EX/MEM result, or MEM/WB writeback.
   - ALU computes results and evaluates branch conditions.
   - Computes branch target (`PC + imm`) and JALR target (`rs1 + imm`).
   - Pipeline register: `ex_mem_reg`.
4. **MEM (Memory Access)**:
   - Reads or writes to byte-addressable `data_memory`.
   - Supports store-data forwarding from WB stage.
   - Pipeline register: `mem_wb_reg`.
5. **WB (Write-Back)**:
   - Multiplexes final write data: ALU Result, Memory Read Data, PC + 4 (JAL/JALR), or Immediate (LUI).
   - Writes to destination register `rd` in register file.

---

## 4. Hazard Detection & Forwarding Unit

### 4.1 Data Forwarding (RAW Hazards)
When an instruction depends on the result of an earlier instruction that hasn't written back to the register file yet:
- **EX-to-EX Forwarding**:
  `if (EX/MEM.RegWrite && EX/MEM.rd != 0 && EX/MEM.rd == ID/EX.rs1) ForwardA = 2'b10`
- **MEM-to-EX Forwarding**:
  `if (MEM/WB.RegWrite && MEM/WB.rd != 0 && MEM/WB.rd == ID/EX.rs1) ForwardA = 2'b01`
- Same rules apply to operand B (`rs2`).
- **Store Forwarding**:
  If a Store instruction in MEM stage depends on data written by the instruction in WB stage, data is forwarded directly into the memory write port.

### 4.2 Load-Use Hazard Stall
When an instruction immediately following a `LW` needs the loaded data:
- **Detection**:
  `ID/EX.MemRead && (ID/EX.rd != 0) && ((ID.rs1 == ID/EX.rd) || (ID.rs2 == ID/EX.rd))`
- **Resolution**:
  - `pc_write = 0`: Freeze Program Counter for 1 cycle.
  - `if_id_write = 0`: Freeze IF/ID register.
  - `id_ex_flush = 1`: Inject a bubble (NOP) into ID/EX register.
  - After 1 cycle stall, the data can be forwarded from the MEM stage!

### 4.3 Control Hazard (Branch & Jump Flushing)
- Branches and jumps are resolved in the **EX stage**.
- When taken:
  - `branch_jump_taken = 1`
  - PC is updated with the branch/jump target.
  - `if_id_flush = 1`: Converts speculative instruction in IF/ID to NOP.
  - `id_ex_flush = 1`: Converts speculative instruction in ID/EX to NOP.
  - Target instruction enters IF on the next clock cycle.
