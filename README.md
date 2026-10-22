# RISC-V Processor Design (Single-Cycle & 5-Stage Pipelined)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Verilog](https://img.shields.io/badge/Language-Verilog%20HDL-red.svg)]()
[![ISA](https://img.shields.io/badge/ISA-RISC--V%20RV32I-green.svg)]()
[![Architecture](https://img.shields.io/badge/Design-Single--Cycle%20%26%205--Stage%20Pipeline-orange.svg)]()

> **Computer Architecture Design Project — Dec 2025**  
> *Designed and implemented a 32-bit RISC-V Instruction Set Architecture (ISA) featuring core ALU, control unit, program counter, and register file modules in synthesizable Verilog.*

---

## 📌 Project Overview

This repository contains full, synthesizable implementations of a **32-bit RISC-V (RV32I) processor core**:
1. **Single-Cycle RISC-V Processor Core (`rv32i_single_cycle`)**:
   - Clean, modular datapath executing each instruction in a single clock cycle.
   - Ideal for architectural study, baseline cycle analysis, and functional verification.
2. **5-Stage Pipelined RISC-V Processor Core (`rv32i_pipelined`)**:
   - Classic RISC pipeline: **IF** (Fetch), **ID** (Decode), **EX** (Execute), **MEM** (Memory), **WB** (Write-back).
   - **Hazard Detection Unit**: Automatic Load-Use hazard detection with stall and bubble injection.
   - **Forwarding Unit**: Full EX-to-EX, MEM-to-EX, and Store-data forwarding to eliminate RAW stalls.
   - **Control Hazard Mitigation**: Dynamic branch/jump resolution in the EX stage with pipeline flushing.

---

## 🚀 Key Features

- **Standard RV32I Base Integer ISA Support**:
  - **R-Type**: `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`
  - **I-Type Arithmetic & Logic**: `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`
  - **I-Type Memory Loads**: `LB`, `LH`, `LW`, `LBU`, `LHU`
  - **S-Type Memory Stores**: `SB`, `SH`, `SW`
  - **B-Type Conditional Branches**: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`
  - **U-Type Upper Immediates**: `LUI`, `AUIPC`
  - **J-Type & Indirect Jumps**: `JAL`, `JALR`
- **Register File**: 32 general-purpose 32-bit registers (`x0` hardwired to zero) with internal forwarding for simultaneous read-write.
- **ALU**: 32-bit Arithmetic Logic Unit with zero and signed/unsigned comparison flags.
- **Memory Subsystem**: Byte-addressable Data Memory supporting word, halfword, and byte access.
- **Verification Suite**: Full set of self-checking Verilog testbenches, unit testbenches, and a golden Python cycle-accurate architectural simulator.

---

## 🏛 Architecture & Datapath

### 1. 5-Stage Pipeline Block Diagram

```
+========================================================================================================+
|                                    RISC-V 5-STAGE PIPELINE DATAPATH                                    |
+========================================================================================================+

    [IF Stage]           [ID Stage]           [EX Stage]           [MEM Stage]          [WB Stage]
   +-----------+       +-----------+        +------------+       +-------------+      +------------+
   |    PC     | ----> |  RegFile  | -----> |    ALU     | ----> | Data Memory | ---> |  Writeback |
   |     +     |       |     +     |        |     +      |       |             |      |    Mux     |
   |   Instr   |       | Imm Gen   |        | Forwarding |       +-------------+      +-----+------+
   |   Memory  |       |  Decoder  |        |    Muxes   |             |                    |
   +-----+-----+       +-----+-----+        +-----+------+             |                    |
         |                   |                    |                    |                    |
      [IF/ID]             [ID/EX]              [EX/MEM]             [MEM/WB]                |
         |                   |                    |                    |                    |
         +-------------------+-- Forwarding & Hazard Unit <------------+--------------------+
                                 (Stall PC, Flush IF/ID, Forward EX/MEM, Forward MEM/WB)
```

### 2. Forwarding & Hazard Unit

- **EX-to-EX Forwarding**: Bypasses execution results from the `EX/MEM` pipeline register directly to the ALU inputs.
- **MEM-to-EX Forwarding**: Bypasses memory or ALU results from the `MEM/WB` stage to the ALU inputs.
- **Load-Use Stall**: Detects when an instruction in the decode stage depends on a `LW` currently in the execute stage. The unit automatically holds `PC` and `IF/ID` while inserting a bubble (NOP) into `ID/EX`.
- **Branch/Jump Flush**: When a branch condition is satisfied or a jump instruction executes, the instructions speculatively fetched in `IF/ID` and `ID/EX` are converted to NOPs.

---

## 📂 Repository Structure

```
Risv-V-Architecture_Implementation/
├── rtl/
│   ├── common/
│   │   ├── defines.vh              # Global opcodes, funct3/funct7, ALU operations
│   │   ├── alu.v                   # 32-bit RV32I Arithmetic Logic Unit
│   │   ├── alu_control.v           # ALU Decoder
│   │   ├── control_unit.v          # Main Control Unit
│   │   ├── register_file.v         # 32 x 32-bit Register File (x0 hardwired 0)
│   │   ├── imm_gen.v               # Immediate Generator (I, S, B, U, J)
│   │   ├── instruction_memory.v    # Instruction ROM ($readmemh support)
│   │   └── data_memory.v           # Byte-addressable Data RAM (B/H/W)
│   ├── single_cycle/
│   │   └── rv32i_single_cycle.v    # Top-Level Single-Cycle Processor Core
│   └── pipelined/
│       ├── pipeline_registers.v    # IF/ID, ID/EX, EX/MEM, MEM/WB Registers
│       ├── hazard_unit.v           # Data Forwarding & Hazard Detection Unit
│       └── rv32i_pipelined.v       # Top-Level 5-Stage Pipelined Processor Core
├── testbench/
│   ├── tb_single_cycle.v           # Top-level Testbench for Single-Cycle core
│   ├── tb_pipelined.v              # Top-level Testbench for 5-Stage Pipelined core
│   ├── tb_alu.v                    # Unit testbench for ALU operations & flags
│   ├── tb_register_file.v          # Unit testbench for Register File & forwarding
│   ├── tb_control_unit.v           # Unit testbench for Control & ALU Decoder
│   └── tb_hazard_unit.v            # Unit testbench for Forwarding & Hazard Unit
├── programs/
│   ├── test_program.asm            # RV32I comprehensive test program source
│   ├── test_program.hex            # Hex machine code for instruction memory
│   ├── hazard_test.asm             # Pipeline hazard & forwarding test program
│   └── hazard_test.hex             # Hex machine code for hazard test
├── sim/
│   ├── run_simulation.py           # Golden architectural reference simulator
│   ├── check_verilog_syntax.py     # Structural & keyword sanity checker
│   ├── generate_test_program.py    # Python instruction assembler & hex generator
│   ├── generate_hazard_test.py     # Pipeline hazard program generator
│   └── run_tests.ps1               # Automated simulation runner for Windows
├── docs/
│   ├── architecture.md             # Detailed datapath & pipeline microarchitecture
│   └── instruction_set.md          # RV32I ISA reference and opcode table
├── Makefile                        # Makefile for Icarus Verilog & GTKWave
├── LICENSE                         # MIT License
└── README.md                       # Project documentation
```

---

## 🛠 Simulation & Verification

### Method 1: Python Architectural Reference Simulator
Run the verification suite containing the golden reference simulator:
```bash
python sim/run_simulation.py
```

**Verification Results**:
```
================================================================================
      RISC-V PROCESSOR VERIFICATION SUITE (Single-Cycle & 5-Stage Pipelined)    
================================================================================

[SIM] Running Single-Cycle Full ISA Program Verification...
 [PASS] Register x01: actual = 0x0000000a (10)  | expected = 0x0000000a (10)
 [PASS] Register x02: actual = 0x00000014 (20)  | expected = 0x00000014 (20)
 [PASS] Register x03: actual = 0x0000001e (30)  | expected = 0x0000001e (30)
 [PASS] Register x04: actual = 0x00000014 (20)  | expected = 0x00000014 (20)
 [PASS] Register x05: actual = 0x00002800 (10240)| expected = 0x00002800 (10240)
 [PASS] Register x06: actual = 0x00000001 (1)   | expected = 0x00000001 (1)
 [PASS] Register x07: actual = 0x0000001e (30)  | expected = 0x0000001e (30)
 [PASS] Register x08: actual = 0x0000001e (30)  | expected = 0x0000001e (30)
 [PASS] Register x09: actual = 0x00000000 (0)   | expected = 0x00000000 (0)
 [PASS] Register x10: actual = 0x0000001e (30)  | expected = 0x0000001e (30)
 [PASS] Register x11: actual = 0x00000001 (1)   | expected = 0x00000001 (1)
 [PASS] Register x13: actual = 0x00000002 (2)   | expected = 0x00000002 (2)
 [PASS] Register x14: actual = 0x12345000       | expected = 0x12345000
 [PASS] Register x15: actual = 0x00000048 (72)  | expected = 0x00000048 (72)
 [PASS] Register x31: actual = 0x0000002a (42)  | expected = 0x0000002a (42)

[SIM] Running Pipeline Hazard Verification...
 [PASS] Register x01: actual = 0x0000000a (10)  | expected = 0x0000000a (10)
 [PASS] Register x03: actual = 0x0000001e (30)  | expected = 0x0000001e (30)
 [PASS] Register x04: actual = 0x00000014 (20)  | expected = 0x00000014 (20) [RAW EX-to-EX]
 [PASS] Register x06: actual = 0x00000032 (50)  | expected = 0x00000032 (50) [RAW MEM-to-EX]
 [PASS] Register x08: actual = 0x00000096 (150) | expected = 0x00000096 (150) [Load-Use Stall]
 [PASS] Register x10: actual = 0x0000004d (77)  | expected = 0x0000004d (77) [Store Forward]
 [PASS] Register x11: actual = 0x00000001 (1)   | expected = 0x00000001 (1) [Branch Flush]
 [PASS] Register x31: actual = 0x0000007b (123) | expected = 0x0000007b (123)

>>> ALL VERIFICATION SUITES PASSED! BOTH DESIGNS FULLY VALIDATED <<<
```

---

### Method 2: Verilog Simulation with Icarus Verilog (`iverilog`)

#### Run All Testbenches via Makefile:
```bash
make all
```

#### Run Individual Modules:
```bash
# Single-Cycle Core
make single_cycle

# 5-Stage Pipelined Core
make pipelined

# Unit Tests
make tb_alu
make tb_rf
make tb_ctrl
make tb_hazard
```

#### Windows PowerShell:
```powershell
.\sim\run_tests.ps1
```

---

### Method 3: Waveform Visualization
Both testbenches automatically generate `.vcd` trace files (`single_cycle.vcd` and `pipelined.vcd`). Open them with GTKWave or ModelSim:
```bash
gtkwave single_cycle.vcd
gtkwave pipelined.vcd
```

---

## 📜 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
