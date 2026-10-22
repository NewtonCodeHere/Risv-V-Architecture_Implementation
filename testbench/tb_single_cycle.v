`timescale 1ns / 1ps

module tb_single_cycle;

    reg         clk;
    reg         rst_n;

    wire [31:0] pc;
    wire [31:0] instr;
    wire [31:0] alu_result;
    wire [31:0] dmem_read_data;
    wire        reg_write;
    wire [4:0]  rd_addr;
    wire [31:0] rd_data;

    integer cycle_count = 0;
    integer errors = 0;

    // Instantiate Single-Cycle RV32I Core
    rv32i_single_cycle #(
        .RESET_PC(32'h00000000),
        .IMEM_DEPTH(1024),
        .DMEM_DEPTH(1024),
        .MEM_INIT_FILE("programs/test_program.hex")
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc),
        .instr(instr),
        .alu_result(alu_result),
        .dmem_read_data(dmem_read_data),
        .reg_write_out(reg_write),
        .rd_addr_out(rd_addr),
        .rd_data_out(rd_data)
    );

    // 100MHz clock (10ns period)
    always #5 clk = ~clk;

    initial begin
        // VCD wave dump
        $dumpfile("single_cycle.vcd");
        $dumpvars(0, tb_single_cycle);

        clk = 0;
        rst_n = 0;

        $display("================================================================================");
        $display("                  RV32I Single-Cycle Processor Testbench                        ");
        $display("================================================================================");

        // Apply Reset
        #25 rst_n = 1;
        $display("[INFO] System reset deasserted at time %0t. Starting execution...", $time);

        // Run until completion flag or timeout
        while (cycle_count < 100) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (reg_write && rd_addr != 0) begin
                $display("Cycle %3d | PC: 0x%08h | Instr: 0x%08h | Write: x%02d = 0x%08h (%0d)", 
                         cycle_count, pc, instr, rd_addr, rd_data, rd_data);
            end

            // Check if test completion instruction executed (x31 = 42)
            if (reg_write && rd_addr == 5'd31 && rd_data == 32'd42) begin
                $display("[INFO] Test completion marker reached at cycle %0d!", cycle_count);
                #20;
                verify_results();
                $finish;
            end
        end

        $display("[ERROR] Simulation timed out after %0d cycles without reaching completion flag!", cycle_count);
        $finish;
    end

    task verify_results;
        begin
            $display("================================================================================");
            $display("                    Self-Checking Verification Results                          ");
            $display("================================================================================");

            check_reg(1, 32'd10, "x1 (ADDI 10)");
            check_reg(2, 32'd20, "x2 (ADDI 20)");
            check_reg(3, 32'd30, "x3 (ADD 10 + 20)");
            check_reg(4, 32'd20, "x4 (SUB 30 - 10)");
            check_reg(5, 32'd10240, "x5 (SLL 10 << 10)");
            check_reg(6, 32'd1, "x6 (SLT 10 < 20)");
            check_reg(7, 32'd30, "x7 (XOR 10 ^ 20)");
            check_reg(8, 32'd30, "x8 (OR 10 | 20)");
            check_reg(9, 32'd0, "x9 (AND 10 & 20)");
            check_reg(10, 32'd30, "x10 (SW & LW through DMEM)");
            check_reg(11, 32'd1, "x11 (BEQ correctly branched over 99)");
            check_reg(13, 32'd2, "x13 (JAL correctly jumped over 99)");
            check_reg(14, 32'h12345000, "x14 (LUI 0x12345)");
            check_reg(15, 32'h00000048, "x15 (AUIPC at 0x48)");
            check_reg(31, 32'd42, "x31 (Completion flag)");

            $display("--------------------------------------------------------------------------------");
            if (errors == 0) begin
                $display(">>> ALL SINGLE-CYCLE PROCESSOR TESTS PASSED SUCCESSFULLY! <<<");
            end else begin
                $display(">>> SINGLE-CYCLE TESTS FAILED WITH %0d ERRORS! <<<", errors);
            end
            $display("================================================================================");
        end
    endtask

    task check_reg;
        input [4:0] reg_idx;
        input [31:0] expected_val;
        input [127:0] desc;
        reg [31:0] actual_val;
        begin
            actual_val = uut.reg_file.registers[reg_idx];
            if (actual_val === expected_val) begin
                $display(" [PASS] Register x%02d: 0x%08h (%0d) - %0s", reg_idx, actual_val, actual_val, desc);
            end else begin
                $display(" [FAIL] Register x%02d: 0x%08h (Expected 0x%08h) - %0s", reg_idx, actual_val, expected_val, desc);
                errors = errors + 1;
            end
        end
    endtask

endmodule
