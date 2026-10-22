# ==============================================================================
# Makefile for RISC-V RV32I Processor (Single-Cycle & 5-Stage Pipelined)
# Simulator: Icarus Verilog (iverilog) + GTKWave / Python Reference Checker
# ==============================================================================

IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave
PYTHON   ?= python3

INC_DIRS = -I rtl/common -I rtl/single_cycle -I rtl/pipelined

COMMON_SRCS = rtl/common/defines.vh \
              rtl/common/alu.v \
              rtl/common/alu_control.v \
              rtl/common/control_unit.v \
              rtl/common/register_file.v \
              rtl/common/imm_gen.v \
              rtl/common/instruction_memory.v \
              rtl/common/data_memory.v

SINGLE_CYCLE_SRCS = $(COMMON_SRCS) rtl/single_cycle/rv32i_single_cycle.v
PIPELINED_SRCS    = $(COMMON_SRCS) rtl/pipelined/hazard_unit.v rtl/pipelined/pipeline_registers.v rtl/pipelined/rv32i_pipelined.v

.PHONY: all single_cycle pipelined tb_alu tb_rf tb_ctrl tb_hazard python_sim clean

all: single_cycle pipelined tb_alu tb_rf tb_ctrl tb_hazard

# ------------------------------------------------------------------------------
# Testbench: Single-Cycle Processor
# ------------------------------------------------------------------------------
single_cycle:
	@echo "=== Compiling & Running Single-Cycle Processor Testbench ==="
	$(IVERILOG) $(INC_DIRS) -o sim_single_cycle.vvp testbench/tb_single_cycle.v $(SINGLE_CYCLE_SRCS)
	$(VVP) sim_single_cycle.vvp

# ------------------------------------------------------------------------------
# Testbench: 5-Stage Pipelined Processor
# ------------------------------------------------------------------------------
pipelined:
	@echo "=== Compiling & Running 5-Stage Pipelined Processor Testbench ==="
	$(IVERILOG) $(INC_DIRS) -o sim_pipelined.vvp testbench/tb_pipelined.v $(PIPELINED_SRCS)
	$(VVP) sim_pipelined.vvp

# ------------------------------------------------------------------------------
# Unit Testbenches
# ------------------------------------------------------------------------------
tb_alu:
	@echo "=== Running ALU Unit Testbench ==="
	$(IVERILOG) $(INC_DIRS) -o sim_alu.vvp testbench/tb_alu.v rtl/common/alu.v
	$(VVP) sim_alu.vvp

tb_rf:
	@echo "=== Running Register File Unit Testbench ==="
	$(IVERILOG) $(INC_DIRS) -o sim_rf.vvp testbench/tb_register_file.v rtl/common/register_file.v
	$(VVP) sim_rf.vvp

tb_ctrl:
	@echo "=== Running Control Unit Unit Testbench ==="
	$(IVERILOG) $(INC_DIRS) -o sim_ctrl.vvp testbench/tb_control_unit.v rtl/common/control_unit.v rtl/common/alu_control.v
	$(VVP) sim_ctrl.vvp

tb_hazard:
	@echo "=== Running Hazard Unit Unit Testbench ==="
	$(IVERILOG) $(INC_DIRS) -o sim_hazard.vvp testbench/tb_hazard_unit.v rtl/pipelined/hazard_unit.v
	$(VVP) sim_hazard.vvp

# ------------------------------------------------------------------------------
# Python Architectural Verification Suite
# ------------------------------------------------------------------------------
python_sim:
	@echo "=== Running Python Golden Reference Verification Suite ==="
	$(PYTHON) sim/run_simulation.py

# ------------------------------------------------------------------------------
# Waveform Viewing
# ------------------------------------------------------------------------------
waves_single:
	$(GTKWAVE) single_cycle.vcd &

waves_pipelined:
	$(GTKWAVE) pipelined.vcd &

# ------------------------------------------------------------------------------
# Clean
# ------------------------------------------------------------------------------
clean:
	rm -f *.vvp *.vcd
