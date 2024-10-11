module lfsr (
    input   wire        clk,
    input   wire        reset,
    output  wire [7:0]  lfsr_out
);

    reg [7:0] lfsr_reg;
    wire feedback;

    assign feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];

    always @(posedge clk) begin
        if (reset) begin
            lfsr_reg <= 8'h1; // Initial value, must be non-zero
        end else begin
            lfsr_reg <= {lfsr_reg[6:0], feedback};
        end
    end

    assign lfsr_out = lfsr_reg;
endmodule

