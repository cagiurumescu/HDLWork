/*******************************************************************************
MIT License

Copyright (c) 2019-2020 Claudiu Giurumescu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*******************************************************************************/

module spi_master_enc424j600 #(
   parameter SLAVE_SAMPLING = 0, // 0 - m/s samples data on posedge SCLK, changes on negedge SCLK
                                 // 1 - m/s samples data on negedge SCLK, changes on posedge SCLK
   parameter CLK_HZ = 50000000,
   parameter SCK_HZ = 13000000 // max datarate is 12Mbps with back2back reads
) (
   // user interface
   input          clk,
   input          rst,
   input  [15:0]  opbyte, // MSB for RCRU/WCRU/BFCU/BFSU unbanked txn only
   input          opbyte_valid,
   input  [10:0]  nbyte_num,   // cannot be zero when N-byte transaction used, max 2KB-1 (actual data is 2KB-2 because of opcode -- including for unbanked)
   input  [7:0]   wrdat_byte,
   input          wrdat_valid, // should assert until ready asserts. byte taken when valid&ready
   output reg     wrdat_ready,
   output [7:0]   rddat_byte,
   output         rddat_valid,
   output reg     txn_done,

   // SPI interface
   output         SCK,
   output         CS_N,
   output         MOSI,
   input          MISO
);

localparam SCK_HALFCLK_CNT=(CLK_HZ+(2*SCK_HZ)-1)/(2*SCK_HZ)-1; // -1 because we got back one clk cycle to master state
localparam TCSS_CNT = (CLK_HZ+19999999)/20000000;
localparam TCSD_CNT = (CLK_HZ+49999999)/50000000;

localparam NBS = 3;
reg [NBS-1:0] state;
reg [NBS-1:0] next_state;
localparam [NBS-1:0] ST_IDLE = 0;
localparam [NBS-1:0] ST_TCSS_CSH = 1;
localparam [NBS-1:0] ST_TCSD = 2;
localparam [NBS-1:0] ST_THLF = 3;
localparam [NBS-1:0] ST_ONEBYTE = 4;
localparam [NBS-1:0] ST_TWOBYTE = 5;
localparam [NBS-1:0] ST_NBYTE = 6;

reg         sck_ff;
reg         csn_ff;
reg         mosi_ff;
assign SCK = sck_ff;
assign CS_N = csn_ff;
assign MOSI = mosi_ff;

reg  [7:0]  rddat_byte_ff;
reg         rddat_valid_ff;
assign      rddat_byte = rddat_byte_ff;
assign      rddat_valid = rddat_valid_ff;

reg  [6:0]  opbyte_shift;
reg  [7:0]  clk_cnt;
reg  [11+3-1:0]  bit_cnt; // to accomodate nbyte_num for n-byte transactions

reg         nbyte_isread;
reg  [7:0]  wrdat_byte_latched;
reg  [10:0] nbyte_num_latched;
reg         unbanked_txn; // RCRU/WCRU/BFCU/BFSU

always @(posedge clk or posedge rst) begin
   if (rst) begin
      sck_ff         <= 'b0;
      csn_ff         <= 'b1;
      mosi_ff        <= 'b0;
      state          <= ST_IDLE;
      next_state     <= ST_IDLE;
      rddat_byte_ff  <= 'b0;
      rddat_valid_ff <= 'b0;
      opbyte_shift   <= 'b0;
      clk_cnt        <= 'b0;
      bit_cnt        <= 'b0;
      txn_done       <= 'b0;
      nbyte_isread   <= 'b0;
      wrdat_ready    <= 'b0;
      wrdat_byte_latched <= 'b0;
      nbyte_num_latched <= 'b0;
      unbanked_txn   <= 'b0;
   end else begin
      txn_done <= 'b0;
      rddat_valid_ff <= 'b0;
      if (wrdat_valid&wrdat_ready) begin
         wrdat_ready    <= 'b0;
         wrdat_byte_latched <= wrdat_byte;
      end
      case(state)
         ST_IDLE: begin
            csn_ff <= 'b1;
            sck_ff <= 'b0;
            clk_cnt<= 'b1;
            bit_cnt<= 'b0;
            unbanked_txn <= 'b0;
            if (opbyte_valid==1'b1) begin
               opbyte_shift <= opbyte[6:0];
               mosi_ff <= opbyte[7];
               state <= ST_TCSS_CSH;
               csn_ff <= 'b0;
               if (opbyte[7:6]==2'b11) begin
                  if (opbyte[5:0]==6'b001000) begin
                     // two-byte command (RBSEL)
                     next_state <= ST_TWOBYTE;
                  end else begin
                     // one-byte command
                     next_state <= ST_ONEBYTE;
                  end
               end else begin
                  if (opbyte[7:5]==3'b011) begin
                     // three-byte command
                     nbyte_isread <= opbyte[1];
                     next_state <= ST_NBYTE;
                     wrdat_ready <= ~opbyte[1];
                     nbyte_num_latched <= 'h3;
                  end
                  if (opbyte[7:5]==3'b001) begin
                     if (opbyte[4:3]==2'b00) begin
                        // n-byte command unbanked to a ONEBYTE+NBYTE
                        next_state <= ST_ONEBYTE;
                        unbanked_txn <= 'b1;
                        nbyte_isread <= ~(opbyte[2]|opbyte[1]);
                        wrdat_ready <= (opbyte[2]|opbyte[1]);
                        nbyte_num_latched <= nbyte_num;
                     end else begin
                        // n-byte command banked
                        next_state <= ST_NBYTE;
                        nbyte_isread <= ~opbyte[1]; // yes, it's inverted compared to 3-byte
                        wrdat_ready <= opbyte[1];
                        nbyte_num_latched <= nbyte_num;
                     end
                  end
                  if ((opbyte[7:6]==2'b10)||(opbyte[7:5]==3'b010)) begin
                     // n-byte command
                     next_state <= ST_NBYTE;
                     nbyte_isread <= 1'b0; // BFS, BFC, WCR always writes
                     wrdat_ready <= 1'b1;
                     nbyte_num_latched <= nbyte_num;
                  end
                  if (opbyte[7:5]==3'b000) begin
                     // n-byte command
                     next_state <= ST_NBYTE;
                     nbyte_isread <= 1'b1; // RCR always read
                     nbyte_num_latched <= nbyte_num;
                  end
               end
            end
         end
         ST_TCSS_CSH: begin
            clk_cnt<= clk_cnt+1;
            if (TCSS_CNT==clk_cnt) begin
               clk_cnt<= 'b1;
               state <= next_state;
            end
         end
         ST_TCSD: begin
            csn_ff <= 'b1;
            clk_cnt<= clk_cnt+1;
            if (TCSD_CNT==clk_cnt) begin
               txn_done <= 'b1;
               state <= ST_IDLE;
            end
         end
         ST_ONEBYTE: begin
            sck_ff <= ~sck_ff;
            if (bit_cnt[3]) begin
               state <= ST_TCSS_CSH;
               next_state <= ST_TCSD;
               if (unbanked_txn) begin
                  opbyte_shift <= opbyte[14:8];
                  mosi_ff <= opbyte[15];
                  state <= ST_THLF;
                  next_state <= ST_NBYTE;
                  bit_cnt <= 'b0; // reset here so that all NBYTE txn are numbytes-1 data
                  // unbanked_txn will clear when we go back to IDLE
               end
            end else begin
               state <= ST_THLF;
               next_state <= ST_ONEBYTE;
            end
         end
         ST_TWOBYTE: begin
            sck_ff <= ~sck_ff;
            if (bit_cnt[4]) begin
               state <= ST_TCSS_CSH;
               next_state <= ST_TCSD;
               rddat_valid_ff <= 'b1;
            end else begin
               state <= ST_THLF;
               next_state <= ST_TWOBYTE;
               if ((~sck_ff)&bit_cnt[3]) begin
                  rddat_byte_ff <= {rddat_byte_ff[6:0], MISO};
               end
            end
         end
         ST_NBYTE: begin
            sck_ff <= ~sck_ff;
            if (bit_cnt[13:3]==nbyte_num_latched) begin
               state <= ST_TCSS_CSH;
               next_state <= ST_TCSD;
               if (nbyte_isread) begin
                  rddat_valid_ff <= 'b1;
               end
            end else begin
               state <= ST_THLF;
               next_state <= ST_NBYTE;
               if (bit_cnt[13:3]!=11'h000) begin
                  if ((~sck_ff)&nbyte_isread) begin
                     rddat_byte_ff <= {rddat_byte_ff[6:0], MISO};
                  end
                  if (sck_ff&(~nbyte_isread)) begin
                     if (bit_cnt[2:0]==3'b000) begin
                        // reuse opbyte_shift for holding writebyte
                        // load next byte
                        mosi_ff <= wrdat_byte_latched[7];
                        opbyte_shift <= wrdat_byte_latched[6:0];
                        wrdat_ready <= 1'b1;
                     end
                  end
               end
               // 1st byte is opcode, 2nd, 3rd bytes are data
               if (sck_ff&nbyte_isread&(bit_cnt[2:0]==3'b000)&(bit_cnt[13:4]!=10'h000)) begin
                  rddat_valid_ff <= 'b1;
               end
            end
         end
         ST_THLF: begin
            clk_cnt <= clk_cnt+1;
            if (clk_cnt==SCK_HALFCLK_CNT) begin
               clk_cnt <= 'b1;
               state <= next_state;
               if (sck_ff) begin
                  bit_cnt <= bit_cnt + 1;
                  opbyte_shift <= {opbyte_shift[5:0], 1'b0};
                  mosi_ff <= opbyte_shift[6];
               end
            end
         end
      endcase
   end
end


endmodule
