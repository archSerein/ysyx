module bool(
    input [31:0] bool_a_i,
    input [31:0] bool_b_i,
    input [3:0] bool_op_i,
    output [31:0] bool_o 
);

    wire [31:0] a = bool_a_i;
    wire [31:0] b = bool_b_i;
    wire [3:0] fn = bool_op_i;
    wire [31:0] S;
    // genvar i;

    // generate
    //     for(i = 0; i < 32; i = i + 1)
    //     begin   :   bool_gen
    //         MuxKey mux (.key({a[i], b[i]}), .value(fn), .out(S[i]));
    //     end
    // endgenerate
    genvar i;

    generate
        for(i = 0; i < 32; i = i + 1)
        begin   :   bool_gen
            assign S[i] =   {a[i], b[i]} == 2'b00 & fn[0] |
                            {a[i], b[i]} == 2'b01 & fn[1] |
                            {a[i], b[i]} == 2'b10 & fn[2] |
                            {a[i], b[i]} == 2'b11 & fn[3];
        end
    endgenerate

    assign bool_o = S;
endmodule
