module compare(
    input [31:0] compare_a_i,
    input [31:0] compare_b_i,
    input [2:0] compare_fn_i,
    output      compare_o
);
    wire [31:0] a = compare_a_i;
    wire [31:0] b = compare_b_i;
    wire [2:0] fn = compare_fn_i;

    wire [31:0] gt_bits;   // a > b
    wire [31:0] lt_bits;   // a < b
    wire [31:0] neq_bits;  // a != b per bit
    wire [31:0] lt_mask;
    wire        lt;

    assign gt_bits = a & ~b;
    assign lt_bits = ~a & b;
    assign neq_bits = a ^ b;

    // Create prefix compare tree logic to decide the first differing bit
    assign lt_mask[31] = lt_bits[31];
    genvar i;
    generate
        for (i = 30; i >= 0; i = i - 1) begin : lt_tree
            wire higher_bits_equal;
            assign higher_bits_equal = ~(|neq_bits[31:i+1]);
            assign lt_mask[i] = lt_bits[i] & higher_bits_equal;
        end
    endgenerate

    assign lt = |lt_mask; // if any lt_mask bit is high, a < b

    wire equal, signed_less, unsigned_less;
    assign equal = !(|neq_bits);
    assign signed_less = (a[31] & !b[31]) | (a[31] == b[31] & lt);
    assign unsigned_less = lt;

    wire equal_or_not;
    wire less_than_or_not_signed;
    wire less_or_greater_unsigned;
    wire not_less_unsigned;
    assign equal_or_not = fn[0] ? !equal : equal;
    assign less_than_or_not_signed = fn[0] ? signed_less : !signed_less;
    assign less_or_greater_unsigned = fn[0] ? unsigned_less : !unsigned_less && !equal;
    assign not_less_unsigned = !fn[0] && !unsigned_less;

    wire equal_or_signed;
    wire unsigned_compare;
    assign equal_or_signed = fn[1] ? less_than_or_not_signed : equal_or_not;
    assign unsigned_compare = fn[1] ? not_less_unsigned : less_or_greater_unsigned;

    assign compare_o = fn[2] ? unsigned_compare : equal_or_signed;
endmodule
