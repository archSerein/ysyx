module sram (
    input               clk_i,
    input               sram_enable,
    input   [31:0]      addr_i,
    output  [31:0]      data_o
);

    import "DPI-C" function int inst_read(input int addr);
    // reg [31:0] isram[0:128];

    reg [31:0] sram_inst;    
    always @(posedge clk_i) begin
        if (sram_enable) begin
            sram_inst <= inst_read(addr_i);
            // sram_inst <= isram[addr_i];
        end else begin
            sram_inst <= 32'h0;         // 复位
        end
    end

    assign data_o = sram_inst;

endmodule
