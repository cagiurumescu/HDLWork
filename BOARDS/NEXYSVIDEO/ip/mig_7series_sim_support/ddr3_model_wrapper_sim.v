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

// pretty much a wrapperized version of MIG 7series example design
// requires ddr3_model.sv and wiredly.v from MIG example design

`timescale 1ps/100fs

module ddr3_model_wrapper_sim (
   // PHY DDR3 interface
   inout  [15:0]   ddr3_dq_fpga,       // [DQ_WIDTH-1:0]
   inout  [1:0]    ddr3_dqs_n_fpga,    // [DQS_WIDTH-1:0]
   inout  [1:0]    ddr3_dqs_p_fpga,    // [DQS_WIDTH-1:0]
   input  [14:0]   ddr3_addr_fpga,     // [ROW_WIDTH-1:0]
   input  [2:0]    ddr3_ba_fpga,
   input           ddr3_ras_n_fpga,
   input           ddr3_cas_n_fpga,
   input           ddr3_we_n_fpga,
   input           ddr3_reset_n,
   input  [0:0]    ddr3_ck_p_fpga,
   input  [0:0]    ddr3_ck_n_fpga,
   input  [0:0]    ddr3_cke_fpga,
   input  [1:0]    ddr3_dm_fpga,       // [DM_WIDTH-1:0]
   input  [0:0]    ddr3_odt_fpga,      // [ODT_WIDTH-1:0]

   // hierarchical input
   input           init_calib_complete
);

   //***************************************************************************
   // The following parameters refer to width of various ports
   //***************************************************************************
   parameter COL_WIDTH              = 10;
                                       // # of memory Column Address bits.
   parameter CS_WIDTH               = 1;
                                       // # of unique CS outputs to memory.
   parameter DM_WIDTH               = 2;
                                       // # of DM (data mask)
   parameter DQ_WIDTH               = 16;
                                       // # of DQ (data)
   parameter DQS_WIDTH              = 2;
   parameter DRAM_WIDTH             = 8;
                                       // # of DQ per DQS
   parameter RANKS                  = 1;
                                       // # of Ranks.
   parameter ODT_WIDTH              = 1;
                                       // # of ODT outputs to memory.
   parameter ROW_WIDTH              = 15;
                                       // # of memory Row Address bits.
   parameter ADDR_WIDTH             = 29;
                                       // # = RANK_WIDTH + BANK_WIDTH
                                       //     + ROW_WIDTH + COL_WIDTH;
                                       // Chip Select is always tied to low for
                                       // single rank devices
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for PLLE2.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   parameter CLKIN_PERIOD           = 5000;
                                       // Input Clock Period
   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   parameter RST_ACT_LOW            = 1;
                                       // =1 for active low reset,
                                       // =0 for active high.
   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
   parameter REFCLK_FREQ            = 200.0;
                                       // IODELAYCTRL reference clock frequency
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   parameter tCK                    = 2500;
                                       // memory tCK paramter.
                                       // # = Clock Period in pS.
   parameter nCK_PER_CLK            = 4;
                                       // # of memory CKs per fabric CLK
   //**************************************************************************//
   // Local parameters Declarations
   //**************************************************************************//

   localparam real TPROP_DQS        = 0.00;
                                       // Delay for DQS signal during Write Operation
   localparam real TPROP_DQS_RD     = 0.00;
                                       // Delay for DQS signal during Read Operation
   localparam real TPROP_PCB_CTRL   = 0.00;
                                       // Delay for Address and Ctrl signals
   localparam real TPROP_PCB_DATA   = 0.00;
                                       // Delay for data signal during Write operation
   localparam real TPROP_PCB_DATA_RD= 0.00;
                                       // Delay for data signal during Read operation
   localparam MEMORY_WIDTH          = 16;
   localparam NUM_COMP              = DQ_WIDTH/MEMORY_WIDTH;
   localparam RESET_PERIOD          = 200000; //in pSec  

   //**************************************************************************//
   // Wire Declarations
   //**************************************************************************//
   reg                     sys_rst_n;
   reg [DM_WIDTH-1:0]      ddr3_dm_sdram_tmp;
   reg [ODT_WIDTH-1:0]     ddr3_odt_sdram_tmp;
   wire [DQ_WIDTH-1:0]     ddr3_dq_sdram;
   reg [ROW_WIDTH-1:0]     ddr3_addr_sdram [0:1];
   reg [3-1:0]             ddr3_ba_sdram [0:1];
   reg                     ddr3_ras_n_sdram;
   reg                     ddr3_cas_n_sdram;
   reg                     ddr3_we_n_sdram;
   wire [(CS_WIDTH*1)-1:0] ddr3_cs_n_sdram;
   wire [ODT_WIDTH-1:0]    ddr3_odt_sdram;
   reg [1-1:0]             ddr3_cke_sdram;
   wire [DM_WIDTH-1:0]     ddr3_dm_sdram;
   wire [DQS_WIDTH-1:0]    ddr3_dqs_p_sdram;
   wire [DQS_WIDTH-1:0]    ddr3_dqs_n_sdram;
   reg [1-1:0]             ddr3_ck_p_sdram;
   reg [1-1:0]             ddr3_ck_n_sdram;

   //**************************************************************************//
   // Reset Generation
   //**************************************************************************//
   initial begin
      sys_rst_n = 1'b0;
      #RESET_PERIOD
      sys_rst_n = 1'b1;
   end
   
   //**************************************************************************//
   // Inputs
   //**************************************************************************//
   always @( * ) begin
      ddr3_ck_p_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_p_fpga;
      ddr3_ck_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_ck_n_fpga;
      ddr3_addr_sdram[0]   <=  #(TPROP_PCB_CTRL) ddr3_addr_fpga;
      ddr3_addr_sdram[1]   <=  #(TPROP_PCB_CTRL) ddr3_addr_fpga;
      ddr3_ba_sdram[0]     <=  #(TPROP_PCB_CTRL) ddr3_ba_fpga;
      ddr3_ba_sdram[1]     <=  #(TPROP_PCB_CTRL) ddr3_ba_fpga;
      ddr3_ras_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_ras_n_fpga;
      ddr3_cas_n_sdram     <=  #(TPROP_PCB_CTRL) ddr3_cas_n_fpga;
      ddr3_we_n_sdram      <=  #(TPROP_PCB_CTRL) ddr3_we_n_fpga;
      ddr3_cke_sdram       <=  #(TPROP_PCB_CTRL) ddr3_cke_fpga;
   end

   assign ddr3_cs_n_sdram =  {(CS_WIDTH*1){1'b0}};

   always @( * )
      ddr3_dm_sdram_tmp <=  #(TPROP_PCB_DATA) ddr3_dm_fpga;//DM signal generation
   assign ddr3_dm_sdram = ddr3_dm_sdram_tmp;

   always @( * )
      ddr3_odt_sdram_tmp  <=  #(TPROP_PCB_CTRL) ddr3_odt_fpga;
   assign ddr3_odt_sdram =  ddr3_odt_sdram_tmp;

   //**************************************************************************//
   // Controlling the bi-directional BUS
   //**************************************************************************//
   genvar dqwd;
   generate
      for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
         WireDelay # (
            .Delay_g    (TPROP_PCB_DATA),
            .Delay_rd   (TPROP_PCB_DATA_RD),
            .ERR_INSERT ("OFF")
         ) u_delay_dq (
            .A             (ddr3_dq_fpga[dqwd]),
            .B             (ddr3_dq_sdram[dqwd]),
            .reset         (sys_rst_n),
            .phy_init_done (init_calib_complete)
         );
      end
      WireDelay # (
         .Delay_g    (TPROP_PCB_DATA),
         .Delay_rd   (TPROP_PCB_DATA_RD),
         .ERR_INSERT ("OFF")
      ) u_delay_dq_0 (
         .A             (ddr3_dq_fpga[0]),
         .B             (ddr3_dq_sdram[0]),
         .reset         (sys_rst_n),
         .phy_init_done (init_calib_complete)
      );
   endgenerate

   genvar dqswd;
   generate
      for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
         WireDelay # (
            .Delay_g    (TPROP_DQS),
            .Delay_rd   (TPROP_DQS_RD),
            .ERR_INSERT ("OFF")
         ) u_delay_dqs_p (
            .A             (ddr3_dqs_p_fpga[dqswd]),
            .B             (ddr3_dqs_p_sdram[dqswd]),
            .reset         (sys_rst_n),
            .phy_init_done (init_calib_complete)
         );
         WireDelay # (
            .Delay_g    (TPROP_DQS),
            .Delay_rd   (TPROP_DQS_RD),
            .ERR_INSERT ("OFF")
         ) u_delay_dqs_n (
            .A             (ddr3_dqs_n_fpga[dqswd]),
            .B             (ddr3_dqs_n_sdram[dqswd]),
            .reset         (sys_rst_n),
            .phy_init_done (init_calib_complete)
         );
      end
   endgenerate

   //**************************************************************************//
   // Memory Models instantiations
   //**************************************************************************//

   genvar r,i;
   generate
      for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
         if(DQ_WIDTH/16) begin: mem
            for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
               ddr3_model u_comp_ddr3 (
                  .rst_n   (ddr3_reset_n),
                  .ck      (ddr3_ck_p_sdram),
                  .ck_n    (ddr3_ck_n_sdram),
                  .cke     (ddr3_cke_sdram[r]),
                  .cs_n    (ddr3_cs_n_sdram[r]),
                  .ras_n   (ddr3_ras_n_sdram),
                  .cas_n   (ddr3_cas_n_sdram),
                  .we_n    (ddr3_we_n_sdram),
                  .dm_tdqs (ddr3_dm_sdram[(2*(i+1)-1):(2*i)]),
                  .ba      (ddr3_ba_sdram[r]),
                  .addr    (ddr3_addr_sdram[r]),
                  .dq      (ddr3_dq_sdram[16*(i+1)-1:16*(i)]),
                  .dqs     (ddr3_dqs_p_sdram[(2*(i+1)-1):(2*i)]),
                  .dqs_n   (ddr3_dqs_n_sdram[(2*(i+1)-1):(2*i)]),
                  .tdqs_n  (),
                  .odt     (ddr3_odt_sdram[r])
               );
            end
         end
         if (DQ_WIDTH%16) begin: gen_mem_extrabits
            ddr3_model u_comp_ddr3 (
               .rst_n   (ddr3_reset_n),
               .ck      (ddr3_ck_p_sdram),
               .ck_n    (ddr3_ck_n_sdram),
               .cke     (ddr3_cke_sdram[r]),
               .cs_n    (ddr3_cs_n_sdram[r]),
               .ras_n   (ddr3_ras_n_sdram),
               .cas_n   (ddr3_cas_n_sdram),
               .we_n    (ddr3_we_n_sdram),
               .dm_tdqs ({ddr3_dm_sdram[DM_WIDTH-1],ddr3_dm_sdram[DM_WIDTH-1]}),
               .ba      (ddr3_ba_sdram[r]),
               .addr    (ddr3_addr_sdram[r]),
               .dq      ({ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)], ddr3_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)]}),
               .dqs     ({ddr3_dqs_p_sdram[DQS_WIDTH-1], ddr3_dqs_p_sdram[DQS_WIDTH-1]}),
               .dqs_n   ({ddr3_dqs_n_sdram[DQS_WIDTH-1], ddr3_dqs_n_sdram[DQS_WIDTH-1]}),
               .tdqs_n  (),
               .odt     (ddr3_odt_sdram[r])
            );
         end
      end
   endgenerate
endmodule
