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
  input           sysclk,  // 100 MHz

  // UART interface
  output          uart_rx_out,
  input           uart_tx_in,

  // DRAM interface
  inout  [15:0]   ddr3_dq,
  inout  [1:0]    ddr3_dqs_n,
  inout  [1:0]    ddr3_dqs_p,
  output [14:0]   ddr3_addr,
  output [2:0]    ddr3_ba,
  output          ddr3_ras_n,
  output          ddr3_cas_n,
  output          ddr3_we_n,
  output          ddr3_reset_n,
  output [0:0]    ddr3_ck_p,
  output [0:0]    ddr3_ck_n,
  output [0:0]    ddr3_cke,
  output [1:0]    ddr3_dm,
  output [0:0]    ddr3_odt
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

// for MIG
wire           clk200m_bufg;
BUFG i_clk200m_bufg (
   .I(clk200m),
   .O(clk200m_bufg)
);

syncrst #(
   .RST_EDGE(1)
) i_syncrst_clk200m (
   .rst_in  (~mmcm_locked),
   .clk     (clk200m),
   .srst    (rst_clk200m)
);

////////////////////////////////////////////////////////////////////////////////
// Microblaze
////////////////////////////////////////////////////////////////////////////////

wire intc_irq; // sw serviced the interrupt
wire hw_int;   // hw interrupt request

wire [31:0] gpi1, gpo1;
wire [31:0] gpi2; //, gpo2;
wire [31:0] gpi3, gpo3;
wire [31:0] gpi4, gpo4;

microblaze_mcs_1 i_microblaze (
   .Clk           (sysclk),      // input
   .Reset         (sysrst),      // input
   .INTC_IRQ      (intc_irq),    // output
   .INTC_Interrupt(hw_int),      // input
   .UART_rxd      (uart_tx_in),  // input
   .UART_txd      (uart_rx_out), // output
   .GPIO1_tri_i   (gpi1),        // input [31:0]
   .GPIO1_tri_o   (gpo1),        // output [31:0]
   .GPIO2_tri_i   (gpi2),        // input [31:0]
   .GPIO2_tri_o   (),            // output [31:0]
   .GPIO3_tri_i   (gpi3),        // input [31:0]
   .GPIO3_tri_o   (gpo3),        // output [31:0]
   .GPIO4_tri_i   (gpi4),        // input [31:0]
   .GPIO4_tri_o   (gpo4)         // output [31:0]
);

////////////////////////////////////////////////////////////////////////////////
// MIG
////////////////////////////////////////////////////////////////////////////////
reg  [28:0]    app_addr = 'b0; // this is a 2-byte word address
reg  [2:0]     app_cmd = 'b0;
reg            app_en = 'b0;
reg  [127:0]   app_wdf_data = 'b0;
reg            app_wdf_end = 'b1;
reg            app_wdf_wren = 'b0;
wire [127:0]   app_rd_data;
wire           app_rd_data_end;
wire           app_rd_data_valid;
wire           app_rdy;
wire           app_wdf_rdy;
wire           ui_clk;
wire           ui_clk_sync_rst;
wire           init_calib_complete;

`ifdef DDR3_NO_MIG_SIM
   // fixme something saner here for simulation
   wire app_rd_data_valid_pre = ((app_en==1'b1)&&(app_rdy==1'b1)&&(app_wdf_wren==1'b0)) ? 1'b1 : 1'b0;
   reg  app_rd_data_valid_ff;

   assign app_rdy = 1'b1;
   assign app_wdf_rdy = 1'b1;
   assign app_rd_data_end = 1'b1;
   assign app_rd_data_valid = app_rd_data_valid_ff;
   assign app_rd_data = 128'haabbccdd_eeff0011_22334455_66778899;

   always @(posedge ui_clk or ui_clk_sync_rst) begin
      app_rd_data_valid_ff <= app_rd_data_valid_pre;
      if (ui_clk_sync_rst) begin
         app_rd_data_valid_ff <= 'b0;
      end
   end

`else // ~DDR3_NO_MIG_SIM
mig_7series_0 u_mig_7series_0 (
   // Memory interface ports
   .ddr3_addr                      (ddr3_addr),          // output [14:0]
   .ddr3_ba                        (ddr3_ba),            // output [2:0]
   .ddr3_cas_n                     (ddr3_cas_n),         // output
   .ddr3_ck_n                      (ddr3_ck_n),          // output [0:0]
   .ddr3_ck_p                      (ddr3_ck_p),          // output [0:0]
   .ddr3_cke                       (ddr3_cke),           // output [0:0]
   .ddr3_ras_n                     (ddr3_ras_n),         // output
   .ddr3_reset_n                   (ddr3_reset_n),       // output
   .ddr3_we_n                      (ddr3_we_n),          // output
   .ddr3_dq                        (ddr3_dq),            // inout [15:0]
   .ddr3_dqs_n                     (ddr3_dqs_n),         // inout [1:0]
   .ddr3_dqs_p                     (ddr3_dqs_p),         // inout [1:0]
   .ddr3_dm                        (ddr3_dm),            // output [1:0]
   .ddr3_odt                       (ddr3_odt),           // output [0:0]
   // Application interface ports
   .app_addr                       (app_addr),           // input [28:0]
   .app_cmd                        (app_cmd),            // input [2:0]
   .app_en                         (app_en),             // input
   .app_wdf_data                   (app_wdf_data),       // input [127:0]
   .app_wdf_mask                   (16'h0000),           // input [15:0]
   .app_wdf_end                    (app_wdf_end),        // input
   .app_wdf_wren                   (app_wdf_wren),       // input
   .app_rd_data                    (app_rd_data),        // output [127:0]
   .app_rd_data_end                (app_rd_data_end),    // output
   .app_rd_data_valid              (app_rd_data_valid),  // output
   .app_rdy                        (app_rdy),            // output
   .app_wdf_rdy                    (app_wdf_rdy),        // output
   .app_sr_req                     (1'b0),               // input
   .app_ref_req                    (1'b0),               // input
   .app_zq_req                     (1'b0),               // input
   .app_sr_active                  (),                   // output
   .app_ref_ack                    (),                   // output
   .app_zq_ack                     (),                   // output
   .ui_clk                         (ui_clk),             // output
   .ui_clk_sync_rst                (ui_clk_sync_rst),    // output

   .init_calib_complete            (init_calib_complete),// output
   .device_temp                    (),                   // output [11:0]
   // System Clock Ports
   .sys_clk_i                      (clk200m_bufg),       // input
   .sys_rst                        (~rst_clk200m)        // input ACTIVE LOW!!!
);
`endif // DDR3_NO_MIG_SIM

////////////////////////////////////////////////////////////////////////////////
// CDC GPIO to ui_clk domain
////////////////////////////////////////////////////////////////////////////////

// sysclk -> ui_clk

wire [31:0] gpo1_uiclk;
value_cdc i_value_cdc_gpo1 (
   .clk_src    (sysclk),
   .rst_src    (sysrst),
   .value_src  (gpo1),

   .clk_dst    (ui_clk),
   .rst_dst    (ui_clk_sync_rst),
   .value_dst  (gpo1_uiclk)
);

wire [31:0] gpo3_uiclk;
value_cdc i_value_cdc_gpo3 (
   .clk_src    (sysclk),
   .rst_src    (sysrst),
   .value_src  (gpo3),

   .clk_dst    (ui_clk),
   .rst_dst    (ui_clk_sync_rst),
   .value_dst  (gpo3_uiclk)
);

wire [31:0] gpo4_uiclk;
value_cdc i_value_cdc_gpo4 (
   .clk_src    (sysclk),
   .rst_src    (sysrst),
   .value_src  (gpo4),

   .clk_dst    (ui_clk),
   .rst_dst    (ui_clk_sync_rst),
   .value_dst  (gpo4_uiclk)
);

wire intc_irq_uiclk;
pulse_cdc i_pulse_cdc_intcirq (
   .clk_src    (sysclk),
   .rst_src    (sysrst),
   .pulse_src  (intc_irq),

   .clk_dst    (ui_clk),
   .rst_dst    (ui_clk_sync_rst),
   .pulse_dst  (intc_irq_uiclk)
);

// ui_clk -> sysclk

reg hw_int_uiclk = 1'b0;

value_cdc #(
   .BITS(1)
) i_value_cdc_hw_int (
   .clk_src    (ui_clk),
   .rst_src    (ui_clk_sync_rst),
   .value_src  (hw_int_uiclk),

   .clk_dst    (sysclk),
   .rst_dst    (sysrst),
   .value_dst  (hw_int)
);

reg [31:0] gpi1_uiclk;
value_cdc i_value_cdc_gpi1 (
   .clk_src    (ui_clk),
   .rst_src    (ui_clk_sync_rst),
   .value_src  (gpi1_uiclk),

   .clk_dst    (sysclk),
   .rst_dst    (sysrst),
   .value_dst  (gpi1)
);

reg [31:0] gpi2_uiclk;
value_cdc i_value_cdc_gpi2 (
   .clk_src    (ui_clk),
   .rst_src    (ui_clk_sync_rst),
   .value_src  (gpi2_uiclk),

   .clk_dst    (sysclk),
   .rst_dst    (sysrst),
   .value_dst  (gpi2)
);

reg [31:0] gpi3_uiclk;
value_cdc i_value_cdc_gpi3 (
   .clk_src    (ui_clk),
   .rst_src    (ui_clk_sync_rst),
   .value_src  (gpi3_uiclk),

   .clk_dst    (sysclk),
   .rst_dst    (sysrst),
   .value_dst  (gpi3)
);

reg [31:0] gpi4_uiclk;
value_cdc i_value_cdc_gpi4 (
   .clk_src    (ui_clk),
   .rst_src    (ui_clk_sync_rst),
   .value_src  (gpi4_uiclk),

   .clk_dst    (sysclk),
   .rst_dst    (sysrst),
   .value_dst  (gpi4)
);

////////////////////////////////////////////////////////////////////////////////
// FSM for MIG access (run this on ui_clk)
////////////////////////////////////////////////////////////////////////////////

localparam S_IDLE  = 3'h0;
localparam S_WRADD = 3'h1;
localparam S_WRDAT_M = 3'h2;
localparam S_WRDAT_L = 3'h3;
localparam S_RDADD = 3'h4;
localparam S_WTIRQ = 3'h5;

reg [2:0] state=S_IDLE;

always @(posedge ui_clk) begin
   case (state)
      S_IDLE: begin
         app_addr <= gpo1_uiclk[28:0];
         case (gpo1_uiclk[31:29])
            3'b100: begin
               // latch write address
               app_cmd  <= 3'b000;
               hw_int_uiclk <= 1'b1; // trigger interrupt to tell sw to write app_wdf_data
               state    <= S_WRADD;
            end
            3'b101: begin
               // latch read address
               app_cmd  <= 3'b001;
               state    <= S_RDADD;
               app_en   <= 1'b1;
            end
            default: begin
            end
         endcase
         // if DRAM was not initialized yet wait until it is
         // sw only proceed upon receiving the interrupt
         if (~init_calib_complete) begin
            state <= S_IDLE;
            hw_int_uiclk <= 'b0;
         end
      end
      S_WRADD: begin
         if (~hw_int_uiclk) begin
            state <= S_WRDAT_M;
         end
      end
      S_WRDAT_M: begin
         if ((gpo1_uiclk[31:29]==3'b110)&&(~hw_int_uiclk)) begin
            state <= S_WRDAT_L;
            app_wdf_data[127:96] <= gpo3_uiclk;
            app_wdf_data[95:64]  <= gpo4_uiclk;
            hw_int_uiclk <= 1'b1; // trigger interrupt to tell sw to write app_wdf_data LSB
         end
      end
      S_WRDAT_L: begin
         if ((gpo1_uiclk[31:29]==3'b111)&&(~hw_int_uiclk)) begin
            state <= S_WTIRQ;
            app_wdf_data[63:32]  <= gpo3_uiclk;
            app_wdf_data[31:0]   <= gpo4_uiclk;
            hw_int_uiclk <= 1'b1; // trigger interrupt to tell sw to write transaction complete
            app_wdf_wren <= 1'b1;
            app_en <= 1'b1;
         end
      end
      S_RDADD: begin
         if (app_rdy) begin
            app_en <= 'b0;
         end
         if (app_rd_data_valid) begin
            state <= S_WTIRQ;
            gpi1_uiclk <= app_rd_data[127:96];
            gpi2_uiclk <= app_rd_data[95:64];
            gpi3_uiclk <= app_rd_data[63:32];
            gpi4_uiclk <= app_rd_data[31:0];
            hw_int_uiclk <= 1'b1; // trigger interrupt to tell sw to write transaction complete
         end
      end
      S_WTIRQ: begin
         if (app_wdf_rdy) begin
            app_wdf_wren <= 'b0;
         end
         if (app_rdy) begin
            app_en <= 'b0;
         end
         if ((app_wdf_wren==1'b0)&&(app_en==1'b0)&&(gpo1_uiclk[31:29]==3'b000)) begin
            hw_int_uiclk <= 1'b1; // trigger interrupt to tell sw we're done with this transaction
            state <= S_IDLE;
         end
      end
   endcase

   if (intc_irq_uiclk) begin
      hw_int_uiclk <= 'b0;
   end

   if (ui_clk_sync_rst) begin
      state <= S_IDLE;
      hw_int_uiclk <= 1'b0;
      app_en   <= 1'b0;
      app_wdf_wren <= 1'b0;
   end
end

////////////////////////////////////////////////////////////////////////////////
// DEBUG
////////////////////////////////////////////////////////////////////////////////
wire [255:0] iladata = {
   256'h0
};

ila_0 i_ila (
   .clk     (clk200m),
   .probe0  (iladata)
);

endmodule
