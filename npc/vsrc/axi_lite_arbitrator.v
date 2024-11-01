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

    wire        uart_awvalid;
    wire        uart_wvalid;
    wire        uart_bvalid;
    wire        uart_awready;
    wire        uart_wready;
    wire [ 1:0] uart_bresp;
    uart uart_module (
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .awvalid_i      (uart_awvalid),
        .awaddr_i       (awaddr),
        .awready_o      (uart_awready),

        .wvalid_i       (uart_wvalid),
        .wdata_i        (wdata),
        .wstrb_i        (wstrb),
        .wready_o       (uart_wready),

        .bvalid_o       (uart_bvalid),
        .bresp_o        (uart_bresp),
        .bready_i       (bready)
    );

    wire            clint_arvalid;
    wire            clint_arready;
    wire            clint_rvalid;
    wire    [31:0]  clint_rdata;
    clint   clint_module(
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .arvalid_i      (clint_arvalid),
        .araddr_i       (araddr),
        .arready_o      (clint_arready),

        .rready_i       (rready),
        .rvalid_o       (clint_rvalid),
        .rdata_o        (clint_rdata)
    );
    assign clint_arvalid    = arvalid && araddr[31:28] == 4'b1010;

    reg            arvalid_r;
    reg    [31:0]  araddr_r;

    reg            awvalid_r;
    reg    [31:0]  awaddr_r;
    reg    [31:0]  wdata_r;
    reg    [ 3:0]  wstrb_r;

    assign arvalid = arvalid_r;
    assign araddr = araddr_r;
    assign awvalid = awvalid_r && (awaddr_r[31:28] != 4'ha);
    assign wvalid = awvalid_r && (awaddr_r[31:28] != 4'ha);
    assign awaddr = awaddr_r;
    assign wstrb = wstrb_r;
    assign wdata = wdata_r;

    assign uart_awvalid = awvalid_r && (awaddr_r[31:28] == 4'ha);
    assign uart_wvalid = awvalid_r && (awaddr_r[31:28] == 4'ha);
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
                    if ((awready && wready) || (uart_awready && uart_wready)) begin
                        awvalid_r <= 1'b0;
                        wstate <= WAIT;
                    end
                end
                WAIT: begin
                    // 目前仲裁器一次只能接受一个请求
                    // 所以只要有写响应就可以进入 IDLE 状态
                    // 结束当前请求
                    if (bvalid || uart_bvalid) begin
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
    assign lsu_bresp_o = {2{bvalid}} & bresp | {2{uart_bvalid}} & uart_bresp;

    reg         req_source;
    reg [31:0]  rdata_r;
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
                    if (arready && araddr_r[31:28] != 4'ha) begin
                        arvalid_r <= 1'b0;
                        rstate <= WAIT;
                    end
                    if (clint_arready && araddr_r[31:28] == 4'ha) begin
                        arvalid_r <= 1'b0;
                        rstate <= WAIT;
                    end
                end
                WAIT: begin
                    // 如果 axi lite 返回了有效的数据
                    // 就进入 RESP 状态
                    if (rvalid || clint_rvalid) begin
                        rstate  <= RESP;
                        rdata_r <= {32{rvalid}} & rdata |
                                    {32{clint_rvalid}} & clint_rdata;
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
    assign lsu_rdata_o = rdata_r;
    assign bdu_rdata_o = rdata_r;
    assign lsu_rresp_o = rresp;
    assign bdu_rresp_o = rresp;
endmodule
