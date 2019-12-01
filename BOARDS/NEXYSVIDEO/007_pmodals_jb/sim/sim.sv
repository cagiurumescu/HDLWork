`include "../src/fpga.sv"
`include "../../ip/ila_0/ila_0_sim_netlist.v"

`timescale 1ns/1ps
module sim;

reg clk;

always begin
   clk = 1'b0;
   #5;
   clk = 1'b1;
   #5;
end

wire [3:0] jb;

reg my_rand;

fpga i_fpga(
   .sysclk(clk),
   .jb(jb)
);

assign jb[2] = my_rand;

always @(negedge jb[3]) begin
   my_rand <= $random;
end



endmodule
