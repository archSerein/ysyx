`include "csr.vh"
module csr(
    input clk_i,
    input csr_wen_i,
    input [`WIDTH_SIZE-1:0] csr_raddr_i,
    input [`WIDTH_SIZE-1:0] csr_waddr_i,
    input [`WIDTH_SIZE-1:0] csr_wdata_i,
    output [`WIDTH_SIZE-1:0] csr_rdata_o
);
    // 特殊功能寄存器
    reg [`WIDTH_SIZE-1:0] mstatus;
    reg [`WIDTH_SIZE-1:0] mepc;
    reg [`WIDTH_SIZE-1:0] mcause;
    reg [`WIDTH_SIZE-1:0] mtvec;

    reg [`WIDTH_SIZE:0] csr_rdata;
    wire [`WIDTH_SIZE:0] csr_wdata = csr_wdata_i;
    wire [`WIDTH_SIZE:0] csr_waddr = csr_waddr_i;
    wire [`WIDTH_SIZE:0] csr_raddr = csr_raddr_i;
    // 时序逻辑
    // 用于写寄存器
    always @ (posedge clk)
    begin
        if(csr_wen)
        begin
            if (csr_waddr == `MSTATUS_ADDR)
                mstatus <= csr_wdata;
            else if (csr_waddr == `MEPC_ADDR)
                mepc <= csr_wdata;
            else if (csr_waddr == `MCAUSE_ADDR)
                mcause <= csr_wdata;
            else
                mtvec <= csr_wdata;
        end
    end

    // 读寄存器
    // wire [`WIDTH_SIZE-1:0] mux_1, mux_2, mux_3, mux_4;
    // assign mux_1 = (csr_raddr == 32'h300) ? mstatus : mepc;
    // assign mux_2 = (csr_raddr == 32'h342) ? mcause : mtvec;
    // assign mux_3 = (csr_raddr == 32'h305) ? mux_2 : mux_1;
    // assign csr_rdata = (csr_raddr == 32'h341) ? mux_3 : 32'h0;
    // assign csr_rdata = (csr_raddr == `MSTATUS_ADDR) ? mstatus :
    //                    (csr_raddr == `MEPC_ADDR) ? mepc :
    //                    (csr_raddr == `MCAUSE_ADDR) ? mcause :
    //                    (csr_raddr == `MTVEC_ADDR) ? mtvec : 32'h0;
    always @ *
    begin
        case (csr_raddr)
            `MSTATUS_ADDR: csr_rdata = mstatus;
            `MEPC_ADDR: csr_rdata = mepc;
            `MCAUSE_ADDR: csr_rdata = mcause;
            `MTVEC_ADDR: csr_rdata = mtvec;
            default: csr_rdata = 32'h0;
        endcase
    end

    assign csr_rdata_o = csr_rdata;
endmodule 