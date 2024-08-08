`include "riscv_param.vh"

module adu (
    input                           clk_i,
    input                           rst_i,
    input                           bdu_valid_i,
    input  [`BDU_ADU_BUS_WIDTH-1:0] bdu_adu_bus_i,
    output [`ADU_EXU_BUS_WIDTH-1:0] adu_exu_bus_o,
    output                          valid_o
);

    reg valid;
    reg [`BDU_ADU_BUS_WIDTH-1:0] bdu_adu_bus;

    wire [31:0] adu_pc;
    wire [31:0] adu_imm;
    wire [31:0] adu_rs1_value;
    wire [31:0] adu_rs2_value;
    wire [ 4:0] adu_rs1;
    wire [ 4:0] adu_rs2;
    wire [ 4:0] adu_rd;
    wire [ 6:0] adu_funct7;
    wire [ 2:0] adu_funct3;
    wire [ 6:0] adu_opcode;
    wire [ 2:0] adu_optype;
    wire [11:0] adu_csr_addr;
    wire [31:0] adu_csr_value;
    wire [31:0] adu_snpc;
    wire        adu_br_taken;
    wire        res_from_compare;
    wire        compare_result;

    assign {
        res_from_compare,
        compare_result,
        adu_snpc,
        adu_pc,
        adu_imm,
        adu_rs1_value,
        adu_rs2_value,
        adu_rs1,
        adu_rs2,
        adu_rd,
        adu_br_taken,
        adu_csr_addr,
        adu_csr_value,
        adu_optype,
        adu_opcode,
        adu_funct3,
        adu_funct7
    } = bdu_adu_bus;

    always @(posedge clk_i) begin
        if (rst_i) begin
            valid <= 1'b0;
            bdu_adu_bus <= 0;
        end else if (bdu_valid_i) begin
            valid <= 1'b1;
            bdu_adu_bus <= bdu_adu_bus_i;
        end else begin
            valid <= 1'b0;
        end
    end

    // instruction
    wire            inst_lui;
    wire            inst_auipc;
    wire            inst_jal;
    wire            inst_jalr;
    wire            inst_lb;
    wire            inst_lh;
    wire            inst_lw;
    wire            inst_lbu;
    wire            inst_lhu;
    wire            inst_sb;
    wire            inst_sh;
    wire            inst_sw;
    wire            inst_addi;
    wire            inst_xori;
    wire            inst_ori;
    wire            inst_andi;
    wire            inst_slli;
    wire            inst_srli;
    wire            inst_srai;
    wire            inst_add;
    wire            inst_sub;
    wire            inst_sll;
    wire            inst_xor;
    wire            inst_srl;
    wire            inst_sra;
    wire            inst_or;
    wire            inst_and;
    // privileged instruction
    wire            inst_ecall;
    wire            inst_mret;
    wire            inst_ebreak;
    // csr instruction
    wire            inst_csrrw;
    wire            inst_csrrs;

    assign inst_lui    = adu_opcode == 7'b0110111;
    assign inst_auipc  = adu_opcode == 7'b0010111;
    assign inst_jal    = adu_opcode == 7'b1101111;
    assign inst_jalr   = adu_opcode == 7'b1100111 && adu_funct3 == 3'b000;
    assign inst_lb     = adu_opcode == 7'b0000011 && adu_funct3 == 3'b000;
    assign inst_lh     = adu_opcode == 7'b0000011 && adu_funct3 == 3'b001;
    assign inst_lw     = adu_opcode == 7'b0000011 && adu_funct3 == 3'b010;
    assign inst_lbu    = adu_opcode == 7'b0000011 && adu_funct3 == 3'b100;
    assign inst_lhu    = adu_opcode == 7'b0000011 && adu_funct3 == 3'b101;
    assign inst_sb     = adu_opcode == 7'b0100011 && adu_funct3 == 3'b000;
    assign inst_sh     = adu_opcode == 7'b0100011 && adu_funct3 == 3'b001;
    assign inst_sw     = adu_opcode == 7'b0100011 && adu_funct3 == 3'b010;
    assign inst_addi   = adu_opcode == 7'b0010011 && adu_funct3 == 3'b000;
    assign inst_xori   = adu_opcode == 7'b0010011 && adu_funct3 == 3'b100;
    assign inst_ori    = adu_opcode == 7'b0010011 && adu_funct3 == 3'b110;
    assign inst_andi   = adu_opcode == 7'b0010011 && adu_funct3 == 3'b111;
    assign inst_slli   = adu_opcode == 7'b0010011 && adu_funct3 == 3'b001 && 
                            adu_funct7 == 7'b0000000;
    assign inst_srli   = adu_opcode == 7'b0010011 && adu_funct3 == 3'b101 &&
                            adu_funct7 == 7'b0000000;
    assign inst_srai   = adu_opcode == 7'b0010011 && adu_funct3 == 3'b101 &&
                            adu_funct7 == 7'b0100000;
    assign inst_add    = adu_opcode == 7'b0110011 && adu_funct3 == 3'b000 &&
                            adu_funct7 == 7'b0000000;
    assign inst_sub    = adu_opcode == 7'b0110011 && adu_funct3 == 3'b000 &&
                            adu_funct7 == 7'b0100000;
    assign inst_sll    = adu_opcode == 7'b0110011 && adu_funct3 == 3'b001 &&
                            adu_funct7 == 7'b0000000;
    assign inst_xor    = adu_opcode == 7'b0110011 && adu_funct3 == 3'b100 &&
                            adu_funct7 == 7'b0000000;
    assign inst_srl    = adu_opcode == 7'b0110011 && adu_funct3 == 3'b101 &&
                            adu_funct7 == 7'b0000000;
    assign inst_sra    = adu_opcode == 7'b0110011 && adu_funct3 == 3'b101 &&
                            adu_funct7 == 7'b0100000;
    assign inst_or     = adu_opcode == 7'b0110011 && adu_funct3 == 3'b110 &&
                            adu_funct7 == 7'b0000000;
    assign inst_and    = adu_opcode == 7'b0110011 && adu_funct3 == 3'b111 &&
                            adu_funct7 == 7'b0000000;
    // privileged instruction
    assign inst_ecall  = adu_opcode == 7'b1110011 && adu_funct3 == 3'b000 &&
                            adu_funct7 == 7'b0000000 && adu_rd == 5'b00000 &&
                            adu_rs1 == 5'b00000 && adu_rs2 == 5'b00000;
    assign inst_ebreak = adu_opcode == 7'b1110011 && adu_funct3 == 3'b000 &&
                            adu_funct7 == 7'b0000000 && adu_rd == 5'b00000 &&
                            adu_rs1 == 5'b00000 && adu_rs2 == 5'b00001;
    assign inst_mret   = adu_opcode == 7'b1110011 && adu_funct3 == 3'b000 &&
                            adu_funct7 == 7'b0011000 && adu_rd == 5'b00000 &&
                            adu_rs1 == 5'b00000 && adu_rs2 == 5'b00010;

    // csr instruction
    assign inst_csrrw  = adu_opcode == 7'b1110011 && adu_funct3 == 3'b001;
    assign inst_csrrs  = adu_opcode == 7'b1110011 && adu_funct3 == 3'b010;

    // control signal generation
    wire [5:0] alu_op;
    assign alu_op = {6{inst_auipc}} & 6'b110000 |
                    {6{inst_jal  }} & 6'b110000 |
                    {6{inst_jalr }} & 6'b110000 |
                    {6{inst_lb   }} & 6'b110000 |
                    {6{inst_lbu  }} & 6'b110000 |
                    {6{inst_lh   }} & 6'b110000 |
                    {6{inst_lhu  }} & 6'b110000 |
                    {6{inst_lw   }} & 6'b110000 |
                    {6{inst_sb   }} & 6'b110000 |
                    {6{inst_sh   }} & 6'b110000 |
                    {6{inst_sw   }} & 6'b110000 |
                    {6{inst_addi }} & 6'b110000 |
                    {6{inst_lui  }} & 6'b110000 |
                    {6{inst_xori }} & 6'b010110 |
                    {6{inst_ori  }} & 6'b011110 |
                    {6{inst_andi }} & 6'b011000 |
                    {6{inst_slli }} & 6'b100000 |
                    {6{inst_srli }} & 6'b100001 |
                    {6{inst_srai }} & 6'b100011 |
                    {6{inst_add  }} & 6'b110000 |
                    {6{inst_sub  }} & 6'b110001 |
                    {6{inst_sll  }} & 6'b100000 |
                    {6{inst_xor  }} & 6'b010110 |
                    {6{inst_srl  }} & 6'b100001 |
                    {6{inst_sra  }} & 6'b100011 |
                    {6{inst_or   }} & 6'b011110 |
                    {6{inst_and  }} & 6'b011000 |
                    {6{adu_optype == `INST_B}} & 6'b110000;

    wire src1_is_pc;
    assign src1_is_pc = adu_optype == `INST_J || adu_optype == `INST_B || inst_auipc;

    wire src1_is_zero;
    assign src1_is_zero = inst_lui;

    wire src2_is_imm;
    assign src2_is_imm = adu_optype == `INST_I || adu_optype == `INST_S || adu_optype == `INST_B ||
                        adu_optype == `INST_U || adu_optype == `INST_J;

    wire res_from_mem;
    assign res_from_mem = inst_lb || inst_lh || inst_lw || inst_lbu || inst_lhu;

    wire res_from_csr;
    assign res_from_csr = inst_csrrw || inst_csrrs;

    wire xret_flush;
    assign xret_flush = inst_mret;

    wire break_signal;
    assign break_signal = inst_ebreak;

    wire excp_flush;
    assign excp_flush = inst_ecall;

    wire gr_we;
    assign gr_we = adu_optype != `INST_S && adu_optype != `INST_B && !inst_ecall && !inst_mret
                    && !inst_ebreak;

    wire csr_we;
    assign csr_we = inst_csrrw || inst_csrrs;

    wire [3:0] adu_mem_re;  
    assign adu_mem_re = {4{inst_lb}} & 4'b0101 |
                        {4{inst_lh}} & 4'b0111 |
                        {4{inst_lw}} & 4'b1111 |
                        {4{inst_lbu}} & 4'b0001 |
                        {4{inst_lhu}} & 4'b0011;

    wire [3:0] adu_mem_we;
    assign adu_mem_we = {4{inst_sb}} & 4'b0001 |
                        {4{inst_sh}} & 4'b0011 |
                        {4{inst_sw}} & 4'b1111;

    wire [31:0] adu_src1;
    wire [31:0] adu_src2;
    assign adu_src1 =   {32{src1_is_pc}} & adu_pc |
                        {32{src1_is_zero}} & 32'h0 |
                        {32{!src1_is_pc & !src1_is_zero}} & adu_rs1_value;
    assign adu_src2 = src2_is_imm ? adu_imm : adu_rs2_value;

    wire jmp_flag;
    assign jmp_flag = inst_jal || inst_jalr || adu_br_taken;

    assign adu_exu_bus_o = {
        res_from_compare,
        compare_result,
        excp_flush,
        xret_flush,
        break_signal,
        adu_snpc,
        adu_src1,
        adu_src2,
        adu_rs2_value,
        alu_op,
        res_from_mem,
        res_from_csr,
        gr_we,
        csr_we,
        adu_mem_re,
        adu_mem_we,
        adu_rd,
        jmp_flag,
        adu_csr_addr,
        adu_csr_value
    };
    /* 1 + 1 + 1 + 32 + 32 + 32 + 6 + 1 + 1 + 1 + 1 + 4 + 4 + 5 + 1 + 12 + 32 = 167*/

    assign valid_o = valid;
endmodule
