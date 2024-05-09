`timescale 1ns / 1ps
`include "define.v"

module pc_reg(
    input clk,
    input rst,
    input jmp_flag,
    input [31:0] snpc,
    input [31:0] jmp_addr,
    output reg [31:0] current_pc
);   

    always @ (posedge clk)
    begin
        if(rst)
        begin
            current_pc <= `RST_ADDR;
        end
        else if (jmp_flag)
            current_pc <= jmp_addr;
        else
            current_pc <= snpc;
    end
endmodule
