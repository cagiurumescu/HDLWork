module design_top (
   inout [14:0]   DDR_addr,
   inout [2:0]    DDR_ba,
   inout          DDR_cas_n,
   inout          DDR_ck_n,
   inout          DDR_ck_p,
   inout          DDR_cke,
   inout          DDR_cs_n,
   inout [3:0]    DDR_dm,
   inout [31:0]   DDR_dq,
   inout [3:0]    DDR_dqs_n,
   inout [3:0]    DDR_dqs_p,
   inout          DDR_odt,
   inout          DDR_ras_n,
   inout          DDR_reset_n,
   inout          DDR_we_n,
   inout          FIXED_IO_ddr_vrn,
   inout          FIXED_IO_ddr_vrp,
   inout [53:0]   FIXED_IO_mio,
   inout          FIXED_IO_ps_clk,
   inout          FIXED_IO_ps_porb,
   inout          FIXED_IO_ps_srstb,
   input          sysclk, // 125 MHz ETHPHY clock
   output [1:0]   led
);

wire clk100_fclk0;
reg [26:0] counter_clk100 = 'b0;

always @(posedge clk100_fclk0) begin
   counter_clk100 <= counter_clk100 + 1;
end

// IRQ_F2P0 stays on for 256 clock cycles (2.56 us) while counter_clk100[25:8]==1
wire irq_f2p0 = ((counter_clk100[26]==1'b1) && (counter_clk100[25:8]==18'h1)) ? 1'b1 : 1'b0;
// IRQ_F2P1 will assert every 2^27*10=1.2s when counter_clk100[26] 0->1
wire irq_f2p1 = (counter_clk100[26]==1'b1) ? 1'b1 : 1'b0;

assign led[0] = counter_clk100[26];

reg [26:0] counter_sysclk;
always @(posedge sysclk) begin
   counter_sysclk <= counter_sysclk + 1;
end

assign led[1] = counter_sysclk[26];

design_top_bd_wrapper i_design_top_bd_wrapper (
   .DDR_addr            (DDR_addr),          //    inout [14:0]
   .DDR_ba              (DDR_ba),            //    inout [2:0]
   .DDR_cas_n           (DDR_cas_n),         //    inout
   .DDR_ck_n            (DDR_ck_n),          //    inout
   .DDR_ck_p            (DDR_ck_p),          //    inout
   .DDR_cke             (DDR_cke),           //    inout
   .DDR_cs_n            (DDR_cs_n),          //    inout
   .DDR_dm              (DDR_dm),            //    inout [3:0]
   .DDR_dq              (DDR_dq),            //    inout [31:0]
   .DDR_dqs_n           (DDR_dqs_n),         //    inout [3:0]
   .DDR_dqs_p           (DDR_dqs_p),         //    inout [3:0]
   .DDR_odt             (DDR_odt),           //    inout
   .DDR_ras_n           (DDR_ras_n),         //    inout
   .DDR_reset_n         (DDR_reset_n),       //    inout
   .DDR_we_n            (DDR_we_n),          //    inout
   .FCLK0               (clk100_fclk0),      //    output
   .FIXED_IO_ddr_vrn    (FIXED_IO_ddr_vrn),  //    inout
   .FIXED_IO_ddr_vrp    (FIXED_IO_ddr_vrp),  //    inout
   .FIXED_IO_mio        (FIXED_IO_mio),      //    inout [53:0]
   .FIXED_IO_ps_clk     (FIXED_IO_ps_clk),   //    inout
   .FIXED_IO_ps_porb    (FIXED_IO_ps_porb),  //    inout
   .FIXED_IO_ps_srstb   (FIXED_IO_ps_srstb), //    inout
   .IRQ_F2P0            (irq_f2p0),          //    input active high intr
   .IRQ_F2P1            (irq_f2p1)           //    input rising edge intr
);

endmodule
