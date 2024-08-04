`include "riscv_param.v"

module decode_stage_2 (
    input                               clk_i,
    input                               rst_i,
    // from decode_stage_1
    input                               decode_stage_1_valid_i,
    input  [`STAGE_1_2_BUS_WIDTH-1:0]   decode_stage_1_2_bus_i,
    // from register file
    output [ 4:0]                       decode_stage_2_rs1_o,
    output [ 4:0]                       decode_stage_2_rs2_o,
    input  [31:0]                       rs1_value,
    input  [31:0]                       rs2_value,
    output [`STAGE_2_MEM_BUS_WIDTH-1:0] decode_stage_2_mem_bus_o,
    output                              valid_o
);

    reg valid;
    reg [`STAGE_1_2_BUS_WIDTH-1:0] decode_stage_1_2_bus;
    wire [31:0] decode_stage_2_pc;
    wire [31:0] decode_stage_2_imm;
    wire        decode_stage_2_src1_is_pc;
    wire        decode_stage_2_src2_is_imm;
    wire [ 4:0] decode_stage_2_rs1;
    wire [ 4:0] decode_stage_2_rs2;
    wire [ 4:0] decode_stage_2_rd;
    wire [ 5:0] decode_stage_2_alu_op;
    wire        decode_stage_2_gr_we;
    wire        decode_stage_2_res_from_mem;
    wire        decode_stage_2_res_from_csr;
    wire [11:0] decode_stage_2_csr_addr;
    wire [1:0]  decode_stage_2_jmp_option;
    wire        decode_stage_2_excp_flush;
    wire        decode_stage_2_xret_flush;
    wire        decode_stage_2_break_signal;


    assign {
        decode_stage_2_excp_flush,
        decode_stage_2_xret_flush,
        decode_stage_2_break_signal,
        decode_stage_2_jmp_option,
        decode_stage_2_rs1,
        decode_stage_2_rs2,
        decode_stage_2_rd,
        decode_stage_2_alu_op,
        decode_stage_2_src1_is_pc,
        decode_stage_2_src2_is_imm,
        decode_stage_2_res_from_mem,
        decode_stage_2_res_from_csr,
        decode_stage_2_gr_we,
        decode_stage_2_csr_addr,
        decode_stage_2_pc,
    } = decode_stage_1_2_bus;

    always @(posedge clk_i) begin
        if (rst_i) begin
            decode_stage_1_2_bus <= 0;
            valid <= 0;
        end else if (decode_stage_1_valid_i) begin
            valid <= 1;
            decode_stage_1_2_bus <= decode_stage_1_2_bus_i;
        end else begin
            valid <= 0;
        end
    end

    // Whether the branch jump condition is satisfied
    wire [31:0] decode_stage_2_compare_result;
    compare compare_module (
        .a_i(rs1_value),
        .b_i(rs2_value),
        .op_i(decode_stage_2_alu_op[2:0]),
        .res_o(decode_stage_2_compare_result)
    );

    wire jmp_flag;
    assign jmp_flag = decode_stage_2_compare_result[0] && decode_stage_2_jmp_option[1] ||
                        decode_stage_2_jmp_option[0];

    wire [31:0] src1;
    wire [31:0] src2;
    assign src1 = decode_stage_2_src1_is_pc ? decode_stage_2_pc : rs1_value;
    assign src2 = decode_stage_2_src2_is_imm ? decode_stage_2_imm : rs2_value;

    assign decode_stage_2_mem_bus_o = {
        decode_stage_2_res_from_mem,
        decode_stage_2_res_from_csr,
        decode_stage_2_gr_we,
        decode_stage_2_rd,
        src1,
        src2,
        decode_stage_2_csr_addr,
        jmp_flag,
        decode_stage_2_excp_flush,
        decode_stage_2_xret_flush,
        decode_stage_2_break_signal
    };

    assign decode_stage_rs1_o = decode_stage_2_rs1;
    assign decode_stage_rs2_o = decode_stage_2_rs2;
endmodule