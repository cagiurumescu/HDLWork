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

// write on 40 MHz clk domain, incrementing address pattern then decrementing
reg [9:0]   addra;
reg [31:0]  dina;
reg         wea;
reg         decr_incr_n;

always @(posedge clk40) begin
   if (rst_clk40) begin
      wea   <= 1'b0;
      dina  <= 'b0;
      addra <= 'b0;
      decr_incr_n <= 'b0;
   end else begin
      wea <= ~wea;
      dina[31:10] <= 22'h0; 
      if (~wea) begin
         addra <= addra + 1;

         if (decr_incr_n) begin
            dina[9:0] <= 10'h3FE - addra;
         end else begin
            dina[9:0] <= addra + 1;
         end
         if (addra==10'h3FF) begin
            decr_incr_n <= ~decr_incr_n;
            if (decr_incr_n) begin
               dina[9:0] <= 'b0;
            end else begin
               dina[9:0] <= 10'h3FF;
            end
         end
      end
   end
end

reg [9:0]   addrb;
reg         enb;
wire [31:0] doutb;
reg  [31:0] doutb_ff;

always @(posedge clk50) begin
   if (rst_clk50) begin
      enb   <= 'b0;
      addrb <= 'b0;
      doutb_ff <= 'b0;
   end else begin
      enb <= ~enb;
      if (~enb) begin
         addrb <= addrb + 1;
      end
      doutb_ff <= doutb;
   end
end

bram_sdp_w32_d1k_noreg i_bram_sdp_w32_d1k_noreg(
   .clka    (clk40),
   .addra   (addra),
   .wea     (wea),
   .dina    (dina),

   .clkb    (clk50),
   .addrb   (addrb),
   .enb     (enb),
   .doutb   (doutb)
);
assign trig0[0]      = enb;
assign trig0[10:1]   = addrb;
assign trig0[20:11]  = doutb_ff;
assign trig0[255:21] = 'b0;

endmodule
