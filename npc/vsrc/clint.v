module clint (
    input                   clock,
    input                   reset,

    input                   arvalid_i,
    output                  arready_o,
    input  [31:0]           araddr_i,

    output                  rvalid_o,
    input                   rready_i,
    output  [31:0]          rdata_o
);

    reg     [63:0]          mtime;
    always @(posedge clock) begin
        if (reset) begin
            mtime <= 0;
        end else begin
            mtime <= mtime + 1;
        end
    end

    reg        valid;
    reg        [31:0]       rdata;
    always @(posedge clock) begin
        if (arvalid_i) begin
            valid <= 1'b1;
            if (araddr_i == 32'h02000048) begin
                rdata <= mtime[31:0];
            end else if (araddr_i == 32'h0200004c) begin
                rdata <= mtime[63:32];
            end
        end else begin
            valid <= 1'b0;
        end
    end

    assign rdata_o     = rdata;
    assign arready_o   = !valid;
    assign rvalid_o    = valid;
endmodule
