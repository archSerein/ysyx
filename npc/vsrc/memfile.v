import "DPI-C" function void pmem_write(input int addr, input int data, input int width);
import "DPI-C" function int pmem_read(input int addr, input int width);

module memfile (
    input clk_i,
    input [31:0] mem_addr_i,
    input [31:0] mem_wdata_i,
    input [31:0] mem_width_i,
    input mem_wen_i,
    input mem_ren_i,
    output [31:0] mem_rdata_o
);

    wire mem_ren;
    wire mem_wen;
    wire [31:0] width;
    wire [31:0] mem_wdata;
    wire [31:0] mem_addr;
    assign mem_ren = mem_ren_i;
    assign mem_wen = mem_wen_i;
    assign mem_addr = mem_addr_i;
    assign mem_wdata = mem_wdata_i;
    assign width = mem_width_i;


    always @(posedge clk_i) begin
        if (mem_wen) begin
            pmem_write(mem_addr, mem_wdata, width);
        end
    end

    // read
    wire [31:0] mem_rdata;
    assign mem_rdata = mem_ren ? pmem_read(mem_addr, width) : 32'h0;
    assign mem_rdata_o = mem_rdata;
endmodule