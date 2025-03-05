`include "./include/generated/autoconf.vh"
`include "riscv_param.vh"
module rfu (
    input                           clock,
    input                           reset,
    input                           ifu_valid_i,
    input  [`IFU_RFU_BUS_WIDTH-1:0] ifu_rfu_bus_i,
    // regfile
    output [ 4:0]                   rfu_rs1_o,
    output [ 4:0]                   rfu_rs2_o,
    input  [31:0]                   rfu_rs1_value_i,
    input  [31:0]                   rfu_rs2_value_i,
    // csr register
    output [11:0]                   rfu_csr_addr_o,
    input  [31:0]                   rfu_csr_value_i,

    input  [31:0]                   rdata_i,
    input                           rvalid_i,

    output [`RFU_DEU_BUS_WIDTH-1:0] rfu_deu_bus_o,
    output                          valid_o
);

    reg                             valid;
    reg [`IFU_RFU_BUS_WIDTH-1:0]    ifu_rfu_bus;

    wire [31:0] rfu_pc;
    wire [31:0] rfu_inst;
    wire [31:0] rfu_snpc;

    assign {rfu_pc, rfu_snpc} = ifu_rfu_bus;

    always @(posedge clock) begin
        if (ifu_valid_i) begin
            ifu_rfu_bus <= ifu_rfu_bus_i;
        end
    end

    `ifdef CONFIG_TRACE_PERFORMANCE
        import "DPI-C" function void ifu_inst_count();
    `endif

    reg  [31:0] rfu_inst_r;
    always @(posedge clock) begin
        if (reset || !rvalid_i) begin
            valid <= 1'b0;
        end else if (rvalid_i) begin
            valid <= 1'b1;
        end
    end

    always @ (posedge clock) begin
      if (rvalid_i) begin
        rfu_inst_r <= rdata_i;
        `ifdef CONFIG_TRACE_PERFORMANCE
            ifu_inst_count();
        `endif
      end
    end

    assign rfu_inst = rfu_inst_r;

    assign rfu_deu_bus_o = {
        rfu_snpc,
        rfu_pc,
        rfu_inst,
        rfu_rs1_value_i,
        rfu_rs2_value_i,
        rfu_csr_value_i
    };
    /* 32 * 6 = 192 */

    assign rfu_rs1_o = rfu_inst[19:15];
    assign rfu_rs2_o = rfu_inst[24:20];
    assign rfu_csr_addr_o = rfu_inst[31:20];
    assign valid_o = valid;

endmodule
