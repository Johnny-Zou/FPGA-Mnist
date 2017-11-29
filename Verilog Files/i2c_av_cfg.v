////////////////////////////////////////////////
///load data values into both audio and video 
/// I2C registers starting with audio first
////////////////////////////////////////////////



module i2c_av_cfg (
			clk, // 50k clock
			reset, // switch 0 on DE2 board
			mend,  // end of load
			mstep,
			SCLK,
			mack,  // acknowledge reference bit
			mgo,   // go transfer for each value
			i2c_data // 23 bit register (8 command, 8 address, 8 data)
			
			);
			
input		clk;
input		reset;
input		SCLK;

input 	mend;
input 	mack;

output[3:0] mstep;
output	mgo;
output[23:0] i2c_data;

// internal register

reg		mgo;
reg[23:0] i2c_data;
reg[15:0] LUT_data;
reg[5:0]  LUT_index;
reg[3:0]  mstep;


// LUT data size value for both audio and video register

parameter 	LUT_size		= 32; // number of values loaded both audio and serial

//Audio register values  ( 9 in total)

parameter	set_lin_l	= 0;
parameter 	set_lin_r	= 1;
parameter 	set_head_l	= 2;
parameter	set_head_r	= 3;
parameter	a_path_cntrl = 4;
parameter 	d_path_cntrl = 5;
parameter	power_on		= 6;
parameter	set_format	= 7;
parameter	sample_cntrl = 8;
parameter 	set_active	= 9;

// video registers

parameter	set_video	= 10; //( beginning of video data load)

// config controllers [Audio and video]

always @ (posedge clk or negedge reset)

begin

	if (!reset)
	
		begin
		
		LUT_index	<= 0;
		mstep			<= 0;
		mgo			<= 0;
		
		end
		else
		
		begin
		
		if (LUT_index < LUT_size)
		begin
		
			case(mstep)
			0: begin
					if (SCLK)
					if(LUT_index < set_video)
					
					i2c_data <= {8'h34,LUT_data};
					else
					i2c_data <= {8'h40,LUT_data};
					mgo <= 1;
					mstep <= 1;
				end
				
			1: begin
			
					if (mend)
					begin
					
						if (mack)
						mstep <= 2;
						else
						mstep <= 0;
						mgo <= 0;
						end
					end
					
			2: begin
			
					LUT_index <= LUT_index + 1;
					mstep <= 0;
					
					end
					
				endcase
			end
		end
	end
				


always 

begin

case ( LUT_index)				

// audio config values

set_lin_l		: LUT_data <= 16'h001a;
set_lin_r		: LUT_data <= 16'h021a;
set_head_l		: LUT_data <= 16'h047b;
set_head_r		: LUT_data <= 16'h067b;
a_path_cntrl	: LUT_data <= 16'h08f8;
d_path_cntrl	: LUT_data <= 16'h0a06;
power_on			: LUT_data <= 16'h0c00;
set_format		: LUT_data <= 16'h0e01;
sample_cntrl 	: LUT_data <= 16'h1002;
set_active		: LUT_data <= 16'h1201;
// video config values
set_video+0 	: LUT_data <= 16'h0000;
set_video+1 	: LUT_data <= 16'hc301;
set_video+2 	: LUT_data <= 16'hc480;
set_video+3 	: LUT_data <= 16'h0457;
set_video+4 	: LUT_data <= 16'h1741;
set_video+5 	: LUT_data <= 16'h5801;
set_video+6 	: LUT_data <= 16'h3da2;
set_video+7 	: LUT_data <= 16'h37a0;
set_video+8 	: LUT_data <= 16'h3e6a;
set_video+9 	: LUT_data <= 16'h3fa0;
set_video+10 	: LUT_data <= 16'h0e80;
set_video+11 	: LUT_data <= 16'h5581;
set_video+12 	: LUT_data <= 16'h37a0;
set_video+13	: LUT_data <= 16'h0880;
set_video+14 	: LUT_data <= 16'h0a18;
set_video+15 	: LUT_data <= 16'h2c8e;
set_video+16 	: LUT_data <= 16'h2df8;
set_video+17 	: LUT_data <= 16'h2ece;
set_video+18 	: LUT_data <= 16'h2ff4;
set_video+19 	: LUT_data <= 16'h30b2;
set_video+20 	: LUT_data <= 16'h3102;
set_video+21 	: LUT_data <= 16'h0e00;

endcase

end

endmodule