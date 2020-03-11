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

module fpga_tb ();

reg clk;
reg clk1;

localparam CLK_T = 20;
localparam CLK1_T = 25;

always begin
   clk = 1'b0;
   #(CLK_T/2);
   clk = 1'b1;
   #(CLK_T/2);
end

always begin
   clk1 = 1'b0;
   #(CLK1_T/2);
   clk1 = 1'b1;
   #(CLK1_T/2);
end

fpga i_fpga (
   .clk  (clk),
   .clk1 (clk1)
);

endmodule
