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
    genvar i;

    generate
        for(i = 0; i < 32; i = i + 1)
        begin   :   bool
            MuxKey mux (.out(S[i]), .key({a[i], b[i]}), .value(fn));
        end
    endgenerate

    assign bool_o = S;
endmodule
