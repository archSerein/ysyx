module bdu (
    input                           clk_i,
    input                           rst_i,
    input                           ifu_valid_i,
    input  [`IFU_BDU_BUS_WIDTH-1:0] ifu_bdu_bus_i,
    // regfile
    output [ 4:0]                   bdu_rs1_o,
    output [ 4:0]                   bdu_rs2_o,
    input  [31:0]                   bdu_rs1_value_i,
    input  [31:0]                   bdu_rs2_value_i,
    // csr register
    output [11:0]                   bdu_csr_addr_o,
    input  [31:0]                   bdu_csr_value_i,
    output [`BDU_ADU_BUS_WIDTH-1:0] bdu_adu_bus_o,
    output                          valid_o
);

    reg                             valid;
    reg [`IFU_BDU_BUS_WIDTH-1:0]    ifu_bdu_bus;

    wire [31:0] bdu_pc;
    wire [31:0] bdu_inst;

    assign {bdu_pc, bdu_inst} = ifu_bdu_bus;

    always @(posedge clk_i) begin
        if (rst_i) begin
            valid <= 1'b0;
            ifu_bdu_bus <= 0;
        end else if (ifu_valid_i) begin
            valid <= 1'b1;
            ifu_bdu_bus <= ifu_bdu_bus_i;
        end else begin
            valid <= 1'b0;
        end
    end

    wire [ 4:0] bdu_rs1;
    wire [ 4:0] bdu_rs2;
    wire [ 4:0] bdu_rd;
    wire [ 6:0] bdu_funct7;
    wire [ 2:0] bdu_funct3;
    wire [ 6:0] bdu_opcode;
    wire [31:0] bdu_imm_i;
    wire [31:0] bdu_imm_s;
    wire [31:0] bdu_imm_b;
    wire [31:0] bdu_imm_u;
    wire [31:0] bdu_imm_j;
    wire [31:0] bdu_imm;
    wire [ 2:0] bdu_optype;

    // branch instruction
    wire        inst_bne;
    wire        inst_beq;
    wire        inst_blt;
    wire        inst_bge;
    wire        inst_bltu;
    wire        inst_bgeu;

    assign bdu_rs1 = bdu_inst[19:15];
    assign bdu_rs2 = bdu_inst[24:20];
    assign bdu_rd  = bdu_inst[11:7];

    assign bdu_funct7 = bdu_inst[31:25];
    assign bdu_funct3 = bdu_inst[14:12];
    assign bdu_opcode = bdu_inst[6:0];

    assign bdu_imm_i = { {20{bdu_inst[31]}}, bdu_inst[31:20] };
    assign bdu_imm_s = { {20{bdu_inst[31]}}, bdu_inst[31], bdu_inst[7], bdu_inst[30:25], bdu_inst[11:8] };
    assign bdu_imm_b = { {19{bdu_inst[31]}}, bdu_inst[31], bdu_inst[7], bdu_inst[30:25], bdu_inst[11:8], 1'b0 };
    assign bdu_imm_u = { bdu_inst[31:12], 12'b0 };
    assign bdu_imm_j = { {12{bdu_inst[31]}}, bdu_inst[19:12], bdu_inst[20], bdu_inst[30:21], 1'b0 };

    assign bdu_optype  =    {3{bdu_opcode == 7'b0110011}} & `INST_R |
                            {3{bdu_opcode == 7'b0100011}} & `INST_S |
                            {3{bdu_opcode == 7'b1100011}} & `INST_B |
                            {3{bdu_opcode == 7'b1101111}} & `INST_J |
                            {3{bdu_opcode == 7'b0110111}} & `INST_U |
                            {3{bdu_opcode == 7'b0010111}} & `INST_U |
                            {3{bdu_opcode == 7'b0010011}} & `INST_I |
                            {3{bdu_opcode == 7'b0000011}} & `INST_I |
                            {3{bdu_opcode == 7'b1100111}} & `INST_I |
                            {3{bdu_opcode == 7'b1110011}} & `INST_PRIV;

    assign bdu_imm  =   {3{bdu_optype == `INST_S}} & bdu_imm_s |
                        {3{bdu_optype == `INST_B}} & bdu_imm_b |
                        {3{bdu_optype == `INST_J}} & bdu_imm_j |
                        {3{bdu_optype == `INST_U}} & bdu_imm_u |
                        {3{bdu_optype == `INST_I}} & bdu_imm_i;

    assign inst_beq    = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b000;
    assign inst_bne    = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b001;
    assign inst_blt    = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b100;
    assign inst_bge    = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b101;
    assign inst_bltu   = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b110;
    assign inst_bgeu   = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b111;

    wire [2:0] bdu_compare_fn;
    assign bdu_compare_fn = {3{inst_beq}} & 3'b000 |
                            {3{inst_bne}} & 3'b001 |
                            {3{inst_blt}} & 3'b011 |
                            {3{inst_bge}} & 3'b010 |
                            {3{inst_bltu}} & 3'b101 |
                            {3{inst_bgeu}} & 3'b110;

    wire [31:0] bdu_compare_result;
    compare compare_module (
        .compare_a_i(bdu_rs1_value_i),
        .compare_b_i(bdu_rs2_value_i),
        .compare_fn_i(bdu_compare_fn),
        .compare_o(bdu_compare_result)
    );

    wire br_taken = (inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu) &
                    bdu_compare_result[0];
    
    wire [11:0] bdu_csr_addr;
    assign bdu_csr_addr = bdu_inst[31:20];

    assign bdu_adu_bus_o = {
        bdu_pc,
        bdu_imm,
        bdu_rs1_value_i,
        bdu_rs2_value_i,
        bdu_rd,
        br_taken,
        bdu_csr_addr,
        bdu_csr_value_i
        bdu_optype,
        bdu_opcode,
        bdu_funct3,
        bdu_funct7
    };
    /* bus width: 32 + 32 + 5 + 1 + 12 + 32 + 3 + 7 + 3 + 7 + 32 + 32 = 198*/
    // out to regfile
    assign bdu_rs1_o = bdu_rs1;
    assign bdu_rs2_o = bdu_rs2;
    assign bdu_csr_addr_o = bdu_csr_addr;
endmodule