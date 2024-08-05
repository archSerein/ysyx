module execute (
    input                               clk_i,
    input                               rst_i,
    input                               decode_stage_2_valid_i,
    input  [`STAGE_2_EXE_BUS_WIDTH-1:0] decode_stage_2_exe_bus_i,
    // memfile
    output [31:0]                       mem_addr_o,
    output [31:0]                       mem_wdata_o,
    output [ 3:0]                       mem_width_o,
    output [`EX_TO_MEM_BUS_WIDTH-1:0]   ex_mem_bus_o,
    output                              valid_o
);

    reg [`STAGE_2_EXE_BUS_WIDTH-1:0] decode_stage_2_exe_bus;
    wire [ 5:0]           ex_alu_op;
    wire [31:0]           ex_alu_src1;
    wire [31:0]           ex_alu_src2;
    wire                  ex_res_from_mem;
    wire                  ex_res_from_csr;
    wire                  ex_gr_we;
    wire [ 4:0]           ex_rd;
    wire [31:0]           ex_pc;
    wire                  ex_xret_flush;
    wire                  ex_excp_flush;
    wire [11:0]           ex_csr_addr;
    wire                  ex_jmp_flag;
    wire                  ex_break_signal;

    assign {
        ex_pc,
        ex_alu_op,
        ex_res_from_mem,
        ex_res_from_csr,
        ex_gr_we,
        ex_rd,
        ex_alu_src1,
        ex_alu_src2,
        ex_csr_addr,
        ex_jmp_flag,
        ex_excp_flush,
        ex_xret_flush,
        ex_break_signal
    } = decode_stage_2_exe_bus;
        
    wire [31:0] ex_alu_result;
    alu alu_module (
        .alu_op_i       (ex_alu_op),
        .alu_a_i        (ex_alu_src1),
        .alu_b_i        (ex_alu_src2),
        .alu_result_o   (ex_alu_result)
    );


endmodule