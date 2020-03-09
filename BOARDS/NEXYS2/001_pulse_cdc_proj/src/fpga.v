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

wire pulse_clk40;
reg pulse_snd_clk50;
wire pulse_rcv_clk50;

pulse_cdc i_pulse_cdc_clk50_to_clk40 (
   .clk_src    (clk50),
   .rst_src    (rst_clk40),
   .pulse_src  (pulse_snd_clk50),

   .clk_dst    (clk40),
   .rst_dst    (rst_clk40),
   .pulse_dst  (pulse_clk40)
);

pulse_cdc i_pulse_cdc_clk40_to_clk50 (
   .clk_src    (clk40),
   .rst_src    (rst_clk40),
   .pulse_src  (pulse_clk40),

   .clk_dst    (clk50),
   .rst_dst    (rst_clk50),
   .pulse_dst  (pulse_rcv_clk50)
);

reg [2:0] counter_snd_pulse;

always @(posedge clk50) begin
   if (rst_clk50) begin
      pulse_snd_clk50 <= 1'b0;
      counter_snd_pulse <= 'b0;
   end else begin
      counter_snd_pulse <= counter_snd_pulse + 1;
      pulse_snd_clk50 <= &counter_snd_pulse;
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

reg [63:0] count_snd;
reg [63:0] count_rcv;

always @(posedge clk50) begin
   if (rst_clk50) begin
      count_snd <= 'b0;
      count_rcv <= 'b0;
   end else begin
      if (pulse_snd_clk50) begin
         count_snd <= count_snd + 1;
      end
      if (pulse_rcv_clk50) begin
         count_rcv <= count_rcv + 1;
      end
   end
end


assign trig0[0] = pulse_snd_clk50;
assign trig0[1] = pulse_rcv_clk50;
assign trig0[65:2]   = count_snd;
assign trig0[129:66] = count_rcv;
assign trig0[255:130] = 'b0;

endmodule
