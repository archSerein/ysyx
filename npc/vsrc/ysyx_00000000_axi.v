`include "./include/generated/autoconf.vh"
module ysyx_00000000_axi (
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

    wire                      ifu_arvalid;
    wire      [31:0]          ifu_araddr;
    wire                      ifu_arready;

    wire                      bdu_rready;
    wire                      bdu_rvalid;
    wire      [31:0]          bdu_rdata;
    wire      [ 1:0]          bdu_rresp;

    wire                      exu_arvalid;
    wire      [ 2:0]          exu_arsize;
    wire      [31:0]          exu_araddr;
    wire                      exu_arready;

    wire                      lsu_rready;
    wire                      lsu_rvalid;
    wire      [31:0]          lsu_rdata;
    wire      [ 1:0]          lsu_rresp;

    wire                      exu_awvalid;
    wire      [31:0]          exu_awaddr;
    wire                      exu_awready;

    wire                      exu_wvalid;
    wire      [31:0]          exu_wdata;
    wire      [ 3:0]          exu_wstrb;
    wire                      exu_wready;

    wire                      lsu_bvalid;
    wire      [ 1:0]          lsu_bresp;
    wire                      lsu_bready;

    ysyx_00000000_core core_module (
        .clock                      (clock),
        .reset                      (reset),

        .ifu_arvalid                (ifu_arvalid),
        .ifu_araddr                 (ifu_araddr),
        .ifu_arready                (ifu_arready),

        .bdu_rready                 (bdu_rready),
        .bdu_rvalid                 (bdu_rvalid),
        .bdu_rdata                  (bdu_rdata),
        .bdu_rresp                  (bdu_rresp),

        .exu_arvalid                (exu_arvalid),
        .exu_araddr                 (exu_araddr),
        .exu_arready                (exu_arready),
        .exu_arsize                 (exu_arsize),

        .lsu_rready                 (lsu_rready),
        .lsu_rvalid                 (lsu_rvalid),
        .lsu_rdata                  (lsu_rdata),
        .lsu_rresp                  (lsu_rresp),

        .exu_awvalid                (exu_awvalid),
        .exu_awaddr                 (exu_awaddr),
        .exu_awready                (exu_awready),

        .exu_wvalid                 (exu_wvalid),
        .exu_wdata                  (exu_wdata),
        .exu_wstrb                  (exu_wstrb),
        .exu_wready                 (exu_wready),

        .lsu_bvalid                 (lsu_bvalid),
        .lsu_bresp                  (lsu_bresp),
        .lsu_bready                 (lsu_bready)
    );

    localparam      IDLE        = 2'b00;
    localparam      HANDSHAKE   = 2'b01;
    localparam      WAIT        = 2'b10;
    localparam      DONE        = 2'b11;

    localparam      INST        = 1'b0;
    localparam      DATA        = 1'b1;

    reg [ 1:0]        rstate;
    reg [ 1:0]        wstate;

    reg [31:0]        raddr;
    reg [31:0]        rdata;
    reg [ 2:0]        rsize;
    reg [ 1:0]        rresp;
    reg               inst_or_data;

    reg [31:0]        waddr;
    reg [31:0]        wdata;
    reg [ 3:0]        wstrb;
    reg [ 1:0]        bresp;

    always @(posedge clock) begin
        if (reset) begin
            rstate <= IDLE;
            wstate <= IDLE;
        end else begin
            case (rstate)
                IDLE: begin
                    if (ifu_arvalid || exu_arvalid) begin
                        rstate  <= HANDSHAKE;
                        raddr   <= ifu_arvalid ? ifu_araddr : exu_araddr;
                        inst_or_data <= ifu_arvalid ? INST : DATA;
                        rsize  <= ifu_arvalid ? 3'b010 : exu_arsize;
                    end
                end
                HANDSHAKE: begin
                    if (io_master_arready) begin
                        rstate  <= WAIT;
                    end
                end
                WAIT: begin
                    if (io_master_rvalid) begin
                        rstate  <= DONE;
                        rdata   <= io_master_rdata;
                        rresp   <= io_master_rresp;
                    end
                end
                DONE: begin
                    if (bdu_rready || lsu_rready) begin
                        rstate  <= IDLE;
                        `ifdef CONFIG_RTL_MTRACE
                            $display("read: addr = %h, data = %h, resp = %b", raddr, rdata, rresp);
                        `endif
                    end
                end
            endcase
            case (wstate)
                IDLE: begin
                    if (exu_awvalid && exu_wvalid) begin
                        wstate  <= HANDSHAKE;
                        waddr   <= exu_awaddr;
                        wdata   <= exu_wdata;
                        wstrb   <= exu_wstrb;
                        `ifdef CONFIG_RTL_MTRACE
                            $display("write: addr = %h, data = %h, strb = %b", waddr, wdata, wstrb);
                        `endif
                    end
                end
                HANDSHAKE: begin
                    if (io_master_awready && io_master_wready) begin
                        wstate  <= WAIT;
                    end
                end
                WAIT: begin
                    if (io_master_bvalid) begin
                        wstate  <= DONE;
                        bresp   <= io_master_bresp;
                    end
                end
                DONE: begin
                    if (lsu_bready) begin
                        wstate  <= IDLE;
                    end
                end
            endcase
        end
    end

    assign io_master_awvalid = wstate == HANDSHAKE;
    assign io_master_awaddr = waddr;
    assign io_master_awid = 4'b0000;
    assign io_master_awlen = 8'b00000000;
    assign io_master_awsize = 3'b000;
    assign io_master_awburst = 2'b00;

    assign io_master_wvalid = wstate == HANDSHAKE;
    assign io_master_wdata = wdata;
    assign io_master_wstrb = wstrb;
    assign io_master_wlast = 1'b0;

    assign io_master_bready = wstate == WAIT;

    assign io_master_arvalid = rstate == HANDSHAKE;
    assign io_master_araddr = raddr;
    assign io_master_arid = 4'b0000;
    assign io_master_arlen = 8'b00000000;
    assign io_master_arsize = rsize;
    assign io_master_arburst = 2'b00;

    assign io_master_rready = rstate == WAIT;

    assign io_slave_awready = 1'b0;
    assign io_slave_wready = 1'b0;
    assign io_slave_bvalid = 1'b0;
    assign io_slave_arready = 1'b0;
    assign io_slave_rvalid = 1'b0;

    assign ifu_arready = rstate == IDLE;

    assign bdu_rvalid = rstate == DONE && inst_or_data == INST;
    assign bdu_rdata = rdata;
    assign bdu_rresp = rresp;

    assign exu_arready = rstate == IDLE;

    assign lsu_rvalid = rstate == DONE && inst_or_data == DATA;
    assign lsu_rdata = rdata;

    assign lsu_rresp = rresp;

    assign exu_awready = wstate == IDLE;

    assign exu_wready = wstate == IDLE;

    assign lsu_bvalid = wstate == DONE;
    assign lsu_bresp = bresp;

    assign io_slave_awready = 1'b0;
    assign io_slave_wready = 1'b0;

    assign io_slave_bvalid = 1'b0;
    assign io_slave_bid = 4'b0000;
    assign io_slave_bresp = 2'b00;

    assign io_slave_arready = 1'b0;

    assign io_slave_rvalid = 1'b0;
    assign io_slave_rdata = 32'h00000000;
    assign io_slave_rresp = 2'b00;
    assign io_slave_rlast = 1'b0;
    assign io_slave_rid = 4'b0000;

    `ifdef CONFIG_DIFFTEST
        import "DPI-C" function void difftest_skip_ref(input int is_skip);
        wire is_device_write;
        assign is_device_write = exu_awaddr >= 32'h10000000 && exu_awaddr <= 32'h10000fff;
        always @(*) begin
            if (is_device_write) begin
                // $display("write to device @ %h, data = %h", exu_awaddr, exu_wdata);
                difftest_skip_ref(1);
            end else begin
                difftest_skip_ref(0);
            end
        end
    `endif
endmodule
