module top (
    input clk_i,
    input rst_i,
    output [31:0] mem_rdata_o
);

    // Internal signals
    wire [31:0] jmp_addr;
    wire jmp_flag;
    wire [31:0] snpc;
    wire [31:0] inst;
    wire [31:0] current_pc;

    fetch fetch_module (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .snpc_i(snpc),
        .jmp_addr_i(jmp_addr),
        .jmp_flag_i(jmp_flag),
        .inst_o(inst),
        .pc_o(current_pc)
    );

    // memory file
    wire [31:0] mem_addr_i;
    wire [31:0] mem_wdata_i;
    wire mem_wen_i;
    wire mem_ren_i;
    wire [31:0] mem_width_i;
    wire mem_wen, mem_ren;
    wire [31:0] mem_width;
    wire [31:0] mem_rdata;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;

    memfile memfile_module (
        .clk_i(clk_i),
        .mem_addr_i(mem_addr),
        .mem_wdata_i(mem_wdata),
        .mem_width_i(mem_width),
        .mem_wen_i(mem_wen),
        .mem_ren_i(mem_ren),
        .mem_rdata_o(mem_rdata_o)
    );
    assign mem_addr = mem_addr_i;
    assign mem_wdata = mem_wdata_i;
    assign mem_wen = mem_wen_i;
    assign mem_ren = mem_ren_i;
    assign mem_width = mem_width_i;
    assign mem_rdata = mem_rdata_o;

    wire [31:0] imm;
    wire [4:0] rs1, rs2, rd;
    wire [5:0] fn, option;
    wire [2:0] optype;
    decode decode_module (
        .decode_inst_i(inst),
        .decode_imm_o(imm),
        .decode_rs1_o(rs1),
        .decode_rs2_o(rs2),
        .decode_rd_o(rd),
        .decode_fn_o(fn),
        .decode_option_o(option),
        .decode_optype_o(optype)
    );

    // register file
    wire [31:0] r1data, r2data, reg_wdata;
    wire reg_wen_o; // 写使能信号在执行的阶段产生
    regfile regfile_module (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .reg_src1_i(rs1),
        .reg_src2_i(rs2),
        .reg_dst_i(rd),
        .reg_wdata_i(reg_wdata),
        .reg_wen_i(reg_wen_o),
        .reg_rdata1_o(r1data),
        .reg_rdata2_o(r2data)
    );

    // csr register
    wire csr_wen_i;
    // writeback stage
    wire csr_wen_o;
    wire [31:0] csr_wdata, csr_rdata;
    wire [31:0] csr_waddr, csr_raddr;
    csr csr_module (
        .clk_i(clk_i),
        .csr_wen_i(csr_wen_o),
        .csr_wdata_i(csr_wdata),
        .csr_waddr_i(csr_waddr),
        .csr_raddr_i(csr_raddr),
        .csr_rdata_o(csr_rdata)
    );

    // execute stage
    wire [31:0] alu_out;
    wire [31:0] compare_out;
    wire reg_wen_i;
    decode_execute decode_execute_module (
        .decode_execute_optype_i(optype),
        .decode_execute_option_i(option),
        .decode_execute_fn_i(fn),
        .decode_execute_imm_i(imm),
        .decode_execute_r1_data_i(r1data),
        .decode_execute_r2_data_i(r2data),
        .decode_execute_inst_addr_i(current_pc),
        .decode_execute_csr_rdata_i(csr_rdata),
        .decode_execute_re_o(mem_ren_i),
        .decode_execute_wen_o(reg_wen_i),
        .decode_execute_csr_wen_o(csr_wen_i),
        .decode_execute_alu_out_o(alu_out),
        .decode_execute_csr_wdata_o(csr_wdata),
        .decode_execute_csr_waddr_o(csr_waddr),
        .decode_execute_csr_raddr_o(csr_raddr),
        .decode_execute_compare_out_o(compare_out)
    );

    // execute stage
    execute execute_module (
        .execute_snpc_i(snpc),
        .execute_alu_out_i(alu_out),
        .execute_compare_out_i(compare_out),
        .execute_imm_i(imm),
        .execute_option_i(option),
        .execute_csr_rdata_i(csr_rdata),
        .execute_mem_rdata_i(mem_rdata),
        .execute_jmp_addr_o(jmp_addr),
        .execute_reg_wdata_o(reg_wdata),
        .execute_mem_width_o(mem_width_i),
        .execute_jmp_flag_o(jmp_flag),
        .execute_mem_wen_o(mem_wen_i)
    );

    writeback writeback_module (
        .writeback_current_pc_i(current_pc),
        .writeback_snpc_o(snpc)
    );
    assign reg_wen_o = reg_wen_i; 
    assign csr_wen_o = csr_wen_i;
endmodule