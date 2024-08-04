`inlcude "riscv_param.v"

module fetch (
    input                               clk_i,
    input                               rst_i,
    input                               wb_finish_i,
    input  [`WB_TO_DECODE_BUS_WIDTH-1:0]wb_fetch_bus_i,     // 从 wb 模块获取的数据, 分支或者异常
    output [`FETCH_DECODE_BUS_WIDTH-1:0]fetch_decode_bus_o,
    output                              valid_o
);

    reg  [31:0] current_pc;
    reg         valid;
    wire [31:0] fetch_inst;
    // 实例化一个加法器用来作为 pc 的自增
    wire [31:0] snpc;
    arith pc_arith (
        .arith_a_i(current_pc),
        .arith_b_i(32'h4),
        .AFN(1'b0),
        .arith_o(snpc),
        .arith_flag_o()
    );

    wire        jmp_flag;
    wire [31:0] jmp_target;

    assign {jmp_flag, jmp_target} = wb_fetch_bus_i;
    // dnpc 的选择逻辑
    wire [31:0] dnpc;
    assign dnpc =   {32{jmp_flag}} & jmp_target |
                    {32{~jmp_flag}} & snpc;

    // 时序逻辑更新更新寄存器
    always @(posedge clk_i) begin
        if (rst_i) begin
            current_pc <= RESET_PC;
            valid <= 1'b0;
        end if (wb_finish_i) begin
            current_pc <= dnpc;
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

    wire sram_enable = ~rst_i;
    sram sram_module (
        .clk_i          (clk_i),
        .sram_enable    (sram_enable),
        .addr_i         (current_pc),
        .data_o         (fetch_inst)
    );

    assign fetch_decode_bus_o = {current_pc, fetch_inst};
    assign valid_o = valid;
endmodule