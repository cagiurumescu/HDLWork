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

module fpga (
   input clk,  // 50 MHz
   input clk1  // ~40 MHz
);

wire clk50 = clk;
wire clk40 = clk1;

reg [3:0] rst_count_clk50 = 4'h0;
reg rst_clk50;

always @(posedge clk50) begin
   if (rst_count_clk50!=4'hF) begin
      rst_count_clk50 <= rst_count_clk50 + 1;
      rst_clk50 <= 1'b1;
   end else begin
      rst_clk50 <= 1'b0;
   end
end

reg [3:0] rst_count_clk40 = 4'h0;
reg rst_clk40;

always @(posedge clk40) begin
   if (rst_count_clk40!=4'hF) begin
      rst_count_clk40 <= rst_count_clk40 + 1;
      rst_clk40 <= 1'b1;
   end else begin
      rst_clk40 <= 1'b0;
   end
end

wire [35:0] control0;
chipscope_icon_ctlr0 i_chipscope_icon(
   .CONTROL0   (control0)
);

wire [255:0] trig0;
chipscope_ila_trig0 i_chipscope_ila(
   .CLK     (clk50),
   .CONTROL (control0),
   .TRIG0   (trig0)
);

reg         wr_en;
reg         wr_enable;
reg  [31:0] din;
wire        wr_full;
wire [10:0] wr_data_count;

wire        rd_empty;
wire        rd_en = ~rd_empty;
reg         rd_en_d;
wire [31:0] dout;
reg  [31:0] dout_d;

always @(posedge clk40) begin
   if (rst_clk40) begin
      wr_en <= 'b0;
      din   <= 'b0;
      wr_enable <= 'b0;
   end else begin
      wr_enable <= ~wr_enable;
      wr_en <= (wr_data_count[10:4]!=7'h7F) ? wr_enable : 1'b0;
      if (wr_en) begin
         din   <= din + 1;
      end
   end
end

fifo_bram_w32_d1k_async i_fifo (
   .wr_clk        (clk40),
   .wr_rst        (rst_clk40),
   .wr_en         (wr_en),
   .din           (din),
   .wr_full       (wr_full),
   .wr_empty      (),
   .wr_data_count (wr_data_count),

   .rd_clk        (clk50),
   .rd_rst        (rst_clk50),
   .rd_en         (rd_en),
   .dout          (dout),
   .rd_full       (),
   .rd_empty      (rd_empty),
   .rd_data_count ()
);

reg fifo_error;

always @(posedge clk50) begin
   if (rst_clk50) begin
      rd_en_d <= 'b0;
      dout_d <= -1;
      fifo_error <= 'b0;
   end else begin
      rd_en_d <= rd_en;
      if (rd_en_d) begin
         dout_d <= dout;
         if (dout!=(dout_d+1)) begin
            fifo_error <= 'b1;
         end
         if (dout==(dout_d+1)) begin
            fifo_error <= 'b0;
         end
      end
   end
end

assign trig0[0]      = fifo_error;
assign trig0[32:1]   = dout_d;
assign trig0[64:33]  = dout;
assign trig0[65]     = rd_empty;
assign trig0[66]     = rd_en_d;
assign trig0[255:67] = 'b0;

endmodule
