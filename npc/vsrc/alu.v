module alu(
    input [31:0] src1,
    input [31:0] src2,
    input [5:0] fn,
    output [31:0] result
);

    // 连接中间信号
    wire [31:0] arith_tmp, cmp_tmp, shift_tmp, bool_tmp;

    // 算术模块
    arith arith_module(
        .x(src1),
        .y(src2),
        .AFN(fn[0]),
        .S(arith_tmp),
        .ZF(),
        .VF(),
        .NF(),
        .CF()
    );

    // 移位模块
    shift shift_module(
        .x(src1),
        .y(src2[4:0]),
        .fn(fn[1:0]),
        .out(shift_tmp)
    );

    // 布尔计算模块
    bool bool_module(
        .a(src1),
        .b(src2),
        .fn(fn[3:0]),
        .S(bool_tmp)
    );

    // 选择需要的输出
    wire [31:0] shift_out, arith_out, bool_out;
    wire [31:0] mux_1, mux_2;

    assign mux_1 = fn[4] ? arith_tmp : 32'b0;
    assign mux_2 = fn[4] ? shift_tmp : bool_tmp;
    assign result = fn[5] ? mux_2 : mux_1;
    
endmodule
