module psram(
  input sck,
  input ce_n,
  inout [3:0] dio
);

  reg        PSRAM_QPI_MODE;
  localparam CMD    = 2'b00;
  localparam ADDR   = 2'b01;
  localparam READ   = 2'b10;
  localparam WRITE  = 2'b11;
  import "DPI-C" function void psram_read(input int raddr, output int rdata);
  import "DPI-C" function void psram_write(input int waddr, input byte wdata);
  wire   ce;
  wire   [31:0] rdata;
  wire   [ 7:0] wdata;
  reg           wait_read;
  reg    [ 7:0] cmd;
  reg    [23:0] addr;
  reg    [31:0] data;
  reg    [ 2:0] counter;
  reg    [ 1:0] state;
  always @(posedge sck or posedge ce_n) begin
    if (!ce) begin
      if (cmd == 8'h35) begin
        PSRAM_QPI_MODE <= 1'b1;
      end
      state <= CMD;
      counter <= 3'h0;
      data <= 32'h0;
      wait_read <= 1'b1;
    end else begin
      case (state)
        CMD: begin
          if (PSRAM_QPI_MODE) begin
            cmd <= {cmd[3:0], dio[3:0]};
          end else begin
            cmd <= {cmd[6:0], dio[0]};
          end
          if ((counter == 3'h7 && !PSRAM_QPI_MODE) ||
              (counter == 3'h1 && PSRAM_QPI_MODE)) begin
            counter <= 3'h0;
            state <= ADDR;
          end else begin
            counter <= counter + 1;
          end
        end
        ADDR: begin
          addr <= {addr[19:0], dio};
          if (counter == 3'h5) begin
            counter <= 3'h0;
            state <= (cmd == 8'h38 ? WRITE : READ);
          end else begin
            counter <= counter + 1;
          end
        end
        READ: begin
          if (wait_read) begin
            if (counter == 3'h6) begin
              data <= rdata;
              wait_read <= 1'b0;
              counter <= 3'h0;
            end else begin
              counter <= counter + 1;
            end
          end else begin
            if (counter == 3'h1) begin
              data <= {8'h0, data[31:8]};
              counter <= 3'h0;
            end else begin
              counter <= counter + 1;
            end
          end
        end
        WRITE: begin
          if (counter == 3'h2) begin
            data <= {data[27:0], dio};
            addr <= addr + 1;
            counter <= 3'h1;
          end else begin
            data <= {data[27:0], dio};
            counter <= counter + 1;
          end
        end
      endcase
    end
  end
  always @(counter) begin
    if (state == WRITE && counter == 3'h2) begin
      psram_write({8'h0, addr}, wdata);
    end
  end

  always @(counter) begin
    if (state == READ && counter == 3'h5) begin
      psram_read({8'h0, addr}, rdata);
    end
  end
       
  assign ce = ~ce_n;
  assign wdata = data[7:0];
  assign dio =  (state == READ) ? 
                (counter == 3'h0 ? data[7:4] : data[3:0]) :
                4'bz;
endmodule
