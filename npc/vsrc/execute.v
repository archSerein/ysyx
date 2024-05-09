`timescale 1ns / 1ps
import "DPI-C" function void ending(input int num);
`include <ctrl.v>
`include <define.v>

module execute (
    input [31:0] snpc,
    input [31:0] alu_out,
    input [31:0] cmp_out,
    input [31:0] imm,
    input [5:0] option,
    input [31:0] dout,
    output [31:0] jmp_addr,
    output [31:0] w_data,
    output [31:0] wdith,
    output jmp_flag,
    output we
);

    // 产生内存和寄存器的读写信号以及多路复用器的选择信号
    // 控制模块在 execute.v 中实现
    // 通过相应的 option 操作数产生对应的信号
    // 执行指令
    // 组合逻辑

    assign we = (option == `sw) ? `mem_w_enable :
                (option == `sh) ? `mem_w_enable :
                (option == `sb) ? `mem_w_enable :
                 `mem_w_disable;
    assign jmp_flag =   (option == `jal || option == `jalr) ? `jmp_enable :
                        (option == `bge)    ?   `jmp_enable :
                        (option == `bne)    ?   `jmp_enable :
                        (option == `beq)    ?   `jmp_enable :
                        (option == `bltu)   ?   `jmp_enable :
                        (option == `bgeu)   ?   `jmp_enable :
                        (option == `blt)    ?   `jmp_enable :
                        `jmp_disable;
    assign w_data = (option == `jal) ? snpc : 
                    (option == `jalr) ? snpc : 
                    (option == `lui) ? imm :
                    (option == `lw) ? dout :
                    (option == `lb) ? {{24{dout[7]}}, dout[7:0]} :
                    (option == `lh) ? {{16{dout[15]}}, dout[15:0]} :
                    (option == `lbu) ? {{24{1'b0}}, dout[7:0]} :
                    (option == `lhu) ? {{16{1'b0}}, dout[15:0]} :
                    (option == `sltiu || option == `slti) ? (cmp_out == 32'b1 ? 32'b1 : 32'b0) :
                    (option == `sltu || option == `slt)  ? (cmp_out == 32'b1 ? 32'b1 : 32'b0) :
                    alu_out;
    assign jmp_addr =   (option == `jal || option == `jalr) ? alu_out : 
                        (option == `bge) ? (cmp_out == 32'b1 ? alu_out : snpc)  :
                        (option == `bne) ? (cmp_out == 32'b1 ? alu_out : snpc)  :
                        (option == `beq) ? (cmp_out == 32'b1 ? alu_out : snpc)  :
                        (option == `bltu || option == `blt) ? (cmp_out == 32'b1 ? alu_out : snpc) :
                        (option == `bgeu) ? (cmp_out == 32'b1 ? alu_out : snpc) :
                        `zeroWord;
    assign wdith =  (option == `sw || option == `lw) ? 32'd4 :
                    (option == `sb || option == `lb || option == `lbu) ? 32'd1 :
                    (option == `sh || option == `lh || option == `lhu) ? 32'd2 :
                    `zeroWord;

    always @ (option)
    begin
        if (option == `ebreak)
        begin
            ending(1);
        end
    end
endmodule


