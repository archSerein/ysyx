module cmp(
    input [31:0] x,
    input [31:0] y,
    input [2:0] fn,
    output [31:0] cmp
);

    wire [31:0] S;
    wire ZF, VF, NF, CF;
    arith arith_cmp_module (
        .x(x),
        .y(y),
        .AFN(1'b1),
        .S(S),
        .ZF(ZF),
        .VF(VF),
        .NF(NF),
        .CF(CF)
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

    wire mux_1, mux_2, mux_3, mux_4, mux_5, mux_6;
    assign mux_1 = fn[0]    ?   ~ZF  :   ZF;
    assign mux_2 = fn[0]    ?   NF  :   (~NF & ~VF) | (NF & VF);
    assign mux_3 = fn[0]    ?   ~CF :   CF & ~ZF;
    assign mux_4 = fn[0]    ?   VF  :   CF;
    assign mux_5 = fn[1]    ?   mux_2   :   mux_1;
    assign mux_6 = fn[1]    ?   mux_4   :   mux_3;
    assign result = fn[2]   ?   mux_6   :   mux_5;
    assign cmp = {{31{1'b0}}, result};

endmodule
