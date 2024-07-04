module execute (
    input [31:0] execute_inst_i,
    input [31:0] execute_snpc_i,
    input [31:0] execute_alu_out_i,
    input [31:0] execute_compare_out_i,
    input [31:0] execute_imm_i,
    input [31:0] execute_option_i,
    input [31:0] execute_csr_rdata_i,
    input [31:0] execute_mem_rdata_i,

    // output
    output [31:0] execute_jmp_addr_o,
    output [31:0] execute_reg_wdata_o,
    output [31:0] execute_mem_width_o,
    output execute_jmp_flag_o,
    output execute_mem_wen
);

    // TODO: Implement the execute module

endmodule