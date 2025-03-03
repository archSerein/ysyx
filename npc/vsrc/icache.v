module icache (
  input             clock,
  input             reset,
  input             rreq_i,
  input [31:0]      raddr_i,
  output            rready_o,
  output  [31:0]    rdata_o,
  output            rvalid_o,

  input             icache_arready_i,
  output            icache_arvalid_o,
  output  [31:0]    icache_araddr_o,

  input             icache_rvalid_i,
  input   [31:0]    icache_rdata_i,
  input   [ 1:0]    icache_rresp_i,
  output            icache_rready_o
);

  reg [31:0]  dataArray[15:0];
  reg [25:0]  tagArray[15:0];
  reg         validArray[15:0];
  reg [31:0]  miss_req_addr;
  wire  [ 3:0] index;
  wire  [ 1:0] offset;
  wire  [25:0] tag;
  wire  [ 3:0] miss_req_index;
  wire  [25:0] miss_req_tag;
  wire         hit;

  assign tag    = raddr_i[31: 6];
  assign index  = raddr_i[ 5: 2];
  assign offset = raddr_i[ 1: 0];

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
  assign hit                      = tag == tagArray[index]  &&  validArray[index];

  always @ (posedge clock) begin
    if (mshr == WAITFILLRESP && icache_rvalid_i) begin
      dataArray[miss_req_index]  <= icache_rdata_i;
    end
  end
  always @ (posedge clock) begin
    if (mshr == WAITFILLRESP && icache_rvalid_i) begin
      tagArray[miss_req_index]   <= miss_req_tag;
    end
  end
  always @ (posedge clock) begin
    if (fill_data_valid) begin
      validArray[miss_req_index] <= 1'b1;
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

  assign fill_data_valid          = mshr == WAITFILLRESP && icache_rvalid_i && (icache_rresp_i == INST_OK || icache_rresp_i == INST_EXOKAY);
  assign access_data_fault        = mshr == WAITFILLRESP && icache_rvalid_i && (icache_rresp_i == INST_DECERR || icache_rresp_i == INST_SLVERR);
  assign rready_o                 = mshr == READY;
  assign rvalid_o                 = hit || fill_data_valid;
  assign rdata_o                  = hit ? dataArray[index] : icache_rdata_i;

  assign icache_rready_o          = mshr == WAITFILLRESP;
  assign icache_araddr_o          = miss_req_addr;
  assign icache_arvalid_o         = mshr == SENDFILLREQ;
endmodule
