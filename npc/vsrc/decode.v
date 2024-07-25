`include "riscv_param.vh"
`include "riscv_inst.vh"

module decode (
    input [31:0] decode_inst_i,
    output [31:0] decode_imm_o,
    output [4:0] decode_rs1_o,
    output [4:0] decode_rs2_o,
    output [4:0] decode_rd_o,
    output [5:0] decode_fn_o,
    output [5:0] decode_option_o,
    output [2:0] decode_optype_o
);

    // TODO
    wire [31:0] decode_imm_i;
    wire [31:0] decode_imm_s;
    wire [31:0] decode_imm_b;
    wire [31:0] decode_imm_u;
    wire [31:0] decode_imm_j;
    wire [31:0] decode_imm;
    wire [5:0] decode_option;
    wire [6:0] decode_funct7;
    wire [2:0] decode_funct3;
    wire [4:0] decode_rs1;
    wire [4:0] decode_rs2;
    wire [4:0] decode_rd;
    wire [5:0] decode_fn;
    wire [6:0] decode_opcode;
    wire [2:0] decode_optype;

    decode_field decode_field_module (
        .inst_i(decode_inst_i),
        .funct3_o(decode_funct3),
        .rs1_o(decode_rs1),
        .rs2_o(decode_rs2),
        .rd_o(decode_rd),
        .opcode_o(decode_opcode),
        .funct7_o(decode_funct7),
        .imm_i_o(decode_imm_i),
        .imm_s_o(decode_imm_s),
        .imm_b_o(decode_imm_b),
        .imm_u_o(decode_imm_u),
        .imm_j_o(decode_imm_j)
    );

    decode_optype decode_optype_module (
        .decode_opcode_i(decode_opcode),
        .decode_optype_o(decode_optype)
    );

    decode_imm decode_imm_module (
        .decode_optype_i(decode_optype),
        .decode_imm_b_i(decode_imm_b),
        .decode_imm_i_i(decode_imm_i),
        .decode_imm_j_i(decode_imm_j),
        .decode_imm_s_i(decode_imm_s),
        .decode_imm_u_i(decode_imm_u),
        .decode_imm_o(decode_imm)
    );

    decode_option decode_option_module (
        .decode_opcode_i(decode_opcode),
        .decode_optype_i(decode_optype),
        .decode_funct3_i(decode_funct3),
        .decode_funct7_i(decode_funct7),
        .decode_funct12_i(decode_inst_i[31:20]),
        .decode_option_o(decode_option)
    );

    decode_fn decode_fn_module (
        .decode_option_i(decode_option),
        .decode_fn_o(decode_fn)
    );

    assign decode_imm_o = decode_imm;
    assign decode_rs1_o = decode_rs1;
    assign decode_rs2_o = decode_rs2;
    assign decode_rd_o = decode_rd;
    assign decode_option_o = decode_option;
    assign decode_optype_o = decode_optype;
    assign decode_fn_o = decode_fn;

endmodule

module decode_field (
    input [31:0] inst_i,
    output [2:0] funct3_o,
    output [4:0] rs1_o,
    output [4:0] rs2_o,
    output [4:0] rd_o,
    output [6:0] opcode_o,
    output [6:0] funct7_o,
    output [31:0] imm_i_o,
    output [31:0] imm_s_o,
    output [31:0] imm_b_o,
    output [31:0] imm_u_o,
    output [31:0] imm_j_o
);

    // opcode
    assign opcode_o = inst_i[6:0];

    // register
    assign rs1_o = inst_i[19:15];
    assign rs2_o = inst_i[24:20];
    assign rd_o = inst_i[11:7];

    // funct
    assign funct3_o = inst_i[14:12];
    assign funct7_o = inst_i[31:25];
    // 不同指令类型的立即数
    assign imm_i_o = { {20{inst_i[31]}}, inst_i[31:20] };
    assign imm_s_o = { {20{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8] };
    assign imm_b_o = { {19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0 };
    assign imm_u_o = { inst_i[31:12], 12'b0 };
    assign imm_j_o = { {12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0 };

endmodule

module decode_imm (
    input [2:0] decode_optype_i,
    input [31:0] decode_imm_b_i,
    input [31:0] decode_imm_i_i,
    input [31:0] decode_imm_j_i,
    input [31:0] decode_imm_s_i,
    input [31:0] decode_imm_u_i,
    output [31:0] decode_imm_o
);

    // 用于作为 imm 多路选择的信号
    wire [31:0] decode_imm_mux_1;
    wire [31:0] decode_imm_mux_2;
    wire [31:0] decode_imm_mux_3;
    wire [31:0] decode_imm_mux_4;
    wire [31:0] decode_imm_mux_5;

    assign decode_imm_mux_1 = decode_optype_i[0] ? decode_imm_s_i : decode_imm_i_i;
    assign decode_imm_mux_2 = decode_optype_i[0] ? decode_imm_u_i : decode_imm_b_i;
    assign decode_imm_mux_3 = decode_optype_i[0] ? decode_imm_i_i : decode_imm_j_i;
    assign decode_imm_mux_4 = decode_optype_i[1] ? decode_imm_mux_1 : `zeroWord;
    assign decode_imm_mux_5 = decode_optype_i[1] ? decode_imm_mux_3 : decode_imm_mux_2;
    assign decode_imm_o = decode_optype_i[2] ? decode_imm_mux_5 : decode_imm_mux_4;

endmodule

module decode_optype (
    input [6:0] decode_opcode_i,
    output [2:0] decode_optype_o
);

    // Intermediate wires for opcode detection
    wire [2:0] opcode_r;
    wire [2:0] opcode_i;
    wire [2:0] opcode_s;
    wire [2:0] opcode_b;
    wire [2:0] opcode_u;
    wire [2:0] opcode_j;
    wire [2:0] opcode_func;

    // Assign operation types based on opcode
  assign opcode_r = (~|(decode_opcode_i ^ 7'b0110011)) ? `INST_R : `NOTYPE;
  assign opcode_i = (~|(decode_opcode_i ^ 7'b0010011) | ~|(decode_opcode_i ^ 7'b0000011) | ~|(decode_opcode_i ^ 7'b1100111)) ? `INST_I : `NOTYPE;
  assign opcode_s = (~|(decode_opcode_i ^ 7'b0100011)) ? `INST_S : `NOTYPE;
  assign opcode_b = (~|(decode_opcode_i ^ 7'b1100011)) ? `INST_B : `NOTYPE;
  assign opcode_u = (~|(decode_opcode_i ^ 7'b0110111) | ~|(decode_opcode_i ^ 7'b0010111)) ? `INST_U : `NOTYPE;
  assign opcode_j = (~|(decode_opcode_i ^ 7'b1101111)) ? `INST_J : `NOTYPE;
  assign opcode_func = (~|(decode_opcode_i ^ 7'b0001111) | ~|(decode_opcode_i ^ 7'b1110011)) ? `FUNC : `NOTYPE;


    // Determine final operation type
    assign decode_optype_o = opcode_r | opcode_i | opcode_s | opcode_b | opcode_u | opcode_j | opcode_func;
endmodule

module decode_option ( 
    input [6:0] decode_opcode_i, 
    input [2:0] decode_optype_i,
    input [2:0] decode_funct3_i,
    input [6:0] decode_funct7_i,
    input [11:0] decode_funct12_i,
    output [5:0] decode_option_o
);

    // 定义需要用到的内部信号
    wire [5:0] decode_option_r;
    wire [5:0] decode_option_i;
    wire [5:0] decode_option_s;
    wire [5:0] decode_option_b;
    wire [5:0] decode_option_u;
    wire [5:0] decode_option_j;
    wire [5:0] decode_option_func;

    wire [2:0] decode_funct3 = decode_funct3_i;
    wire [6:0] decode_funct7 = decode_funct7_i;
    wire [11:0] decode_funct12 = decode_funct12_i;
    wire [6:0] decode_opcode = decode_opcode_i;
    wire [2:0] decode_optype = decode_optype_i;

    wire [5:0] add_sub;
    assign add_sub = (decode_funct7 == 7'b0000000) ? `inst_add : `inst_sub;

    wire [5:0] sra_srl;
    assign sra_srl = (decode_funct7 == 7'b0000000) ? `inst_srl : `inst_sra;

    assign decode_option_r = ({6{~|(decode_funct3 ^ 3'b000)}} & add_sub) |
                             ({6{~|(decode_funct3 ^ 3'b001)}} & `inst_sll) |
                             ({6{~|(decode_funct3 ^ 3'b010)}} & `inst_slt) |
                             ({6{~|(decode_funct3 ^ 3'b011)}} & `inst_sltu) |
                             ({6{~|(decode_funct3 ^ 3'b100)}} & `inst_xor) |
                             ({6{~|(decode_funct3 ^ 3'b101)}} & sra_srl) |
                             ({6{~|(decode_funct3 ^ 3'b110)}} & `inst_or) |
                             ({6{~|(decode_funct3 ^ 3'b111)}} & `inst_and);

    wire [5:0] srai_srli;
    assign srai_srli = (decode_funct7 == 7'b0000000) ? `inst_srli : `inst_srai;

    wire [5:0] decode_option_load;
    wire [5:0] decode_option_arith;

    assign decode_option_arith = ({6{~|(decode_funct3 ^ 3'b000)}} & `inst_addi) |
                                 ({6{~|(decode_funct3 ^ 3'b010)}} & `inst_slti) |
                                 ({6{~|(decode_funct3 ^ 3'b011)}} & `inst_sltiu) |
                                 ({6{~|(decode_funct3 ^ 3'b100)}} & `inst_xori) |
                                 ({6{~|(decode_funct3 ^ 3'b110)}} & `inst_ori) |
                                 ({6{~|(decode_funct3 ^ 3'b111)}} & `inst_andi) |
                                 ({6{~|(decode_funct3 ^ 3'b001)}} & `inst_slli) |
                                 ({6{~|(decode_funct3 ^ 3'b101)}} & srai_srli);

    assign decode_option_load = ({6{~|(decode_funct3 ^ 3'b000)}} & `inst_lb) |
                                ({6{~|(decode_funct3 ^ 3'b001)}} & `inst_lh) |
                                ({6{~|(decode_funct3 ^ 3'b010)}} & `inst_lw) |
                                ({6{~|(decode_funct3 ^ 3'b100)}} & `inst_lbu) |
                                ({6{~|(decode_funct3 ^ 3'b101)}} & `inst_lhu);

    assign decode_option_i = ({6{~|(decode_opcode ^ 7'b0010011)}} & decode_option_arith) |
                             ({6{~|(decode_opcode ^ 7'b0000011)}} & decode_option_load) |
                             ({6{~|(decode_opcode ^ 7'b1100111)}} & `inst_jalr);

    assign decode_option_s = ({6{~|(decode_funct3 ^ 3'b000)}} & `inst_sb) |
                             ({6{~|(decode_funct3 ^ 3'b001)}} & `inst_sh) |
                             ({6{~|(decode_funct3 ^ 3'b010)}} & `inst_sw);

    assign decode_option_b = ({6{~|(decode_funct3 ^ 3'b000)}} & `inst_beq) |
                             ({6{~|(decode_funct3 ^ 3'b001)}} & `inst_bne) |
                             ({6{~|(decode_funct3 ^ 3'b100)}} & `inst_blt) |
                             ({6{~|(decode_funct3 ^ 3'b101)}} & `inst_bge) |
                             ({6{~|(decode_funct3 ^ 3'b110)}} & `inst_bltu) |
                             ({6{~|(decode_funct3 ^ 3'b111)}} & `inst_bgeu);

    assign decode_option_u = ({6{~|(decode_opcode ^ 7'b0110111)}} & `inst_lui) |
                             ({6{~|(decode_opcode ^ 7'b0010111)}} & `inst_auipc);

    assign decode_option_j = `inst_jal;

    wire [5:0] ecall_ebreak;
    assign ecall_ebreak = (decode_funct12 == 12'h0) ? `inst_ecall : `inst_ebreak;

    assign decode_option_func = ({6{~|(decode_funct3 ^ 3'b000)}} & ecall_ebreak) |
                                ({6{~|(decode_funct3 ^ 3'b001)}} & `inst_csrrw) |
                                ({6{~|(decode_funct3 ^ 3'b010)}} & `inst_csrrs);

    wire [5:0] decode_option;
    assign decode_option = ({6{~|(decode_optype ^ `INST_R)}} & decode_option_r) |
                           ({6{~|(decode_optype ^ `INST_I)}} & decode_option_i) |
                           ({6{~|(decode_optype ^ `INST_S)}} & decode_option_s) |
                           ({6{~|(decode_optype ^ `INST_B)}} & decode_option_b) |
                           ({6{~|(decode_optype ^ `INST_U)}} & decode_option_u) |
                           ({6{~|(decode_optype ^ `INST_J)}} & decode_option_j) |
                           ({6{~|(decode_optype ^ `FUNC)}} & decode_option_func);

    assign decode_option_o = decode_option;
endmodule

module decode_fn(
    input [5:0] decode_option_i,
    output [5:0] decode_fn_o
);

    // 目前使用行为描述
    // 用于使用掩码，通过 assign 连线，综合的结果 decode_fn_o 是常量
    // 没有想到好的解决方法
    reg [5:0] decode_fn;
    always @(*) begin
        casez (decode_option_i)
            `inst_sub: decode_fn = 6'b010001;
            `inst_and: decode_fn = 6'b000111;
            `inst_andi: decode_fn = 6'b000111;
            `inst_or: decode_fn = 6'b101110;
            `inst_ori: decode_fn = 6'b101110;
            `inst_xor: decode_fn = 6'b100110;
            `inst_xori: decode_fn = 6'b100110;
            `inst_sll: decode_fn = 6'b110000;
            `inst_slli: decode_fn = 6'b110000;
            `inst_slt: decode_fn = 6'b000110;
            `inst_slti: decode_fn = 6'b000110;
            `inst_sltu: decode_fn = 6'b001010;
            `inst_sltiu: decode_fn = 6'b000000;
            `inst_sra: decode_fn = 6'b110011;
            `inst_srai: decode_fn = 6'b110011;
            `inst_srl: decode_fn = 6'b110001;
            `inst_srli: decode_fn = 6'b110001;
            `inst_beq: decode_fn = 6'b010000;
            `inst_bge: decode_fn = 6'b010100;
            `inst_bgeu: decode_fn = 6'b011100;
            `inst_blt: decode_fn = 6'b010110;
            `inst_bltu: decode_fn = 6'b011010;
            `inst_bne: decode_fn = 6'b010010;
            default: decode_fn = 6'b010000;
        endcase
    end

    assign decode_fn_o = decode_fn;
endmodule
