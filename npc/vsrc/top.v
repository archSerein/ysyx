`timescale 1ns / 1ps
`include "define.v"

module top(
    input clk,
    input rst
);

    // pc_reg 更新 pc 的模块
    reg [31:0] current_pc;
    wire [31:0] inst;
    wire [31:0] snpc, jmp_addr;
    wire jmp_flag;
    pc_reg pc_reg_module (
        .clk(clk),
        .rst(rst),
        .snpc(snpc),
        .jmp_addr(jmp_addr),
        .jmp_flag(jmp_flag),
        .current_pc(current_pc)
    );

    // 取指模块
    // 将指令信号传输到 Decode 模块
    ifetch ifetch_module (
        .clk(clk),
        .pc(current_pc),
        .inst(inst)
    );

    // 译码模块
    // 从指令翻译出源操作数
    // 将源操作数信号传输到 execute 模块
    wire [2:0] optype;
    wire [4:0] src1, src2, rd;
    wire [5:0] option, fn;
    wire [31:0] imm;
    reg wen;
    Decode Decode_module (
        .inst(inst),
        .optype(optype),
        .option(option),
        .src1(src1),
        .src2(src2),
        .rd(rd),
        .fn(fn),
        .imm(imm)
    );

    // 将译码模块的源操作数传输到 regfile 模块
    // 取出对应寄存器的数据
    wire [31:0] w_data;
    wire [31:0] r1_data, r2_data;
    regfile regfile_module (
        .clk(clk),
        .wen(wen),
        .r1_addr(src1),
        .r2_addr(src2),
        .w_addr(rd),
        .w_data(w_data),
        .r1_data(r1_data),
        .r2_data(r2_data)
    );

    // 译码模块的信号传输到执行模块
    wire [31:0] alu_out;
    wire [31:0] cmp_out;
    decode_execute decode_execute_module (
        .optype(optype),
        .option(option),
        .fn(fn),
        .imm(imm),
        .r1_data(r1_data),
        .r2_data(r2_data),
        .inst_addr(current_pc),
        .re(re),
        .wen(wen),
        .alu_out(alu_out),
        .cmp_out(cmp_out)
    );

    // 内存写使能
    // 内存模块
    reg [31:0] dout, wdith;
    wire we, re;
    memfile memfile_module (
        .clk(clk),
        .we(we),
        .re(re),
        .wdith(wdith),
        .addr(alu_out),
        .din(r2_data),
        .dout(dout)
    );

    // 根据译码模块的信号
    // 执行指令对应的行为

    execute execute_module(
        .option(option),
        .imm(imm),
        .snpc(snpc),
        .alu_out(alu_out),
        .cmp_out(cmp_out),
        .dout(dout),
        .jmp_addr(jmp_addr),
        .jmp_flag(jmp_flag),
        .w_data(w_data),
        .wdith(wdith),
        .we(we)
    );

    arith arith_module (
        .x(current_pc),
        .y(32'h4),
        .AFN(1'b0),
        .S(snpc),
        .ZF(),
        .VF(),
        .NF(),
        .CF() 
    );

endmodule
