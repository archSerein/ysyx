module execute (
    input [5:0] execute_option_i,
    input [31:0] execute_snpc_i,
    input [31:0] execute_alu_out_i,
    input [31:0] execute_compare_out_i,
    input [31:0] execute_imm_i,
    input [31:0] execute_csr_rdata_i,
    input [31:0] execute_mem_rdata_i,

    // output
    output [31:0] execute_jmp_addr_o,
    output [31:0] execute_reg_wdata_o,
    output [31:0] execute_mem_width_o,
    output execute_jmp_flag_o,
    output execute_mem_wen_o
);

    // TODO: Implement the execute module
    `include "riscv_param.vh"
    `include "riscv_inst.vh"
    `include "csr.vh"
    // Inner signals
    wire [31:0] alu_out = execute_alu_out_i;
    wire [31:0] compare_out = execute_compare_out_i;
    wire [31:0] imm = execute_imm_i;
    wire [5:0] option = execute_option_i;
    wire [31:0] csr_rdata = execute_csr_rdata_i;
    wire [31:0] mem_rdata = execute_mem_rdata_i;
    wire [31:0] snpc = execute_snpc_i;
    // mem write enable signal
    wire execute_mem_wen;
    assign execute_mem_wen = (option == `inst_sw ||
                             option == `inst_sh ||
                             option == `inst_sb) ? `mem_write_enable : `mem_write_disable;

    // mem width signal
    wire [31:0] mem_width;
    assign mem_width = (option == `inst_sw) ? `mem_width_word :
                       (option == `inst_sh) ? `mem_width_half :
                       (option == `inst_sb) ? `mem_width_byte : `mem_width_none;

    // jmp flag signal
    wire execute_jmp_flag;
    assign execute_jmp_flag = (option == `inst_jalr ||
                               option == `inst_jal ||
                               option == `inst_beq ||
                               option == `inst_bne ||
                               option == `inst_blt ||
                               option == `inst_bge ||
                               option == `inst_bltu ||
                               option == `inst_bgeu) ? `jmp_enable : `jmp_disable;

    // reg write data signal
    wire [31:0] reg_wdata;
    wire [31:0] set_data = (compare_out == 32'h1) ? 32'h1 : 32'h0;

    wire [31:0] reg_data_alu_out =  (option == `inst_auipc ||
                                    option == `inst_addi ||
                                    option == `inst_andi ||
                                    option == `inst_ori ||
                                    option == `inst_xori ||
                                    option == `inst_slli ||
                                    option == `inst_srli ||
                                    option == `inst_srai ||
                                    option == `inst_add ||
                                    option == `inst_sub ||
                                    option == `inst_and ||
                                    option == `inst_or ||           
                                    option == `inst_xor ||
                                    option == `inst_sll ||
                                    option == `inst_srl ||
                                    option == `inst_sra) ? alu_out : `zeroWord;
    wire [31:0] reg_data_mem_rdata = (option == `inst_lw ||
                                    option == `inst_lh ||
                                    option == `inst_lhu ||
                                    option == `inst_lb ||
                                    option == `inst_lbu) ? mem_rdata : `zeroWord;
    wire [31:0] reg_data_csr_rdata = (option == `inst_csrrw ||
                                    option == `inst_csrrs) ? csr_rdata : `zeroWord;
    wire [31:0] reg_data_set_data = (option == `inst_sltiu ||
                                    option == `inst_slti ||
                                    option == `inst_sltu ||
                                    option == `inst_slt) ? set_data : `zeroWord;
    wire [31:0] reg_data_snpc = (option == `inst_jalr ||
                                option == `inst_jal) ? snpc : `zeroWord;
    wire [31:0] reg_data_imm = (option == `inst_lui) ? imm : `zeroWord;

    assign reg_wdata = reg_data_alu_out | reg_data_mem_rdata | reg_data_csr_rdata |
                        reg_data_set_data | reg_data_snpc | reg_data_imm;
    always @(*) begin
        $display("reg_wdata: %h alu_out: %h set_data: %h snpc: %h mem_data: %h csr_data: %h",
                    reg_wdata, alu_out, set_data, snpc, mem_rdata, csr_rdata);
    end

    // 用于产生 jmp_addr 信号
    wire [31:0] jmp_addr;
    wire [31:0] branch_addr = (compare_out == 32'h1) ? alu_out : snpc;
    assign jmp_addr =   ({32{~|(option & `inst_jal_mask)}} & alu_out) |
                        ({32{~|(option & `inst_jalr_mask)}} & alu_out) |
                        ({32{~|(option & `inst_beq_mask)}} & branch_addr) |
                        ({32{~|(option & `inst_bne_mask)}} & branch_addr) |
                        ({32{~|(option & `inst_blt_mask)}} & branch_addr) |
                        ({32{~|(option & `inst_bge_mask)}} & branch_addr) |
                        ({32{~|(option & `inst_bltu_mask)}} & branch_addr) |
                        ({32{~|(option & `inst_bgeu_mask)}} & branch_addr) |
                        ({32{~|(option & `inst_ecall_mask)}} & csr_rdata) |
                        ({32{~|(option & `inst_mret_mask)}} & csr_rdata) |
                        `zeroWord;

    // 输出信号
    assign execute_jmp_addr_o = jmp_addr;
    assign execute_reg_wdata_o = reg_wdata;
    assign execute_mem_width_o = mem_width;
    assign execute_jmp_flag_o = execute_jmp_flag;
    assign execute_mem_wen_o = execute_mem_wen;
endmodule