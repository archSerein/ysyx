module bitrev (
  input  sck,
  input  ss,
  input  mosi,
  output miso
);
  // assign miso = 1'b1;
  wire    ss_n;
  reg   [ 2:0] cnt;
  reg   [ 7:0] data;
  reg          flag;
  // sample the mosi signal on the rising edge of the sck signal
  always @(posedge sck) begin
    if (ss_n && !flag) begin
      data[7] <= data[6];
      data[6] <= data[5];
      data[5] <= data[4];
      data[4] <= data[3];
      data[3] <= data[2];
      data[2] <= data[1];
      data[1] <= data[0];
      data[0] <= mosi;
      cnt <= cnt + 1;
      if (cnt == 3'b111) begin
        flag <= ~flag;
      end
    end else if (ss_n && flag) begin
      cnt <= cnt - 1;
      if (cnt == 3'b000) begin
        flag <= ~flag;
      end
    end else begin
      // nothing to do
    end
  end

    assign ss_n = ~ss;
    assign miso = (ss_n && flag) ? data[cnt] : 1'b1;
    // always @(*) begin
    //   if (ss_n) begin
    //     $display("cnt=%d, data=%h, flag=%d", cnt, data, flag);
    //   end
    // end
endmodule
