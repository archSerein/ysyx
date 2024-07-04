import "DPI-C" function void pmem_write(input int addr, input int data, input int mask);

module memfile (
    input clk_i,
    input [31:0] mem_addr_i,
    input [31:0] mem_wdata_i,
    input mem_wen_i,
    input mem_ren_i,
    output [31:0] mem_rdata_o
);

    // mask 读写掩码
    // sw sb sh
    
    always @(posedge clk_i) begin
        if (mem_wen_i) begin
            pmem_write(mem_addr_i, mem_wdata_i, MASK);
        end
    end

    // read
    assign mem_rdata_o = (mem_ren_i) ? pmem_read(mem_addr_i, MASK) : `zeroWord;
endmodule