module ps2_top_apb(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  input         ps2_clk,
  input         ps2_data
);

  reg [ 9:0]  buffer;
  reg [ 7:0]  fifo[7:0];
  reg [ 2:0]  fifo_wptr;
  reg [ 2:0]  fifo_rptr;
  reg [ 3:0]  cnt;
  reg [ 2:0]  ps2_clk_sync;

  wire sampling;
  wire read;

  always @(posedge clock) begin
    ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
  end

  always @(posedge clock) begin
    if (reset) begin
      buffer <= 10'b0;
      fifo_wptr <= 3'b0;
      fifo_rptr <= 3'b0;
      cnt <= 4'b0;
    end else begin
      if (sampling) begin
        if (cnt == 4'ha) begin
          if  (buffer[0] == 1'b0 && ps2_data && 
              (^buffer[9:1])) begin
            fifo[fifo_wptr] <= buffer[8:1];
            fifo_wptr <= fifo_wptr + 1;
          end
        cnt <= 4'b0;
        end else begin
          cnt <= cnt + 1;
          buffer[cnt] <= ps2_data;
        end
      end
      if (read && fifo_rptr != fifo_wptr) begin
        fifo_rptr <= fifo_rptr + 1;
      end
    end
  end

  assign sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];
  assign in_pready = !reset && fifo_rptr != fifo_wptr;  
  assign read = in_psel && in_penable && !in_pwrite;
  assign in_prdata = in_pready ? {24'b0, fifo[fifo_rptr]} : 32'b0;
  assign in_pslverr = 1'b0;
endmodule
