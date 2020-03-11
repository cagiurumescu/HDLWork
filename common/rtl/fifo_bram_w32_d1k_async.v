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

module fifo_bram_w32_d1k_async #(
   parameter AWIDTH = 10,
   parameter DWIDTH = 32
) (
   input          wr_clk,
   input          wr_rst,
   input          wr_en,
   input  [DWIDTH-1:0] din,
   output         wr_full,
   output         wr_empty,
   output [AWIDTH:0] wr_data_count,

   input          rd_clk,
   input          rd_rst,
   input          rd_en,
   output [DWIDTH-1:0] dout,
   output         rd_full,
   output         rd_empty,
   output [AWIDTH:0] rd_data_count
);

reg  [AWIDTH:0]   wr_ptr_wrclk;
wire [AWIDTH:0]   rd_ptr_wrclk;

reg  [AWIDTH:0]   rd_ptr_rdclk;
wire [AWIDTH:0]   wr_ptr_rdclk;

always @(posedge wr_clk) begin
   if (wr_rst) begin
      wr_ptr_wrclk   <= 'b0;
   end else begin
      if (wr_en & ~wr_full) begin
         wr_ptr_wrclk <= wr_ptr_wrclk + 1;
      end
   end
end

assign wr_empty = (wr_ptr_wrclk==rd_ptr_wrclk) ? 1'b1 : 1'b0;
assign wr_full = ((wr_ptr_wrclk^rd_ptr_wrclk)=={1'b1, {(AWIDTH-1){1'b0}}}) ? 1'b1 : 1'b0;
assign wr_data_count = wr_ptr_wrclk-rd_ptr_wrclk;

counter_cdc #(
   .BITS(AWIDTH+1)
) i_counter_cdc_wrptr (
   .clk_src    (wr_clk),
   .rst_src    (wr_rst),
   .counter_src(wr_ptr_wrclk),

   .clk_dst    (rd_clk),
   .rst_dst    (rd_rst),
   .counter_dst(wr_ptr_rdclk)
);

always @(posedge rd_clk) begin
   if (rd_rst) begin
      rd_ptr_rdclk   <= 'b0;
   end else begin
      if (rd_en & ~rd_empty) begin
         rd_ptr_rdclk <= rd_ptr_rdclk + 1;
      end
   end
end

counter_cdc #(
   .BITS(AWIDTH+1)
) i_counter_cdc_rdptr (
   .clk_src    (rd_clk),
   .rst_src    (rd_rst),
   .counter_src(rd_ptr_rdclk),

   .clk_dst    (wr_clk),
   .rst_dst    (wr_rst),
   .counter_dst(rd_ptr_wrclk)
);

assign rd_empty = (wr_ptr_rdclk==rd_ptr_rdclk) ? 1'b1 : 1'b0; 
assign rd_full = ((wr_ptr_rdclk^rd_ptr_rdclk)=={1'b1, {(AWIDTH-1){1'b0}}}) ? 1'b1 : 1'b0;
assign rd_data_count = wr_ptr_rdclk-rd_ptr_rdclk;

bram_sdp_w32_d1k_noreg i_bram_sdp_w32_d1k_noreg (
   .clka    (wr_clk),
   .wea     (wr_en & ~wr_full),
   .addra   (wr_ptr_wrclk[9:0]),
   .dina    (din),

   .clkb    (rd_clk),
   .enb     (~rd_empty), // always read
   .addrb   (rd_ptr_rdclk[9:0]),
   .doutb   (dout)
);

endmodule
