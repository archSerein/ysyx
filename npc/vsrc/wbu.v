module wbu (
    input                           clk_i,
    input                           rst_i,
    input                           lsu_valid_i,
    input  [`LSU_WBU_BUS_WIDTH-1:0] lsu_wbu_bus_i,
    // register file
    output [ 4:0]                   rf_rd_o,
    output [31:0]                   rf_wdata_o,
    output                          rf_we_o,
    // csr register
    output [11:0]                   csr_addr_o,
    output [31:0]                   csr_wdata_o,
    output                          csr_we_o,
    output [`WBU_IFU_BUS_WIDTH-1:0] wbu_ifu_bus_o,
    output                          valid_o
);

    reg valid;
    reg [`LSU_WBU_BUS_WIDTH-1:0] lsu_wbu_bus;

    wire [31:0] wbu_pc;
    wire [31:0] wbu_final_result;
    wire        wbu_gr_we;
    wire [ 4:0] wbu_rd;
    wire [11:0] wbu_csr_addr;
    wire        wbu_break_signal;
    wire        wbu_excp_flush;
    wire        wbu_xret_flush;
    wire        wbu_jmp_flag;
    wire [31:0] wbu_jmp_target;
    wire        wbu_csr_we;

    assign {
        wbu_csr_we,
        wbu_final_result,
        wbu_gr_we,
        wbu_rd,
        wbu_csr_addr,
        wbu_pc,
        wbu_jmp_flag,
        wbu_jmp_target,
        wbu_break_signal,
        wbu_excp_flush,
        wbu_xret_flush
    } = lsu_wbu_bus;

    assign rf_we_o = wbu_gr_we && lsu_valid;
    assign rf_rd_o = wbu_rd;
    assign rf_wdata_o = wbu_final_result;
    assign csr_we_o = wbu_csr_we && lsu_valid;
    assign csr_addr_o = wbu_csr_addr;
    assign csr_wdata_o = wbu_final_result;
    assign valid_o = valid;

    always @(posedge clk_i) begin
        if (rst_i) begin
            valid <= 1'b0;
            lsu_wbu_bus <= 0;
        end else if (lsu_valid_i) begin
            valid <= 1'b1;
            lsu_wbu_bus <= lsu_wbu_bus_i;
        end else begin
            valid <= 1'b0;
        end
    end

    assign wbu_ifu_bus_o = {
        wbu_excp_flush,
        wbu_xret_flush,
        wbu_jmp_flag,
        wbu_jmp_target
    };

    import "DPI-C" function void ending(input int num);
    // break signal
    always @(*) begin
        if (wbu_break_signal) begin
            ending(1);
        end
    end
endmodule