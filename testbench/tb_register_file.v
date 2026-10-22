`timescale 1ns / 1ps

module tb_register_file;

    reg         clk;
    reg         rst_n;
    reg         reg_write;
    reg  [4:0]  rs1_addr;
    reg  [4:0]  rs2_addr;
    reg  [4:0]  rd_addr;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    integer errors = 0;

    register_file uut (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(reg_write),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    // Clock generator: 10ns period
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        reg_write = 0;
        rs1_addr = 0;
        rs2_addr = 0;
        rd_addr = 0;
        rd_data = 0;

        $display("========================================");
        $display("Starting Register File Testbench");
        $display("========================================");

        // Reset
        #12 rst_n = 1;

        // Test 1: Writing to x0 must have no effect (hardwired to zero)
        @(posedge clk);
        reg_write = 1; rd_addr = 5'd0; rd_data = 32'hDEADBEEF;
        @(posedge clk);
        reg_write = 0; rs1_addr = 5'd0;
        #1;
        if (rs1_data !== 32'd0) begin
            $display("[FAIL] x0 was modified! Read value: 0x%08h", rs1_data);
            errors = errors + 1;
        end else begin
            $display("[PASS] x0 remains hardwired to zero after write attempt.");
        end

        // Test 2: Write to registers x1 to x31 and read back
        @(posedge clk);
        reg_write = 1; rd_addr = 5'd5; rd_data = 32'h12345678;
        @(posedge clk);
        reg_write = 1; rd_addr = 5'd10; rd_data = 32'hAABBCCDD;
        @(posedge clk);
        reg_write = 0;
        rs1_addr = 5'd5;
        rs2_addr = 5'd10;
        #1;
        if (rs1_data !== 32'h12345678) begin
            $display("[FAIL] x5 read mismatch: got 0x%08h, expected 0x12345678", rs1_data);
            errors = errors + 1;
        end else begin
            $display("[PASS] x5 read successfully: 0x%08h", rs1_data);
        end

        if (rs2_data !== 32'hAABBCCDD) begin
            $display("[FAIL] x10 read mismatch: got 0x%08h, expected 0xAABBCCDD", rs2_data);
            errors = errors + 1;
        end else begin
            $display("[PASS] x10 read successfully: 0x%08h", rs2_data);
        end

        // Test 3: Simultaneous read and write (internal forwarding)
        @(posedge clk);
        reg_write = 1; rd_addr = 5'd15; rd_data = 32'h5555AAAA;
        rs1_addr = 5'd15;
        #1;
        if (rs1_data !== 32'h5555AAAA) begin
            $display("[FAIL] Simultaneous write/read forwarding mismatch: got 0x%08h", rs1_data);
            errors = errors + 1;
        end else begin
            $display("[PASS] Simultaneous write/read internal forwarding verified: 0x%08h", rs1_data);
        end

        $display("========================================");
        if (errors == 0)
            $display("Register File Testbench PASSED ALL TESTS!");
        else
            $display("Register File Testbench FAILED with %0d errors", errors);
        $display("========================================");
        $finish;
    end

endmodule
