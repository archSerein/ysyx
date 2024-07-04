module cmp(
    input [31:0] compare_a_i,
    input [31:0] compare_b_i,
    input [2:0] compare_fn_i,
    output [31:0] compare_o
);

    wire [31:0] x = compare_a_i;
    wire [31:0] y = compare_b_i;
    wire [2:0] fn = compare_fn_i;

    wire [31:0] arith_result;
    wire [2:0] arith_flag;
    
    arith arith_module (
        .AFN(1'b1),
        .arith_a_i(x),
        .arith_b_i(y),
        .arith_o(arith_result),
        .arith_flag_o(arith_flag)
    );
    wire result;
    /*
    assign result = (fn == 3'b000) ? ZF :   // equal 
                    (fn == 3'b001) ? ~ZF :  // not equal
                    (fn == 3'b010) ? (~NF & ~VF) | (NF & VF) :  // greater than or equal to (signed)
                    (fn == 3'b011) ? NF :   // less than (signed)
                    (fn == 3'b100) ? CF & ~ZF :   // greater than (unsigned)
                    (fn == 3'b101) ? ~CF :   // less than (unsigned)
                    (fn == 3'b110) ? CF :    // greater than or equal to (unsigned) 
                    VF;            // undifined -> overflow
    */

    wire ZF, NF, VF, CF;
    assign ZF = (|arith_result) ? 1'b0 : 1'b1;
    assign NF = (arith_result[31] == 1'b1) ? 1'b1 : 1'b0;
    assign VF = (~(x[31] ^ y[31] ^ 1'b1)) & (x[31] ^ arith_result[31]);
    assign CF = arith_flag[2] | (arith_flag[1] & arith_flag[0]);

    wire mux_1, mux_2, mux_3, mux_4, mux_5, mux_6;
    assign mux_1 = fn[0]    ?   ~ZF  :   ZF;
    assign mux_2 = fn[0]    ?   NF  :   (~NF & ~VF) | (NF & VF);
    assign mux_3 = fn[0]    ?   ~CF :   CF & ~ZF;
    assign mux_4 = fn[0]    ?   VF  :   CF;
    assign mux_5 = fn[1]    ?   mux_2   :   mux_1;
    assign mux_6 = fn[1]    ?   mux_4   :   mux_3;
    assign result = fn[2]   ?   mux_6   :   mux_5;
    assign cmp = {{31{1'b0}}, result};

    assign compare_o = cmp;
endmodule
