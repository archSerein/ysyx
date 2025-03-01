`include "riscv_param.vh"
module bdu (
    input                           clock,
    input                           reset,
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
    // axi read data channel
    input  [31:0]                   rdata_i,
    input                           rvalid_i,
    input  [ 1:0]                   rresp_i,
    output                          rready_o,

    output [`BDU_ADU_BUS_WIDTH-1:0] bdu_adu_bus_o,
    output                          valid_o
);

    localparam INST_OK      = 2'b00;
    localparam INST_EXOKAY  = 2'b01;
    // localparam INST_SLVERR  = 2'b10;
    // localparam INST_DECERR  = 2'b11;

    reg                             valid;
    reg [`IFU_BDU_BUS_WIDTH-1:0]    ifu_bdu_bus;

    wire [31:0] bdu_pc;
    wire [31:0] bdu_inst;
    wire [31:0] bdu_snpc;

    assign {bdu_pc, bdu_snpc} = ifu_bdu_bus;

    always @(posedge clock) begin
        if (ifu_valid_i) begin
            ifu_bdu_bus <= ifu_bdu_bus_i;
        end
    end

    import "DPI-C" function void ifu_inst_count();
    wire is_br_inst;
    wire is_set_inst;
    // axi read data channel
    reg  [31:0] bdu_inst_r;
    reg rready;
    always @(posedge clock) begin
        if (reset) begin
            rready <= 1'b1;
            valid <= 1'b0;
        end else if (rvalid_i && rready) begin
            // only rresp_i == INST_OK or rresp_i == INST_EXOKAY update the
            // bdu_inst_r and rready, otherwise the bdu_inst_r keep the old value
            if (rresp_i == INST_OK || rresp_i == INST_EXOKAY) begin
                bdu_inst_r <= rdata_i;
                valid <= 1'b1;
                ifu_inst_count();
                // $display("bdu_pc: %h bdu_inst: %h", bdu_pc, rdata_i);
            end else begin
                $display("mem response error: %h", rresp_i);
                $finish;
            end
            rready <= 1'b0;
        end else if (!rvalid_i) begin
            rready <= 1'b1;
            valid <= 1'b0;
        end
    end
    assign rready_o = rready;
    assign bdu_inst = bdu_inst_r;

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
    wire        inst_slti;
    wire        inst_sltiu;
    wire        inst_slt;
    wire        inst_sltu;

    assign bdu_rs1 = bdu_inst[19:15];
    assign bdu_rs2 = bdu_inst[24:20];
    assign bdu_rd  = bdu_inst[11:7];

    assign bdu_funct7 = bdu_inst[31:25];
    assign bdu_funct3 = bdu_inst[14:12];
    assign bdu_opcode = bdu_inst[6:0];

    assign bdu_imm_i = { {20{bdu_inst[31]}}, bdu_inst[31:20] };
    assign bdu_imm_s = { {20{bdu_inst[31]}}, bdu_inst[31:25], bdu_inst[11:7] };
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

    assign bdu_imm  =   {32{bdu_optype == `INST_S}} & bdu_imm_s |
                        {32{bdu_optype == `INST_B}} & bdu_imm_b |
                        {32{bdu_optype == `INST_J}} & bdu_imm_j |
                        {32{bdu_optype == `INST_U}} & bdu_imm_u |
                        {32{bdu_optype == `INST_I}} & bdu_imm_i;

    assign inst_beq    = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b000;
    assign inst_bne    = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b001;
    assign inst_blt    = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b100;
    assign inst_bge    = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b101;
    assign inst_bltu   = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b110;
    assign inst_bgeu   = bdu_opcode == 7'b1100011 && bdu_funct3 == 3'b111;
    assign inst_slti   = bdu_opcode == 7'b0010011 && bdu_funct3 == 3'b010;
    assign inst_sltiu  = bdu_opcode == 7'b0010011 && bdu_funct3 == 3'b011;
    assign inst_slt    = bdu_opcode == 7'b0110011 && bdu_funct3 == 3'b010 &&
                            bdu_funct7 == 7'b0000000;
    assign inst_sltu   = bdu_opcode == 7'b0110011 && bdu_funct3 == 3'b011 &&
                            bdu_funct7 == 7'b0000000;

    assign is_br_inst = inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu;
    assign is_set_inst = inst_slti | inst_sltiu | inst_slt | inst_sltu;
    wire [2:0] bdu_compare_fn;
    assign bdu_compare_fn = {3{inst_beq}} & 3'b000 |
                            {3{inst_bne}} & 3'b001 |
                            {3{inst_blt}} & 3'b011 |
                            {3{inst_bge}} & 3'b010 |
                            {3{inst_bltu}} & 3'b101 |
                            {3{inst_bgeu}} & 3'b110 |
                            {3{inst_slti}} & 3'b011 |
                            {3{inst_sltiu}} & 3'b101 |
                            {3{inst_slt}} & 3'b011 |
                            {3{inst_sltu}} & 3'b101;

    wire        bdu_compare_result;
    wire [31:0] compare_src2;
    assign compare_src2 = (inst_sltiu | inst_slti) ? bdu_imm : bdu_rs2_value_i;
    compare compare_module (
        .compare_a_i(bdu_rs1_value_i),
        .compare_b_i(compare_src2),
        .compare_fn_i(bdu_compare_fn),
        .compare_o(bdu_compare_result)
    );

    wire br_taken = (inst_beq | inst_bne | inst_blt | inst_bge | inst_bltu | inst_bgeu) &
                    bdu_compare_result;
    
    wire [11:0] bdu_csr_addr;
    assign bdu_csr_addr = bdu_inst[31:20];

    wire res_from_compare;
    assign res_from_compare = inst_slt | inst_sltu | inst_slti | inst_sltiu;

    assign bdu_adu_bus_o = {
        res_from_compare,
        bdu_compare_result,
        bdu_snpc,
        bdu_pc,
        bdu_imm,
        bdu_rs1_value_i,
        bdu_rs2_value_i,
        bdu_rs1,
        bdu_rs2,
        bdu_rd,
        br_taken,
        bdu_csr_addr,
        bdu_csr_value_i,
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
    assign valid_o = valid;

    import "DPI-C" function void inst_type_count(input byte mask);
    always @*
    begin
        if (valid) begin
            if (is_br_inst) begin
                inst_type_count(3);
            end else if (is_set_inst) begin
                inst_type_count(6);
            end
        end
    end
endmodule
