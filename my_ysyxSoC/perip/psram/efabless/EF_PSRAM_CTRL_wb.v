/*
	Copyright 2020 Efabless Corp.

	Author: Mohamed Shalan (mshalan@efabless.com)

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at:
	http://www.apache.org/licenses/LICENSE-2.0
	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.
*/

`timescale              1ns/1ps
`default_nettype        none

// Using EBH Command
module EF_PSRAM_CTRL_wb (
    // WB bus Interface
    input   wire        clk_i,
    input   wire        rst_i,
    input   wire [31:0] adr_i,
    input   wire [31:0] dat_i,
    output  wire [31:0] dat_o,
    input   wire [3:0]  sel_i,
    input   wire        cyc_i,
    input   wire        stb_i,
    output  wire        ack_o,
    input   wire        we_i,

    // External Interface to Quad I/O
    output  wire            sck,
    output  wire            ce_n,
    input   wire [3:0]      din,
    output  wire [3:0]      dout,
    output  wire [3:0]      douten
);

    localparam  ST_IDLE = 1'b0,
                ST_WAIT = 1'b1;

    wire        mr_sck;
    wire        mr_ce_n;
    wire [3:0]  mr_din;
    wire [3:0]  mr_dout;
    wire        mr_doe;

    wire        mw_sck;
    wire        mw_ce_n;
    wire [3:0]  mw_din;
    wire [3:0]  mw_dout;
    wire        mw_doe;

    wire        mm_sck;
    wire        mm_ce_n;
    wire [3:0]  mm_dout;
    wire        mm_doe;

    // PSRAM Reader and Writer wires
    wire        mr_rd;
    wire        mr_done;
    wire        mw_wr;
    wire        mw_done;
    wire        mm_sw;
    wire        mm_done;

    //wire        doe;

    // WB Control Signals
    wire        wb_valid        =   cyc_i & stb_i;
    wire        wb_we           =   we_i & wb_valid;
    wire        wb_re           =   ~we_i & wb_valid;
    //wire[3:0]   wb_byte_sel     =   sel_i & {4{wb_we}};

    // The FSM
    reg         state, nstate;
    reg         psram_qpi_mode;
    always @ (posedge clk_i or posedge rst_i)
        if(rst_i) begin
            state <= ST_IDLE;
            psram_qpi_mode <= 1'b0;
        end else begin
            state <= nstate;
            if (nstate == ST_IDLE && !psram_qpi_mode)
                psram_qpi_mode <= 1'b1;                
        end

    always @* begin
        case(state)
            ST_IDLE :
                if(wb_valid || !psram_qpi_mode)
                    nstate = ST_WAIT;
                else
                    nstate = ST_IDLE;

            ST_WAIT :
                if((mw_done & wb_we) | (mr_done & wb_re) |
                    (mm_done & mm_sw))
                    nstate = ST_IDLE;
                else
                    nstate = ST_WAIT;
        endcase
    end

    wire [2:0]  size =  (sel_i == 4'b0001) ? 1 :
                        (sel_i == 4'b0010) ? 1 :
                        (sel_i == 4'b0100) ? 1 :
                        (sel_i == 4'b1000) ? 1 :
                        (sel_i == 4'b0011) ? 2 :
                        (sel_i == 4'b1100) ? 2 :
                        (sel_i == 4'b1111) ? 4 : 4;



    wire [7:0]  byte0 = (sel_i[0])          ? dat_i[7:0]   :
                        (sel_i[1] & size==1)? dat_i[15:8]  :
                        (sel_i[2] & size==1)? dat_i[23:16] :
                        (sel_i[3] & size==1)? dat_i[31:24] :
                        (sel_i[2] & size==2)? dat_i[23:16] :
                        dat_i[7:0];

    wire [7:0]  byte1 = (sel_i[1])          ? dat_i[15:8]  :
                        dat_i[31:24];

    wire [7:0]  byte2 = dat_i[23:16];

    wire [7:0]  byte3 = dat_i[31:24];

    wire [31:0] wdata = {byte3, byte2, byte1, byte0};

    /*
    wire [1:0]  waddr = (size==1 && sel_i[0]==1) ? 2'b00 :
                        (size==1 && sel_i[1]==1) ? 2'b01 :
                        (size==1 && sel_i[2]==1) ? 2'b10 :
                        (size==1 && sel_i[3]==1) ? 2'b11 :
                        (size==2 && sel_i[2]==1) ? 2'b10 :
                        2'b00;
                      */

    assign mr_rd    = ( (state==ST_IDLE ) & wb_re );
    assign mw_wr    = ( (state==ST_IDLE ) & wb_we );
    assign mm_sw    = ( !psram_qpi_mode & !rst_i );

    PSRAM_READER MR (
        .clk(clk_i),
        .rst_n(~rst_i),
        .addr({adr_i[23:2],2'b0}),
        .rd(mr_rd),
        //.size(size), Always read a word
        .size(3'd4),
        .is_qpi_mode(psram_qpi_mode),
        .done(mr_done),
        .line(dat_o),
        .sck(mr_sck),
        .ce_n(mr_ce_n),
        .din(mr_din),
        .dout(mr_dout),
        .douten(mr_doe)
    );

    PSRAM_WRITER MW (
        .clk(clk_i),
        .rst_n(~rst_i),
        .addr({adr_i[23:0]}),
        .wr(mw_wr),
        .size(size),
        .is_qpi_mode(psram_qpi_mode),
        .done(mw_done),
        .line(wdata),
        .sck(mw_sck),
        .ce_n(mw_ce_n),
        .din(mw_din),
        .dout(mw_dout),
        .douten(mw_doe)
    );

    PSRAM_MODE MM (
        .clk(clk_i),
        .rst_n(~rst_i),
        .sw(mm_sw),
        .done(mm_done),
        .sck(mm_sck),
        .ce_n(mm_ce_n),
        .dout(mm_dout),
        .douten(mm_doe)
    );

    assign sck  = mm_sw ? mm_sck :
                  wb_we ? mw_sck :
                  mr_sck;
    assign ce_n = mm_sw ? mm_ce_n :
                  wb_we ? mw_ce_n :
                  mr_ce_n;
    assign dout = mm_sw ? mm_dout :
                  wb_we ? mw_dout :
                  mr_dout;
    assign douten  = mm_sw ? {4{mm_doe}} :
                     wb_re ? {4{mr_doe}} :
                     {4{mw_doe}};

    assign mw_din = din;
    assign mr_din = din;
    assign ack_o = mm_sw ? mm_done :
                   wb_we ? mw_done :
                   mr_done;
endmodule
