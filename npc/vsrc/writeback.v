module writeback (
    input [31:0] writeback_current_pc_i,
    output [31:0] writeback_snpc_o
);


// 涉及到后面的多周期流水线时，会完善这个模块的实现
// TODO: Implement the writeback module

    // 现在用于产生 snpc 信号
    wire [31:0] snpc;
    assign snpc = writeback_current_pc_i + 32'h4;
    assign writeback_snpc_o = snpc;
endmodule