`include "csr.vh"
`include "riscv_param.vh"

module top (
    input clk_i,
    input rst_i,
    output difftest_o
);

    wire                             wbu_finish;
    wire [`WBU_IFU_BUS_WIDTH-1:0]    wbu_ifu_bus;
    wire [`IFU_BDU_BUS_WIDTH-1:0]    ifu_bdu_bus;
    wire                             ifu_valid;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mtvec;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mepc;

    ifu ifu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .wbu_finish_i   (wbu_finish),
        .wbu_ifu_bus_i  (wbu_ifu_bus),
        // csr register
        .csr_mtvec      (csr_mtvec),
        .csr_mepc       (csr_mepc),
        .ifu_bdu_bus_o  (ifu_bdu_bus),
        .difftest_o     (difftest_o),
        .valid_o        (ifu_valid)
    );

    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [31:0] rs1_value;
    wire [31:0] rs2_value;

    wire [11:0] csr_raddr;
    wire [31:0] csr_value;

    wire [`BDU_ADU_BUS_WIDTH-1:0] bdu_adu_bus;
    wire bdu_valid;

    bdu bdu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .ifu_valid_i    (ifu_valid),
        .ifu_bdu_bus_i  (ifu_bdu_bus),
        
        // regfile
        .bdu_rs1_o      (rs1),
        .bdu_rs2_o      (rs2),
        .bdu_rs1_value_i(rs1_value),
        .bdu_rs2_value_i(rs2_value),

        // csr register
        .bdu_csr_addr_o (csr_raddr),
        .bdu_csr_value_i(csr_value),

        .bdu_adu_bus_o  (bdu_adu_bus),
        .valid_o        (bdu_valid)
    );

    wire [`ADU_EXU_BUS_WIDTH-1:0] adu_exu_bus;
    wire adu_valid;

    adu adu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .bdu_valid_i    (bdu_valid),
        .bdu_adu_bus_i  (bdu_adu_bus),
        .adu_exu_bus_o  (adu_exu_bus),
        .valid_o        (adu_valid)
    );

    wire [`EXU_LSU_BUS_WIDTH-1:0] exu_lsu_bus;
    wire exu_valid;

    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_we_mask;
    wire         mem_wen;
    wire         mem_ren;
    exu exu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .adu_valid_i    (adu_valid),
        .adu_exu_bus_i  (adu_exu_bus),
        // memfile
        .mem_addr_o     (mem_addr),
        .mem_wdata_o    (mem_wdata),
        .mem_we_mask_o  (mem_we_mask),
        .mem_wen_o      (mem_wen),
        .mem_ren_o      (mem_ren),
        .exu_lsu_bus_o  (exu_lsu_bus),
        .valid_o        (exu_valid)
    );

    wire [31:0] mem_rdata;
    wire [`LSU_WBU_BUS_WIDTH-1:0] lsu_wbu_bus;
    wire lsu_valid;

    lsu lsu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .exu_valid_i    (exu_valid),
        .exu_lsu_bus_i  (exu_lsu_bus),
        // memfile
        .mem_rdata_i    (mem_rdata),

        .lsu_wbu_bus_o  (lsu_wbu_bus),
        .valid_o        (lsu_valid)
    );

    wire [ 4:0] rd;
    wire [11:0] csr_waddr;
    wire [31:0] rf_wdata;
    wire rf_we;
    wire [31:0] csr_wdata;
    wire csr_we;

    wbu wbu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .lsu_valid_i    (lsu_valid),
        .lsu_wbu_bus_i  (lsu_wbu_bus),
        // register file
        .rf_rd_o        (rd),
        .rf_wdata_o     (rf_wdata),
        .rf_we_o        (rf_we),
        // csr register
        .csr_addr_o     (csr_waddr),
        .csr_wdata_o    (csr_wdata),
        .csr_we_o       (csr_we),

        .wbu_ifu_bus_o  (wbu_ifu_bus),
        .finish_o        (wbu_finish)
    );

    // regfile
    regfile rf_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .reg_src1_i     (rs1),
        .reg_src2_i     (rs2),
        .reg_dst_i      (rd),
        .reg_wen_i      (rf_we),
        .reg_wdata_i    (rf_wdata),
        .reg_rdata1_o   (rs1_value),
        .reg_rdata2_o   (rs2_value)
    );

    // csr register
    csr csr_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .csr_we_i       (csr_we),
        .csr_raddr_i    (csr_raddr),
        .csr_waddr_i    (csr_waddr),
        .csr_wdata_i    (csr_wdata),
        // ifu
        .csr_mtvec_o    (csr_mtvec),
        .csr_mepc_o     (csr_mepc),

        .csr_rdata_o    (csr_value)
    );

    // memfile
    memfile mem_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .mem_addr_i     (mem_addr),
        .mem_wdata_i    (mem_wdata),
        .mem_we_mask_i  (mem_we_mask),
        .mem_wen_i      (mem_wen),
        .mem_ren_i      (mem_ren),
        .mem_rdata_o    (mem_rdata)
    );
endmodule
