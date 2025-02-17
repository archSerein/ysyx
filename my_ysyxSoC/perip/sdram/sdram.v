module sdram(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [12:0] a,
  input [ 1:0] ba,
  input [ 1:0] dqm,
  inout [15:0] dq
);

  import "DPI-C" function void sdram_read(input int raddr, output int data);
  import "DPI-C" function void sdram_write(input int waddr, input byte mask, input int data);

  localparam STATE_IDLE = 2'b00;
  localparam STATE_READ = 2'b01;
  localparam STATE_WRITE = 2'b10;
  localparam STATE_ACTIVE = 2'b11;

  parameter SDRAM_ADDR_W  = 24;
  parameter SDRAM_COL_W   = 9;
  localparam SDRAM_BANK_W = 2;
  localparam SDRAM_BANKS  = 2 ** SDRAM_BANK_W;
  localparam SDRAM_ROW_W  = SDRAM_ADDR_W - SDRAM_COL_W - SDRAM_BANK_W;

  wire NOP, ACTIVE, READ, WRITE, BURST_TERMINATE, LOAD_MODE;
  wire PRECHARGE, INHIBIT, AUTO_REFRESH;
  wire [ 1:0] state_idle_next;
  wire [ 1:0] state_read_next;
  wire [ 1:0] state_write_next;
  wire [ 1:0] state_active_next;
  wire [ 1:0] state_next;
  wire [ 2:0] cas_latency;
  wire [ 2:0] burst_length;
  wire [15:0] odata;
  wire [31:0] addr, wdata, rdata, waddr, raddr;
  wire [ 2:0] counter_r, counter_w, counter_active, burst_cnt_r, burst_cnt_w;
  wire [ 7:0] wmask;
  reg  [ 1:0] state, mask;
  reg  [ 1:0] active_bank;
  reg  [ 8:0] active_col;
  reg  [ 2:0] counter, burst_cnt;
  reg  [11:0] mode;
  reg  [15:0] data;
  reg [SDRAM_ROW_W-1:0]  active_row_q[0:SDRAM_BANKS-1];
  always @(posedge clk) begin
    if (INHIBIT) begin
      mode <= 12'h000;
    end
    if (LOAD_MODE && state == STATE_IDLE && a[12] == 1'b0) begin
      mode <= a[11:0];
    end
  end

  always @(posedge clk) begin
    if (INHIBIT) begin
      state <= STATE_IDLE;
    end else begin
      state <= state_next;
    end
  end

  always @(posedge clk) begin
    if (INHIBIT) begin
      counter <= 3'h0;
      burst_cnt <= 3'h0;
    end else if (ACTIVE) begin
      active_row_q[ba] <= a[12:0];
    end else if (READ) begin
      active_bank <= ba;
      active_col <= a[8:0];
    end else if (WRITE) begin
      active_bank <= ba;
      active_col <= a[8:0];
    end
  end

  always @(posedge clk) begin
    if (state == STATE_READ || READ) begin
      mask <= dqm;
      if (counter_r == cas_latency) begin
        sdram_read(raddr, rdata);
        burst_cnt <= burst_cnt_r;
      end else begin
        counter <= counter_r;
      end
    end else if (state == STATE_WRITE || WRITE) begin
      mask <= dqm;
      data <= dq;
      if (counter_w == cas_latency) begin
        sdram_write(waddr, wmask, wdata);
        burst_cnt <= burst_cnt_w;
      end else begin
        counter <= counter_w;
      end
    end else if (state == STATE_ACTIVE || ACTIVE) begin
      counter <= counter_active;
    end else begin
      burst_cnt <= 3'h0;
      counter <= 3'h0;
    end
  end
  // read/write logic
  assign wmask = {6'h0, mask};
  assign wdata = {16'h0, data};
  assign counter_active = (state == STATE_ACTIVE || ACTIVE) ? counter + 1 : 3'h0;
  assign counter_r = (state == STATE_READ || READ) ? counter + 1 : 3'h0;
  assign burst_cnt_r = (state == STATE_READ || READ) ? burst_cnt + 1 : 3'h0;
  assign counter_w = (state == STATE_WRITE || WRITE) ? counter + 1 : 3'h0;
  assign burst_cnt_w = (state == STATE_WRITE || WRITE) ? burst_cnt + 1 : 3'h0;
  assign waddr = addr + {29'h0, burst_cnt << 1};
  assign raddr = addr + {29'h0, burst_cnt << 1};

  // next state logic
  assign state_idle_next = {2{READ}} & STATE_READ |
                           {2{WRITE}} & STATE_WRITE |
                           {2{ACTIVE}} & STATE_ACTIVE |
                           {2{AUTO_REFRESH || PRECHARGE || NOP ||
                              BURST_TERMINATE || LOAD_MODE}} & STATE_IDLE; 
  assign state_read_next = {2{burst_cnt_r == burst_length}} & STATE_IDLE |
                           {2{burst_cnt_r != burst_length}} & STATE_READ;
  assign state_write_next = {2{burst_cnt_w == burst_length}} & STATE_IDLE |
                            {2{burst_cnt_w != burst_length}} & STATE_WRITE;
  assign state_active_next = {2{counter_active == cas_latency && READ}} & STATE_READ |
                              {2{counter_active == cas_latency && WRITE}} & STATE_WRITE |
                              {2{counter_active != cas_latency}} & STATE_ACTIVE |
                              {2{counter_active == cas_latency && !READ && !WRITE}} & STATE_IDLE;
  assign state_next = state_idle_next & {2{state == STATE_IDLE}} |
                      state_read_next & {2{state == STATE_READ}} |
                      state_write_next & {2{state == STATE_WRITE}} |
                      state_active_next & {2{state == STATE_ACTIVE}};

  assign addr = {7'h0,active_row_q[active_bank],active_bank,active_col[8:0], 1'b0};
  assign INHIBIT = cs;
  assign NOP = !cs && ras && cas && we;
  assign PRECHARGE = !cs && !ras && cas && !we;
  assign AUTO_REFRESH = !cs && !ras && !cas && we;
  assign ACTIVE = !cs && !ras && cas && we;
  assign READ = !cs && ras && !cas && we;
  assign WRITE = !cs && ras && !cas && !we;
  assign BURST_TERMINATE = !cs && ras && cas && !we;
  assign LOAD_MODE = !cs && !ras && !cas && !we;
  assign cas_latency = mode[6:4];
  assign burst_length = mode[2:0] == 3'h0 ? 3'h1 :
                        mode[2:0] == 3'h1 ? 3'h2 :
                        mode[2:0] == 3'h2 ? 3'h4 :
                        mode[2:0] == 3'h3 ? 3'h8 :
                        3'h0;
  assign odata =  (mask == 2'h0) ? rdata[15:0] :
                  (mask == 2'h1) ? {rdata[15:8], 8'hZZ} :
                  (mask == 2'h2) ? {8'hZZ, rdata[7:0]} :
                  16'hZZZZ;
  assign dq = (state != STATE_WRITE && !WRITE) ? odata :
              16'hZZZZ;
endmodule
