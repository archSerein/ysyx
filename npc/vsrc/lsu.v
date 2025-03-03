`include "./include/generated/autoconf.vh"
`include "riscv_param.vh"
module lsu (
    input                               clock,
    input                               reset,
    input                               exu_valid_i,
    input  [`EXU_LSU_BUS_WIDTH-1:0]     exu_lsu_bus_i,
    // memfile
    // input  [31:0]                       mem_rdata_i,
    // read data channel
    input  [31:0]                       rdata_i,
    input  [ 1:0]                       rresp_i,
    input                               rvalid_i,
    output                              rready_o,

    // wirte response channel
    input  [ 1:0]                       bresp_i,
    input                               bvalid_i,
    output                              bready_o,

    output [`LSU_WBU_BUS_WIDTH-1:0]     lsu_wbu_bus_o,
    output                              valid_o
);

    localparam INST_OK      = 2'b00;
    localparam INST_EXOKAY  = 2'b01;
    // localparam INST_SLVERR  = 2'b10;
    // localparam INST_DECERR  = 2'b11;

    reg valid;
    reg [`EXU_LSU_BUS_WIDTH-1:0] exu_lsu_bus;
    wire [31:0] ms_snpc;
    wire [31:0] ms_alu_result;
    wire [31:0] ms_csr_value;
    wire [31:0] ms_jmp_target;
    wire [31:0] ms_csr_wdata;
    wire        ms_res_from_mem;
    wire        ms_res_from_csr;
    wire        ms_gr_we;
    wire [ 4:0] ms_rd;
    wire [ 3:0] ms_mem_re;
    wire        ms_mem_we;
    wire [11:0] ms_csr_addr;
    wire        ms_jmp_flag;
    wire        ms_break_signal;
    wire        ms_excp_flush;
    wire        ms_xret_flush;
    wire [ 1:0] ms_mem_addr_mask;
    wire [ 3:0] ms_mem_re;
    wire        compare_result;
    wire        res_from_compare;
    wire        ms_csr_we;
    
    assign {
        ms_csr_wdata,
        res_from_compare,
        compare_result,
        ms_snpc,
        ms_csr_we,
        ms_mem_addr_mask,
        ms_mem_re,
        ms_mem_we,
        ms_csr_addr,
        ms_alu_result,
        ms_csr_value,
        ms_res_from_mem,
        ms_res_from_csr,
        ms_gr_we,
        ms_rd,
        ms_excp_flush,
        ms_xret_flush,
        ms_break_signal,
        ms_jmp_flag,
        ms_jmp_target
    } = exu_lsu_bus;
        

    wire [ 7:0] ms_byteload;
    wire [15:0] ms_halfload;
    wire [31:0] ms_wordload;
    wire [31:0] ms_result;
    wire [31:0] ms_final_result;

    wire [31:0] rdata;
    assign ms_byteload =   {8{ms_mem_addr_mask == 2'b00}} & rdata[7:0] |
                           {8{ms_mem_addr_mask == 2'b01}} & rdata[15:8] |
                           {8{ms_mem_addr_mask == 2'b10}} & rdata[23:16] |
                           {8{ms_mem_addr_mask == 2'b11}} & rdata[31:24];

    assign ms_halfload =   {16{ms_mem_addr_mask == 2'b00}} & rdata[15:0] |
                           {16{ms_mem_addr_mask == 2'b10}} & rdata[31:16];

    assign ms_wordload =   rdata;

    assign ms_result   =    {32{ms_mem_re == 4'b1111}} & ms_wordload |
                            {32{ms_mem_re == 4'b0111}} & {{16{ms_halfload[15]}}, ms_halfload} |
                            {32{ms_mem_re == 4'b0011}} & {{16'b0}, ms_halfload} |
                            {32{ms_mem_re == 4'b0101}} & {{24{ms_byteload[7]}}, ms_byteload} |
                            {32{ms_mem_re == 4'b0001}} & {{24'b0}, ms_byteload};

    assign ms_final_result = {32{ms_res_from_mem}} & ms_result |
                             {32{ms_res_from_csr}} & ms_csr_value |
                             {32{ms_jmp_flag}} & ms_snpc |
                             {32{res_from_compare}} & {31'b0, compare_result} |
                             {32{!ms_res_from_mem && !ms_res_from_csr &
                                    !res_from_compare & !ms_jmp_flag}} & ms_alu_result;

    always @(posedge clock) begin
        if (exu_valid_i) begin
            exu_lsu_bus <= exu_lsu_bus_i;
        end
    end

    localparam [ 1:0] IDLE      = 2'b00;
    localparam [ 1:0] HANDLE    = 2'b01;
    localparam [ 1:0] WAIT      = 2'b10;
    localparam [ 1:0] FINISH    = 2'b11;
    reg        [ 1:0] state;
    reg        [31:0] rdata_r;
    `ifdef CONFIG_TRACE_PERFORMANCE
        import "DPI-C" function void lsu_load_store_count();
        import "DPI-C" function void mem_cycle_count();
    `endif
    always @(posedge clock) begin
        if (reset) begin
            state <= IDLE;
            valid <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (exu_valid_i) begin
                        state <= HANDLE;
                        `ifdef CONFIG_TRACE_PERFORMANCE
                            mem_cycle_count();
                        `endif
                    end
                end
                HANDLE: begin
                    `ifdef CONFIG_TRACE_PERFORMANCE
                        mem_cycle_count();
                    `endif
                    if (|ms_mem_re || ms_mem_we) begin
                        state <= WAIT;
                    end
                    if (!ms_mem_we && !(|ms_mem_re)) begin
                        valid <= 1'b1;
                        state <= FINISH;
                    end
                end
                WAIT: begin
                    `ifdef CONFIG_TRACE_PERFORMANCE
                        mem_cycle_count();
                    `endif
                    if (bvalid_i || rvalid_i) begin
                        state <= FINISH;
                        valid <= 1'b1;
                        if (rvalid_i && (rresp_i == INST_OK || rresp_i == INST_EXOKAY)) begin
                            rdata_r <= rdata_i;
                        end else if (rvalid_i) begin
                            $display("fault response from memory");
                            $finish;
                        end
                        `ifdef CONFIG_TRACE_PERFORMANCE
                            lsu_load_store_count();
                        `endif
                    end
                end
                FINISH: begin
                    `ifdef CONFIG_TRACE_PERFORMANCE
                        mem_cycle_count();
                    `endif
                    valid <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end

    assign rdata = rdata_r;
    // assign rdata = {32{(rvalid_i && (rresp_i == INST_OK || rresp_i == INST_EXOKAY))}} & rdata_i;

    assign lsu_wbu_bus_o = {
        ms_csr_we,
        ms_final_result,
        ms_gr_we,
        ms_rd,
        ms_csr_addr,
        ms_csr_wdata,
        ms_jmp_flag,
        ms_jmp_target,
        ms_break_signal,
        ms_excp_flush,
        ms_xret_flush
    };
    /* 1 + 32 + 1 + 5 + 12 + 32 + 1 + 32 + 1 + 1 + 1 = 119*/

    // 写回复的处理
    always @(bvalid_i) begin
        if (bresp_i == 2'b00) begin
            // $display("write response okay");
        end
        else begin
            $display("write response error, bresp: %b", bresp_i);
            $finish;
        end
    end

    assign bready_o = state == WAIT;
    assign rready_o = state == WAIT;

    assign valid_o = valid;
endmodule
