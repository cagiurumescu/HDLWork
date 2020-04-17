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

`timescale 1ns/1ps

module spi_master_enc424j600_tb();

localparam CLK_HALF = 10;

reg clk;
always begin
   clk='b0;
   #CLK_HALF;
   clk='b1;
   #CLK_HALF;
end

reg rst;
initial begin
   rst = 'b1;
   repeat (20) @(posedge clk);
   rst = 'b0;
end

reg [7:0]   opbyte;
reg         opbyte_valid;
wire        txn_done;
integer ird;
reg [7:0]   rd_byte; // MISO
wire        sck;
reg [7:0]   wr_byte; // MOSI
reg         wrdat_valid;
wire        wrdat_ready;

initial begin
   opbyte_valid=1'b0;
   wrdat_valid=1'b0;
   rd_byte = 'bz;
   wr_byte = 'b0;
   wait (rst == 1);
   wait (rst == 0);
   @(negedge clk);
   opbyte_valid=1'b1;
   opbyte=8'hDA;
   @(negedge clk);
   opbyte_valid=1'b0;
   wait (txn_done==1'b1);
   @(negedge clk);

   @(posedge clk);

   @(negedge clk);
   opbyte_valid=1'b1;
   opbyte=8'hC8;
   @(negedge clk);
   opbyte_valid=1'b0;
   repeat (8) @(negedge sck);
   rd_byte = $random;
   for (ird=0; ird<8; ird=ird+1) begin
      @(negedge sck);
      rd_byte = {rd_byte[6:0], 1'b0};
   end
   rd_byte='bz;
   wait (txn_done==1'b1);

   @(negedge clk);
   opbyte_valid=1'b1;
   opbyte=8'h62;
   @(negedge clk);
   opbyte_valid=1'b0;
   repeat (8) @(negedge sck);
   repeat (2) begin
      rd_byte = $random;
      for (ird=0; ird<8; ird=ird+1) begin
         @(negedge sck);
         rd_byte = {rd_byte[6:0], 1'b0};
      end
   end
   rd_byte='bz;
   wait (txn_done==1'b1);

   @(negedge clk);
   opbyte_valid=1'b1;
   opbyte=8'h60;
   @(negedge clk);
   opbyte_valid=1'b0;
   repeat (2) begin
      fork
         begin
            repeat (8) @(negedge sck);
         end
         begin
            wr_byte = $random;
            wait (wrdat_ready);
            @(negedge clk);
            wrdat_valid <= 'b1;
            @(negedge clk);
            wrdat_valid <= 'b0;
         end
      join
   end
   wait (txn_done==1'b1);
   $stop;
end

spi_master_enc424j600 i_spi_master (
   .clk           (clk),
   .rst           (rst),

   .opbyte        (opbyte),
   .opbyte_valid  (opbyte_valid),
   .nbyte_num     (11'h5),
   .wrdat_byte    (wr_byte),
   .wrdat_valid   (wrdat_valid|1'b1),
   .wrdat_ready   (wrdat_ready),
   .rddat_byte    (),
   .rddat_valid   (),
   .txn_done      (txn_done),

   .SCK           (sck),
   .CS_N          (),
   .MOSI          (),
   .MISO          (rd_byte[7])
);

endmodule
