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

    wire    [31:0]  inst_araddr;
    wire            inst_arvalid;
    wire            inst_arready;
    ifu ifu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .wbu_finish_i   (wbu_finish),
        .wbu_ifu_bus_i  (wbu_ifu_bus),
        // csr register
        .csr_mtvec      (csr_mtvec),
        .csr_mepc       (csr_mepc),
        .ifu_bdu_bus_o  (ifu_bdu_bus),
        // axi read addr channel
        .araddr_o       (inst_araddr),
        .arvalid_o      (inst_arvalid),
        .arready_i      (inst_arready),

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

    wire    [31:0]  inst_rdata;
    wire            inst_rvalid;
    wire            inst_rready;
    wire    [ 1:0]  inst_rresp;

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

        // axi read data channel
        .rdata_i        (inst_rdata),
        .rvalid_i       (inst_rvalid),
        .rready_o       (inst_rready),
        .rresp_i        (inst_rresp),

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

    // wire [31:0] mem_addr;
    // wire [31:0] mem_wdata;
    // wire [ 3:0] mem_we_mask;
    // wire         mem_wen;
    // wire         mem_ren;
    wire [31:0] araddr;
    wire        arvalid;
    wire        arready;
    wire [31:0] awaddr;
    wire        awvalid;
    wire        awready;
    wire [31:0] wdata;
    wire [ 3:0] wstrb;
    wire        wvalid;
    wire        wready;
    exu exu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .adu_valid_i    (adu_valid),
        .adu_exu_bus_i  (adu_exu_bus),
        // memfile
        // .mem_addr_o     (mem_addr),
        // .mem_wdata_o    (mem_wdata),
        // .mem_we_mask_o  (mem_we_mask),
        // .mem_wen_o      (mem_wen),
        // .mem_ren_o      (mem_ren),
        .arready_i      (arready),
        .araddr_o       (araddr),
        .arvalid_o      (arvalid),
        .awready_i      (awready),
        .awaddr_o       (awaddr),
        .awvalid_o      (awvalid),
        .wready_i       (wready),
        .wdata_o        (wdata),
        .wstrb_o        (wstrb),
        .wvalid_o       (wvalid),

        .exu_lsu_bus_o  (exu_lsu_bus),
        .valid_o        (exu_valid)
    );

    // wire [31:0] mem_rdata;
    wire [`LSU_WBU_BUS_WIDTH-1:0] lsu_wbu_bus;
    wire lsu_valid;
    wire [31:0] rdata;
    wire [ 1:0] rresp;
    wire        rvalid;
    wire        rready;
    wire [ 1:0] bresp;
    wire        bvalid;
    wire        bready;

    lsu lsu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .exu_valid_i    (exu_valid),
        .exu_lsu_bus_i  (exu_lsu_bus),
        // memfile
        // .mem_rdata_i    (mem_rdata),
        .rdata_i        (rdata),
        .rresp_i        (rresp),
        .rvalid_i       (rvalid),
        .rready_o       (rready),

        .bresp_i        (bresp),
        .bvalid_i       (bvalid),
        .bready_o       (bready),

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

    inst_axi_lite inst_axi_lite_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .araddr_i       (inst_araddr),
        .arvalid_i      (inst_arvalid),
        .arready_o      (inst_arready),

        .rdata_o        (inst_rdata),
        .rvalid_o       (inst_rvalid),
        .rready_i       (inst_rready),
        .rresp_o        (inst_rresp)
    );

    // TODO
    data_axi_lite data_axi_lite_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .araddr_i       (araddr),
        .arvalid_i      (arvalid),
        .arready_o      (arready),

        .rdata_o        (rdata),
        .rvalid_o       (rvalid),
        .rready_i       (rready),
        .rresp_o        (rresp),

        .awaddr_i       (awaddr),
        .awvalid_i      (awvalid),
        .awready_o      (awready),

        .wdata_i        (wdata),
        .wstrb_i        (wstrb),
        .wvalid_i       (wvalid),
        .wready_o       (wready),

        .bvalid_o       (bvalid),
        .bresp_o        (bresp),
        .bready_i       (bready)
    );
endmodule
