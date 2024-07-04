module alu (
    input [5:0] alu_op_i,
    input [31:0] alu_a_i,
    input [31:0] alu_b_i,
    output [31:0] alu_result_o
);

    wire [5:0] alu_op = alu_op_i;
    wire [31:0] alu_a = alu_a_i;
    wire [31:0] alu_b = alu_b_i;

    wire [31:0] arith_result;
    wire [31:0] bool_result;
    wire [31:0] shift_result;

    // 实例化一个 arith 模块
    // 用于算术运算
    arith arith_module (
        .AFN(alu_op[0]),
        .arith_a_i(alu_a),
        .arith_b_i(alu_b),
        .arith_o(arith_result),
        .arith_flag_o()
    );

    // 实例化一个 bool 模块
    // 用于逻辑运算
    bool bool_module (
        .bool_op_i(alu_op[3:0]),
        .bool_a_i(alu_a),
        .bool_b_i(alu_b),
        .bool_o(bool_result)
    );

    // 移位运算
    shift shift_module (
        .shift_op_i(alu_op[1:0]),
        .shift_a_i(alu_a),
        .shift_b_i(alu_b),
        .shift_o(shift_result)
    );

    // 选择器
    wire [31:0] alu_result_mux1, alu_result_mux2;
    assign alu_result_mux1 = (alu_op[4]) ? arith_result : 32'h0;
    assign alu_result_mux2 = (alu_op[4]) ? shift_result : bool_result;
    assign alu_result_o = (alu_op[5]) ? alu_result_mux2 : alu_result_mux1;
endmodule