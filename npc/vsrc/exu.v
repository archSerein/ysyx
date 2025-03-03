`include "./include/generated/autoconf.vh"
`include "riscv_param.vh"

module exu (
    input                               clock,
    input                               reset,
    input                               adu_valid_i,
    input  [`ADU_EXU_BUS_WIDTH-1:0]     adu_exu_bus_i,
    // memfile
    // output [31:0]                       mem_addr_o,
    // output [31:0]                       mem_wdata_o,
    // output [ 3:0]                       mem_we_mask_o,
    // output                              mem_wen_o,
    // output                              mem_ren_o,
    // axi read addr channel
    input                               arready_i,
    output [31:0]                       araddr_o,
    output [ 2:0]                       arsize_o,
    output                              arvalid_o,
    // axi write addr channel
    input                               awready_i,
    output [31:0]                       awaddr_o,
    output                              awvalid_o,
    // axi wirte data channel
    input                               wready_i,
    output [31:0]                       wdata_o,
    output [ 3:0]                       wstrb_o,
    output                              wvalid_o,

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
    wire                  ex_xret_flush;
    wire                  ex_excp_flush;
    wire [11:0]           ex_csr_addr;
    wire                  ex_jmp_flag;
    wire                  ex_break_signal;
    wire [ 3:0]           ex_mem_re;
    wire [ 3:0]           ex_mem_we;
    wire [31:0]           ex_csr_value;
    wire [31:0]           ex_csr_wdata;
    wire [31:0]           ex_rs2_value;
    wire [31:0]           ex_snpc;
    wire                  compare_result;
    wire                  res_from_compare;

    assign {
        res_from_compare,
        compare_result,
        ex_excp_flush,
        ex_xret_flush,
        ex_break_signal,
        ex_snpc,
        ex_alu_src1,
        ex_alu_src2,
        ex_rs2_value,
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
        ex_csr_wdata,
        ex_csr_value
    } = adu_exu_bus;

    wire [31:0] ex_alu_result;
    alu alu_module (
        .alu_op_i       (ex_alu_op),
        .alu_a_i        (ex_alu_src1),
        .alu_b_i        (ex_alu_src2),
        .alu_result_o   (ex_alu_result)
    );

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

    wire [ 3:0] mem_we_mask;
    assign mem_we_mask   =  ({4{ex_mem_we == 4'b1111}} & 4'b1111) |
                            ({4{ex_mem_we == 4'b0011}} & sh_we)   |
                            ({4{ex_mem_we == 4'b0001}} & sb_we);

    wire [31:0] mem_byte_wdata;
    assign mem_byte_wdata = {
        {8{sb_we[3]}} & ex_rs2_value[7:0],
        {8{sb_we[2]}} & ex_rs2_value[7:0],
        {8{sb_we[1]}} & ex_rs2_value[7:0],
        {8{sb_we[0]}} & ex_rs2_value[7:0]
    };

    wire [31:0] mem_half_wdata;
    assign mem_half_wdata = {
        {16{sh_we[3]}} & ex_rs2_value[15:0],
        {16{sh_we[0]}} & ex_rs2_value[15:0]
    };
    wire [31:0] ex_jmp_target;
    assign ex_jmp_target = ex_alu_result;

    assign exu_lsu_bus_o = {
        ex_csr_wdata,           
        res_from_compare,       
        compare_result,         
        ex_snpc,                
        ex_csr_we,              
        mem_addr_mask,          
        ex_mem_re,              
        |ex_mem_we,
        ex_csr_addr,
        ex_alu_result,          
        ex_csr_value,           
        ex_res_from_mem,        
        ex_res_from_csr,        
        ex_gr_we,               
        ex_rd,                  
        ex_excp_flush,          
        ex_xret_flush,          
        ex_break_signal,        
        ex_jmp_flag,            
        ex_jmp_target
    };
    /*32 + 1 + 1 + 32 + 1 + 2 + 4 + 1 + 12 + 32 + 32 + 1 + 1 + 1 + 5 + 1 + 1 + 1 + 1 + 32 = 194*/
    wire    idle;
    always @(posedge clock) begin
        if (reset) begin
            valid <= 1'b0;
        end else if (adu_valid_i) begin
            valid <= 1'b1;
            adu_exu_bus <= adu_exu_bus_i;
        end else if (idle) begin
            valid <= 1'b0;
        end
    end
    // to memfile module
    // assign mem_addr_o       = ex_alu_result;
    // assign mem_wdata_o      =   ({32{ex_mem_we == 4'b1111}} & ex_rs2_value) |
    //                             ({32{ex_mem_we == 4'b0011}} & mem_half_wdata) |
    //                             ({32{ex_mem_we == 4'b0001}} & mem_byte_wdata);
    // assign mem_wen_o        = (|ex_mem_we) && valid;
    // assign mem_ren_o        = (|ex_mem_re) && valid;
    assign arsize_o         = {{3{ex_mem_re == 4'b1111}} & 3'b010} | 
                              {{3{ex_mem_re == 4'b0011 || ex_mem_re == 4'b0111}} & 3'b001} |
                              {{3{ex_mem_re == 4'b0001 || ex_mem_re == 4'b0101}} & 3'b000};
    assign araddr_o         = ex_alu_result;
    assign awaddr_o         = ex_alu_result;

    assign arvalid_o        = (|ex_mem_re) && valid;
    assign awvalid_o        = (|ex_mem_we) && valid;

    // assign wdata_o          =   ex_rs2_value;
    assign wdata_o          =   ({32{ex_mem_we == 4'b1111}} & ex_rs2_value) |
                                ({32{ex_mem_we == 4'b0011}} & mem_half_wdata) |
                                ({32{ex_mem_we == 4'b0001}} & mem_byte_wdata); 
    assign wstrb_o          = mem_we_mask;
    assign wvalid_o         = (|ex_mem_we) && valid;

    // 没有访存请求或者握手成功时, 有效数据会直接向下传递, 同时将 valid 置为 0,
    // 表示后续的数据并不是有效的
    assign idle = !(arvalid_o || awvalid_o || wvalid_o) || (arvalid_o && arready_i) || (awvalid_o && awready_i && wvalid_o && wready_i);
    assign valid_o = valid;

    `ifdef CONFIG_TRACE_PERFORMANCE
        import "DPI-C" function void exu_alu_count();
        always @*
        begin
            if (!ex_res_from_csr && !ex_res_from_mem && !res_from_compare && !ex_jmp_flag && valid)
                exu_alu_count();
        end
    `endif
endmodule
