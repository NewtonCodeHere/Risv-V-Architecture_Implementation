`timescale 1ns / 1ps

module tb_pipelined;

    reg         clk;
    reg         rst_n;

    wire [31:0] pc_if;
    wire [31:0] instr_if;
    wire [31:0] pc_id;
    wire [31:0] instr_id;
    wire [31:0] pc_ex;
    wire [31:0] alu_result_ex;
    wire [31:0] alu_result_mem;
    wire        reg_write_wb;
    wire [4:0]  rd_wb;
    wire [31:0] wb_data;
    wire        pipeline_stall;
    wire        pipeline_flush;

    integer cycle_count = 0;
    integer stall_count = 0;
    integer flush_count = 0;
    integer errors = 0;

    // Instantiate 5-Stage Pipelined RV32I Processor
    rv32i_pipelined #(
        .RESET_PC(32'h00000000),
        .IMEM_DEPTH(1024),
        .DMEM_DEPTH(1024),
        .MEM_INIT_FILE("programs/hazard_test.hex")
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .pc_if(pc_if),
        .instr_if(instr_if),
        .pc_id(pc_id),
        .instr_id(instr_id),
        .pc_ex(pc_ex),
        .alu_result_ex(alu_result_ex),
        .alu_result_mem(alu_result_mem),
        .reg_write_wb(reg_write_wb),
        .rd_wb(rd_wb),
        .wb_data(wb_data),
        .pipeline_stall(pipeline_stall),
        .pipeline_flush(pipeline_flush)
    );

    // 100MHz clock (10ns period)
    always #5 clk = ~clk;

    initial begin
        $dumpfile("pipelined.vcd");
        $dumpvars(0, tb_pipelined);

        clk = 0;
        rst_n = 0;

        $display("================================================================================");
        $display("              RV32I 5-Stage Pipelined Processor Testbench                       ");
        $display("================================================================================");

        // Apply Reset
        #25 rst_n = 1;
        $display("[INFO] System reset deasserted at time %0t. Starting pipeline execution...", $time);

        // Run until completion flag or timeout
        while (cycle_count < 150) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;

            if (pipeline_stall) begin
                stall_count = stall_count + 1;
                $display("Cycle %3d | [STALL] Load-Use Hazard Detected (PC frozen at 0x%08h)", cycle_count, pc_if);
            end

            if (pipeline_flush) begin
                flush_count = flush_count + 1;
                $display("Cycle %3d | [FLUSH] Control Hazard: Branch/Jump Taken in EX Stage", cycle_count);
            end

            if (reg_write_wb && rd_wb != 0) begin
                $display("Cycle %3d | [WB STAGE] Write-back: x%02d = 0x%08h (%0d)", 
                         cycle_count, rd_wb, wb_data, wb_data);
            end

            // Check if test completion instruction executed (x31 = 123)
            if (reg_write_wb && rd_wb == 5'd31 && wb_data == 32'd123) begin
                $display("[INFO] Test completion marker (x31=123) written back at cycle %0d!", cycle_count);
                #30;
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
            $display("                  Pipeline Hazard Verification Results                          ");
            $display("================================================================================");
            $display(" Pipeline Statistics: Total Cycles = %0d | Stalls = %0d | Flushes = %0d", 
                     cycle_count, stall_count, flush_count);
            $display("--------------------------------------------------------------------------------");

            check_reg(1, 32'd10,  "x1 (Initialization: ADDI 10)");
            check_reg(2, 32'd20,  "x2 (Initialization: ADDI 20)");
            check_reg(3, 32'd30,  "x3 (ADD x1, x2 = 30)");
            check_reg(4, 32'd20,  "x4 (RAW EX-to-EX forward x3: 30 - 10 = 20)");
            check_reg(5, 32'd5,   "x5 (ADDI 5)");
            check_reg(6, 32'd50,  "x6 (RAW MEM-to-EX forward: 20 + 30 = 50)");
            check_reg(7, 32'd50,  "x7 (SW & LW from DMEM)");
            check_reg(8, 32'd150, "x8 (Load-Use Stall + Forward: 50 + 100 = 150)");
            check_reg(9, 32'd77,  "x9 (ADDI 77)");
            check_reg(10, 32'd77, "x10 (Store Forwarding & LW verification)");
            check_reg(11, 32'd1,  "x11 (Branch Flush: 999 flushed, target 1 executed)");
            check_reg(31, 32'd123,"x31 (Test completion flag)");

            if (stall_count == 0) begin
                $display("[FAIL] Expected at least 1 Load-Use stall, but none occurred!");
                errors = errors + 1;
            end else begin
                $display("[PASS] Load-Use hazard successfully caused pipeline stalls.");
            end

            if (flush_count == 0) begin
                $display("[FAIL] Expected branch flush, but none occurred!");
                errors = errors + 1;
            end else begin
                $display("[PASS] Branch hazard successfully flushed speculative pipeline stages.");
            end

            $display("--------------------------------------------------------------------------------");
            if (errors == 0) begin
                $display(">>> ALL 5-STAGE PIPELINED PROCESSOR TESTS PASSED SUCCESSFULLY! <<<");
            end else begin
                $display(">>> PIPELINED PROCESSOR TESTS FAILED WITH %0d ERRORS! <<<", errors);
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
