module icache (
  input                 clock,
  input                 reset,
  input                 rreq_i,
  input [WIDTH-1:0]      raddr_i,
  output                rready_o,
  output [WIDTH-1:0]     rdata_o,
  output                rvalid_o,

  input                 icache_arready_i,
  output  [ 7:0]        icache_arlen_o,
  output  [ 2:0]        icache_arsize_o,
  output  [ 1:0]        icache_arburst_o,
  output                icache_arvalid_o,
  output  [WIDTH-1:0]   icache_araddr_o,

  input                 icache_rvalid_i,
  input   [WIDTH-1:0]   icache_rdata_i,
  input   [ 1:0]        icache_rresp_i,
  input                 icache_rlast_i,
  output                icache_rready_o
);

  parameter   WIDTH       = 32;
  parameter   OFFSET      = 4;
  parameter   INDEX       = 2;
  parameter   BLOCK       = 4;
  parameter   TAG         = WIDTH - OFFSET - INDEX;

  reg [WIDTH-1:0]          dataArray[BLOCK-1:0][OFFSET-1:0];
  reg [TAG-1:0]            tagArray[BLOCK-1:0];
  reg                      validArray[BLOCK-1:0];
  reg [WIDTH-1:0]          miss_req_addr;
  wire  [INDEX-1:0]        index;
  wire  [OFFSET-3:0]       offset;
  wire  [TAG-1:0]          tag;
  wire  [INDEX-1:0]        miss_req_index;
  wire  [TAG-1:0]          miss_req_tag;
  wire  [OFFSET-3:0]       miss_req_offset;
  wire                     hit;
  wire  [WIDTH-1:0]        hit_data;

  assign tag    = raddr_i[ WIDTH-1: OFFSET+INDEX];
  assign index  = raddr_i[ OFFSET+INDEX-1: OFFSET];
  assign offset = raddr_i[ OFFSET-1: 2];

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
  assign waitfillresp_next_state  = icache_rlast_i && icache_rvalid_i ? READY : WAITFILLRESP;
  assign mshr_next_state          = {2{mshr == READY}} & ready_next_state |
                                    {2{mshr == SENDFILLREQ}} & sendfillreq_next_state |
                                    {2{mshr == WAITFILLRESP}} & waitfillresp_next_state;

  assign                      hit = tagArray[index] == tag && validArray[index] && rreq_i;

  always @ (posedge clock) begin
    if (!hit && rreq_i) begin
      miss_req_addr <= raddr_i;
    end
  end

  reg [ 1:0]      fill_data_ptr;
  always @ (posedge clock) begin
    if (!hit && rreq_i) begin
      fill_data_ptr <= offset;
    end
    if (fill_data_valid) begin
      fill_data_ptr <= fill_data_ptr + 1;
    end
  end
  always @ (posedge clock) begin
    if (fill_data_valid && !uncache_addr) begin
      dataArray[miss_req_index][fill_data_ptr]  <= icache_rdata_i;
    end
  end
  always @ (posedge clock) begin
    if (icache_rlast_i && fill_data_valid && !uncache_addr) begin
      tagArray[miss_req_index]   <= miss_req_tag;
    end
  end
  always @ (posedge clock) begin
    if (icache_rlast_i && fill_data_valid && !uncache_addr) begin
      validArray[miss_req_index] <= 1'b1;
    end
  end

  assign miss_req_tag             = miss_req_addr[WIDTH-1: OFFSET+INDEX];
  assign miss_req_index           = miss_req_addr[OFFSET+INDEX-1: OFFSET]; 
  assign miss_req_offset          = miss_req_addr[OFFSET-1: 2];
  assign fill_data_valid          = mshr == WAITFILLRESP && icache_rvalid_i && (icache_rresp_i == INST_OK || icache_rresp_i == INST_EXOKAY);
  assign uncache_addr             = miss_req_addr[31:16] == 16'h0f00;
  assign access_data_fault        = mshr == WAITFILLRESP && icache_rvalid_i && (icache_rresp_i == INST_DECERR || icache_rresp_i == INST_SLVERR);
  assign rready_o                 = mshr == READY;
  assign rvalid_o                 = hit || (icache_rlast_i && fill_data_valid);

  assign rdata_o                  = {32{hit}} & dataArray[index][offset] |
                                    {32{!uncache_addr && !hit}} & dataArray[miss_req_index][miss_req_offset] |
                                    {32{uncache_addr && !hit}} & icache_rdata_i;

  assign icache_rready_o          = mshr == WAITFILLRESP;
  assign icache_araddr_o          = miss_req_addr;
  assign icache_arvalid_o         = mshr == SENDFILLREQ;
  assign icache_arsize_o          = 3'b010;
  assign icache_arburst_o         = uncache_addr ? 2'b00 : 2'b10;
  assign icache_arlen_o           = 3;
endmodule
