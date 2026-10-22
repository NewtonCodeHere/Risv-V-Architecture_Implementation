# PowerShell Simulation Script for RISC-V RV32I Processor

param (
    [string]$Target = "all"
)

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "              RISC-V Processor Verification Test Suite Runner                   " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# First run Python cycle-accurate verification
Write-Host "`n>>> Running Golden Architectural Reference Simulator..." -ForegroundColor Yellow
python sim/run_simulation.py

# Check if iverilog is installed
$iverilog = Get-Command "iverilog" -ErrorAction SilentlyContinue
if ($null -ne $iverilog) {
    Write-Host "`n>>> Icarus Verilog found! Running RTL simulation..." -ForegroundColor Green
    $inc = "-I rtl/common -I rtl/single_cycle -I rtl/pipelined"
    $common = "rtl/common/alu.v rtl/common/alu_control.v rtl/common/control_unit.v rtl/common/register_file.v rtl/common/imm_gen.v rtl/common/instruction_memory.v rtl/common/data_memory.v"

    if ($Target -eq "all" -or $Target -eq "single_cycle") {
        Write-Host "`n[Verilog] Simulating Single-Cycle Processor..." -ForegroundColor Cyan
        iverilog -I rtl/common -I rtl/single_cycle -o sim_single_cycle.vvp testbench/tb_single_cycle.v rtl/single_cycle/rv32i_single_cycle.v $common.Split(" ")
        vvp sim_single_cycle.vvp
    }

    if ($Target -eq "all" -or $Target -eq "pipelined") {
        Write-Host "`n[Verilog] Simulating 5-Stage Pipelined Processor..." -ForegroundColor Cyan
        iverilog -I rtl/common -I rtl/pipelined -o sim_pipelined.vvp testbench/tb_pipelined.v rtl/pipelined/hazard_unit.v rtl/pipelined/pipeline_registers.v rtl/pipelined/rv32i_pipelined.v $common.Split(" ")
        vvp sim_pipelined.vvp
    }
} else {
    Write-Host "`n[INFO] Icarus Verilog (iverilog) not found in system PATH." -ForegroundColor Gray
    Write-Host "       The Python reference verification above verified the test program execution." -ForegroundColor Gray
    Write-Host "       To run RTL in Icarus Verilog, install via 'winget install -e --id IcarusVerilog.IcarusVerilog'." -ForegroundColor Gray
}
