module fetch (
    input clk_i,
    input rst_i,
    input [31:0] jmp_addr_i,
    input [31:0] snpc_i,
    input jmp_flag_i,
    output [31:0] inst_o,
    output [31:0] pc_o
);

    // Internal signals
    wire [31:0] ifu_inst;
    wire [31:0] ifu_pc;
    wire valid;

    // Instantiate IFU
    ifu ifu_module (
        .clk_i(clk_i),
        .valid_i(valid),
        .ifu_addr_i(pc_o),
        .ifu_inst_o(ifu_inst)
    );

    // Instantiate PC register
    pc_reg pc_reg_module (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .jmp_flag_i(jmp_flag_i),
        .jmp_addr_i(jmp_addr_i),
        .snpc_i(snpc_i),
        .valid_o(valid),
        .current_pc_o(ifu_pc)
    );

    // Output
    assign inst_o = ifu_inst;
    assign pc_o = ifu_pc;
endmodule

module pc_reg (
    input clk_i,
    input rst_i,
    input jmp_flag_i,
    input [31:0] jmp_addr_i,
    input [31:0] snpc_i,
    output valid_o,
    output [31:0] current_pc_o
);

    parameter RST_ADDR = 32'h80000000;
    // Internal signals
    reg pc_reg_clk_count = 1'b0;
    reg [31:0] current_pc = RST_ADDR;

    reg pc_reg_clk = 1'b0;
    reg valid = 1'b0;
    always @(posedge clk_i)
    begin
        if (rst_i) begin
            pc_reg_clk_count <= 1'b0;
            valid <= 1'b1;
        end else if (pc_reg_clk_count == 1'b1) begin
            pc_reg_clk_count <= 1'b0;
            pc_reg_clk <= ~pc_reg_clk;
            valid <= 1'b1;
        end else begin
            pc_reg_clk_count <= pc_reg_clk_count + 1;
            valid <= 1'b0;
        end
    end        

    // PC register
    always @(posedge pc_reg_clk) begin
        if (rst_i) begin
            current_pc <= RST_ADDR;
        end else if (jmp_flag_i) begin
            current_pc <= jmp_addr_i;
        end else begin
            current_pc <= snpc_i;
        end
    end

    assign valid_o = valid;
    assign current_pc_o = current_pc;
endmodule

module ifu (
    input clk_i,
    input valid_i,
    // input ifu_accept_i,
    input [31:0] ifu_addr_i,
    // output ifu_valid_o,
    output [31:0] ifu_inst_o
);

    // Internal signals
    reg [31:0] ifu_inst;
    wire [31:0] ifu_inst_i;
    // Instantiate SRAM
    SRAM sram (
        .clk_i(clk_i),
        .valid(valid_i),
        .fetch_addr_i(ifu_addr_i),
        .fetch_data_o(ifu_inst_i)
    );

    always @(posedge clk_i) begin
        ifu_inst <= ifu_inst_i;    
    end

    assign ifu_inst_o = ifu_inst;
endmodule

module SRAM (
    input clk_i,
    input valid,
    input [31:0] fetch_addr_i,
    output [31:0] fetch_data_o
);

    import "DPI-C" function int inst_read(input int addr);

    wire [31:0] fetch_addr = fetch_addr_i;   
    // Internal signals
    reg [31:0] fetch_data;
    always @(posedge clk_i) begin
        if (valid)
            fetch_data <= inst_read(fetch_addr);
    end

    assign fetch_data_o = fetch_data;
endmodule