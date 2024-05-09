`timescale 1ns / 1ps
module regfile (
    input clk,
    input wen,
    input [4:0] r1_addr,
    input [4:0] r2_addr,
    input [4:0] w_addr,
    input [31:0] w_data,
    output reg [31:0] r1_data,
    output reg [31:0] r2_data
);

    parameter WIDTH_SIZE = 32;
    parameter WIDTH_LENGTH = 32;
    reg [WIDTH_SIZE-1:0] register [WIDTH_LENGTH-1:0];
    // 时序逻辑
    // 用于写寄存器
    always @ (posedge clk)
    begin
        if(wen)
        begin         
            register[w_addr] <= w_data;
        end
        
        // 保存0寄存器的值一直为0
        register[0] <= 0;
    end

    // 读寄存器
    assign r1_data = register[r1_addr];
    assign r2_data = register[r2_addr];

endmodule

