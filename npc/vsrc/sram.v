module sram (
    input               clk_i,
    input               mem_ren_i,
    input               mem_wen_i,
    input   [31:0]      mem_addr_i,
    input   [31:0]      mem_wdata_i,
    input   [ 3:0]      mem_we_mask_i,
    output  [31:0]      mem_rdata_o,
    output  [ 1:0]      mem_resp_o
);

    import "DPI-C" function void    pmem_write(input int addr, input int data, input byte wmask);
    import "DPI-C" function int     pmem_read(input int addr);

    reg [31:0] rdata;
    // 读数据
    always @(posedge clk_i) begin
        if (mem_ren_i) begin
            rdata <= pmem_read(mem_addr_i);
        end
    end

    // 写数据
    wire [ 7:0] wmask;
    assign wmask = {4'b0, mem_we_mask_i};
    always @(posedge clk_i) begin
        if (mem_wen_i) begin
            pmem_write(mem_addr_i, mem_wdata_i, wmask);
        end
    end

    assign mem_rdata_o = rdata;
    assign mem_resp_o  = 2'b00;
endmodule
