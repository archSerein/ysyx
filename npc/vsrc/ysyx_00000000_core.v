`include "csr.vh"
`include "riscv_param.vh"

module ysyx_00000000_core (
    input                       clock,
    input                       reset,

    input                       ifu_arready,
    output                      ifu_arvalid,
    output [31:0]               ifu_araddr,

    output                      bdu_rready,
    input                       bdu_rvalid,
    input [31:0]                bdu_rdata,
    input [ 1:0]                bdu_rresp,

    input                       exu_arready,
    output                      exu_arvalid,
    output [ 2:0]               exu_arsize,
    output [31:0]               exu_araddr,

    output                      lsu_rready,
    input                       lsu_rvalid,
    input [31:0]                lsu_rdata,
    input [ 1:0]                lsu_rresp,

    input                       exu_awready,
    output                      exu_awvalid,
    output [31:0]               exu_awaddr,

    input                       exu_wready,
    output                      exu_wvalid,
    output [31:0]               exu_wdata,
    output [ 3:0]               exu_wstrb,

    output                      lsu_bready,
    input                       lsu_bvalid,
    input [ 1:0]                lsu_bresp
);

    wire                             wbu_finish;
    wire [`WBU_IFU_BUS_WIDTH-1:0]    wbu_ifu_bus;
    wire [`IFU_BDU_BUS_WIDTH-1:0]    ifu_bdu_bus;
    wire                             ifu_valid;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mtvec;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mepc;
    wire                             clk_i;
    wire                             rst_i;

    assign clk_i = clock;
    assign rst_i = reset;

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
        .araddr_o       (ifu_araddr),
        .arvalid_o      (ifu_arvalid),
        .arready_i      (ifu_arready),

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

        // axi read data channel
        .rdata_i        (bdu_rdata),
        .rvalid_i       (bdu_rvalid),
        .rready_o       (bdu_rready),
        .rresp_i        (bdu_rresp),

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

    exu exu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .adu_valid_i    (adu_valid),
        .adu_exu_bus_i  (adu_exu_bus),

        .arready_i      (exu_arready),
        .araddr_o       (exu_araddr),
        .arsize_o   (exu_arsize),
        .arvalid_o      (exu_arvalid),
        .awready_i      (exu_awready),
        .awaddr_o       (exu_awaddr),
        .awvalid_o      (exu_awvalid),
        .wready_i       (exu_wready),
        .wdata_o        (exu_wdata),
        .wstrb_o        (exu_wstrb),
        .wvalid_o       (exu_wvalid),

        .exu_lsu_bus_o  (exu_lsu_bus),
        .valid_o        (exu_valid)
    );

    // wire [31:0] mem_rdata;
    wire [`LSU_WBU_BUS_WIDTH-1:0] lsu_wbu_bus;
    wire lsu_valid;

    lsu lsu_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        .exu_valid_i    (exu_valid),
        .exu_lsu_bus_i  (exu_lsu_bus),

        .rdata_i        (lsu_rdata),
        .rresp_i        (lsu_rresp),
        .rvalid_i       (lsu_rvalid),
        .rready_o       (lsu_rready),

        .bresp_i        (lsu_bresp),
        .bvalid_i       (lsu_bvalid),
        .bready_o       (lsu_bready),

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

endmodule
