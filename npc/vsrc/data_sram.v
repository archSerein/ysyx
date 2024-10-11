module data_sram (
    input               clk_i,
    input               dmem_ren_i,
    input               dmem_wen_i,
    input   [31:0]      dmem_addr_i,
    input   [31:0]      dmem_wdata_i,
    input   [ 3:0]      dmem_we_mask_i,
    output  [31:0]      dmem_rdata_o,
    output  [ 1:0]      dmem_resp_o
);

    import "DPI-C" function void    pmem_write(input int addr, input int data, input byte wmask);
    import "DPI-C" function int     pmem_read(input int addr);
    
    reg [31:0] rdata;
    // 读数据
    always @(posedge clk_i) begin
        if (dmem_ren_i) begin
            rdata <= pmem_read(dmem_addr_i);
        end
    end

    // 写数据
    wire [ 7:0] wmask;
    assign wmask = {4'b0, dmem_we_mask_i};
    always @(posedge clk_i) begin
        if (dmem_wen_i) begin
            pmem_write(dmem_addr_i, dmem_wdata_i, wmask);
        end
    end

    assign dmem_rdata_o = rdata;
    assign dmem_resp_o = 2'b00;
endmodule

