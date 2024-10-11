module inst_sram (
    input               clk_i,
    input               imem_ren_i,
    input   [31:0]      imem_addr_i,
    output  [31:0]      imem_rdata_o
);

    import "DPI-C" function int     inst_read(input int addr);
    
    reg [31:0] inst;
    always @ (posedge clk_i) begin
        if (imem_ren_i) begin
            inst <= inst_read(imem_addr_i);
        end
    end
    assign imem_rdata_o = inst;
endmodule
