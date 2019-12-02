module fpga (
  // JC header
  input        sysclk,  // 100 MHz
  inout  [3:0] jc       // {SCLK,SDATA,UNUSED,CS_N}
);

reg spi_cs_n = 1'b1;
// JC[0] - output to PMOD
IOBUF i_jc_cs_n (
   .IO   (jc[0]),    // inout
   .I    (spi_cs_n), // input
   .T    (1'b0),     // input
   .O    ()          // output
);

// JC[1] - unused IO

wire spi_sdata;
// JC[2] - input from PMOD
IOBUF i_jb_sdata (
   .IO   (jc[2]),    // inout
   .I    (1'b0),     // input
   .T    (1'b1),     // input
   .O    (spi_sdata) // output
);

reg spi_sclk = 'b1;
// JC[3] - output to PMOD
IOBUF i_jb_sclk (
   .IO   (jc[3]),    // inout
   .I    (spi_sclk), // input
   .T    (1'b0),     // input
   .O    ()          // output
);

// create <=20 MHz SPI clock
localparam CLK_DIVIDE = 50; // 6 -> 16.67MHz,  8 -> 12.5MHz, 10 -> 10MHz, 100 -> 1MHz
reg [7:0] clk_divide_count = 'b1;
reg [7:0] clk_count_onehot; // up to 8 clk cycles delay
reg [17:0] sclk_count_onehot; // up to 17 sclk cycles delay

localparam CLK_COUNT_CSN_LO = 3;
typedef enum logic [7:0] {
   ST_IDLE,
   ST_PWRUP_CSN_LO,
   ST_PWRUP,
   ST_READ_CSN_LO,
   ST_READ
} fsm_state_t;
fsm_state_t fsm_state = ST_IDLE;

reg [15:0] spi_data;
reg [15:0] spi_data_latched;

always @(posedge sysclk) begin
   clk_count_onehot <= {clk_count_onehot[6:0], 1'b0};
   case (fsm_state)
      ST_IDLE: begin
         spi_cs_n <= 1'b1;
         spi_sclk <= 1'b1;
         clk_count_onehot <= 'b1;
         fsm_state <= ST_PWRUP_CSN_LO;
      end
      ST_PWRUP_CSN_LO: begin
         spi_cs_n <= 1'b0;
         spi_sclk <= 1'b1;
         if (clk_count_onehot[3]) begin // with 100 MHz sysclk this should cover req. for t2 and t3.
            spi_sclk <= 1'b0;
            clk_divide_count <= 'b1;
            sclk_count_onehot <= 'b1;
            fsm_state <= ST_PWRUP;
         end
      end
      ST_PWRUP: begin
         clk_divide_count <= clk_divide_count + 1;
         if (clk_divide_count==(CLK_DIVIDE/2)) begin
            spi_sclk <= ~spi_sclk;
            clk_divide_count <= 'b1;
            if (spi_sclk==1'b1) begin
               sclk_count_onehot <= {sclk_count_onehot[16:0], 1'b0};
            end
         end
         if ((sclk_count_onehot[15])&&(spi_sclk==1'b1)) begin
            spi_cs_n <= 1'b1;
         end
         if ((sclk_count_onehot[16])&&(spi_sclk==1'b0)&&(clk_divide_count==(CLK_DIVIDE/2))) begin
            // except for power up, first edge of sclk after scn negedge are sclk posedges
            sclk_count_onehot <= {sclk_count_onehot[16:0], 1'b0};
            spi_sclk <= 1'b0;
         end
         if ((sclk_count_onehot[17])&&(clk_divide_count==(CLK_DIVIDE/2))) begin
            clk_count_onehot <= 'b1;
            fsm_state <= ST_READ_CSN_LO;
            spi_sclk <= 1'b0;
         end
      end
      ST_READ_CSN_LO: begin
         spi_cs_n <= 1'b0;
         spi_sclk <= 1'b0;
         if (clk_count_onehot[3]) begin // with 100 MHz sysclk this should cover req. for t2 and t3.
            spi_sclk <= 1'b1;
            clk_divide_count <= 'b1;
            sclk_count_onehot <= 'b1;
            fsm_state <= ST_READ;
         end
      end
      ST_READ : begin
         clk_divide_count <= clk_divide_count + 1;
         if (clk_divide_count==(CLK_DIVIDE/2)) begin
            spi_sclk <= ~spi_sclk;
            clk_divide_count <= 'b1;
            if (spi_sclk==1'b0) begin
               sclk_count_onehot <= {sclk_count_onehot[16:0], 1'b0};
               if (sclk_count_onehot[16]) begin
                  spi_sclk <= 1'b0;
               end
            end
         end
         if ((sclk_count_onehot[16])&&(spi_sclk==1'b1)) begin
            spi_cs_n <= 1'b1;
            spi_data_latched <= spi_data;
         end
         if ((sclk_count_onehot[17])&&(clk_divide_count==(CLK_DIVIDE/2))) begin
            clk_count_onehot <= 'b1;
            fsm_state <= ST_READ_CSN_LO;
            spi_sclk <= 1'b0;
         end
         // read data after 7 ns but before 40 ns from negedge to satisfy t4 and t7
         if ((spi_sclk==1'b0) && (clk_divide_count=='h2) && (sclk_count_onehot[16]==1'b0)) begin
            spi_data <= {spi_data[14:0], spi_sdata};
         end
      end
   endcase
end

wire [11:0] mic3_value = spi_data_latched[0+:12];

ila_0 i_ila (
   .clk     (sysclk),
   .probe0  (spi_data_latched)
);

endmodule
