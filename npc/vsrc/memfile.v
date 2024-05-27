`include "ctrl.v"
import "DPI-C" function void pmem_write(input int addr, input int len, input int din);
import "DPI-C" function int pmem_read(input int addr, input int len);

module memfile (
    input clk,
    input we,
    input re,
    input [31:0] wdith,
    input [31:0] addr,
    input [31:0] din,
    output reg [31:0] dout
);
    
    always @ (posedge clk)
    begin
        if (we) pmem_write(addr, wdith, din); 
    end

    always @ (*)
    begin
        if(re == `mem_r_enable)
            dout = pmem_read(addr, wdith);
        else
            dout = 32'd0;
    end

endmodule
