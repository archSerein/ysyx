module vga_top_apb(
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

  output [7:0]  vga_r,
  output [7:0]  vga_g,
  output [7:0]  vga_b,
  output        vga_hsync,
  output        vga_vsync,
  output        vga_valid
);

  parameter    VGA_LENGTH = 640;
  parameter    VGA_HEIGHT = 480;
  reg [23:0]  vga_frame[0:VGA_LENGTH*VGA_HEIGHT-1];
  always @(posedge clock) begin
    if (in_psel && in_penable && in_pwrite) begin
      vga_frame[in_paddr[18:0]] <= in_pwdata[23:0];
    end
  end

  parameter    h_frontporch = 96;
  parameter    h_active = 144;
  parameter    h_backporch = 784;
  parameter    h_total = 800;

  parameter    v_frontporch = 2;
  parameter    v_active = 35;
  parameter    v_backporch = 515;
  parameter    v_total = 525;

  //像素计数值
  reg [9:0]    x_cnt;
  reg [9:0]    y_cnt;
  wire         h_valid;
  wire         v_valid;
  wire [ 9:0]  h_addr, v_addr;
  wire [23:0]  vga_data;

  //行像素计数
  always @(posedge clock) begin
      if (reset)
        x_cnt <= 1;
      else begin
        if (x_cnt == h_total)
            x_cnt <= 1;
        else
            x_cnt <= x_cnt + 10'd1;
      end
  end

  //列像素计数
  always @(posedge clock) begin
      if (reset)
        y_cnt <= 1;
      else begin
        if (y_cnt == v_total & x_cnt == h_total)
            y_cnt <= 1;
        else if (x_cnt == h_total)
            y_cnt <= y_cnt + 10'd1;
      end
  end
  //生成同步信号
  assign vga_hsync = (x_cnt > h_frontporch);
  assign vga_vsync = (y_cnt > v_frontporch);
  //生成消隐信号
  assign h_valid = (x_cnt > h_active) & (x_cnt <= h_backporch);
  assign v_valid = (y_cnt > v_active) & (y_cnt <= v_backporch);
  assign vga_valid = h_valid & v_valid;
  //计算当前有效像素坐标
  assign h_addr = h_valid ? (x_cnt - 10'd145) : {10{1'b0}};
  assign v_addr = v_valid ? (y_cnt - 10'd36) : {10{1'b0}};
  //设置输出的颜色值
  assign vga_data = vga_frame[h_addr + v_addr * VGA_LENGTH];
  assign vga_r = vga_data[23:16];
  assign vga_g = vga_data[15:8];
  assign vga_b = vga_data[7:0];

  // apb interface
  assign in_pready = 1'b1;
  assign in_pslverr = 1'b0;
  assign in_prdata = 32'b0;
endmodule
