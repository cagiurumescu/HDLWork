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

module pulse_cdc_tb();

localparam CLK_SRC_T = 10;
localparam CLK_DST_T = 20;

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

reg   pulse_src;
wire  pulse_dst;

pulse_cdc i_pulse_cdc (
   .clk_src    (clk_src),     // input  clk_src,
   .rst_src    (rst_src),     // input  rst_src,
   .pulse_src  (pulse_src),   // input  pulse_src,

   .clk_dst    (clk_dst),     // input  clk_dst,
   .rst_dst    (rst_dst),     // input  rst_dst,
   .pulse_dst  (pulse_dst)    // output reg pulse_dst
);

initial begin
   pulse_src = 1'b0;
   @(posedge clk_dst);
   wait (rst_dst == 1'b0);

   repeat (10) @(posedge clk_src);
   while (1) begin
      pulse_src = 1'b1;
      @(posedge clk_src);
      pulse_src = 1'b0;
      repeat (10) @(posedge clk_src);
   end
end


endmodule
