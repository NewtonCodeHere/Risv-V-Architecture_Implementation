`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_DEPTH     = 1024,
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 32,
    parameter MEM_INIT_FILE = ""
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [DATA_WIDTH-1:0] instr
);

    // Memory array: MEM_DEPTH words of 32 bits
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            mem[i] = 32'h00000013; // NOP (addi x0, x0, 0)
        end
        if (MEM_INIT_FILE != "") begin
            $readmemh(MEM_INIT_FILE, mem);
        end
    end

    // Word address: drop lower 2 bits (pc[31:2])
    // Mask address within memory depth
    wire [$clog2(MEM_DEPTH)-1:0] word_addr = addr[1+$clog2(MEM_DEPTH):2];

    assign instr = mem[word_addr];

endmodule
