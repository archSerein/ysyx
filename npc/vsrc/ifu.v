`include "./include/generated/autoconf.vh"
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

    output                              valid_o,

    // axi-lite access memory interface
    output  [31:0]                      araddr_o,
    output                              arvalid_o,
    input                               arready_i
);

    localparam RESET_PC = 32'h30000000;

    reg  [31:0] ifu_pc;
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

    // pre_if 阶段
    assign {excp_flush, xret_flush, jmp_flag, jmp_target} = wbu_ifu_bus_i;
    // dnpc 的选择逻辑
    wire [31:0] dnpc;
    assign dnpc =   excp_flush ? csr_mtvec :
                    xret_flush ? csr_mepc :
                    jmp_flag ? jmp_target :
                    snpc;

    // valid: 表示向下一个阶段传递的数据是否有效
    // rreq: pc 有效但是握手没有完成需要将请求信号保持, 1->表示还有请求没有成
    // 功发起, 0->表示所有请求都以发送成功
    reg  valid;
    reg  rreq;
    reg  started;

    always @ (posedge clk_i) begin
        if (rst_i) begin
            started <= 1'b0;
        end else begin
            started <= 1'b1;
        end
    end

    always @ (posedge clk_i) begin
        if (rst_i) begin
            // 复位期间不发送取指请求
            // 传递的数据无效
            valid <= 1'b0;
            rreq  <= 1'b0;
            ifu_pc <= RESET_PC;
        end else if (arready_i && rreq) begin
            // 握手成功, 传递的数据有效
            valid <= 1'b1;
            rreq  <= 1'b0;
        end else if (!rreq && wbu_finish_i) begin
            // 发起新的请求
            rreq  <= 1'b1;
            valid <= 1'b0;
            if (started)
                ifu_pc <= dnpc;
        end
    end

    `ifdef CONFIG_DIFFTEST
        import "DPI-C" function void is_difftest(input byte difftest);
        reg [ 7:0] difftest;
        always @(posedge clk_i) begin
            if (rst_i) begin
                difftest <= 8'b0;
            end else if (started && wbu_finish_i) begin
                difftest <= 8'b1;
            end else begin
                difftest <= 8'b0;
            end
            is_difftest(difftest);
        end
    `endif

    // 握手信号
    assign araddr_o = ifu_pc;
    assign arvalid_o = rreq;

    assign ifu_bdu_bus_o = {ifu_pc, snpc};
    assign valid_o = valid;

endmodule
