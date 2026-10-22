`timescale 1ns / 1ps

module register_file #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  reg_write,
    input  wire [ADDR_WIDTH-1:0] rs1_addr,
    input  wire [ADDR_WIDTH-1:0] rs2_addr,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    input  wire [DATA_WIDTH-1:0] rd_data,
    output wire [DATA_WIDTH-1:0] rs1_data,
    output wire [DATA_WIDTH-1:0] rs2_data
);

    reg [DATA_WIDTH-1:0] registers [0:31];
    integer i;

    // Synchronous write with active-low asynchronous reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (reg_write && (rd_addr != 5'd0)) begin
            registers[rd_addr] <= rd_data;
        end
    end

    // Asynchronous read with x0 hardwired to 0
    // Internal forwarding: if reading the register currently being written in WB stage, forward new data
    assign rs1_data = (rs1_addr == 5'd0) ? 32'b0 :
                      ((reg_write && (rd_addr == rs1_addr)) ? rd_data : registers[rs1_addr]);

    assign rs2_data = (rs2_addr == 5'd0) ? 32'b0 :
                      ((reg_write && (rd_addr == rs2_addr)) ? rd_data : registers[rs2_addr]);

endmodule
