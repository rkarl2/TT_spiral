`default_nettype	none
module tt_um_rkarl_Spiral(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);
  assign uio_out = 0;
  assign uio_oe  = 0;
  wire _unused = &{ena, clk, rst_n, 1'b0,uio_in};


  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  
  wire [1:0] speed = {ui_in[0],~ui_in[1]};//Make the default 2
  wire [2:0] background = ui_in[4:2];
  wire [2:0] foreGround = ui_in[7:5];
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  
  wire signed [9:0] normilizedX = (pix_x -323);
  wire signed [9:0] normilizedY = (pix_y -243);
  wire [3:0] angle;
  reg [4:0] angleOffset;
  wire [3:0] adjustedAngle = angle + angleOffset[4:1];

  always @(posedge vsync)
	begin
		angleOffset <= angleOffset+{3'b000,speed};
	end 
  
  topolar cordicAlg(
  .i_clk(clk),
  .i_reset(~rst_n),
  .i_ce(1'b1),
  .i_xval(normilizedX[9:3]),
  .i_yval(normilizedY[9:3]),
  .o_phase(angle)
  );
  
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  wire [3:0] r;
  
  hypCal hypotenuse(.x_pos(normilizedX),
							.y_pos(normilizedY),
							.clk(clk),
							.rst(~rst_n),
							.r_sqroot(r)
							);

	assign R = video_active ? ((r[3:0] == adjustedAngle[3:0])? {~foreGround[0],~foreGround[0]} : {background[0],background[0]}) : 2'b00;
	assign G = video_active ? ((r[3:0] == adjustedAngle[3:0])? {foreGround[1],foreGround[1]} : {background[1],background[1]}) : 2'b00;
	assign B = video_active ? ((r[3:0] == adjustedAngle[3:0])? {foreGround[2],foreGround[2]} : {background[2],background[2]}) : 2'b00;




endmodule