module lsu (
    input                               clk_i,
    input                               rst_i,
    input                               exu_valid_i,
    input  [`EXU_LSU_BUS_WIDTH-1:0]     exu_lsu_bus_i,
    // memfile
    input  [31:0]                       mem_rdata_i,

    output [`LSU_WBU_BUS_WIDTH-1:0]     lsu_wbu_bus_o,
    output                              valid_o
);

    reg valid;
    reg [`EXU_LSU_BUS_WIDTH-1:0] exu_lsu_bus;
    wire [31:0] ms_pc;
    wire [31:0] ms_alu_result;
    wire [31:0] ms_csr_value;
    wire [31:0] ms_jmp_target;
    wire        ms_res_from_mem;
    wire        ms_res_from_csr;
    wire        ms_gr_we;
    wire [ 4:0] ms_rd;
    wire [ 3:0] ms_mem_re;
    wire [11:0] ms_csr_addr;
    wire        ms_jmp_flag;
    wire        ms_break_signal;
    wire        ms_excp_flush;
    wire        ms_xret_flush;
    wire [ 1:0] ms_mem_addr_mask;
    wire [ 3:0] ms_mem_re;
    wire        ms_csr_we;
    
    assign {
        ms_csr_we,
        ms_mem_addr_mask,
        ms_mem_re,
        ms_csr_addr
        ms_pc,
        ms_alu_result,
        ms_csr_value,
        ms_res_from_mem,
        ms_res_from_csr,
        ms_gr_we,
        ms_rd,
        ms_excp_flush,
        ms_xret_flush,
        ms_break_signal
        ms_jmp_flag,
        ms_jmp_target
    };
        

    wire [ 7:0] ms_byteload;
    wire [15:0] ms_halfload;
    wire [31:0] ms_wordload;
    wire [31:0] mem_result;

    assign mem_byteload =   {8{ms_mem_addr_mask == 2'b00}} & mem_rdata_i[7:0] |
                            {8{ms_mem_addr_mask == 2'b01}} & mem_rdata_i[15:8] |
                            {8{ms_mem_addr_mask == 2'b10}} & mem_rdata_i[23:16] |
                            {8{ms_mem_addr_mask == 2'b11}} & mem_rdata_i[31:24];

    assign mem_halfload =   {16{ms_mem_addr_mask == 2'b00}} & mem_rdata_i[15:0] |
                            {16{ms_mem_addr_mask == 2'b10}} & mem_rdata_i[31:16];

    assign mem_wordload =   mem_rdata_i;

    assign mem_result   =   {32{ms_mem_re == 4'b1111}} & mem_wordload |
                            {32{ms_mem_re == 4'b0111}} & {{16{mem_halfload[15]}}, mem_halfload} |
                            {32{ms_mem_re == 4'b0011}} & {{16'b0}, mem_halfload} |
                            {32{ms_mem_re == 4'b0101}} & {{24{mem_byteload[7]}}, mem_byteload} |
                            {32{ms_mem_re == 4'b0001}} & {{24'b0}, mem_byteload};

    assign ms_final_result = {32{ms_res_from_mem}} & mem_result |
                             {32{ms_res_from_csr}} & ms_csr_value |
                             {32{!ms_res_from_mem && !ms_res_from_csr}} & ms_alu_result;

    always @(posedge clk_i) begin
        if (rst_i) begin
            valid <= 0;
            exu_lsu_bus <= 0;
        end else if (exu_valid_i) begin
            valid <= 1;
            exu_lsu_bus <= exu_lsu_bus_i;
        end else begin
            valid <= 0;
        end
    end

    assign lsu_wbu_bus_o = {
        ms_csr_we,
        ms_final_result,
        ms_gr_we,
        ms_rd,
        ms_csr_addr,
        ms_pc,
        ms_jmp_flag,
        ms_jmp_target,
        ms_break_signal,
        ms_excp_flush,
        ms_xret_flush
    };
    /* 1 + 32 + 1 + 5 + 12 + 32 + 1 + 32 + 1 + 1 + 1 = 119*/
endmodule