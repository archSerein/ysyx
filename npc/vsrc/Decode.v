`timescale 1ns / 1ps
module Decode (
    input [31:0] inst,
    output [2:0] optype,
    output [5:0] option,
    output [4:0] src1,
    output [4:0] src2,
    output [4:0] rd,
    output [5:0] fn,
    output [31:0] imm
);

    wire [6:0] opcode;
    assign opcode = inst[6:0];
    // 源寄存器编号
    assign src1 = inst[19:15];
    assign src2 = inst[24:20];

    // 目的寄存器编号
    assign rd = inst[11:7];

    wire [31:0] imm_I, imm_U, imm_J, imm_S, imm_B;
    // 对 U 类型指令的 imm 低位用0补齐, 其余进行符号扩展
    assign imm_I = {{20{inst[31]}}, inst[31:20]};
    assign imm_J = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], {1'b0}};
    assign imm_B = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], {1'b0}};
    assign imm_S = {{20{inst[31]}}, inst[31:25], inst[11:7]};
    assign imm_U = {inst[31:12], {12'h0}};

    // 使用逻辑表达式分配指令类型
    assign optype = (opcode == 7'b0110011) ? `INST_R  :
                    (opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b1100111) ? `INST_I  :
                    (opcode == 7'b0100011) ? `INST_S  :
                    (opcode == 7'b1100011) ? `INST_B  :
                    (opcode == 7'b0110111 || opcode == 7'b0010111) ? `INST_U  :
                    (opcode == 7'b1101111) ? `INST_J  :
                    (opcode == 7'b1110011 || opcode == 7'b0001111) ? `FUNC    :
                    `NOTYPE;

    // 通过 optype 选择立即数类型
    assign imm =    (optype == `INST_I) ? imm_I :
                    (optype == `INST_S) ? imm_S :
                    (optype == `INST_U) ? imm_U :
                    (optype == `INST_J) ? imm_J :
                    (optype == `INST_B) ? imm_B :
                    32'h0;
    wire [2:0] funct3;
    wire [6:0] funct7;
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];

    assign option = 
      (optype == `INST_R) ? (
        (funct3 == 3'b000) ? (funct7 == 7'b0000000 ? `add : `sub) :
        (funct3 == 3'b001) ? `sll :
        (funct3 == 3'b010) ? `slt :
        (funct3 == 3'b011) ? `sltu :
        (funct3 == 3'b100) ? `xor :
        (funct3 == 3'b101) ? (funct7 == 7'b0000000 ? `srl : `sra) :
        (funct3 == 3'b110) ? `or :
        (funct3 == 3'b111) ? `and :
        `nop
      ) :
      (optype == `INST_I) ? (
        (opcode == 7'b1100111) ? `jalr :
        (opcode == 7'b0010011) ? (
            (funct3 == 3'b000) ? `addi :
            (funct3 == 3'b001) ? `slli :
            (funct3 == 3'b010) ? `slti :
            (funct3 == 3'b011) ? `sltiu :
            (funct3 == 3'b100) ? `xori :
            (funct3 == 3'b101) ? (
                (funct7 == 7'b0000000) ? `srli : `srai
                ) :
            (funct3 == 3'b110) ? `ori :
            (funct3 == 3'b111) ? `andi :
          `nop
        ) :
        (opcode == 7'b0000011) ? (
            (funct3 == 3'b000) ? `lb :
            (funct3 == 3'b001) ? `lh :
            (funct3 == 3'b010) ? `lw :
            (funct3 == 3'b100) ? `lbu :
            (funct3 == 3'b101) ? `lhu :
          `nop
        ) :
        `nop
      ) :
      (optype == `INST_S) ? (
        (funct3 == 3'b000) ? `sb :
        (funct3 == 3'b001) ? `sh :
        (funct3 == 3'b010) ? `sw :
        `nop
      ) :
      (optype == `INST_B) ? (
        (funct3 == 3'b000) ? `beq :
        (funct3 == 3'b001) ? `bne :
        (funct3 == 3'b100) ? `blt :
        (funct3 == 3'b101) ? `bge :
        (funct3 == 3'b110) ? `bltu :
        (funct3 == 3'b111) ? `bgeu :
        `nop
      ) :
      (optype == `INST_U) ? (
        (opcode == 7'b0110111) ? `lui :
        (opcode == 7'b0010111) ? `auipc :
        `nop
      ) :
      (optype == `INST_J) ? `jal :
      (optype == `FUNC) ? (
        (opcode == 7'b1110011) ? 
            ((inst[31:20] == 12'b000000000000) ? `ecall : `ebreak) :
        (opcode == 7'b0001111) ? `fence :
        `nop
      ) :
      `nop; 

    
    assign fn = (option == `sub) ? 6'b010001                    :
                (option == `and || option == `andi) ? 6'b101000 :
                (option == `or || option == `ori) ?  6'b101110  :
                (option == `xor || option == `xori) ? 6'b100110 :
                (option == `sll || option == `slli) ? 6'b110000 :
                (option == `srl || option == `srli) ? 6'b110001 :
                (option == `sra || option == `srai) ? 6'b110011 :
                (option == `bge) ? 6'b010100 :
                (option == `bne) ? 6'b010010 :
                (option == `beq) ? 6'b010000 :
                (option == `bltu) ? 6'b011010 :
                (option == `blt) ?  6'b010110 :
                (option == `bgeu) ? 6'b011100 :
                (option == `sltiu) ? 6'b000000 :
                (option == `slti) ?  6'b000110 :
                (option == `sltu)  ? 6'b001010 :
                (option == `slt)   ? 6'b000110 :
                6'b010000;

endmodule
