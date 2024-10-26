module axi_lite_arbitrator (
    input                       clk_i,
    input                       rst_i,

    input                       ifu_arvalid_i,
    input       [31:0]          ifu_araddr_i,
    output                      ifu_arready_o,

    input                       bdu_rready_i,
    output                      bdu_rvalid_o,
    output      [31:0]          bdu_rdata_o,
    output      [ 1:0]          bdu_rresp_o,

    input                       exu_arvalid_i,
    input       [31:0]          exu_araddr_i,
    output                      exu_arready_o,

    input                       lsu_rready_i,
    output                      lsu_rvalid_o,
    output      [31:0]          lsu_rdata_o,
    output      [ 1:0]          lsu_rresp_o,

    input                       exu_awvalid_i,
    input       [31:0]          exu_awaddr_i,
    output                      exu_awready_o,

    input                       exu_wvalid_i,
    input       [31:0]          exu_wdata_i,
    input       [ 3:0]          exu_wstrb_i,
    output                      exu_wready_o,

    output                      lsu_bvalid_o,
    output      [ 1:0]          lsu_bresp_o,
    input                       lsu_bready_i
);

    wire            arvalid;
    wire    [31:0]  araddr;
    wire            arready;
    wire            rready;
    wire            rvalid;
    wire    [31:0]  rdata;
    wire    [ 1:0]  rresp;
    wire            awvalid;
    wire    [31:0]  awaddr;
    wire            awready;
    wire            wvalid;
    wire    [31:0]  wdata;
    wire    [ 3:0]  wstrb;
    wire            wready;
    wire            bvalid;
    wire    [ 1:0]  bresp;
    wire            bready;

    axi_lite axi_lite_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .arvalid_i      (arvalid),
        .araddr_i       (araddr),
        .arready_o      (arready),

        .rready_i       (rready),
        .rvalid_o       (rvalid),
        .rdata_o        (rdata),
        .rresp_o        (rresp),

        .awvalid_i      (awvalid),
        .awaddr_i       (awaddr),
        .awready_o      (awready),

        .wvalid_i       (wvalid),
        .wdata_i        (wdata),
        .wstrb_i        (wstrb),
        .wready_o       (wready),

        .bvalid_o       (bvalid),
        .bresp_o        (bresp),
        .bready_i       (bready)
    );

    reg            arvalid_r;
    reg    [31:0]  araddr_r;

    reg            awvalid_r;
    reg    [31:0]  awaddr_r;
    reg    [31:0]  wdata_r;
    reg    [ 3:0]  wstrb_r;

    assign arvalid = arvalid_r;
    assign araddr = araddr_r;
    assign awvalid = awvalid_r;
    assign wvalid = awvalid_r;
    assign awaddr = awaddr_r;
    assign wstrb = wstrb_r;
    assign wdata = wdata_r;

    // state machine
    localparam      IDLE    = 2'b00;
    localparam      HANDLE  = 2'b01;
    localparam      WAIT    = 2'b10;
    localparam      RESP    = 2'b11;
    reg     [ 1:0]  wstate;
    reg     [ 1:0]  rstate;

    assign rready = rstate == WAIT;
    assign bready = wstate == WAIT;

    always @ (posedge clk_i) begin
        if (rst_i) begin
            wstate  <= IDLE;
        end else begin
            case (wstate)
                IDLE: begin
                    if (exu_awvalid_i && exu_wvalid_i) begin
                        wstate <= HANDLE;
                        awaddr_r <= exu_awaddr_i;
                        wdata_r <= exu_wdata_i;
                        wstrb_r <= exu_wstrb_i;
                        awvalid_r <= 1'b1;
                    end
                end
                HANDLE: begin
                    if (awready && wready) begin
                        awvalid_r <= 1'b0;
                        wstate <= WAIT;
                    end
                end
                WAIT: begin
                    if (bvalid) begin
                        wstate <= RESP;
                    end
                end
                RESP: begin
                    if (lsu_bready_i) begin
                        wstate <= IDLE;
                    end
                end
            endcase
        end
    end
    assign exu_awready_o = wstate == IDLE;
    assign exu_wready_o = wstate == IDLE;
    assign lsu_bvalid_o = wstate == RESP;
    assign lsu_bresp_o = bresp;

    reg     req_source;
    always @(posedge clk_i) begin
        if (rst_i) begin
            rstate <= IDLE;
        end else begin
            case (rstate)
                IDLE: begin
                    // 如果有来自 ifu 或者 exu 的请求
                    // 就进入 HANDLE 状态
                    if (ifu_arvalid_i) begin
                        rstate <= HANDLE;
                        req_source <= 0;
                        araddr_r <= ifu_araddr_i;
                        arvalid_r <= 1'b1;
                    end
                    if (exu_arvalid_i) begin
                        rstate <= HANDLE;
                        req_source <= 1;
                        araddr_r <= exu_araddr_i;
                        arvalid_r <= 1'b1;
                    end
                end
                HANDLE: begin
                    // 如果 axi lite is ready
                    // 就进入 WAIT 状态
                    if (arready) begin
                        arvalid_r <= 1'b0;
                        rstate <= WAIT;
                    end
                end
                WAIT: begin
                    // 如果 axi lite 返回了有效的数据
                    // 就进入 RESP 状态
                    if (rvalid) begin
                        rstate <= RESP;
                    end
                end
                RESP: begin
                    if (bdu_rready_i && req_source == 0) begin
                        rstate <= IDLE;
                    end
                    if (lsu_rready_i && req_source == 1) begin
                        rstate <= IDLE;
                    end
                end
            endcase
        end
    end
    assign bdu_rvalid_o = rstate == RESP && req_source == 0;
    assign lsu_rvalid_o = rstate == RESP && req_source == 1;
    assign ifu_arready_o = rstate == IDLE;
    assign exu_arready_o = rstate == IDLE;
    assign lsu_rdata_o = rdata;
    assign bdu_rdata_o = rdata;
    assign lsu_rresp_o = rresp;
    assign bdu_rresp_o = rresp;
endmodule
