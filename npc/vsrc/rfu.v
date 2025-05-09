`include "./include/generated/autoconf.vh"
`include "riscv_param.vh"
module rfu (
    input                           clock,
    input                           reset,

    input                           excp_flush,
    input                           mret_flush,

    input                           deu_valid_i,
    input  [`DEU_RFU_BUS_WIDTH-1:0] deu_rfu_bus_i,
    input  [ 4:0]                   deu_excp_bus_i,
    output                          rfu_ready_o,
    // regfile
    output [ 4:0]                   rfu_rs1_o,
    output [ 4:0]                   rfu_rs2_o,
    input  [31:0]                   rfu_rs1_value_i,
    input  [31:0]                   rfu_rs2_value_i,
    // csr register
    output [11:0]                   rfu_csr_addr_o,
    input  [31:0]                   rfu_csr_value_i,

    input                           branch_flush,

    // data harzard (bypass)
    input                           exu_valid,
    input  [ 4:0]                   exu_rd,
    input  [11:0]                   exu_csr_addr,
    input                           lsu_valid,
    input  [ 4:0]                   lsu_rd,
    input  [11:0]                   lsu_csr_addr,
    input                           wbu_valid,
    input  [ 4:0]                   wbu_rd,
    input  [11:0]                   wbu_csr_addr,

    input                           exu_ready_i,
    output [`RFU_EXU_BUS_WIDTH-1:0] rfu_exu_bus_o,
    output [ 4:0]                   rfu_excp_bus_o,
    output                          valid_o
);

    reg                             valid;
    reg [`DEU_RFU_BUS_WIDTH-1:0]    deu_rfu_bus;
    reg [ 4:0]                      deu_excp_bus;

    wire [ 4:0] rfu_rd;
    wire [11:0] rfu_csr_addr;
    wire [31:0] rfu_imm;
    wire        rfu_res_from_compare;
    wire [ 2:0] rfu_alu_op;
    wire        rfu_src1_from_pre;
    wire        rfu_res_from_csr;
    wire        rfu_res_from_mem;
    wire        rfu_xret_flush;
    wire        rfu_gr_we;
    wire        rfu_csr_we;
    wire [ 3:0] rfu_mem_re;
    wire [ 3:0] rfu_mem_we;
    wire        rfu_jmp_flag;
    wire [31:0] rfu_snpc;
    wire [31:0] rfu_src1;
    wire        rfu_branch_taken;
    wire        rfu_src2_is_imm;
    wire        rfu_compare_src2_is_imm;
    wire        rfu_src2_is_csr;
    wire [ 2:0] rfu_compare_fn;
    wire        rfu_csr_op;
    wire [31:0] rfu_pc;

    assign {
      rfu_pc,
      rfu_rs1_o,
      rfu_rs2_o,
      rfu_rd,
      rfu_csr_addr,
      rfu_imm,
      rfu_compare_fn,
      rfu_compare_src2_is_imm,
      rfu_src2_is_imm,
      rfu_src2_is_csr,
      rfu_csr_op,
      rfu_res_from_compare,
      rfu_alu_op,
      rfu_src1_from_pre,
      rfu_res_from_mem,
      rfu_res_from_csr,
      rfu_xret_flush,
      rfu_gr_we,
      rfu_csr_we,
      rfu_mem_re,
      rfu_mem_we,
      rfu_jmp_flag,
      rfu_snpc,
      rfu_src1,
      rfu_branch_taken
    } = deu_rfu_bus;
    assign rfu_csr_addr_o = rfu_csr_addr;

    always @(posedge clock) begin
        if (deu_valid_i && rfu_ready_o) begin
            deu_rfu_bus <= deu_rfu_bus_i;
        end
    end

    always @(posedge clock) begin
      if (deu_valid_i && rfu_ready_o) begin
          deu_excp_bus <= deu_excp_bus_i;
      end
    end

    wire  has_flush_sign;
    always @(posedge clock) begin
      if (has_flush_sign) begin
        valid <= 1'b0;
      end else if (deu_valid_i) begin
        valid <= 1'b1;
      end else if (exu_ready_i && !stall) begin
        valid <= 1'b0;
      end
    end
    assign has_flush_sign = reset || branch_flush || excp_flush || mret_flush;

    // stall
    wire stall;
    assign stall =  (exu_valid && ((exu_rd == rfu_rs1_o || exu_rd == rfu_rs2_o) || (rfu_csr_addr_o == exu_csr_addr))) ||
                    (lsu_valid && ((lsu_rd == rfu_rs1_o || lsu_rd == rfu_rs2_o) || (rfu_csr_addr_o == lsu_csr_addr))) ||
                    (wbu_valid && ((wbu_rd == rfu_rs1_o || wbu_rd == rfu_rs2_o) || (rfu_csr_addr_o == wbu_csr_addr)));


    wire        rfu_compare_result;
    wire [31:0] compare_src2;
    assign compare_src2 = rfu_compare_src2_is_imm ? rfu_imm : rfu_rs2_value_i;
    compare compare_module (
        .compare_a_i(rfu_rs1_value_i),
        .compare_b_i(compare_src2),
        .compare_fn_i(rfu_compare_fn),
        .compare_o(rfu_compare_result)
    );

    wire  [31:0]  rfu_src1_value;
    wire  [31:0]  rfu_src2_value;
    assign rfu_src1_value = rfu_src1_from_pre ? rfu_src1 : rfu_rs1_value_i;
    assign rfu_src2_value = rfu_src2_is_imm ? rfu_imm :
                            rfu_src2_is_csr ? rfu_csr_value_i :
                            rfu_rs2_value_i;
    wire  [31:0]  rfu_final_result;
    assign rfu_final_result = rfu_jmp_flag ? rfu_snpc :
                              rfu_res_from_compare ? {31'b0, rfu_compare_result} :
                              rfu_csr_value_i;

    wire          rfu_res_from_pre;
    assign rfu_res_from_pre = rfu_jmp_flag | rfu_res_from_compare | rfu_res_from_csr;

    wire [31:0]  rfu_csr_wdata;
    assign rfu_csr_wdata = rfu_csr_op ? rfu_rs1_value_i : rfu_rs1_value_i | rfu_csr_value_i;

    wire         rfu_branch;
    assign rfu_branch = rfu_branch_taken & rfu_compare_result | rfu_jmp_flag;

    assign rfu_exu_bus_o = {
      rfu_pc,
      rfu_rd,
      rfu_branch,
      rfu_alu_op,
      rfu_src1_value,
      rfu_src2_value,
      rfu_rs2_value_i,
      rfu_res_from_mem,
      rfu_res_from_pre,
      rfu_final_result,
      rfu_mem_re,
      rfu_mem_we,
      rfu_gr_we,
      rfu_csr_we,
      rfu_csr_addr,
      rfu_csr_wdata,
      rfu_snpc,
      rfu_xret_flush,
      rfu_excp_flush,
      rfu_break_signal
    };

    assign rfu_ready_o = !valid || (valid && exu_ready_i && !stall);
    assign valid_o = valid && !stall && !branch_flush;
    // assign rfu_excp_bus_o = deu_excp_bus;
endmodule
