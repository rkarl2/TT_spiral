
`default_nettype	none
//
module	topolar(i_clk, i_reset, i_ce, i_xval, i_yval,
		o_phase);
	localparam	IW=7,	// The number of bits in our inputs
			OW=4,// The number of output bits to produce
			NSTAGES=3,
			WW=7,	// Our working bit-width
			PW=4;	// Bits in our phase variables
	input					i_clk, i_reset, i_ce;
	input	wire	signed	[(IW-1):0]	i_xval, i_yval;
	output	reg		[(OW-1):0]	o_phase;

	wire	signed [(WW-1):0]	e_xval, e_yval;
	assign	e_xval = i_xval;
	assign	e_yval = i_yval;

	// Declare variables for all of the separate stages
	reg	signed	[(WW-1):0]	xv	[0:NSTAGES];
	reg	signed	[(WW-1):0]	yv	[0:NSTAGES];
	reg		[(PW-1):0]	ph	[0:NSTAGES];



	// First stage, map to within +/- 45 degrees
	always @(posedge i_clk)
	if (i_reset)
	begin
		xv[0] <= 0;
		yv[0] <= 0;
		ph[0] <= 0;
	end else if (i_ce)
		case({i_xval[IW-1], i_yval[IW-1]})
		2'b01: begin // Rotate by -315 degrees
			xv[0] <=  e_xval - e_yval;
			yv[0] <=  e_xval + e_yval;
//			ph[0] <= 19'h70000 >> (19-PW-1);
			ph[0] <= 4'hC;
			end
		2'b10: begin // Rotate by -135 degrees
			xv[0] <= -e_xval + e_yval;
			yv[0] <= -e_xval - e_yval;
//			ph[0] <= 19'h30000 >> (19-PW-1);
			ph[0] <= 4'hC;
			end
		2'b11: begin // Rotate by -225 degrees
			xv[0] <= -e_xval - e_yval;
			yv[0] <=  e_xval - e_yval;
//			ph[0] <= 19'h50000>> (19-PW-1);
			ph[0] <= 4'h4;
			end
		default: begin // Rotate by -45 degrees
			xv[0] <=  e_xval + e_yval;
			yv[0] <= -e_xval + e_yval;
//			ph[0] <= 19'h10000>> (19-PW-1);
			ph[0] <= 4'h4;
			end
		endcase
	wire	[(PW-1):0]	cordic_angle [0:(NSTAGES-1)];
//	assign	cordic_angle[ 0] = 19'h0_9720>> (19-PW-1); //  26.565051 deg
//	assign	cordic_angle[ 1] = 19'h0_4fd9>> (19-PW-1); //  14.036243 deg
//	assign	cordic_angle[ 2] = 19'h0_2888>> (19-PW-1); //   7.125016 deg

	assign	cordic_angle[ 0] = 4'h2; //  26.565051 deg
	assign	cordic_angle[ 1] = 4'h1; //  14.036243 deg
	assign	cordic_angle[ 2] = 4'h0; //   7.125016 deg
	
	genvar	i;
	generate for(i=0; i<NSTAGES; i=i+1) begin : TOPOLARloop
		always @(posedge i_clk)
		// Here's where we are going to put the actual CORDIC
		// rectangular to polar loop.  Everything up to this
		// point has simply been necessary preliminaries.
		if (i_reset)
		begin
			xv[i+1] <= 0;
			yv[i+1] <= 0;
			ph[i+1] <= 0;
		end else if (i_ce)
		begin
			if ((cordic_angle[i] == 0)||(i >= WW))
			begin // Do nothing but move our vector
			// forward one stage, since we have more
			// stages than valid data
				xv[i+1] <= xv[i];
				yv[i+1] <= yv[i];
				ph[i+1] <= ph[i];
			end else if (yv[i][(WW-1)]) // Below the axis
			begin
				// If the vector is below the x-axis, rotate by
				// the CORDIC angle in a positive direction.
				xv[i+1] <= xv[i] - (yv[i]>>>(i+1));
				yv[i+1] <= yv[i] + (xv[i]>>>(i+1));
				ph[i+1] <= ph[i] - cordic_angle[i];
			end else begin
				// On the other hand, if the vector is above the
				// x-axis, then rotate in the other direction
				xv[i+1] <= xv[i] + (yv[i]>>>(i+1));
				yv[i+1] <= yv[i] - (xv[i]>>>(i+1));
				ph[i+1] <= ph[i] + cordic_angle[i];
			end
		end
	end endgenerate

always @(posedge i_clk)
	if (i_reset)
	begin
		o_phase <= 0;
	end else if (i_ce)
	begin
		o_phase <= ph[NSTAGES][(PW-1):(PW-OW)];
	end

endmodule