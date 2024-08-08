import "DPI-C" function void pmem_write(input int addr, input int data, input byte wmask);
import "DPI-C" function int pmem_read(input int addr);

module memfile (
    input        clk_i,
    input        rst_i,
    input [31:0] mem_addr_i,
    input [31:0] mem_wdata_i,
    input [ 3:0] mem_we_mask_i,
    input        mem_wen_i,
    input        mem_ren_i,
    output[31:0] mem_rdata_o
);

    // reg [31:0] dsram[0:128];

    wire [31:0] mem_wdata;
    wire [31:0] mem_addr;
    assign mem_addr = mem_addr_i;
    assign mem_wdata = mem_wdata_i;

    wire [ 7:0] wmask;
    assign wmask = {4'b0, mem_we_mask_i};

    reg [31:0] mem_rdata;
    always @(posedge clk_i) begin
        if (rst_i) begin
            mem_rdata <= 0;
        end
        if (mem_wen_i) begin
            pmem_write(mem_addr, mem_wdata, wmask);
            // dsram[mem_addr] <= mem_wdata;
        end
        if (mem_ren_i) begin
            mem_rdata <= pmem_read(mem_addr);
            // mem_rdata <= dsram[mem_addr];
        end
    end

    // read
    assign mem_rdata_o = mem_rdata;
endmodule
