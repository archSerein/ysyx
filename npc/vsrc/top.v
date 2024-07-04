module top (
    input clk_i,
    input rst_i,
    input mem_addr_i,
    input mem_wdata_i,
    input mem_wen_i,
    input mem_ren_i,
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

    memfile memfile_module (
        .clk_i(clk_i),
        .mem_addr_i(mem_addr_i),
        .mem_wdata_i(mem_wdata_i),
        .mem_wen_i(mem_wen_i),
        .mem_ren_i(mem_ren_i),
        .mem_rdata_o(mem_rdata_o)
    );

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

endmodule