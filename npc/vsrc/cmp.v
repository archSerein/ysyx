`timescale 1ns / 1ps
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
    assign result = (fn == 3'b000) ? ZF :   // equal 
                    (fn == 3'b001) ? ~ZF :  // not equal
                    (fn == 3'b010) ? (~NF & ~VF) | (NF & VF) :  // greater than or equal to (signed)
                    (fn == 3'b011) ? NF :   // less than (signed)
                    (fn == 3'b100) ? CF & ~ZF :   // greater than (unsigned)
                    (fn == 3'b101) ? ~CF :   // less than (unsigned)
                    (fn == 3'b110) ? CF :    // greater than or equal to (unsigned) 
                    VF;            // undifined -> overflow

    assign cmp = {{31{1'b0}}, result};

endmodule
