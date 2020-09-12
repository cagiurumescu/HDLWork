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
module design_top (
  input        sysclk,  // 100 MHz
  output       uart_rx_out,
  input        uart_tx_in
);

////////////////////////////////////////////////////////////////////////////////
// Clocking+resets
////////////////////////////////////////////////////////////////////////////////
reg [15:0] sysrst_ary = 16'hFFFF;
wire sysrst = sysrst_ary[15];

always @(posedge sysclk) begin
   sysrst_ary <= {sysrst_ary[14:0], 1'b0};
end

wire clk200m;
wire rst_clk200m;

wire clkfbio;
wire mmcm_locked;

// 100.0 <= fclkin <= 800.0 MHz
// 0.01  <= fpsclk <= 450.0 MHz
// 600.0 <= fvco   <= 1200.0 MHz
// 4.69  <= fclkout<= 800.0 MHz
// Fvco = Fclkin * M / D;
// Fout = Fclkin * M / D / O;
// M = CLKFBOUT_MULT_F
// D = DIVCLK_DIVIDE
// O = CLKOUT_DIVIDE
MMCME2_ADV #(
   .CLKIN1_PERIOD    (10.000), // 100 MHz
   .CLKFBOUT_MULT_F  (8), // 2:0.125:64
   .DIVCLK_DIVIDE    (1), // 1:106
   .CLKOUT1_DIVIDE   (4)  // 1:128 or 2:0.125:128
) i_mmcme2_adv (
   .CLKIN1        (sysclk),
   .CLKIN2        (1'b0),
   .CLKFBIN       (clkfbio),
   .RST           (sysrst),
   .PWRDWN        (1'b0),
   .CLKINSEL      (1'b1), // 0=clkin2, 1=clkin1
   .DCLK          (sysclk),
   .DADDR         (7'h0),
   .DI            (16'h0),
   .DWE           (1'b0),
   .DEN           (1'b0),
   .PSINCDEC      (1'b0),
   .PSEN          (1'b0),
   .PSCLK         (sysclk),
   .CLKOUT0       (),
   .CLKOUT0B      (),
   .CLKOUT1       (clk200m),
   .CLKOUT1B      (),
   .CLKOUT2       (),
   .CLKOUT2B      (),
   .CLKOUT3       (),
   .CLKOUT3B      (),
   .CLKOUT4       (),
   .CLKOUT5       (),
   .CLKOUT6       (),
   .CLKFBOUT      (clkfbio),
   .LOCKED        (mmcm_locked),
   .DO            (),
   .PSDONE        (),
   .CLKINSTOPPED  (),
   .CLKFBSTOPPED  ()
);

syncrst #(
   .RST_EDGE(1)
) i_syncrst_clk200m (
   .rst_in  (~mmcm_locked),
   .clk     (clk200m),
   .srst    (rst_clk200m)
);

// generate interrupts faster in simulation
localparam COUNTER_SEL = 26
                     // synthesis translate_off
                     *0+16
                     // synthesis translate_on
                     ;

reg [26:0] counter = 'b0;
wire counter_msb = counter[COUNTER_SEL];
wire intc_irq;

always @(posedge sysclk) begin
   counter <= counter + 1;
   if (intc_irq) begin
      counter <= 'b0;
   end
end

wire [31:0] gpi1, gpo1;
wire [31:0] gpi2, gpo2;
wire [31:0] gpi3, gpo3;
wire [31:0] gpi4, gpo4;

microblaze_mcs_0 i_microblaze (
   .Clk           (sysclk),      // input
   .Reset         (sysrst),      // input
   .INTC_IRQ      (intc_irq),    // output
   .INTC_Interrupt(counter_msb), // input
   .UART_rxd      (uart_tx_in),  // input
   .UART_txd      (uart_rx_out), // output
   .GPIO1_tri_i   (32'habcdef01),// input [31:0]
   .GPIO1_tri_o   (),            // output [31:0]
   .GPIO2_tri_i   (32'h23456789),// input [31:0]
   .GPIO2_tri_o   (),            // output [31:0]
   .GPIO3_tri_i   (32'h01efcdab),// input [31:0]
   .GPIO3_tri_o   (),            // output [31:0]
   .GPIO4_tri_i   (32'h89674523),// input [31:0]
   .GPIO4_tri_o   ()             // output [31:0]
);

////////////////////////////////////////////////////////////////////////////////
// DEBUG
////////////////////////////////////////////////////////////////////////////////
wire [255:0] iladata = {
   227'h0,
   counter,
   counter_msb,
   intc_irq
};

ila_0 i_ila (
   .clk     (clk200m),
   .probe0  (iladata)
);

endmodule
