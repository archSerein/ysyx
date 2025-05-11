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

    wire [`IFU_ICU_BUS_WIDTH-1:0]    ifu_icu_bus;
    wire                             ifu_valid;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mtvec;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mepc;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mepc_w;
    wire [`CSR_DATA_WIDTH-1:0]       csr_mcause_w;
    wire                             icache_flush;

    wire                             icache_ready;
    wire                             rfu_ready;

    wire                             branch_flush;
    wire [31:0]                      branch_target;

    wire                             excp_flush;
    wire                             mret_flush;

    wire                             ifu_excp_bus;
    wire [ 1:0]                      icu_excp_bus;
    wire [ 4:0]                      deu_excp_bus;
    wire [ 4:0]                      rfu_excp_bus;
    wire [ 6:0]                      exu_excp_bus;
    wire [ 8:0]                      lsu_excp_bus;

    ifu ifu_module (
        .clock          (clock),
        .reset          (reset),

        .excp_flush     (excp_flush),
        .mret_flush     (mret_flush),

        // csr register
        .csr_mtvec      (csr_mtvec),
        .csr_mepc       (csr_mepc),

        .ifu_icu_bus_o  (ifu_icu_bus),
        .ifu_excp_bus_o (ifu_excp_bus),

        .branch_flush   (branch_flush),
        .branch_target  (branch_target),

        .ready_i        (icache_ready),
        .valid_o        (ifu_valid)
    );

    wire [`ICU_DEU_BUS_WIDTH-1:0]    icu_deu_bus;
    wire                             icache_valid;
    wire deu_ready;
    icache icache_module (
      .clock            (clock),
      .reset            (reset),

      .excp_flush       (excp_flush),
      .mret_flush       (mret_flush),

      .ready_o          (icache_ready),
      .ifu_valid_i      (ifu_valid),
      .ifu_icu_bus_i    (ifu_icu_bus),
      .ifu_excp_bus_i   (ifu_excp_bus),

      .branch_flush     (branch_flush),
      .icache_flush     (icache_flush),

      .valid_o          (icache_valid),
      .icu_deu_bus_o    (icu_deu_bus),
      .icu_excp_bus_o   (icu_excp_bus),
      .deu_ready_i      (deu_ready),

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

    wire [`DEU_RFU_BUS_WIDTH-1:0] deu_rfu_bus;
    wire deu_valid;
    wire exu_ready;

    deu deu_module (
        .clock          (clock),
        .reset          (reset),

        .excp_flush     (excp_flush),
        .mret_flush     (mret_flush),

        .icu_valid_i    (icache_valid),
        .icu_deu_bus_i  (icu_deu_bus),
        .icu_excp_bus_i (icu_excp_bus),

        .deu_ready_o    (deu_ready),
        .deu_rfu_bus_o  (deu_rfu_bus),
        .deu_excp_bus_o (deu_excp_bus),

        .icache_flush   (icache_flush),
        .branch_flush   (branch_flush),

        .rfu_ready_i    (rfu_ready),
        .valid_o        (deu_valid)
    );

    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [31:0] rs1_value;
    wire [31:0] rs2_value;

    wire [11:0] csr_raddr;
    wire [31:0] csr_value;

    wire [`RFU_EXU_BUS_WIDTH-1:0] rfu_exu_bus;
    wire rfu_valid;
    wire [`FORWARD_BUS_WIDTH-1:0] exu_forward_bus;
    wire [`FORWARD_BUS_WIDTH-1:0] lsu_forward_bus;
    wire [`FORWARD_BUS_WIDTH-1:0] wbu_forward_bus;

    rfu rfu_module (
        .clock          (clock),
        .reset          (reset),

        .excp_flush     (excp_flush),
        .mret_flush     (mret_flush),

        .deu_valid_i    (deu_valid),
        .exu_ready_i    (exu_ready),
        .deu_rfu_bus_i  (deu_rfu_bus),
        .deu_excp_bus_i (deu_excp_bus),

        // regfile
        .rfu_rs1_o      (rs1),
        .rfu_rs2_o      (rs2),
        .rfu_rs1_value_i(rs1_value),
        .rfu_rs2_value_i(rs2_value),

        // csr register
        .rfu_csr_addr_o (csr_raddr),
        .rfu_csr_value_i(csr_value),

        .branch_flush   (branch_flush),

        .rfu_exu_bus_o  (rfu_exu_bus),
        .rfu_excp_bus_o (rfu_excp_bus),

        .exu_forward_bus(exu_forward_bus),
        .lsu_forward_bus(lsu_forward_bus),
        .wbu_forward_bus(wbu_forward_bus),

        .rfu_ready_o    (rfu_ready),
        .valid_o        (rfu_valid)
    );

    wire [`EXU_LSU_BUS_WIDTH-1:0] exu_lsu_bus;
    wire exu_valid;
    wire lsu_ready;

    exu exu_module (
        .clock          (clock),
        .reset          (reset),

        .excp_flush     (excp_flush),
        .mret_flush     (mret_flush),

        .rfu_valid_i    (rfu_valid),
        .lsu_ready_i    (lsu_ready),
        .rfu_exu_bus_i  (rfu_exu_bus),
        .rfu_excp_bus_i (rfu_excp_bus),

        .arready_i      (exu_arready),
        .araddr_o       (exu_araddr),
        .arsize_o       (exu_arsize),
        .arvalid_o      (exu_arvalid),
        .awready_i      (exu_awready),
        .awaddr_o       (exu_awaddr),
        .awvalid_o      (exu_awvalid),
        .wready_i       (exu_wready),
        .wdata_o        (exu_wdata),
        .wstrb_o        (exu_wstrb),
        .wvalid_o       (exu_wvalid),

        .branch_flush   (branch_flush),
        .branch_target  (branch_target),

        .exu_forward_bus(exu_forward_bus),

        .exu_excp_bus_o (exu_excp_bus),
        .exu_lsu_bus_o  (exu_lsu_bus),
        .exu_ready_o    (exu_ready),
        .valid_o        (exu_valid)
    );

    // wire [31:0] mem_rdata;
    wire [`LSU_WBU_BUS_WIDTH-1:0] lsu_wbu_bus;
    wire lsu_valid;
    wire wbu_ready;

    lsu lsu_module (
        .clock          (clock),
        .reset          (reset),

        .excp_flush     (excp_flush),
        .mret_flush     (mret_flush),

        .exu_valid_i    (exu_valid),
        .wbu_ready_i    (wbu_ready),
        .exu_lsu_bus_i  (exu_lsu_bus),
        .exu_excp_bus_i (exu_excp_bus),

        .rdata_i        (lsu_rdata),
        .rresp_i        (lsu_rresp),
        .rvalid_i       (lsu_rvalid),
        .rready_o       (lsu_rready),

        .bresp_i        (lsu_bresp),
        .bvalid_i       (lsu_bvalid),
        .bready_o       (lsu_bready),

        .lsu_forward_bus(lsu_forward_bus),

        .lsu_excp_bus_o (lsu_excp_bus),
        .lsu_wbu_bus_o  (lsu_wbu_bus),
        .lsu_ready_o    (lsu_ready),
        .valid_o        (lsu_valid)
    );

    wire [31:0] rf_wdata;
    wire rf_we;
    wire [4:0]  rd;
    wire [31:0] csr_wdata;
    wire csr_we;
    wire [11:0] csr_waddr;

    wbu wbu_module (
        .clock          (clock),
        .reset          (reset),
        .lsu_valid_i    (lsu_valid),
        .lsu_wbu_bus_i  (lsu_wbu_bus),
        .lsu_excp_bus_i (lsu_excp_bus),
        // register file
        .rf_rd_o        (rd),
        .rf_wdata_o     (rf_wdata),
        .rf_we_o        (rf_we),
        // csr register
        .csr_addr_o     (csr_waddr),
        .csr_wdata_o    (csr_wdata),
        .csr_we_o       (csr_we),

        .excp_flush     (excp_flush),
        .mret_flush     (mret_flush),
        .csr_mcause_o   (csr_mcause_w),
        .csr_mepc_o     (csr_mepc_w),

        .wbu_forward_bus(wbu_forward_bus),

        .wbu_ready_o    (wbu_ready)
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

        .excp_flush     (excp_flush),
        .csr_mepc_i     (csr_mepc_w),
        .csr_mcause_i   (csr_mcause_w),

        .csr_rdata_o    (csr_value)
    );

endmodule
