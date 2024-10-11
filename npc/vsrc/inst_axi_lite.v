module inst_axi_lite (
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
    output [ 1:0]       rresp_o
);

    wire mem_ren;
    wire [31:0] mem_addr;
    wire [31:0] sram_inst;

    inst_sram inst_sram_module (
        .clk_i          (clk_i),
        .imem_ren_i     (mem_ren),
        .imem_addr_i    (mem_addr),
        .imem_rdata_o   (sram_inst)
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
    localparam IDLE = 1'b0;
    localparam READ = 1'b1;
    reg         state;
    reg [31:0]  inst;
    reg [ 7:0]  cnt;
    reg [ 7:0]  randon_latency;
    reg         valid;

    always @(posedge clk_i) begin
        if (rst_i) begin
            state <= IDLE;
            valid <= 1'b0;
            cnt <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    if (arvalid_i) begin
                        // $display("Read from memory addr: %h", mem_addr);
                        state <= READ;
                        randon_latency <= lfsr_out;
                    end
                end
                READ: begin
                    if (cnt == randon_latency) begin
                        state <= IDLE;
                        valid <= 1'b1;
                        cnt <= 8'h00;
                    end
                    if (cnt == 8'b0) begin
                        inst <= sram_inst;
                        cnt <= cnt + 8'h01;
                    end 
                    if (cnt != randon_latency && cnt != 0) begin
                        cnt <= cnt + 8'h01;
                    end
                end
            endcase
        end
    end

    // when the read request is valid and the state is idle
    // enable mem read
    assign mem_ren  = arvalid_i && state == IDLE;

    // if the state is IDLE, the memory can access the read/write request
    assign arready_o = state == IDLE;

    assign mem_addr = araddr_i;

    assign rvalid_o = valid;
    assign rdata_o = rready_i ? inst : 32'h0;
    assign rresp_o = 2'b00;
endmodule
