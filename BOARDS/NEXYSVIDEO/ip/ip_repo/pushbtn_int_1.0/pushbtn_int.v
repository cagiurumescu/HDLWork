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

// very similar to an AXI4LITE slave peripheral created by Vivado's "create IP".

module pushbtn_int #(
   // make it match the SENSITIVITY parameter value for interrupt Xilinx interface
   // NB, seems that uBlaze controller does not support EDGE_FALLING/LEVEL_LOW
   // but will infer the correct interrupt if the TCL script for generation of this
   // ip adds the correct sensitivity (which must match the value here)!
   parameter INTERRUPT_TYPE = "LEVEL_HIGH", // "EDGE_RISING", "EDGE_FALLING", "LEVEL_HIGH", "LEVEL_LOW"
   parameter S_AXI_ADDRW = 4,
   parameter S_AXI_DATAW = 32 // 32 or 64 only
) (
   // AXI interface
   input  wire                   S_AXI_ACLK,
   input  wire                   S_AXI_ARESETN,
   input  wire [S_AXI_ADDRW-1:0] S_AXI_AWADDR,
   input  wire [2:0]             S_AXI_AWPROT,
   input  wire                   S_AXI_AWVALID,
   output wire                   S_AXI_AWREADY,
   input  wire [S_AXI_DATAW-1:0] S_AXI_WDATA,
   input  wire [(S_AXI_DATAW/8)-1:0] S_AXI_WSTRB,
   input  wire                   S_AXI_WVALID,
   output wire                   S_AXI_WREADY,
   output wire [1:0]             S_AXI_BRESP,
   output wire                   S_AXI_BVALID,
   input  wire                   S_AXI_BREADY,
   input  wire [S_AXI_ADDRW-1:0] S_AXI_ARADDR,
   input  wire [2:0]             S_AXI_ARPROT,
   input  wire                   S_AXI_ARVALID,
   output wire                   S_AXI_ARREADY,
   output wire [S_AXI_DATAW-1:0] S_AXI_RDATA,
   output wire [1:0]             S_AXI_RRESP,
   output wire                   S_AXI_RVALID,
   input  wire                   S_AXI_RREADY,

   // async I/O
   input  wire                   PUSHBTN_IN, // active high, pressed=high depressed=low
   output wire                   INTERRUPT_OUT
);

reg         sw_clear_interrupt; // only for level interrupt
reg         pushbtn_in_meta;
reg [2:0]   pushbtn_in_ffs;
reg         interrupt_out_ff;

// assuming 100 MHz S_AXI_ACLK
reg [19:0]  pushbtn_change_count;

always @(posedge S_AXI_ACLK or posedge S_AXI_ARESETN) begin
   if (~S_AXI_ARESETN) begin
      pushbtn_in_meta <= 'b0;
      pushbtn_in_ffs  <= 'b0;
      interrupt_out_ff <= ((INTERRUPT_TYPE=="LEVEL_LOW")||(INTERRUPT_TYPE=="EDGE_FALLING")) ? 1'b1 : 1'b0;
      pushbtn_change_count <= 'b0;
   end else begin
      pushbtn_in_meta <= PUSHBTN_IN;
      pushbtn_in_ffs  <= {pushbtn_in_ffs[1:0], pushbtn_in_meta};

      if (pushbtn_change_count!=0) begin
         pushbtn_change_count <= pushbtn_change_count + 1;
      end
      if ((pushbtn_change_count==0)&&(pushbtn_in_ffs[2]==1'b0)&&(pushbtn_in_ffs[1]==1'b1)) begin
         pushbtn_change_count <= 'h1;
      end

      if ((INTERRUPT_TYPE=="LEVEL_HIGH")||(INTERRUPT_TYPE=="LEVEL_LOW")) begin
         if (pushbtn_change_count==1'b1) begin
            interrupt_out_ff <= (INTERRUPT_TYPE=="LEVEL_HIGH") ? 1'b1 : 1'b0;
         end
         if (sw_clear_interrupt) begin
            interrupt_out_ff <= (INTERRUPT_TYPE=="LEVEL_HIGH") ? 1'b0 : 1'b1;
         end
      end

      if ((INTERRUPT_TYPE=="EDGE_RISING")||(INTERRUPT_TYPE=="EDGE_FALLING")) begin
         interrupt_out_ff <= (INTERRUPT_TYPE=="EDGE_FALLING") ? 1'b1 : 1'b0;
         if (pushbtn_change_count==1'b1) begin
            interrupt_out_ff <= (INTERRUPT_TYPE=="EDGE_FALLING") ? 1'b0 : 1'b1;
         end
      end

   end
end

assign INTERRUPT_OUT = interrupt_out_ff;

////////////////////////////////////////////////////////////////////////////////
// AXI accesses
////////////////////////////////////////////////////////////////////////////////

reg  [S_AXI_ADDRW-1:0]  axi_awaddr;
reg                     axi_awready;
reg                     axi_wready;
reg  [1:0]              axi_bresp;
reg                     axi_bvalid;
reg  [S_AXI_ADDRW-1:0]  axi_araddr;
reg                     axi_arready;
reg  [S_AXI_DATAW-1:0]  axi_rdata;
reg  [1:0]              axi_rresp;
reg                     axi_rvalid;

assign S_AXI_AWREADY = axi_awready;
assign S_AXI_WREADY  = axi_wready;
assign S_AXI_BRESP   = axi_bresp;
assign S_AXI_BVALID  = axi_bvalid;
assign S_AXI_ARREADY = axi_arready;
assign S_AXI_RDATA   = axi_rdata;
assign S_AXI_RRESP   = axi_rresp;
assign S_AXI_RVALID  = axi_rvalid;

localparam ADDR_LSB = S_AXI_DATAW/32+1; // 2 for 32-bit, 3 for 64-bit
localparam ADDR_MSB = ADDR_LSB+1;

reg  [S_AXI_DATAW-1:0]  slv_reg0;
reg  [S_AXI_DATAW-1:0]  slv_reg1;
reg  [S_AXI_DATAW-1:0]  slv_reg2;
reg  [S_AXI_DATAW-1:0]  slv_reg3;

reg  [S_AXI_DATAW-1:0]  reg_data_out;

wire                    slv_reg_rden;
wire                    slv_reg_wren;
reg                     aw_en;

////////////////////////////////////////////////////////////////////////////////
// AXI protocol writes
////////////////////////////////////////////////////////////////////////////////

// generate axi_awready and axi_wready, axi_awaddr latching
// generate axi_bvalid, axi_bresp
always @(posedge S_AXI_ACLK) begin
   if (~axi_awready & S_AXI_AWVALID & S_AXI_WVALID & aw_en) begin
      axi_awready <= 1'b1;
      aw_en <= 1'b0;
      axi_awaddr <= S_AXI_AWADDR;
   end else if (S_AXI_BREADY & axi_bvalid) begin
      axi_awready <= 1'b0;
      aw_en <= 1'b1;
   end else begin
      axi_awready <= 1'b0;
   end

   if (~axi_wready & S_AXI_WVALID & S_AXI_AWVALID & aw_en) begin
      axi_wready <= 1'b1;
   end else begin
      axi_wready <= 1'b0;
   end

   if (axi_awready & S_AXI_AWVALID & ~axi_bvalid & axi_wready && S_AXI_WVALID) begin
      axi_bvalid <= 1'b1;
   end else if (S_AXI_BREADY && axi_bvalid) begin
      axi_bvalid <= 1'b0;
   end

   if (~S_AXI_ARESETN) begin
      axi_awready <= 1'b0;
      axi_awaddr <= 'b0;
      axi_wready <= 1'b0;
      aw_en <= 1'b1;
      axi_bvalid <= 1'b0;
      axi_bresp <= 'b0; // no error ever
   end
end

assign slv_reg_wren = axi_wready & axi_awready & S_AXI_WVALID & S_AXI_AWVALID;

// register writes
integer byteidx;

always @(posedge S_AXI_ACLK) begin
   sw_clear_interrupt <= 'b0;
   if (slv_reg_wren) begin
      case (axi_awaddr[ADDR_MSB:ADDR_LSB])
         2'h0 : begin
            for (byteidx=0; byteidx<(S_AXI_DATAW/8); byteidx=byteidx+1) begin
               if (S_AXI_WSTRB[byteidx]) begin
                  slv_reg0[(byteidx*8)+:8] <= S_AXI_WDATA[(byteidx*8)+:8];
               end
            end
            // always keep bit [0] cleared
            slv_reg0[0] <= 1'b0;
            sw_clear_interrupt <= S_AXI_WDATA[0];
         end
         2'h1 : begin
            for (byteidx=0; byteidx<(S_AXI_DATAW/8); byteidx=byteidx+1) begin
               if (S_AXI_WSTRB[byteidx]) begin
                  slv_reg1[(byteidx*8)+:8] <= S_AXI_WDATA[(byteidx*8)+:8];
               end
            end
         end
         2'h2 : begin
            for (byteidx=0; byteidx<(S_AXI_DATAW/8); byteidx=byteidx+1) begin
               if (S_AXI_WSTRB[byteidx]) begin
                  slv_reg2[(byteidx*8)+:8] <= S_AXI_WDATA[(byteidx*8)+:8];
               end
            end
         end
         2'h3 : begin
            for (byteidx=0; byteidx<(S_AXI_DATAW/8); byteidx=byteidx+1) begin
               if (S_AXI_WSTRB[byteidx]) begin
                  slv_reg3[(byteidx*8)+:8] <= S_AXI_WDATA[(byteidx*8)+:8];
               end
            end
         end
         default: begin
         end
      endcase
   end

   if (~S_AXI_ARESETN) begin
      slv_reg0 <= 'b0;
      slv_reg1 <= 'b0;
      slv_reg2 <= 'b0;
      slv_reg3 <= 'b0;
      sw_clear_interrupt <= 'b0;
   end
end

////////////////////////////////////////////////////////////////////////////////
// AXI protocol reads
////////////////////////////////////////////////////////////////////////////////

// generate axi_arready, axi_araddr latching
// generate axi_rvalid, axi_rresp

always @(posedge S_AXI_ACLK) begin
   if (~axi_arready & S_AXI_ARVALID) begin
      axi_arready <= 1'b1;
      axi_araddr <= S_AXI_ARADDR;
   end else begin
      axi_arready <= 1'b0;
   end

   if (axi_arready & S_AXI_ARVALID & ~axi_rvalid) begin
      axi_rvalid <= 1'b1;
   end else if (axi_rvalid & S_AXI_RREADY) begin
      axi_rvalid <= 1'b0;
   end

   if (~S_AXI_ARESETN) begin
      axi_arready <= 1'b0;
      axi_araddr <= 'b0;
      axi_rvalid <= 1'b0;
      axi_rresp <= 'b0; // no error ever
   end
end

always @(*) begin
   case (axi_araddr[ADDR_MSB:ADDR_LSB])
      2'h0: reg_data_out <= slv_reg0[31:0];
      2'h1: reg_data_out <= slv_reg1;
      2'h2: reg_data_out <= slv_reg2;
      2'h3: reg_data_out <= slv_reg3;
      default: reg_data_out <= 'b0;
   endcase
end

// latch read data
assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
always @(posedge S_AXI_ACLK) begin
   if (slv_reg_rden) begin
      axi_rdata <= reg_data_out;     // register read data
   end
   if (~S_AXI_ARESETN) begin
      axi_rdata <= 'b0;
   end
end

endmodule
