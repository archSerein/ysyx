`include "riscv_param.vh"

module ifu (
    input                               clk_i,
    input                               rst_i,
    input                               wbu_finish_i,
    input  [`WBU_TO_IFU_BUS_WIDTH-1:0]  wbu_ifu_bus_i,     // 从 wbu 模块获取的数据, 分支或者异常
    output [`IFU_BDU_BUS_WIDTH-1   :0]  ifu_bdu_bus_o,
    output                              valid_o
);

    reg  [31:0] ifu_pc;
    reg         valid;
    wire [31:0] ifu_inst;
    // 实例化一个加法器用来作为 pc 的自增
    wire [31:0] snpc;
    arith pc_arith (
        .arith_a_i(ifu_pc),
        .arith_b_i(32'h4),
        .AFN(1'b0),
        .arith_o(snpc),
        .arith_flag_o()
    );

    wire        jmp_flag;
    wire [31:0] jmp_target;

    assign {jmp_flag, jmp_target} = wbu_ifu_bus_i;
    // dnpc 的选择逻辑
    wire [31:0] dnpc;
    assign dnpc =   {32{jmp_flag}} & jmp_target |
                    {32{~jmp_flag}} & snpc;

    // 时序逻辑更新更新寄存器
    always @(posedge clk_i) begin
        if (rst_i) begin
            ifu_pc <= RESET_PC;
            valid <= 1'b0;
        end if (wbu_finish_i) begin
            ifu_pc <= dnpc;
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

    wire sram_enable = ~rst_i;
    sram sram_module (
        .clk_i          (clk_i),
        .sram_enable    (sram_enable),
        .addr_i         (ifu_pc),
        .data_o         (ifu_inst)
    );

    assign ifu_bdu_bus_o = {ifu_pc, ifu_inst};
    assign valid_o = valid;
endmodule