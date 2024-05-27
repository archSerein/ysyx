module bool(
    input [31:0] a,
    input [31:0] b,
    input [3:0] fn,
    output [31:0] S 
);

    genvar i;

    generate
        for(i = 0; i < 32; i = i + 1)
        begin   :   bool
            MuxKey mux (.out(S[i]), .key({a[i], b[i]}), .value(fn));
        end
    endgenerate
endmodule
