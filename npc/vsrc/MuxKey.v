/*
module MuxKey #(parameter NR_KEY = 2, parameter KEY_LEN = 1, parameter DATA_LEN = 1) (
    output [DATA_LEN-1:0] out,
    input [KEY_LEN-1:0] key,
    input [NR_KEY * (KEY_LEN + DATA_LEN) - 1:0] lut
);

    wire [KEY_LEN-1:0] keylist [NR_KEY-1:0];
    wire [DATA_LEN-1:0] datalist [NR_KEY-1:0];

    // 解析 LUT
    genvar i;
    generate
        for (i = 0; i < NR_KEY; i = i + 1) begin : parse_lut
            assign keylist[i] = lut[(i+1)*(KEY_LEN + DATA_LEN)-1 -: KEY_LEN];
            assign datalist[i] = lut[(i+1)*(KEY_LEN + DATA_LEN)-DATA_LEN-1 -: DATA_LEN];
        end
    endgenerate

    // Generate MUX logic using gates
    wire [NR_KEY-1:0] match;
    wire [DATA_LEN-1:0] mux_outputs [NR_KEY-1:0];

    genvar j;
    generate
        for (i = 0; i < NR_KEY; i = i + 1) begin : generate_mux
            // Compare key with key list
            assign match[i] = (key == keylist[i]);

            // If match, output the corresponding data
            for (j = 0; j < DATA_LEN; j = j + 1) begin : bit_select
                assign mux_outputs[i][j] = match[i] ? datalist[i][j] : 1'b0;
            end
        end
    endgenerate

    // OR all outputs to get the final output
    genvar k;
    generate
        for (k = 0; k < DATA_LEN; k = k + 1) begin : output_or
            wire [NR_KEY-1:0] out_bits;
            for (i = 0; i < NR_KEY; i = i + 1) begin : collect_bits
                assign out_bits[i] = mux_outputs[i][k];
            end
            assign out[k] = |out_bits;
        end
    endgenerate

endmodule
*/

module MuxKey (
    output out,
    input [1:0] key,
    input [3:0] value
);

    assign out = key == 2'b00 & value[0] |
                 key == 2'b01 & value[1] |
                 key == 2'b10 & value[2] |
                 key == 2'b11 & value[3];
endmodule
