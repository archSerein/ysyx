`include "./include/generated/autoconf.vh"
`include "riscv_param.vh"
module lsu (
    input                               clock,
    input                               reset,
    input                               exu_valid_i,
    input  [`EXU_LSU_BUS_WIDTH-1:0]     exu_lsu_bus_i,
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
    wire [31:0] ms_csr_value;
    wire [31:0] ms_jmp_target;
    wire [31:0] ms_csr_wdata;
    wire        ms_res_from_mem;
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
    wire        ms_csr_we;
    wire [31:0] ms_final_result;
    
    assign {
        ms_csr_wdata,
        ms_csr_we,
        ms_mem_addr_mask,
        ms_mem_re,
        ms_mem_we,
        ms_csr_addr,
        ms_res_from_mem,
        ms_gr_we,
        ms_rd,
        ms_excp_flush,
        ms_xret_flush,
        ms_break_signal,
        ms_jmp_flag,
        ms_jmp_target,
        ms_final_result
    } = exu_lsu_bus;

    wire [ 7:0] ms_byteload;
    wire [15:0] ms_halfload;
    wire [31:0] ms_wordload;
    wire [31:0] ms_result;
    wire [31:0] final_result;

    assign ms_byteload =   {8{ms_mem_addr_mask == 2'b00}} & rdata_i[7:0] |
                           {8{ms_mem_addr_mask == 2'b01}} & rdata_i[15:8] |
                           {8{ms_mem_addr_mask == 2'b10}} & rdata_i[23:16] |
                           {8{ms_mem_addr_mask == 2'b11}} & rdata_i[31:24];

    assign ms_halfload =   {16{ms_mem_addr_mask == 2'b00}} & rdata_i[15:0] |
                           {16{ms_mem_addr_mask == 2'b10}} & rdata_i[31:16];

    assign ms_wordload =   rdata_i;

    assign ms_result   =    {32{ms_mem_re == 4'b1111}} & ms_wordload |
                            {32{ms_mem_re == 4'b0111}} & {{16{ms_halfload[15]}}, ms_halfload} |
                            {32{ms_mem_re == 4'b0011}} & {{16'b0}, ms_halfload} |
                            {32{ms_mem_re == 4'b0101}} & {{24{ms_byteload[7]}}, ms_byteload} |
                            {32{ms_mem_re == 4'b0001}} & {{24'b0}, ms_byteload};

    assign final_result = ms_res_from_mem ? ms_result : ms_final_result;

    always @(posedge clock) begin
        if (exu_valid_i) begin
            exu_lsu_bus <= exu_lsu_bus_i;
        end
    end

    localparam IDLE      = 1'b0;
    localparam WAIT      = 1'b1;
    reg         state;
    `ifdef CONFIG_TRACE_PERFORMANCE
        import "DPI-C" function void lsu_load_store_count();
        import "DPI-C" function void mem_cycle_count();
        always @ (posedge clock) begin
          if (state == WAIT && (bvalid_i || rvalid_i)) begin
            lsu_load_store_count();
          end
          if (state == WAIT) begin
            mem_cycle_count();
          end
        end
    `endif
    wire        next_state;
    wire        idle_next;
    wire        wait_next;
    always @(posedge clock) begin
      if (reset)
        state <= IDLE;
      else
        state <= next_state;
    end
    assign idle_next = valid && (|ms_mem_re || ms_mem_we) ? WAIT : IDLE;
    assign wait_next = bvalid_i || rvalid_i ? IDLE : WAIT;
    assign next_state = state ? wait_next : idle_next;

    wire        valid_q;
    always @(posedge clock) begin
      valid <= valid_q;
    end
    assign valid_q = exu_valid_i && !reset;

    assign lsu_wbu_bus_o = {
        ms_csr_we,
        final_result,
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
      if (bresp_i[1] == 1'b1) begin
        $display("write response error, bresp: %b", bresp_i);
        $finish;
      end
    end

    assign bready_o = state == WAIT;
    assign rready_o = state == WAIT;

    assign valid_o = (valid && (!(|ms_mem_re | ms_mem_we))) || (state && (bvalid_i || rvalid_i));
endmodule
