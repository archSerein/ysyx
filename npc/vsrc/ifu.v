`include "riscv_param.vh"
`include "csr.vh"

module ifu (
    input                               clk_i,
    input                               rst_i,
    input                               wbu_finish_i,
    input  [`WBU_IFU_BUS_WIDTH-1:0]     wbu_ifu_bus_i,     // 从 wbu 模块获取的数据, 分支或者异常

    // csr register
    input  [`CSR_DATA_WIDTH-1:0]        csr_mtvec,
    input  [`CSR_DATA_WIDTH-1:0]        csr_mepc,

    output [`IFU_BDU_BUS_WIDTH-1:0]     ifu_bdu_bus_o,

    output                              difftest_o,
    output                              valid_o
);

    localparam RESET_PC = 32'h80000000;

    reg  [31:0] ifu_pc;
    reg         valid;
    reg         difftest;
    wire [31:0] ifu_inst;
    // 实例化一个加法器用来作为 pc 的自增
    wire [31:0] snpc;
    arith pc_arith (
        .arith_a_i(ifu_pc),
        .arith_b_i(32'h4),
        .AFN(1'b0),
        .arith_o(snpc),
        /* verilator lint_off PINCONNECTEMPTY */
        .arith_flag_o()
        /* verilator lint_on PINCONNECTEMPTY */
    );

    wire        jmp_flag;
    wire        xret_flush;
    wire        excp_flush;
    wire [31:0] jmp_target;

    assign {excp_flush, xret_flush, jmp_flag, jmp_target} = wbu_ifu_bus_i;
    // dnpc 的选择逻辑
    wire [31:0] dnpc;
    assign dnpc =   excp_flush ? csr_mtvec :
                    xret_flush ? csr_mepc :
                    jmp_flag ? jmp_target :
                    snpc;

    localparam    reset = 2'b00;
    localparam    idle  = 2'b01;
    localparam    fetch = 2'b10;
    localparam    ready = 2'b11;
    reg [1:0] state;
    // 时序逻辑更新更新寄存器
    always @(posedge clk_i) begin
        if (rst_i) begin
            ifu_pc <= RESET_PC;
            state <= reset;
            valid <= 1'b0;
            difftest <= 1'b0;
        end
        else begin
            case (state)
                reset: begin
                    ifu_pc <= RESET_PC;
                    valid <= 1'b1;
                    state <= idle;
                end
                idle: begin
                    valid <= 1'b0;
                    if (wbu_finish_i) begin
                        ifu_pc <= dnpc;
                        state <= fetch;
                    end
                end
                fetch: begin
                    state <= ready;
                    valid <= 1'b1;
                    difftest <= 1'b1;
                end
                ready: begin
                    state <= idle;
                    valid <= 1'b0;
                    difftest <= 1'b0;
                end
            endcase
        end
    end

    wire sram_enable = ~rst_i;
    sram sram_module (
        .clk_i          (clk_i),
        .sram_enable    (sram_enable),
        .addr_i         (ifu_pc),
        .data_o         (ifu_inst)
    );

    assign ifu_bdu_bus_o = {ifu_pc, ifu_inst, snpc};
    assign difftest_o = difftest;
    assign valid_o = valid;
endmodule
