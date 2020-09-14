
`timescale 1ns/1ps

module design_top_tb;


////////////////////////////////////////////////////////////////////////////////
// System clock
////////////////////////////////////////////////////////////////////////////////
reg clk; // 100 MHz sysclk
function integer log2ceil;
   input integer n;
   integer i;
   begin
      log2ceil=1;
      for (i=1; (2**i)<n; i=i+1) begin
      end
      log2ceil=i;
   end
endfunction

always begin
   clk = 1'b0;
   #5;
   clk = 1'b1;
   #5;
end

wire uart_rx;

////////////////////////////////////////////////////////////////////////////////
// DRAM
////////////////////////////////////////////////////////////////////////////////
wire [15:0] ddr3_dq_fpga;       // [DQ_WIDTH-1:0]
wire [1:0]  ddr3_dqs_n_fpga;    // [DQS_WIDTH-1:0]
wire [1:0]  ddr3_dqs_p_fpga;    // [DQS_WIDTH-1:0]
wire [14:0] ddr3_addr_fpga;     // [ROW_WIDTH-1:0]
wire [2:0]  ddr3_ba_fpga;
wire        ddr3_ras_n_fpga;
wire        ddr3_cas_n_fpga;
wire        ddr3_we_n_fpga;
wire        ddr3_reset_n;
wire [0:0]  ddr3_ck_p_fpga;
wire [0:0]  ddr3_ck_n_fpga;
wire [0:0]  ddr3_cke_fpga;
wire [1:0]  ddr3_dm_fpga;       // [DM_WIDTH-1:0]
wire [0:0]  ddr3_odt_fpga;      // [ODT_WIDTH-1:0]

wire        init_calib_complete = i_design_top.init_calib_complete;

design_top i_design_top(
   .sysclk        (clk),               // input

   .uart_rx_out   (uart_rx),           // output
   .uart_tx_in    (1'b1),              // input

   .ddr3_dq       (ddr3_dq_fpga),      // inout  [15:0]
   .ddr3_dqs_n    (ddr3_dqs_n_fpga),   // inout  [1:0]
   .ddr3_dqs_p    (ddr3_dqs_p_fpga),   // inout  [1:0]
   .ddr3_addr     (ddr3_addr_fpga),    // output [14:0]
   .ddr3_ba       (ddr3_ba_fpga),      // output [2:0]
   .ddr3_ras_n    (ddr3_ras_n_fpga),   // output
   .ddr3_cas_n    (ddr3_cas_n_fpga),   // output
   .ddr3_we_n     (ddr3_we_n_fpga),    // output
   .ddr3_reset_n  (ddr3_reset_n),      // output          
   .ddr3_ck_p     (ddr3_ck_p_fpga),    // output [0:0]    
   .ddr3_ck_n     (ddr3_ck_n_fpga),    // output [0:0]    
   .ddr3_cke      (ddr3_cke_fpga),     // output [0:0]    
   .ddr3_dm       (ddr3_dm_fpga),      // output [1:0]    
   .ddr3_odt      (ddr3_odt_fpga)      // output [0:0]    
);

`ifdef DDR3_NO_MIG_SIM
   reg ui_clk;
   reg ui_clk_sync_rst;
   reg init_calib_complete_nomig;

   always begin
      ui_clk = 1'b1;
      #5;
      ui_clk = 1'b0;
      #5;
   end

   initial begin
      ui_clk_sync_rst = 1'b1;
      init_calib_complete_nomig = 1'b0;
      repeat (20) @(posedge ui_clk);
      ui_clk_sync_rst = 1'b0;
      repeat (3000) @(posedge ui_clk);
      init_calib_complete_nomig = 1'b1;
   end

   assign i_design_top.init_calib_complete = init_calib_complete_nomig;
   assign i_design_top.ui_clk = ui_clk;
   assign i_design_top.ui_clk_sync_rst = ui_clk_sync_rst;
`else // ~DDR3_NO_MIG_SIM
ddr3_model_wrapper_sim i_ddr3_model(
   // PHY DDR3 interface
   .ddr3_dq_fpga        (ddr3_dq_fpga),         // inout  [15:0]
   .ddr3_dqs_n_fpga     (ddr3_dqs_n_fpga),      // inout  [1:0] 
   .ddr3_dqs_p_fpga     (ddr3_dqs_p_fpga),      // inout  [1:0]
   .ddr3_addr_fpga      (ddr3_addr_fpga),       // input  [14:0]
   .ddr3_ba_fpga        (ddr3_ba_fpga),         // input  [2:0]
   .ddr3_ras_n_fpga     (ddr3_ras_n_fpga),      // input
   .ddr3_cas_n_fpga     (ddr3_cas_n_fpga),      // input
   .ddr3_we_n_fpga      (ddr3_we_n_fpga),       // input
   .ddr3_reset_n        (ddr3_reset_n),         // input
   .ddr3_ck_p_fpga      (ddr3_ck_p_fpga),       // input  [0:0]
   .ddr3_ck_n_fpga      (ddr3_ck_n_fpga),       // input  [0:0]
   .ddr3_cke_fpga       (ddr3_cke_fpga),        // input  [0:0]
   .ddr3_dm_fpga        (ddr3_dm_fpga),         // input  [1:0]
   .ddr3_odt_fpga       (ddr3_odt_fpga),        // input  [0:0]
   // hierarchical input
   .init_calib_complete (init_calib_complete)   // input
);
`endif // DDR3_NO_MIG_SIM

////////////////////////////////////////////////////////////////////////////////
// UART processing
////////////////////////////////////////////////////////////////////////////////
// BAUD_RATE=115200, count with 100MHz clock
localparam BAUD_CLKS=100000000/115200;
localparam BAUD_CNT_BITS=log2ceil(BAUD_CLKS);

// xsim doesn't like cross-language hierarchy
//i_design_top.i_microblaze.inst.iomodule_0.U0.IOModule_Core_I1.C_UART_USE_PARITY;
localparam UART_USEPAR  = 1;
//i_design_top.i_microblaze.inst.iomodule_0.U0.IOModule_Core_I1.C_UART_ODD_PARITY;
localparam UART_ODDPAR  = 0; // even=0, odd=1

localparam S_IDLE  = 3'h0;
localparam S_START = 3'h1;
localparam S_BITS  = 3'h2; 
localparam S_PAR   = 3'h3;
localparam S_STOP  = 3'h4;

reg [2:0] bit_cnt='b0;
reg [2:0] state = S_IDLE;

reg [BAUD_CNT_BITS-1:0] baud_cnt='b0;
reg [7:0] uart_byte;
reg       parity_bit_rx='b0;
reg       parity_data='b0;
reg [1024*8-1:0] uart_string='b0;
reg [9:0] uart_string_len='b0; // last char is always NULL;

always @(posedge clk) begin
   case (state)
      S_IDLE : begin
         if (uart_rx==1'b0) begin
            state <= S_START;
            baud_cnt <= 'b0;
         end
      end
      S_START: begin
         if (baud_cnt!=BAUD_CLKS) begin
            baud_cnt <= baud_cnt + 1;
         end else begin
            state <= S_BITS;
            baud_cnt <= 'b0;

            bit_cnt <= 'b0;
            uart_byte <= 'bx;
            parity_data <= 'b0;
         end
      end
      S_BITS : begin
         if (baud_cnt!=BAUD_CLKS) begin
            baud_cnt <= baud_cnt + 1;
            if (baud_cnt==(BAUD_CLKS/2)) begin
               // sample the received bit
               uart_byte <= {uart_rx, uart_byte[7:1]};
               parity_data <= parity_data ^ uart_rx;
            end
         end else begin
            if (bit_cnt==3'b111) begin
               state <= (UART_USEPAR!=0) ? S_PAR : S_STOP;
            end
            baud_cnt <= 'b0;

            // increment bit in received byte
            bit_cnt <= bit_cnt + 1;
         end
      end
      S_PAR : begin
         if (baud_cnt!=BAUD_CLKS) begin
            baud_cnt <= baud_cnt + 1;
            if (baud_cnt==(BAUD_CLKS/2)) begin
               // sample the received bit
               parity_bit_rx <= uart_rx;
            end
         end else begin
            state <= S_STOP;
            baud_cnt <= 'b0;
         end
      end
      S_STOP : begin
         if (baud_cnt!=(BAUD_CLKS/2)) begin
            baud_cnt <= baud_cnt + 1;
         end else begin
            state <= S_IDLE;
            // we'll reset baud_cnt in S_IDLE

            if (UART_USEPAR) begin
               // parity check
               if (UART_ODDPAR) begin
                  if (parity_bit_rx!=(~parity_data)) begin
                     $display("ERROR: parity mismatch got=%x exp=%x", ~parity_data, parity_bit_rx);
                  end
               end else begin
                  if (parity_bit_rx!=parity_data) begin
                     $display("ERROR: parity mismatch got=%x exp=%x", parity_data, parity_bit_rx);
                  end
               end
            end

            uart_string_len <= uart_string_len+1;
            uart_string[(1024-uart_string_len-1)*8+:8] <= uart_byte;
            if ((uart_byte==8'hA)||(uart_byte==8'hD)) begin
               if (uart_string!='b0) begin
                  $display("%s", uart_string);
               end
               uart_string <= 'b0;
               uart_string_len <= 'b0;
            end

         end
      end
   endcase
end


endmodule
