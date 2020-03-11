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

// if clk_src faster than clk_dst then resulting cdc graycode counter is not gray anymore.

// pipeline gray2binary decoding (not really useful, uses 
// way more flops for minor fmax improvement)
//`define USE_PIPELINED

module counter_cdc #(
   parameter BITS = 32
) (
   input clk_src,
   input rst_src,
   input [BITS-1:0] counter_src,

   input clk_dst,
   input rst_dst,
   output [BITS-1:0] counter_dst
);

// convert binary counter to gray counter on clk_src domain
// g[i]=b[i+1]^b[i] i=0..N-1; b[N]=0

reg [BITS-1:0] counter_src_ff;
reg [BITS-1:0] counter_gray_src;

always @(posedge clk_src) begin
   if (rst_src) begin
      counter_src_ff    <= 'b0;
      counter_gray_src  <= 'b0;
   end else begin
      counter_src_ff    <= counter_src;
      counter_gray_src  <= {1'b0, counter_src_ff[BITS-1:1]}^counter_src_ff[BITS-1:0];
   end
end

(* ASYNC_REG = "TRUE" *) reg [BITS-1:0] meta_counter_gray_src;
(* ASYNC_REG = "TRUE" *) reg [BITS-1:0] counter_gray_dst;
(* ASYNC_REG = "TRUE" *) reg [BITS-1:0] counter_gray_dst_d;

always @(posedge clk_dst) begin
   if (rst_dst) begin
      meta_counter_gray_src   <= 'b0;
      counter_gray_dst        <= 'b0;
      counter_gray_dst_d      <= 'b0;
   end else begin
      meta_counter_gray_src   <= counter_gray_src;
      counter_gray_dst        <= meta_counter_gray_src;
      counter_gray_dst_d      <= counter_gray_dst;
   end
end

// - convert gray counter to binary counter on clk_src domain
//   b[i]=b[i+1]^g[i] i=0..N-1; b[N]=0

wire [BITS:0] counter_dst_comb;
assign counter_dst_comb[BITS] = 1'b0;

genvar i;
generate
   for (i=BITS-1; i>=0; i=i-1) begin : gen_counter_dst_comb
      assign counter_dst_comb[i] = counter_dst_comb[i+1]^counter_gray_dst_d[i];
   end
endgenerate

reg [BITS-1:0] counter_dst_ff;
always @(posedge clk_dst) begin
   if (rst_dst) begin
      counter_dst_ff <= 'b0;
   end else begin
      counter_dst_ff <= counter_dst_comb;
   end
end

`ifdef USE_PIPELINED
// use pipelining to reduce the amount of combinational logic
// behind counter_dst_comb (reduces fmax)

localparam LUT_SIZE = 4; // depends on FPGA generation
localparam PIPE_STAGE = (BITS-1+LUT_SIZE-2)/(LUT_SIZE-1);

reg  [BITS-1:0] counter_dst_pipe_ff;
reg  [BITS-1:0] counter_bin_dst[0:PIPE_STAGE-1];
wire [BITS-1:0] counter_bin_comb_dst;

reg [PIPE_STAGE-1:0] pipe_stage_onehot;
reg [BITS-1:0] counter_gray_dst_d_latched;
always @(posedge clk_dst) begin
   if (rst_dst) begin
      pipe_stage_onehot <= 'b0;
      counter_gray_dst_d_latched <= 'b0;
      counter_dst_pipe_ff <= 'b0;
   end else begin
      if (pipe_stage_onehot=='b0) begin
         pipe_stage_onehot <= 'b1;
         counter_gray_dst_d_latched <= counter_gray_dst_d;
         counter_dst_pipe_ff <= counter_bin_dst[PIPE_STAGE-1];
      end else begin
         pipe_stage_onehot <= {pipe_stage_onehot[PIPE_STAGE-2:0],1'b0};
      end
   end
end

// handle extra case BITS-1
assign counter_bin_comb_dst[BITS-1] = counter_gray_dst_d_latched[BITS-1];
// combinational logic every LUT_SIZE-1 bits
genvar j,k;
generate
   for (j=BITS-2; j>=0; j=j-1) begin : gen_j
      for (k=0;k<PIPE_STAGE;k=k+1) begin : gen_k
         if ((((BITS-2-j) / (LUT_SIZE-1))==k) && (k==0)) begin : gen_k_eq_0
            assign counter_bin_comb_dst[j] = counter_bin_comb_dst[j+1] ^ counter_gray_dst_d_latched[j];
         end else begin : gen_k_other
            if ((((BITS-2-j) / (LUT_SIZE-1))==k) && (k>0)) begin : gen_k_gt_0
               if (((BITS-2-j) % (LUT_SIZE-1))==0) begin : gen_first
                  assign counter_bin_comb_dst[j] = counter_bin_dst[k-1][j+1] ^ counter_gray_dst_d_latched[j];
               end else begin
                  assign counter_bin_comb_dst[j] = counter_bin_comb_dst[j+1] ^ counter_gray_dst_d_latched[j];
               end
            end
         end
      end // gen_k
   end // gen_j
endgenerate

// pipelining flip-flops
// handle extra case BITS-1
integer m;
always @(posedge clk_dst) begin
   if (rst_dst) begin
      for (m=0; m<PIPE_STAGE;m=m+1) begin
         counter_bin_dst[m][BITS-1] <= 1'b0;
      end
   end else begin
      counter_bin_dst[0][BITS-1] <= counter_bin_comb_dst[BITS-1];
      for (m=1; m<PIPE_STAGE;m=m+1) begin
         counter_bin_dst[m][BITS-1] <= counter_bin_dst[m-1][BITS-1];
      end
   end
end

// handle bits BITS-2 to 0
generate
   for (j=BITS-2; j>=0; j=j-1) begin : gen_j_pipe
      for (k=0;k<PIPE_STAGE;k=k+1) begin : gen_k_pipe
         // assignment from combinatorial logic
         if (((BITS-2-j) / (LUT_SIZE-1))==k) begin
            always @(posedge clk_dst) begin
               if (rst_dst) begin
                  counter_bin_dst[k][j] <= 'b0;
               end else begin
                  counter_bin_dst[k][j] <= counter_bin_comb_dst[j];
               end
            end // always
         end else begin
            // pipeline already assigned
            if (((BITS-2-j) / (LUT_SIZE-1))<k) begin
               always @(posedge clk_dst) begin
                  if (rst_dst) begin
                     counter_bin_dst[k][j] <= 'b0;
                  end else begin
                     counter_bin_dst[k][j] <= counter_bin_dst[k-1][j];
                  end
               end // always
            end
         end // if neq k
      end // for k
   end // for j
endgenerate

assign counter_dst = counter_dst_pipe_ff;

`else // ~USE_PIPELINED

assign counter_dst = counter_dst_ff;

`endif // USE_PIPELINED

endmodule // USE_PIPELINED
