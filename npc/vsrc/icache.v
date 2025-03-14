`include "./include/generated/autoconf.vh"
module icache #(
  parameter BLOCK = 16,
  parameter WAYS  = 4,
  parameter WIDTH = 32 ) (
  input                 clock,
  input                 reset,
  input                 rreq_i,
  input [WIDTH-1:0]     raddr_i,
  output                rready_o,
  output [WIDTH-1:0]    rdata_o,
  output                rvalid_o,

  input                 icache_arready_i,
  output                icache_arvalid_o,
  output  [WIDTH-1:0]   icache_araddr_o,

  input                 icache_rvalid_i,
  input   [WIDTH-1:0]   icache_rdata_i,
  input   [ 1:0]        icache_rresp_i,
  output                icache_rready_o
);

  parameter   word_bits   = 2;
  parameter   offset_bits = $clog2(WAYS);
  parameter   index_bits  = $clog2(BLOCK);
  parameter   tag_bits    = WIDTH - index_bits - offset_bits - word_bits;

  reg [WIDTH-1:0]          dataArray[BLOCK-1:0][WAYS-1:0];
  reg [tag_bits-1:0]       tagArray[BLOCK-1:0][WAYS-1:0];
  reg                      validArray[BLOCK-1:0][WAYS-1:0];
  reg [WIDTH-1:0]          miss_req_addr;
  wire  [index_bits-1:0]   index;
  wire  [offset_bits-1:0]  offset;
  wire  [tag_bits-1:0]     tag;
  wire  [index_bits-1:0]   miss_req_index;
  wire  [tag_bits-1:0]     miss_req_tag;
  wire  [offset_bits-1:0]  miss_req_offset;
  wire                     hit;

  assign tag    = raddr_i[WIDTH-1: offset_bits+index_bits+word_bits];
  assign index  = raddr_i[ offset_bits+index_bits+word_bits-1: offset_bits+word_bits];
  assign offset = raddr_i[ offset_bits-1+word_bits: word_bits];

  localparam INST_OK      = 2'b00;
  localparam INST_EXOKAY  = 2'b01;
  localparam INST_SLVERR  = 2'b10;
  localparam INST_DECERR  = 2'b11;

  reg [ 1:0]  mshr;
  localparam  READY         = 2'b00;
  localparam  SENDFILLREQ   = 2'b01;
  localparam  WAITFILLRESP  = 2'b10;

  wire  [ 1:0]  mshr_next_state;
  wire  [ 1:0]  ready_next_state;
  wire  [ 1:0]  sendfillreq_next_state;
  wire  [ 1:0]  waitfillresp_next_state;
  wire          fill_data_valid;
  wire          uncache_addr;
  wire          access_data_fault;

  always @(posedge clock) begin
    if (reset)
      mshr <= READY;
    else
      mshr <= mshr_next_state;
  end

  assign ready_next_state         = rreq_i && !hit  ? SENDFILLREQ : READY;
  assign sendfillreq_next_state   = icache_arready_i ? WAITFILLRESP : SENDFILLREQ;
  assign waitfillresp_next_state  = icache_rvalid_i ? READY : WAITFILLRESP;
  assign mshr_next_state          = {2{mshr == READY}} & ready_next_state |
                                    {2{mshr == SENDFILLREQ}} & WAITFILLRESP |
                                    {2{mshr == WAITFILLRESP}} & waitfillresp_next_state;

  assign hit                      = tagArray[index][offset] == tag &&
                                    validArray[index][offset_bits] && rreq_i;

  always @ (posedge clock) begin
    if (fill_data_valid && !uncache_addr) begin
      dataArray[miss_req_index][miss_req_offset]  <= icache_rdata_i;
    end
  end
  always @ (posedge clock) begin
    if (fill_data_valid && !uncache_addr) begin
      tagArray[miss_req_index][miss_req_offset]   <= miss_req_tag;
    end
  end
  always @ (posedge clock) begin
    if (fill_data_valid && !uncache_addr) begin
      validArray[miss_req_index][miss_req_offset] <= 1'b1;
    end
  end
  always @ (posedge clock) begin
    if (!hit) begin
      miss_req_addr <= raddr_i;
    end
  end
  always @ (posedge clock) begin
    if (access_data_fault) begin
      $display("access data fault");
      $finish;
    end
  end

  assign miss_req_tag             = miss_req_addr[WIDTH-1: offset_bits+index_bits+word_bits];
  assign miss_req_index           = miss_req_addr[ offset_bits+index_bits+word_bits-1: offset_bits+word_bits]; 
  assign miss_req_offset          = miss_req_addr[ offset_bits-1+word_bits: word_bits];
  assign fill_data_valid          = mshr == WAITFILLRESP && icache_rvalid_i && (icache_rresp_i == INST_OK || icache_rresp_i == INST_EXOKAY);
  assign uncache_addr             = miss_req_addr <= 32'h0f002000 && miss_req_addr >= 32'h0f000000;
  assign access_data_fault        = mshr == WAITFILLRESP && icache_rvalid_i && (icache_rresp_i == INST_DECERR || icache_rresp_i == INST_SLVERR);
  assign rready_o                 = mshr == READY;
  assign rvalid_o                 = hit || fill_data_valid;
  assign rdata_o                  = hit ? dataArray[index][offset] : icache_rdata_i;

  assign icache_rready_o          = mshr == WAITFILLRESP;
  assign icache_araddr_o          = miss_req_addr;
  assign icache_arvalid_o         = mshr == SENDFILLREQ;

  `ifdef CONFIG_TRACE_PERFORMANCE
    import "DPI-C"  function  void  hit_cnt();
    import "DPI-C"  function  void  miss_count();
    import "DPI-C"  function  void  penalty_count();
    always @*
    begin
      if (hit && rreq_i) begin
        hit_cnt();
      end
      if (!hit && rreq_i) begin
        miss_count();
      end
    end
    always @ (posedge clock) begin
      if (mshr != READY) begin
        penalty_count();
      end
    end
  `endif
endmodule
