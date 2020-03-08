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

module pulse_cdc (
   input  clk_src,
   input  rst_src,
   input  pulse_src,

   input  clk_dst,
   input  rst_dst,
   output reg pulse_dst
);

reg toggle_src;

always @(posedge clk_src or posedge rst_src) begin
   if (rst_src) begin
      toggle_src <= 1'b0;
   end else begin
      if (pulse_src) begin
         toggle_src <= ~toggle_src;
      end
   end
end

// ASYNC_REG is not a timing constraint, it is a placement constraint for following FFs to be placed close together
// so that metastability of meta_toggle does not propagate downstream
(* ASYNC_REG = "TRUE" *) reg meta_toggle;
(* ASYNC_REG = "TRUE" *) reg [1:0] toggle_dst;


always @(posedge clk_dst or posedge rst_dst) begin
   if (rst_dst) begin
      meta_toggle <= 1'b0;
      toggle_dst <= 'b0;
   end else begin
      meta_toggle <= toggle_src;
      toggle_dst <= {toggle_dst[0], meta_toggle};
      pulse_dst <= toggle_dst[1]^toggle_dst[0];
   end
end


endmodule
