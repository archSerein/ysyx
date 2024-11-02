`include "csr.vh"
`include "riscv_param.vh"

module ysyx_00000000 (
    input                           clock,
    input                           reset,
    input                           io_interrupt,

    input                           io_master_awready,
    output                          io_master_awvalid,
    output [31:0]                   io_master_awaddr,
    output [ 3:0]                   io_master_awid,
    output [ 7:0]                   io_master_awlen,
    output [ 2:0]                   io_master_awsize,
    output [ 1:0]                   io_master_awburst,

    input                           io_master_wready,
    output                          io_master_wvalid,
    output [31:0]                   io_master_wdata,
    output [ 3:0]                   io_master_wstrb,
    output                          io_master_wlast,

    output                          io_master_bready,
    input                           io_master_bvalid,
    input [ 1:0]                    io_master_bresp,
    input [ 3:0]                    io_master_bid,

    input                           io_master_arready,
    output                          io_master_arvalid,
    output [31:0]                   io_master_araddr,
    output [ 3:0]                   io_master_arid,
    output [ 7:0]                   io_master_arlen,
    output [ 2:0]                   io_master_arsize,
    output [ 1:0]                   io_master_arburst,

    output                          io_master_rready,
    input                           io_master_rvalid,
    input [31:0]                    io_master_rdata,
    input [ 1:0]                    io_master_rresp,
    input                           io_master_rlast,
    input [ 3:0]                    io_master_rid,

    output                          io_slave_awready,
    input                           io_slave_awvalid,
    input [31:0]                    io_slave_awaddr,
    input [ 3:0]                    io_slave_awid,
    input [ 7:0]                    io_slave_awlen,
    input [ 2:0]                    io_slave_awsize,
    input [ 1:0]                    io_slave_awburst,

    output                          io_slave_wready,
    input                           io_slave_wvalid,
    input [31:0]                    io_slave_wdata,
    input [ 3:0]                    io_slave_wstrb,
    input                           io_slave_wlast,

    input                           io_slave_bready,
    output                          io_slave_bvalid,
    output [ 1:0]                   io_slave_bresp,
    output [ 3:0]                   io_slave_bid,

    output                          io_slave_arready,
    input                           io_slave_arvalid,
    input [31:0]                    io_slave_araddr,
    input [ 3:0]                    io_slave_arid,
    input [ 7:0]                    io_slave_arlen,
    input [ 2:0]                    io_slave_arsize,
    input [ 1:0]                    io_slave_arburst,

    input                           io_slave_rready,
    output                          io_slave_rvalid,
    output [31:0]                   io_slave_rdata,
    output [ 1:0]                   io_slave_rresp,
    output                          io_slave_rlast,
    output [ 3:0]                   io_slave_rid
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

    axi_lite_arbitrator axi_lite_arbitrator_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .ifu_araddr_i   (inst_araddr),
        .ifu_arvalid_i  (inst_arvalid),
        .ifu_arready_o  (inst_arready),

        .bdu_rdata_o    (inst_rdata),
        .bdu_rvalid_o   (inst_rvalid),
        .bdu_rready_i   (inst_rready),
        .bdu_rresp_o    (inst_rresp),

        .exu_araddr_i   (araddr),
        .exu_arvalid_i  (arvalid),
        .exu_arready_o  (arready),

        .lsu_rdata_o    (rdata),
        .lsu_rvalid_o   (rvalid),
        .lsu_rready_i   (rready),
        .lsu_rresp_o    (rresp),

        .exu_awaddr_i   (awaddr),
        .exu_awvalid_i  (awvalid),
        .exu_awready_o  (awready),

        .exu_wdata_i    (wdata),
        .exu_wstrb_i    (wstrb),
        .exu_wvalid_i   (wvalid),
        .exu_wready_o   (wready),

        .lsu_bvalid_o   (bvalid),
        .lsu_bresp_o    (bresp),
        .lsu_bready_i   (bready)
    );
endmodule
