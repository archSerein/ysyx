`include "csr.vh"

 module csr (
    input                           clk_i,
    input                           rst_i,
    input                           csr_we_i,
    input  [`CSR_ADDR_WIDTH-1:0]    csr_waddr_i,
    input  [`CSR_ADDR_WIDTH-1:0]    csr_raddr_i,
    input  [`CSR_DATA_WIDTH-1:0]    csr_wdata_i,
    // ifu
    output [`CSR_DATA_WIDTH-1:0]    csr_mtvec_o,
    output [`CSR_DATA_WIDTH-1:0]    csr_mepc_o,

    output [`CSR_DATA_WIDTH-1:0]    csr_rdata_o
 );

    reg     [`CSR_DATA_WIDTH-1:0]    MCAUSE;
    reg     [`CSR_DATA_WIDTH-1:0]    MSTATUS;
    reg     [`CSR_DATA_WIDTH-1:0]    MTVEC;
    reg     [`CSR_DATA_WIDTH-1:0]    MEPC;
    reg     [`CSR_DATA_WIDTH-1:0]    MVENDORID;
    reg     [`CSR_DATA_WIDTH-1:0]    MARCHID;

    wire                    csr_mcause_we;
    wire                    csr_mstatus_we;
    wire                    csr_mtvec_we;
    wire                    csr_mepc_we;

    assign csr_mcause_we = csr_we_i && (csr_waddr_i == `CSR_ADDR_MCAUSE);
    assign csr_mstatus_we = csr_we_i && (csr_waddr_i == `CSR_ADDR_MSTATUS);
    assign csr_mtvec_we = csr_we_i && (csr_waddr_i == `CSR_ADDR_MTVEC);
    assign csr_mepc_we = csr_we_i && (csr_waddr_i == `CSR_ADDR_MEPC);

    always @(posedge clk_i) begin
        if (rst_i) begin
            MCAUSE <= 0;
        end
        else if (csr_mcause_we) begin
            MCAUSE <= csr_wdata_i;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            MSTATUS <= 0;
        end
        else if (csr_mstatus_we) begin
            MSTATUS <= csr_wdata_i;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            MTVEC <= 0;
        end
        else if (csr_mtvec_we) begin
            MTVEC <= csr_wdata_i;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            MEPC <= 0;
        end
        else if (csr_mepc_we) begin
            MEPC <= csr_wdata_i;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            MVENDORID <= 32'h78797379;
        end
    end

    always @(posedge clk_i) begin
        if (rst_i) begin
            MARCHID <= 32'h150be98;
        end
    end

    assign csr_rdata_o = {32{csr_raddr_i == `CSR_ADDR_MCAUSE}} & MCAUSE |
                         {32{csr_raddr_i == `CSR_ADDR_MSTATUS}} & MSTATUS |
                         {32{csr_raddr_i == `CSR_ADDR_MTVEC}} & MTVEC |
                         {32{csr_raddr_i == `CSR_ADDR_MEPC}} & MEPC |
                         {32{csr_raddr_i == `CSR_ADDR_MVENDORID}} & MVENDORID |
                         {32{csr_raddr_i == `CSR_ADDR_MARCHID}} & MARCHID;
    assign csr_mtvec_o = MTVEC;
    assign csr_mepc_o = MEPC;

 endmodule
