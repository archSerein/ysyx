`include "riscv_param.h"
// decode stage 1
module decode_stage_1 (
    input                               clk_i,
    input                               rst_i,
    input [`FETCH_DECODE_BUS_WIDTH-1:0] fetch_decode_bus_i,
    output[`STAGE_1_2_BUS_WIDTH-1:0]    stage_1_2_bus_o,
    output                              valid_o
);

    // instruction
    wire            inst_lui;
    wire            inst_auipc;
    wire            inst_jal;
    wire            inst_jalr;
    wire            inst_beq;
    wire            inst_bne;
    wire            inst_blt;
    wire            inst_bge;
    wire            inst_bltu;
    wire            inst_bgeu;
    wire            inst_lb;
    wire            inst_lh;
    wire            inst_lw;
    wire            inst_lbu;
    wire            inst_lhu;
    wire            inst_sb;
    wire            inst_sh;
    wire            inst_sw;
    wire            inst_addi;
    wire            inst_slti;
    wire            inst_sltiu;
    wire            inst_xori;
    wire            inst_ori;
    wire            inst_andi;
    wire            inst_slli;
    wire            inst_srli;
    wire            inst_srai;
    wire            inst_add;
    wire            inst_sub;
    wire            inst_sll;
    wire            inst_slt;
    wire            inst_sltu;
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

    // inst field
    wire [ 6:0]     inst_opcode;
    wire [ 6:0]     inst_funct7;
    wire [ 2:0]     inst_funct3;
    wire [ 4:0]     inst_rs1;
    wire [ 4:0]     inst_rs2;
    wire [ 4:0]     inst_rd;

    // immidiate field
    wire [31:0]     imm_i;
    wire [31:0]     imm_s;
    wire [31:0]     imm_b;
    wire [31:0]     imm_u;
    wire [31:0]     imm_j;

    wire [2:0]      optype;

    wire [31:0]     decode_pc;
    wire [31:0]     decode_inst;
    reg  [`FETCH_DECODE_BUS_WIDTH-1:0] fetch_decode_bus;
    assign {decode_pc, decode_inst} = fetch_decode_bus;

    assign inst_opcode = decode_inst[6:0];
    assign inst_funct7 = decode_inst[31:25];
    assign inst_funct3 = decode_inst[14:12];
    assign inst_rs1    = decode_inst[19:15];
    assign inst_rs2    = decode_inst[24:20];
    assign inst_rd     = decode_inst[11:7];
    assign imm_i       = { {20{inst_i[31]}}, inst_i[31:20] };
    assign imm_s       = { {20{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8] };
    assign imm_b       = { {19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0 };
    assign imm_u       = { inst_i[31:12], 12'b0 };
    assign imm_j       = { {12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0 };

    // 不包括 fence 和 fence.i 指令
    assign optype      =    {3{inst_decode == 7'b0110011}} & `INST_R |
                            {3{inst_decode == 7'b0100011}} & `INST_S |
                            {3{inst_decode == 7'b1100011}} & `INST_B |
                            {3{inst_decode == 7'b1101111}} & `INST_J |
                            {3{inst_decode == 7'b0110111}} & `INST_U |
                            {3{inst_decode == 7'b0010111}} & `INST_U |
                            {3{inst_decode == 7'b0010011}} & `INST_I |
                            {3{inst_decode == 7'b0000011}} & `INST_I |
                            {3{inst_decode == 7'b1100111}} & `INST_I |
                            {3{inst_decode == 7'b1110011}} & `INST_PRIV;
                            
    assign inst_lui    = inst_opcode == 7'b0110111;
    assign inst_auipc  = inst_opcode == 7'b0010111;
    assign inst_jal    = inst_opcode == 7'b1101111;
    assign inst_jalr   = inst_decode == 7'b1101111 && inst_funct3 == 3'b000;
    assign inst_beq    = inst_decode == 7'b1100011 && inst_funct3 == 3'b000;
    assign inst_bne    = inst_decode == 7'b1100011 && inst_funct3 == 3'b001;
    assign inst_blt    = inst_decode == 7'b1100011 && inst_funct3 == 3'b100;
    assign inst_bge    = inst_decode == 7'b1100011 && inst_funct3 == 3'b101;
    assign inst_bltu   = inst_decode == 7'b1100011 && inst_funct3 == 3'b110;
    assign inst_bgeu   = inst_decode == 7'b1100011 && inst_funct3 == 3'b111;
    assign inst_lb     = inst_decode == 7'b0000011 && inst_funct3 == 3'b000;
    assign inst_lh     = inst_decode == 7'b0000011 && inst_funct3 == 3'b001;
    assign inst_lw     = inst_decode == 7'b0000011 && inst_funct3 == 3'b010;
    assign inst_lbu    = inst_decode == 7'b0000011 && inst_funct3 == 3'b100;
    assign inst_lhu    = inst_decode == 7'b0000011 && inst_funct3 == 3'b101;
    assign inst_sb     = inst_decode == 7'b0100011 && inst_funct3 == 3'b000;
    assign inst_sh     = inst_decode == 7'b0100011 && inst_funct3 == 3'b001;
    assign inst_sw     = inst_decode == 7'b0100011 && inst_funct3 == 3'b010;
    assign inst_addi   = inst_decode == 7'b0010011 && inst_funct3 == 3'b000;
    assign inst_slti   = inst_decode == 7'b0010011 && inst_funct3 == 3'b010;
    assign inst_sltiu  = inst_decode == 7'b0010011 && inst_funct3 == 3'b011;
    assign inst_xori   = inst_decode == 7'b0010011 && inst_funct3 == 3'b100;
    assign inst_ori    = inst_decode == 7'b0010011 && inst_funct3 == 3'b110;
    assign inst_andi   = inst_decode == 7'b0010011 && inst_funct3 == 3'b111;
    assign inst_slli   = inst_decode == 7'b0010011 && inst_funct3 == 3'b001 && 
                            inst_funct7 == 7'b0000000;
    assign inst_srli   = inst_decode == 7'b0010011 && inst_funct3 == 3'b101 &&
                            inst_funct7 == 7'b0000000;
    assign inst_srai   = inst_decode == 7'b0010011 && inst_funct3 == 3'b101 &&
                            inst_funct7 == 7'b0100000;
    assign inst_add    = inst_decode == 7'b0110011 && inst_funct3 == 3'b000 &&
                            inst_funct7 == 7'b0000000;
    assign inst_sub    = inst_decode == 7'b0110011 && inst_funct3 == 3'b000 &&
                            inst_funct7 == 7'b0100000;
    assign inst_sll    = inst_decode == 7'b0110011 && inst_funct3 == 3'b001 &&
                            inst_funct7 == 7'b0000000;
    assign inst_slt    = inst_decode == 7'b0110011 && inst_funct3 == 3'b010 &&
                            inst_funct7 == 7'b0000000;
    assign inst_sltu   = inst_decode == 7'b0110011 && inst_funct3 == 3'b011 &&
                            inst_funct7 == 7'b0000000;
    assign inst_xor    = inst_decode == 7'b0110011 && inst_funct3 == 3'b100 &&
                            inst_funct7 == 7'b0000000;
    assign inst_srl    = inst_decode == 7'b0110011 && inst_funct3 == 3'b101 &&
                            inst_funct7 == 7'b0000000;
    assign inst_sra    = inst_decode == 7'b0110011 && inst_funct3 == 3'b101 &&
                            inst_funct7 == 7'b0100000;
    assign inst_or     = inst_decode == 7'b0110011 && inst_funct3 == 3'b110 &&
                            inst_funct7 == 7'b0000000;
    assign inst_and    = inst_decode == 7'b0110011 && inst_funct3 == 3'b111 &&
                            inst_funct7 == 7'b0000000;
    // privileged instruction
    assign inst_ecall  = inst_decode == 7'b1110011 && inst_funct3 == 3'b000 &&
                            inst_funct7 == 7'b0000000 && inst_rd == 5'b00000 &&
                            inst_rs1 == 5'b00000 && inst_rs2 == 5'b00000;
    assign inst_ebreak = inst_decode == 7'b1110011 && inst_funct3 == 3'b000 &&
                            inst_funct7 == 7'b0000000 && inst_rd == 5'b00000 &&
                            inst_rs1 == 5'b00000 && inst_rs2 == 5'b00001;
    assign inst_mret   = inst_decode == 7'b1110011 && inst_funct3 == 3'b000 &&
                            inst_funct7 == 7'b0011000 && inst_rd == 5'b00000 &&
                            inst_rs1 == 5'b00000 && inst_rs2 == 5'b00010;

    // csr instruction
    assign inst_csrrw  = inst_decode == 7'b1110011 && inst_funct3 == 3'b001;
    assign inst_csrrs  = inst_decode == 7'b1110011 && inst_funct3 == 3'b010;

    // control signal generation
    wire [5:0] alu_op;
    assign alu_op = {6{inst_auipc}} & 6'b110000 |
                    {6{inst_jal  }} & 6'b110000 |
                    {6{inst_jalr }} & 6'b110000 |
                    {6{inst_beq  }} & 6'b000000 |
                    {6{inst_bne  }} & 6'b000001 |
                    {6{inst_blt  }} & 6'b000011 |
                    {6{inst_bge  }} & 6'b000010 |
                    {6{inst_bltu }} & 6'b000101 |
                    {6{inst_bgeu }} & 6'b000110 |
                    {6{inst_lb   }} & 6'b110000 |
                    {6{inst_lbu  }} & 6'b110000 |
                    {6{inst_lh   }} & 6'b110000 |
                    {6{inst_lhu  }} & 6'b110000 |
                    {6{inst_lw   }} & 6'b110000 |
                    {6{inst_sb   }} & 6'b110000 |
                    {6{inst_sh   }} & 6'b110000 |
                    {6{inst_sw   }} & 6'b110000 |
                    {6{inst_addi }} & 6'b110000 |
                    {6{inst_slti }} & 6'b000011 |
                    {6{inst_sltiu}} & 6'b000101 |
                    {6{inst_xori }} & 6'b010110 |
                    {6{inst_ori  }} & 6'b111110 |
                    {6{inst_andi }} & 6'b111000 |
                    {6{inst_slli }} & 6'b100000 |
                    {6{inst_srli }} & 6'b100001 |
                    {6{inst_srai }} & 6'b100011 |
                    {6{inst_add  }} & 6'b110000 |
                    {6{inst_sub  }} & 6'b110001 |
                    {6{inst_sll  }} & 6'b100000 |
                    {6{inst_slt  }} & 6'b000011 |
                    {6{inst_sltu }} & 6'b000101 |
                    {6{inst_xor  }} & 6'b010110 |
                    {6{inst_srl  }} & 6'b100001 |
                    {6{inst_sra  }} & 6'b100011 |
                    {6{inst_or   }} & 6'b111110 |
                    {6{inst_and  }} & 6'b111000;

    wire src1_is_pc;
    assign src1_is_pc = optype == `INST_U || optype == `INST_J || optype == `INST_B;

    wire src2_is_imm;
    assign src2_is_imm = optype == `INST_I || optype == `INST_S || optype == `INST_B ||
                        optype == `INST_U || optype == `INST_J;

    wire res_from_mem;
    assign res_from_mem = inst_lb || inst_lh || inst_lw || inst_lbu || inst_lhu;

    wire res_from_csr;
    assign res_from_csr = inst_csrrw || inst_csrrs;

    wire gr_we;
    assign gr_we = optype != `INST_S && optype != `INST_B && !inst_ecall && !inst_mret
                    && !inst_ebreak;

    wire csr_we;
    assign csr_we = inst_csrrw || inst_csrrs;

    wire [11:0] csr_addr;
    assign csr_addr = decode_inst[31:20];

    wire [31:0] imm;
    assign imm =    {32{optype == `INST_U}} & imm_u |
                    {32{optype == `INST_J}} & imm_j |
                    {32{optype == `INST_I}} & imm_i |
                    {32{optype == `INST_S}} & imm_s |
                    {32{optype == `INST_B}} & imm_b;
    
    wire [1:0] jmp_option;
    assign jmp_option = {optype == `INST_B, inst_jal | inst_jalr};

    wire excp_flush;
    assign excp_flush = inst_ecall;

    wire xret_flush;
    assign xret_flush = inst_mret;

    wire break_signal;
    assign break_signal = inst_ebreak;

    always @(posedge clk_i) begin
        if (rst_i) begin
            valid <= 0;
            fetch_decode_bus <= 0;
        end else if (fetch_valid_i) begin
            valid <= 1;
            fetch_decode_bus <= fetch_decode_bus_i;
        end else begin
            valid <= 0;
        end
    end

    // stage 1 to stage 2 bus
    assign stage_1_2_bus_o = {
                                excp_flush,         // 107:107
                                xret_flush,         // 106:106
                                break_signal,       // 105:105
                                jmp_option,         // 104:103
                                rs1,                // 102:98
                                rs2,                // 97:93
                                rd,                 // 92:88
                                imm,                // 87:56
                                alu_op,             // 55:50
                                src1_is_pc,         // 49:49
                                src2_is_imm,        // 48:48
                                res_from_mem,       // 47:47
                                res_from_csr,       // 46:46
                                gr_we,              // 45:45
                                csr_we,             // 44:44
                                csr_addr,           // 43:32
                                decode_pc,          // 31:0
                            };
    assign valid_o = valid;
endmodule             