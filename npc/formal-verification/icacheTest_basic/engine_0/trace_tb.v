`ifndef VERILATOR
module testbench;
  reg [4095:0] vcdfile;
  reg clock;
`else
module testbench(input clock, output reg genclock);
  initial genclock = 1;
`endif
  reg genclock = 1;
  reg [31:0] cycle = 0;
  wire [0:0] PI_clock = clock;
  icache_formal UUT (
    .clock(PI_clock)
  );
`ifndef VERILATOR
  initial begin
    if ($value$plusargs("vcd=%s", vcdfile)) begin
      $dumpfile(vcdfile);
      $dumpvars(0, testbench);
    end
    #5 clock = 0;
    while (genclock) begin
      #5 clock = 0;
      #5 clock = 1;
    end
  end
`endif
  initial begin
`ifndef VERILATOR
    #1;
`endif
    // UUT.$auto$async2sync.\cc:101:execute$410  = 1'b0;
    // UUT.$auto$async2sync.\cc:110:execute$414  = 1'b1;
    UUT.dut.fill_data_ptr = 2'b00;
    UUT.dut.miss_req_addr = 32'b00000000000000000000000000000000;
    UUT.dut.mshr = 2'b00;
    UUT.\memInfo[0]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[10]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[11]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[12]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[13]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[14]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[15]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[16]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[17]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[18]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[19]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[1]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[20]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[21]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[22]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[23]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[24]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[25]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[26]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[27]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[28]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[29]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[2]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[30]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[31]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[3]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[4]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[5]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[6]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[7]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[8]  = 32'b00000000000000000000000000000000;
    UUT.\memInfo[9]  = 32'b00000000000000000000000000000000;
    UUT.raddr_r = 32'b00000000000000000000000000000000;
    UUT.reset = 1'b0;
    UUT.reset_cnt = 3'b000;
    UUT.rreq_i = 1'b0;
    UUT.dut.dataArray[6'b111111] = 32'b00000000000000000000000000000000;
    UUT.dut.dataArray[6'b111110] = 32'b00000000000000000000000000000000;
    UUT.dut.dataArray[6'b111101] = 32'b00000000000000000000000000000000;
    UUT.dut.tagArray[4'b0000] = 26'b00000000000000000000000000;
    UUT.dut.validArray[4'b0000] = 1'b1;

    // state 0
  end
  always @(posedge clock) begin
    // state 1
    if (cycle == 0) begin
    end

    // state 2
    if (cycle == 1) begin
    end

    // state 3
    if (cycle == 2) begin
    end

    // state 4
    if (cycle == 3) begin
    end

    // state 5
    if (cycle == 4) begin
    end

    // state 6
    if (cycle == 5) begin
    end

    // state 7
    if (cycle == 6) begin
    end

    genclock <= cycle < 7;
    cycle <= cycle + 1;
  end
endmodule
