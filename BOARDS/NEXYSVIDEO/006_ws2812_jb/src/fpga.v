module fpga (
  // JB header
  input        sysclk,  // 100 MHz
  output [0:0] jb,      // {SDO}
  input  [0:0] sw       // 
);

// 0 => 0.35us H, 0.90us L
// 1 => 0.90us H, 0.35us L
// rst => >50.00us L

reg sdo;
assign jb[0] = sdo;

reg [22:0] rst_count = 20'h0001; // 2^20*10 ns 

reg [5:0] led_count;
reg [23:0] grb; // {7..0, 7..0, 7..0}

reg [23:0] on_count; // 2^23*10 ns
reg hi_en;

localparam [5:0] LED_COUNT = 6'd40;

// POR
always @(posedge sysclk) begin
   if (rst_count!=0) begin
      rst_count <= rst_count + 1;
      led_count <= 'b0;
      on_count <= 'b0;
      hi_en <= 1'b0;
   end

   if ((grb==24'h0)&&(hi_en==1'b0))
      led_count <= led_count + 1;

   if (led_count[5:0]==LED_COUNT) begin
      on_count <= on_count + 1;
      hi_en <= 1'b1;
   end

   if ((sw[0]==1'b1)||((led_count[5:0]==LED_COUNT)&&(&on_count==1'b1))) begin
      rst_count <= 'b1;
      led_count <= 'b0;
      on_count <= 'b0;
      hi_en <= 1'b0;
   end
end

wire rst = (rst_count != 0) ? 1'b1 : 1'b0;

reg [6:0] sysclk_cnt;

reg [63:0] lfsr = 64'h01234567_89ABCDEF;

always @(posedge sysclk) begin

   sysclk_cnt <= sysclk_cnt + 1; // freerunning, 1280 ns

   if ((grb[23]==1'b0) && (sysclk_cnt==7'd36))
      sdo <= hi_en;

   if ((sdo==1'b1) && (sysclk_cnt==7'd70))
      sdo <= hi_en;

   if (sysclk_cnt == 7'd0) begin
      grb[23:0] <= {grb[22:0], 1'b0};
      sdo <= 'b1;
   end

   if (grb==24'd0) begin
      grb[23:0] <= {5'h0,lfsr[18:16], 5'h0,lfsr[10:8], 5'h0, lfsr[2:0]};
      //grb[23:0] <= {18'h0, lfsr[5:0]};
      lfsr[63:0] <= {lfsr[62:0], lfsr[0]^lfsr[1]^lfsr[3]^lfsr[4]};
   end

   if (lfsr[23:0]==24'h0)
      lfsr <= 'b1;

   if (rst) begin
      sdo <= 'b0;
      sysclk_cnt <= 'b0;
      grb[23:0] <= lfsr[23:0];
      //lfsr <= 64'h01234567_89ABCDEF;
   end
end

endmodule
