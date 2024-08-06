module exu (
    input                               clk_i,
    input                               rst_i,
    input                               adu_valid_i,
    input  [`ADU_EXU_BUS_WIDTH-1:0]     adu_exu_bus_i,
    // memfile
    output [31:0]                       mem_addr_o,
    output [31:0]                       mem_wdata_o,
    output [ 3:0]                       mem_we_mask_o,
    output                              mem_wen_o,
    output                              mem_ren_o,
    output [`EXU_LSU_BUS_WIDTH-1:0]     exu_lsu_bus_o,
    output                              valid_o
);

    reg valid;
    reg  [`ADU_EXU_BUS_WIDTH-1:0]     adu_exu_bus;
    wire [ 5:0]           ex_alu_op;
    wire [31:0]           ex_alu_src1;
    wire [31:0]           ex_alu_src2;
    wire                  ex_res_from_mem;
    wire                  ex_res_from_csr;
    wire                  ex_gr_we;
    wire                  ex_csr_we;
    wire [ 4:0]           ex_rd;
    wire [31:0]           ex_pc;
    wire                  ex_xret_flush;
    wire                  ex_excp_flush;
    wire [11:0]           ex_csr_addr;
    wire                  ex_jmp_flag;
    wire                  ex_break_signal;
    wire [ 3:0]           ex_mem_re;
    wire [ 3:0]           ex_mem_we;
    wire [31:0]           ex_csr_value;

    assign {
        ex_excp_flush,
        ex_xret_flush,
        ex_break_signal,
        ex_pc,
        ex_alu_src1,
        ex_alu_src2,
        ex_alu_op,
        ex_res_from_mem,
        ex_res_from_csr,
        ex_gr_we,
        ex_csr_we,
        ex_mem_re,
        ex_mem_we,
        ex_rd,
        ex_jmp_flag,
        ex_csr_addr,
        ex_csr_value
    } = adu_exu_bus;

    wire [31:0] ex_alu_result;
    alu alu_module (
        .alu_op_i       (ex_alu_op),
        .alu_a_i        (ex_alu_src1),
        .alu_b_i        (ex_alu_src2),
        .alu_result_o   (ex_alu_result)
    );

    wire [ 3:0] mem_wmask;
    wire [ 3:0] sb_we, sh_we;
    wire [ 1:0] mem_addr_mask;

    assign mem_addr_mask = ex_alu_result[1:0];

    assign sb_we = {
                    mem_addr_mask == 2'b11,
                    mem_addr_mask == 2'b10,
                    mem_addr_mask == 2'b01,
                    mem_addr_mask == 2'b00
                };
    assign sh_we = {
                    mem_addr_mask == 2'b10,
                    mem_addr_mask == 2'b10,
                    mem_addr_mask == 2'b00,
                    mem_addr_mask == 2'b00
                };
    assign mem_wmask =  {4{ex_mem_we == 4'b1111}} & 4'b1111 |
                        {4{ex_mem_we == 4'b0011}} & sh_we   |
                        {4{ex_mem_we == 4'b0001}} & sb_we;

    wire [31:0] ex_jmp_target;
    assign ex_jmp_target = ex_alu_result;

    assign exu_lsu_bus_o = {
        ex_csr_we,              // 158:158
        mem_addr_mask,          // 157:156
        ex_mem_re,              // 155:152
        csr_addr,               // 151:140
        ex_pc,                  // 139:108
        ex_alu_result,          // 107:76
        ex_csr_value,           // 75:44
        ex_res_from_mem,        // 43:43
        ex_res_from_csr,        // 42:42
        ex_gr_we,               // 41:41
        ex_rd,                  // 40:36
        ex_excp_flush,          // 35:35
        ex_xret_flush,          // 34:34
        ex_break_signal,        // 33:33
        ex_jmp_flag,            // 32:32
        ex_jmp_target           // 31:0
    };
    always @(posedge clk_i) begin
        if (rst_i) begin
            adu__exu_bus <= 0;
            valid <= 0;
        end else if (adu_valid_i) begin
            valid <= 1;
            adu_exu_bus <= adu_exu_bus_i;
        end else begin
            valid <= 0;
        end
    end
    // to memfile module
    assign mem_addr_o       = ex_alu_result;
    assign mem_wdata_o      = ex_alu_src2;
    assign mem_we_mask_o    = mem_wmask;
    assign mem_wen_o        = |ex_mem_we;
    assign mem_ren_o        = |ex_mem_re;
    
endmodule