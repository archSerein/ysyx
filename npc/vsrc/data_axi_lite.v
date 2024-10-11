module data_axi_lite (
    input               clk_i,
    input               rst_i,

    // 读地址通道
    input               arvalid_i,
    output              arready_o,
    input  [31:0]       araddr_i,
    // 读数据通道
    input               rready_i,
    output              rvalid_o,
    output [31:0]       rdata_o,
    output [ 1:0]       rresp_o,
    // 写地址通道
    input               awvalid_i,
    output              awready_o,
    input  [31:0]       awaddr_i,
    // 写数据通道
    input               wvalid_i,
    input  [31:0]       wdata_i,
    input  [ 3:0]       wstrb_i,
    output              wready_o,
    // 写响应通道
    input               bready_i,
    output              bvalid_o,
    output [ 1:0]       bresp_o
);

    wire mem_ren;
    wire mem_wen;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [ 3:0] mem_we_mask;
    wire [31:0] sram_data;
    wire [ 1:0] sram_resp;

    data_sram data_sram_module (
        .clk_i          (clk_i),
        .dmem_ren_i     (mem_ren),
        .dmem_wen_i     (mem_wen),
        .dmem_addr_i    (mem_addr),
        .dmem_wdata_i   (mem_wdata),
        .dmem_we_mask_i (mem_we_mask),
        .dmem_rdata_o   (sram_data),
        .dmem_resp_o    (sram_resp)
    );

    wire [ 7:0] lfsr_out;
    lfsr lfsr_module (
        .clk            (clk_i),
        .reset          (rst_i),
        .lfsr_out       (lfsr_out)
    );

    // state machine for axi-lite
    // IDLE: the state machine is idle
    // READ: the state machine is reading data from memory
    // WRITE: the state machine is writing data to memory
    // RESP: the state machine is sending response to the master
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WRITE = 2'b10;
    localparam RESP = 2'b11;
    reg [ 1:0] state;
    reg [ 7:0] cnt;
    reg [31:0] data;
    reg [ 7:0] randon_latency;

    reg         rvalid;
    reg         bvalid;

    always @(posedge clk_i) begin
        if (rst_i) begin
            rvalid <= 1'b0;
            bvalid <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    rvalid <= 1'b0;
                    bvalid <= 1'b0;
                    if (arvalid_i) begin
                        state <= READ;
                        randon_latency <= lfsr_out;
                    end else if (awvalid_i) begin
                        state <= WRITE;
                        randon_latency <= lfsr_out;
                    end
                end
                READ: begin
                    if (cnt == randon_latency) begin
                        state <= IDLE;
                        rvalid <= 1'b1;
                        cnt  <= 8'd0;
                    end 
                    if (cnt == 8'd0) begin
                        data <= sram_data;
                        cnt  <= cnt + 8'd1;
                    end
                    if (cnt != randon_latency && cnt != 0) begin
                        cnt <= cnt + 8'd1;
                    end
                end
                WRITE: begin
                    if (cnt == randon_latency) begin
                        state <= RESP;
                    end
                    if (cnt != randon_latency) begin
                        cnt <= cnt + 8'd1;
                    end
                end
                RESP: begin
                    state <= IDLE;
                    bvalid <= 1'b1;
                    cnt  <= 8'd0;
                end
            endcase
        end
    end

    // when the read request is valid and the state is idle
    // enable mem read
    assign mem_ren  = arvalid_i && state == IDLE;

    // when the write request is valid and the state is idle
    // enable mem write
    assign mem_wen  = wvalid_i && state == IDLE;

    // if the state is IDLE, the memory can access the read/write request
    assign arready_o = state == IDLE;

    assign mem_addr = arvalid_i ? araddr_i : awaddr_i;

    assign mem_wdata = wdata_i;

    assign mem_we_mask = wstrb_i;

    // output
    assign rvalid_o = rvalid;
    assign awready_o = state == IDLE && !rst_i;

    assign rdata_o = data;
    assign rresp_o = rready_i ? sram_resp : 2'b00;
    assign wready_o = state == IDLE && !rst_i;

    assign bvalid_o = bvalid;

    assign bresp_o = bready_i ? sram_resp : 2'b00;
endmodule
