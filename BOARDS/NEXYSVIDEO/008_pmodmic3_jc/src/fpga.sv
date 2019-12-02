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

reg spi_sclk = 'b0;
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

always @(posedge sysclk) begin
   clk_divide_count <= clk_divide_count + 1;
   if (clk_divide_count==(CLK_DIVIDE/2)) begin
      spi_sclk <= ~spi_sclk;
      clk_divide_count <= 'b1;
   end
end

typedef enum logic [7:0] {
   ST_IDLE,
   ST_POWER_UP,
   ST_POWERED_READ
} fsm_state_t;

fsm_state_t fsm_state = ST_IDLE;
reg [7:0] spi_sclk_count;
reg       spi_read_valid='b0;
reg [15:0] spi_data;

task spi_sclk_ctrl;
   input fsm_state_t next_fsm_state;
   begin
      spi_cs_n <= 1'b0;
      spi_sclk_count <= spi_sclk_count + 1;
      if ((spi_cs_n==1'b1)&&(spi_sclk_count!='b0)) begin
         spi_cs_n <= 1'b1;
      end
      if (spi_sclk_count=='d16) begin
         spi_cs_n <= 1'b1;
      end
      if (spi_sclk_count=='d32) begin
         spi_sclk_count <= 'b0;
         fsm_state <= next_fsm_state;
      end
   end
endtask


always @(posedge spi_sclk) begin
   case (fsm_state)
      ST_IDLE : begin
         spi_cs_n <= 1'b1;
         spi_sclk_count <= 'b0;
         fsm_state <= ST_POWER_UP;
      end
      ST_POWER_UP : begin
         spi_sclk_ctrl(ST_POWERED_READ);
      end
      ST_POWERED_READ: begin
         spi_sclk_ctrl(ST_POWERED_READ);
         if (spi_sclk_count!=0) begin
            spi_data <= {spi_data[14:0], spi_sdata};
         end
         if (spi_sclk_count=='b0) begin
            spi_read_valid <= 'b1;
         end
         if (spi_sclk_count=='d16) begin
            spi_read_valid <= 'b0;
         end
      end
   endcase
end

reg spi_read_valid_cdc = 'b0;
reg spi_read_valid_cdc_d = 'b0;

reg [15:0] spi_data_cdc;
reg [15:0] spi_data_latched;

always @(posedge sysclk) begin
   spi_read_valid_cdc <= spi_read_valid;
   spi_read_valid_cdc_d <= spi_read_valid_cdc;
   spi_data_cdc <= spi_data;
   if (spi_read_valid_cdc_d&~spi_read_valid_cdc) begin
      spi_data_latched <= spi_data_cdc;
   end
end

wire [11:0] mic3_value = spi_data_latched[0+:12];

ila_0 i_ila (
   .clk     (sysclk),
   .probe0  (spi_data_latched)
);

endmodule
