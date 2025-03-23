`include "csr.vh"
`include "riscv_param.vh"

module ysyx_00000000_core (
    input                       clock,
    input                       reset,

    input                       icache_arready,
    output                      icache_arvalid,
    output [31:0]               icache_araddr,
    output [ 1:0]               icache_arburst,
    output [ 7:0]               icache_arlen,
    output [ 2:0]               icache_arsize,

    input                       icache_rlast,
    output                      icache_rready,
    input                       icache_rvalid,
    input [31:0]                icache_rdata,
    input [ 1:0]                icache_rresp,

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
    wire [`IFU_RFU_BUS_WIDTH-1:0]    ifu_rfu_bus;
    wire                             ifu_valid;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mtvec;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mepc;
    wire                             icache_flush;

    wire                             arvalid;
    wire [31:0]                      araddr;
    wire                             arready;
    ifu ifu_module (
        .clock          (clock),
        .reset          (reset),
        .wbu_finish_i   (wbu_finish),
        .wbu_ifu_bus_i  (wbu_ifu_bus),
        // csr register
        .csr_mtvec      (csr_mtvec),
        .csr_mepc       (csr_mepc),
        .ifu_rfu_bus_o  (ifu_rfu_bus),

        .araddr_o       (araddr),
        .arvalid_o      (arvalid),
        .arready_i      (arready),

        .valid_o        (ifu_valid)
    );

    wire [31:0]                      rdata;
    wire                             rvalid;
    icache icache_module (
      .clock            (clock),
      .reset            (reset),
      .rreq_i           (arvalid),
      .raddr_i          (araddr),
      .rready_o         (arready),

      .icache_flush     (icache_flush),

      .rdata_o          (rdata),
      .rvalid_o         (rvalid),

      .icache_arready_i (icache_arready),
      .icache_arvalid_o (icache_arvalid),
      .icache_araddr_o  (icache_araddr),
      .icache_arburst_o (icache_arburst),
      .icache_arlen_o   (icache_arlen),
      .icache_arsize_o  (icache_arsize),

      .icache_rlast_i   (icache_rlast),
      .icache_rvalid_i  (icache_rvalid),
      .icache_rdata_i   (icache_rdata),
      .icache_rresp_i   (icache_rresp),
      .icache_rready_o  (icache_rready)
    );

    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [31:0] rs1_value;
    wire [31:0] rs2_value;

    wire [11:0] csr_raddr;
    wire [31:0] csr_value;

    wire [`RFU_DEU_BUS_WIDTH-1:0] rfu_deu_bus;
    wire rfu_valid;

    rfu rfu_module (
        .clock          (clock),
        .reset          (reset),
        .ifu_valid_i    (ifu_valid),
        .ifu_rfu_bus_i  (ifu_rfu_bus),
        
        // regfile
        .rfu_rs1_o      (rs1),
        .rfu_rs2_o      (rs2),
        .rfu_rs1_value_i(rs1_value),
        .rfu_rs2_value_i(rs2_value),

        // csr register
        .rfu_csr_addr_o (csr_raddr),
        .rfu_csr_value_i(csr_value),

        .rdata_i        (rdata),
        .rvalid_i       (rvalid),

        .rfu_deu_bus_o  (rfu_deu_bus),
        .valid_o        (rfu_valid)
    );

    wire [`DEU_EXU_BUS_WIDTH-1:0] deu_exu_bus;
    wire deu_valid;

    deu deu_module (
        .clock          (clock),
        .reset          (reset),
        .rfu_valid_i    (rfu_valid),
        .rfu_deu_bus_i  (rfu_deu_bus),
        .deu_exu_bus_o  (deu_exu_bus),
        .icache_flush   (icache_flush),
        .valid_o        (deu_valid)
    );

    wire [`EXU_LSU_BUS_WIDTH-1:0] exu_lsu_bus;
    wire exu_valid;

    exu exu_module (
        .clock          (clock),
        .reset          (reset),
        .deu_valid_i    (deu_valid),
        .deu_exu_bus_i  (deu_exu_bus),

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
        .clock          (clock),
        .reset          (reset),
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
        .clock          (clock),
        .reset          (reset),
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
        .clock          (clock),
        .reset          (reset),
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
        .clock          (clock),
        .reset          (reset),
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
