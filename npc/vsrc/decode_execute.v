module decode_execute (
    input [2:0] decode_execute_optype_i,
    input [5:0] decode_execute_option_i,
    input [5:0] decode_execute_fn_i,
    input [31:0] decode_execute_imm_i,
    input [31:0] decode_execute_r1_data_i,
    input [31:0] decode_execute_r2_data_i,
    input [31:0] decode_execute_inst_addr_i,
    input [31:0] decode_execute_csr_rdata_i,

    // output
    output decode_execute_re_o,
    output decode_execute_wen_o,
    output decode_execute_csr_wen_o,
    output [31:0] decode_execute_alu_out_o,
    output [31:0] decode_execute_csr_wdata_o,
    output [31:0] decode_execute_csr_waddr_o,
    output [31:0] decode_execute_csr_raddr_o,
    output [31:0] decode_execute_compare_out_o
);

    // 后续会将具体的数值使用宏定义替换
    // 使代码更加清晰，便于阅读和维护
    `include "riscv_param.vh"
    `include "csr.vh"
    wire [2:0] decode_execute_optype = decode_execute_optype_i;
    wire [5:0] decode_execute_fn = decode_execute_fn_i;
    wire [5:0] decode_execute_option = decode_execute_option_i;
    wire [31:0] decode_execute_r1_data = decode_execute_r1_data_i;
    wire [31:0] decode_execute_r2_data = decode_execute_r2_data_i;
    wire [31:0] decode_execute_imm = decode_execute_imm_i;
    wire [31:0] decode_execute_inst_addr = decode_execute_inst_addr_i;
    wire [31:0] decode_execute_csr_rdata = decode_execute_csr_rdata_i;


    // mem  读使能信号
    wire decode_execute_re;
    assign decode_execute_re = (decode_execute_option == `inst_lw ||
                                decode_execute_option == `inst_lh ||
                                decode_execute_option == `inst_lhu ||
                                decode_execute_option == `inst_lb ||
                                decode_execute_option == `inst_lbu) ? `mem_read_enable : `mem_read_disable;

    // 寄存器写使能信号
    wire decode_execute_wen;
    assign decode_execute_wen = (decode_execute_optype == `INST_S ||
                                 decode_execute_optype == `INST_B) ? `reg_write_disable : `reg_write_enable;

    // csr 写使能信号
    wire decode_execute_csr_wen;
    assign decode_execute_csr_wen = (decode_execute_option == `inst_csrrw ||
                                     decode_execute_option == `inst_csrrs ||
                                     decode_execute_option == `inst_ecall) ? `csr_write_enable : `csr_write_disable;

    // csr write data
    wire [31:0] decode_execute_csr_wdata;
    assign decode_execute_csr_wdata = (decode_execute_option == `inst_csrrw) ? decode_execute_r1_data :
                                      (decode_execute_option == `inst_ecall) ? decode_execute_inst_addr :
                                      (decode_execute_r1_data | decode_execute_csr_rdata);

    // csr read address
    wire [31:0] decode_execute_csr_raddr;
    assign decode_execute_csr_raddr =   (decode_execute_option == `inst_csrrs ||
                                        decode_execute_option == `inst_csrrw) ? decode_execute_imm :
                                        (decode_execute_option == `inst_ecall) ? `MTVEC_ADDR :
                                        `MEPC_ADDR;

    // csr write address
    wire [31:0] decode_execute_csr_waddr;
    assign decode_execute_csr_waddr =   (decode_execute_option == `inst_csrrw ||
                                        decode_execute_option == `inst_csrrs) ? decode_execute_imm :
                                        (decode_execute_option == `inst_ecall) ? `MEPC_ADDR :
                                        `zeroWord;
    // 根据不同的指令选择不同的操作数
    wire [31:0] alu_a, alu_b;
    wire [31:0] decode_execute_alu_out;
    assign alu_a = (decode_execute_optype == `INST_B ||
                    decode_execute_optype == `INST_U ||
                    decode_execute_optype == `INST_J) ?
                    decode_execute_inst_addr : decode_execute_r1_data;

    assign alu_b = (decode_execute_optype == `INST_I ||
                    decode_execute_optype == `INST_S ||
                    decode_execute_optype == `INST_B ||
                    decode_execute_optype == `INST_U ||
                    decode_execute_optype == `INST_J) ?
                    decode_execute_imm : decode_execute_r2_data;
    // alu 模块
    alu alu_module (
        .alu_op_i(decode_execute_fn),
        .alu_a_i(alu_a),
        .alu_b_i(alu_b),
        .alu_result_o(decode_execute_alu_out)
    );

    // 比较器模块
    wire [31:0] decode_execute_b = (decode_execute_option == `inst_sltiu) ? `zeroWord : decode_execute_r2_data;
    wire [31:0] decode_execute_compare_out;
    compare compare_module (
        .compare_fn_i(decode_execute_fn[3:1]),
        .compare_a_i(decode_execute_r1_data),
        .compare_b_i(decode_execute_b),
        .compare_o(decode_execute_compare_out)
    );
    
    // output signal
    assign decode_execute_re_o = decode_execute_re;
    assign decode_execute_wen_o = decode_execute_wen;
    assign decode_execute_csr_wen_o = decode_execute_csr_wen;
    assign decode_execute_alu_out_o = decode_execute_alu_out;
    assign decode_execute_csr_wdata_o = decode_execute_csr_wdata;
    assign decode_execute_csr_waddr_o = decode_execute_csr_waddr;
    assign decode_execute_csr_raddr_o = decode_execute_csr_raddr;
    assign decode_execute_compare_out_o = decode_execute_compare_out;
endmodule