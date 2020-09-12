`timescale 1ns/1ps

module design_top_tb;

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

design_top i_design_top(
   .sysclk(clk),
   .uart_rx_out(uart_rx),
   .uart_tx_in(1'b1)
);

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
