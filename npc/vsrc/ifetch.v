`timescale 1ns / 1ps
import "DPI-C" function int inst_read(input int vaddr);

module ifetch (
    input clk,
    input [31:0] pc,
    output reg [31:0] inst
);

    // pc 信号传输到 ifetch 模块
    // 将 pc 信号传输到 inst_read 函数

    always_latch
    begin
        if(pc != 0)
        begin
            inst = inst_read(pc);
        end
    end
endmodule
