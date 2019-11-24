`timescale 1ns/1ps

`include "../src/fpga.v"
module sim;

reg clk;

always begin
   clk = 1'b0;
   #5;
   clk = 1'b1;
   #5;
end

wire sdo;

fpga i_fpga(
   .sysclk(clk),
   .jb(sdo),
   .sw(1'b0)
);

endmodule
