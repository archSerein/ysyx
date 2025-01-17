// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
// `define FAST_FLASH

module spi_top_apb #(
  parameter flash_addr_start = 32'h30000000,
  parameter flash_addr_end   = 32'h3fffffff,
  parameter spi_ss_num       = 8
) (
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

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else

localparam spi_addr_start = 32'h10001000;
localparam spi_addr_end   = 32'h10001fff;

wire [ 4:0]  paddr;
wire [31:0]  pwdata, prdata;
wire [ 3:0]  pstrb;
wire         pwrite, psel, penable, pready;
spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(paddr),
  .wb_dat_i(pwdata),
  .wb_dat_o(prdata),
  .wb_sel_i(pstrb),
  .wb_we_i (pwrite),
  .wb_stb_i(psel),
  .wb_cyc_i(penable),
  .wb_ack_o(pready),
  .wb_err_o(in_pslverr),
  .wb_int_o(spi_irq_out),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

localparam IDLE   = 3'h0;
localparam CMD    = 3'h1;
localparam DIV    = 3'h2;
localparam SS_EN  = 3'h3;
localparam CTRL   = 3'h4;
localparam SS_DIS = 3'h5;
localparam DONE   = 3'h6;
localparam RX     = 3'h7;
localparam GO_BSY = 32'h100;
localparam MODE   = 32'h40;
reg [2:0] xip_state;
reg       in_xip;
reg [31:0] pwdata_reg;

// xip finite state machine
always @(posedge clock) begin
  if (reset) begin
    in_xip <= 1'b0;
  end else begin
    if (!in_xip && in_paddr >= flash_addr_start && in_paddr <= flash_addr_end) begin
      in_xip <= 1'b1;
    end else if (xip_state == IDLE) begin
      in_xip <= 1'b0;
    end
  end
end

`define FLASH_READ 32'h3
`define FLASH_CMD_MASK(addr) ((`FLASH_READ << 24) | (addr & 32'h00ffffff))
`define INVERT_ENDIAN(data) ({data[7:0], data[15:8], data[23:16], data[31:24]})
// XIP FSM for handling flash read operations
always @(posedge clock) begin
  if (reset) begin
    xip_state <= IDLE;
  end else if (in_xip) begin
    case (xip_state)
      IDLE: begin
        // Transition to CMD state to start flash read
        if (in_xip) begin
          xip_state <= CMD;
          // Write the command to SPI TX register (SPI_TX1)
          // e.g., SPI command to read data from flash
          pwdata_reg <= `FLASH_CMD_MASK(in_paddr);  // Update the command based on the address
        end
      end
      CMD: begin
        if (pready && !in_pslverr) begin
          // Set the SPI divider to an appropriate value
          pwdata_reg <= 32'h1;  // Set division factor
          xip_state <= DIV;
        end
      end
      DIV: begin
        if (pready && !in_pslverr) begin
          // Enable SPI slave select (SS)
          // Update the slave select line as needed
          pwdata_reg <= 32'h1;  // select SS0
          xip_state <= SS_EN;
        end
      end
      SS_EN: begin
        if (pready && !in_pslverr) begin
          // Set SPI control register (GO_BSY flag to start the transfer)
          pwdata_reg <= GO_BSY | MODE;
          xip_state <= CTRL;
        end
      end
      CTRL: begin
        if (pready && !in_pslverr)
          xip_state <= DONE;
      end
      DONE: begin
        // Read the data from SPI_RX0
        if (!in_pslverr && (prdata & GO_BSY) == 0)
          xip_state <= RX;
      end
      RX: begin
        if (pready && !in_pslverr) begin
          // Poll for completion, then read the data from SPI_RX0
          pwdata_reg <= 32'h0;  // disable slave device
          xip_state <= SS_DIS;
        end
      end
      SS_DIS: begin
        if (pready && !in_pslverr)
          xip_state <= IDLE;
      end
      default: begin
        $write("ERROR: Unsupported state %d\n", xip_state);
        $stop;
      end
    endcase
  end
end

assign paddr    = !in_xip ? in_paddr[4:0] :
                  {5{xip_state == CMD}} & 5'h4 |
                  {5{xip_state == DIV}} & 5'h14 |
                  {5{xip_state == SS_EN}} & 5'h18 |
                  {5{xip_state == CTRL}} & 5'h10 |
                  {5{xip_state == SS_DIS}} & 5'h18 |
                  {5{xip_state == DONE}} & 5'h10 |
                  {5{xip_state == RX}} & 5'h0;
assign pstrb    = !in_xip ? in_pstrb : 4'b1111;
assign pwrite   = !in_xip ? in_pwrite :
                  (xip_state != RX && xip_state != DONE);
assign psel     = !in_xip ? in_psel : 1'b1;
assign penable  = !in_xip ? in_penable : 1'b1;
assign pwdata   = !in_xip ? in_pwdata : pwdata_reg;
assign in_pready= !in_xip ? pready :
                  (xip_state == IDLE || xip_state == SS_DIS);
assign in_prdata= !in_xip ? prdata :
                  {32{xip_state == SS_DIS}} & `INVERT_ENDIAN(prdata);
`endif // FAST_FLASH

endmodule
