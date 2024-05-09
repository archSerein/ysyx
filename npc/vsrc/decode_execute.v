`timescale 1ns / 1ps
`include "define.v"
`include "ctrl.v"

module decode_execute (
    input [2:0] optype,
    input [5:0] option,
    input [5:0] fn,
    input [31:0] imm,
    input [31:0] r1_data,
    input [31:0] r2_data,
    input [31:0] inst_addr,
    output re,
    output wen,
    output [31:0] alu_out,
    output [31:0] cmp_out
);

    // 实例化alu模块
    // 用于执行bool，arith，cmp，shift运算
    reg [31:0] alu_op1, alu_op2;
    alu alu_module (
        .src1(alu_op1),
        .src2(alu_op2),
        .fn(fn),
        .result(alu_out)
    );

    wire [31:0] cmp_op;
    cmp cmp_module (
        .x(r1_data),
        .y(cmp_op),
        .fn(fn[3:1]),
        .cmp(cmp_out)
    );

    assign cmp_op = (option == `sltiu) ? 32'd0 : r2_data;
    assign alu_op1 = (optype == `INST_B || optype == `INST_U || optype == `INST_J) ? inst_addr : r1_data;
    assign alu_op2 = (optype == `INST_I || optype == `INST_S || optype == `INST_B || optype == `INST_U || optype == `INST_J) ? imm : r2_data;
    assign re = (option == `lw) ? `mem_r_enable :
                (option == `lbu) ? `mem_r_enable : 
                (option == `lh) ? `mem_r_enable :
                (option == `lhu) ? `mem_r_enable :
                (option == `lb) ? `mem_r_enable :
                `mem_r_disable;
    assign wen = (optype == `INST_S || optype == `INST_B) ? `reg_w_disable : `reg_w_enable;

endmodule
