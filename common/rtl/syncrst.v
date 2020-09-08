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

module syncrst #(
   parameter RST_EDGE = 1 // 1=active high, 0=active low
) (

   input    rst_in,
   input    clk,
   output   srst
);

reg         srst_meta = (RST_EDGE!=0) ? 1'b1 : 1'b0;
reg [1:0]   srst_ff = (RST_EDGE!=0) ? 2'b11 : 1'b00;

always @(posedge clk) begin
   srst_meta <= rst_in;
   srst_ff <= {srst_ff[0], srst_meta};
end

assign srst = srst_ff[1];

endmodule
/******************************************************************************/
// Timing constraints (e.g., for a 200 MHz target clk)
//  set_max_delay 5.0 \
//    -from [get_pins -of [get_cells -hier -filter name=~*i_syncrst_clk200*/srst_ff_reg[0]*] -filter {REF_PIN_NAME==CLK}] \
//    -to   [get_pins -of [get_cells -hier -filter name=~*i_syncrst_clk200*/srst_ff_reg[1]] -filter {REF_PIN_NAME==D}] \
//    -datapath_only
