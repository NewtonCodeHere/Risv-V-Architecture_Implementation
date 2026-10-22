`timescale 1ns / 1ps
`include "defines.vh"

module data_memory #(
    parameter MEM_DEPTH  = 1024,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  mem_read,
    input  wire                  mem_write,
    input  wire [2:0]            funct3,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] write_data,
    output reg  [DATA_WIDTH-1:0] read_data
);

    reg [31:0] mem [0:MEM_DEPTH-1];
    integer i;

    wire [$clog2(MEM_DEPTH)-1:0] word_addr = addr[1+$clog2(MEM_DEPTH):2];
    wire [1:0] byte_offset = addr[1:0];

    // Synchronous write
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                mem[i] <= 32'b0;
            end
        end else if (mem_write) begin
            case (funct3)
                `FUNCT3_SB: begin
                    case (byte_offset)
                        2'b00: mem[word_addr][7:0]   <= write_data[7:0];
                        2'b01: mem[word_addr][15:8]  <= write_data[7:0];
                        2'b10: mem[word_addr][23:16] <= write_data[7:0];
                        2'b11: mem[word_addr][31:24] <= write_data[7:0];
                    endcase
                end
                `FUNCT3_SH: begin
                    if (byte_offset[1] == 1'b0)
                        mem[word_addr][15:0]  <= write_data[15:0];
                    else
                        mem[word_addr][31:16] <= write_data[15:0];
                end
                `FUNCT3_SW: begin
                    mem[word_addr] <= write_data;
                end
                default: begin
                    mem[word_addr] <= write_data;
                end
            endcase
        end
    end

    // Combinational read
    wire [31:0] raw_word = mem[word_addr];
    reg  [7:0]  selected_byte;
    reg  [15:0] selected_half;

    always @(*) begin
        case (byte_offset)
            2'b00: selected_byte = raw_word[7:0];
            2'b01: selected_byte = raw_word[15:8];
            2'b10: selected_byte = raw_word[23:16];
            2'b11: selected_byte = raw_word[31:24];
        endcase

        if (byte_offset[1] == 1'b0)
            selected_half = raw_word[15:0];
        else
            selected_half = raw_word[31:16];

        if (mem_read) begin
            case (funct3)
                `FUNCT3_LB:  read_data = {{24{selected_byte[7]}}, selected_byte};
                `FUNCT3_LH:  read_data = {{16{selected_half[15]}}, selected_half};
                `FUNCT3_LW:  read_data = raw_word;
                `FUNCT3_LBU: read_data = {24'b0, selected_byte};
                `FUNCT3_LHU: read_data = {16'b0, selected_half};
                default:     read_data = raw_word;
            endcase
        end else begin
            read_data = 32'b0;
        end
    end

endmodule
