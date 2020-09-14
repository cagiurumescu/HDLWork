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

module value_cdc #(
   parameter BITS = 32
) (
   input clk_src,
   input rst_src,
   input [BITS-1:0] value_src,

   input clk_dst,
   input rst_dst,
   output reg [BITS-1:0] value_dst
);

reg [BITS-1:0] value_src_ff;

always @(posedge clk_src) begin
   if (rst_src) begin
      value_src_ff<= 'b0;
   end else begin
      value_src_ff<= value_src;
   end
end

// ASYNC_REG is also a placement constraint for following FFs to be placed 
// close together so that metastability of meta_* does not propagate 
// downstream (UG625)

(* ASYNC_REG = "TRUE" *) reg [BITS-1:0] meta_value_src;
(* ASYNC_REG = "TRUE" *) reg [BITS-1:0] value_pre_dst;
(* ASYNC_REG = "TRUE" *) reg [BITS-1:0] value_dst;

always @(posedge clk_dst) begin
   if (rst_dst) begin
      meta_value_src <= 'b0;
      value_pre_dst  <= 'b0;
      value_dst      <= 'b0;
   end else begin
      meta_value_src <= value_src_ff;
      value_pre_dst  <= meta_value_src;
      value_dst      <= value_pre_dst;
   end
end

endmodule
