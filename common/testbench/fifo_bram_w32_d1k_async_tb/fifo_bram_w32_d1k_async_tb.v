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
`timescale 1ns/1ps

module fifo_bram_w32_d1k_async_tb();

localparam CLK_SRC_T = 20;
localparam CLK_DST_T = 25;

reg clk_src;
reg rst_src;

always begin
   clk_src = 1'b0;
   #(CLK_SRC_T/2);
   clk_src = 1'b1;
   #(CLK_SRC_T/2);
end

initial begin
   rst_src = 1'b1;
   repeat (10) @(posedge clk_src);
   rst_src = 1'b0;
end

reg clk_dst;
reg rst_dst;

always begin
   clk_dst = 1'b0;
   #(CLK_DST_T/2);
   clk_dst = 1'b1;
   #(CLK_DST_T/2);
end

initial begin
   rst_dst = 1'b1;
   repeat (10) @(posedge clk_dst);
   rst_dst = 1'b0;
end

reg         wr_en;
reg  [31:0] din;
wire        wr_full;
wire [10:0] wr_data_count;

wire        rd_empty;
wire        rd_en = ~rd_empty;
reg         rd_en_d;
wire [31:0] dout;
reg  [31:0] dout_d;

always @(posedge clk_src) begin
   if (rst_src) begin
      wr_en <= 'b0;
      din   <= 'b0;
   end else begin
      wr_en <= (wr_data_count[10:4]!=7'h7F) ? $random : 1'b0;
      if (wr_en) begin
         din   <= din + 1;
      end
   end
end

fifo_bram_w32_d1k_async i_fifo (
   .wr_clk        (clk_src),
   .wr_rst        (rst_src),
   .wr_en         (wr_en),
   .din           (din),
   .wr_full       (wr_full),
   .wr_empty      (),
   .wr_data_count (wr_data_count),

   .rd_clk        (clk_dst),
   .rd_rst        (rst_dst),
   .rd_en         (rd_en),
   .dout          (dout),
   .rd_full       (),
   .rd_empty      (rd_empty),
   .rd_data_count ()
);

always @(posedge clk_dst) begin
   if (rst_dst) begin
      rd_en_d <= 'b0;
      dout_d <= -1;
   end else begin
      rd_en_d <= rd_en;
      if (rd_en_d) begin
         dout_d <= dout;
         if (dout!=(dout_d+1)) begin
            $stop;
         end
      end
   end
end

endmodule
