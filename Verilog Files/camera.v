// video in module for the DE1-SoC board
// Sept 20 2017
// by Fred Aulich
// 
// camera input size is 624 X 420 [odd lines 624 X 210] + [even lines 624 X 210] 

module camera (
clk_27,		// 27 Mhz clock
vid_vs,		// vertical sync
vid_hs,		// horizontal sync
address_cam, // address counter for video in signal
vid_address,
video_in,    // 8 bits video in
data_caml,   // lower 8 bits storage buffer
data_camh,   // upper 8 bits storage buffer
vid_ldll,	 // 
vid_ldlh,
//vid_ldhl,
vid_ldhh,
vid_udll,
vid_udlh,
//vid_udhl,
vid_udhh,
we_cam
);


// signal identification

input 		clk_27; 		
inout 		vid_hs; 		
inout 		vid_vs; 		
input[7:0] 	video_in;

output[15:0] address_cam;
output[23:0] data_caml;
output[23:0] data_camh;
output		vid_ldll;
output		vid_ldlh;
//output		vid_ldhl;
output		vid_ldhh;
output		vid_udll;
output		vid_udlh;
//output		vid_udhl;
output		vid_udhh;

output		we_cam;

reg[15:0] address_cam;
reg[23:0] data_caml;
reg[23:0] data_camh;

//internal registers

reg[10:0] horizontal; 
reg[17:0] timer1;
reg[2:0]  timer2;
output reg[17:0] vid_address;

wire[7:0] video_in;

wire vid_ldll = (frame & !timer2[0] & !vid_address[1] & !vid_address[0]) ? 1'b1 : 1'b0;
wire vid_udll = (frame & timer2[0] & !vid_address[1] & !vid_address[0]) ? 1'b1 : 1'b0; // low byte even address enable



//wire vid_ldll = (frame & !timer2[0] & !vid_address[1] & !vid_address[0] & clk_27 ) ? 1'b1 : 1'b0; // low byte odd address enable
wire vid_ldlh = (frame & !timer2[0] & !vid_address[1] & vid_address[0] & clk_27 ) ? 1'b1 : 1'b0; // low byte odd address enable
//wire vid_ldhl = (frame & !timer2[0] & vid_address[1] & !vid_address[0] & clk_27 ) ? 1'b1 : 1'b0; // high byte odd address enable
wire vid_ldhh = (frame & !timer2[0] & vid_address[1] & vid_address[0] & clk_27 ) ? 1'b1 : 1'b0; // high byte odd address enable
//wire vid_udll = (frame & timer2[0] & !vid_address[1] & !vid_address[0] & clk_27 ) ? 1'b1 : 1'b0; // low byte even address enable
wire vid_udlh = (frame & timer2[0] & !vid_address[1] & vid_address[0] & clk_27 ) ? 1'b1 : 1'b0; // low byte even address enable
//wire vid_udhl = (frame & timer2[0] & vid_address[1] & !vid_address[0] & clk_27 ) ? 1'b1 : 1'b0; // high byte even address enable
wire vid_udhh = (frame & timer2[0] & vid_address[1] & !vid_address[0] & clk_27 ) ? 1'b1 : 1'b0; // high byte even address enable

wire we_cam = (frame & !vid_address[0] & clk_27 ) ? 1'b1 : 1'b0; // write enable memory


wire vert = ( ( timer1 > 30 &  timer1 <= 240 ) ) ? 1'b1 : 1'b0; // adjust vertical sync
wire horiz = ( ( horizontal > 300 & horizontal <= 1548) ) ? 1'b1 : 1'b0; // adjust horizontal sync
wire frame = ( horiz  & vert) ? 1'b1 : 1'b0 ; // address range enable


parameter address_0 = 16'h00000;  // lower address start at 0 meg



///////////////////////////////////////////////
///// counter for each 1/2 frame  (vert)	   //
///////////////////////////////////////////////
always @ (posedge vid_hs)
begin
	
	if (! vid_vs)
		timer1 <= address_0;
		else
		
		begin
		
		timer1 <= timer1 + 1;
		end
	end
	
//////////////////////////////////////////////	
////// counter for each 1/2 frame			 ///
//////////////////////////////////////////////

always @ (posedge  vid_vs)
begin

		timer2 <= timer2 + 1;
end

//////////////////////////////////////////////
//// horizontal counter							 ///
//////////////////////////////////////////////
always @(posedge clk_27 )

begin
		if (vid_hs)
		horizontal <= 0;
	
		else
		
		begin
		horizontal <= horizontal + 1;
		end

end		

/////////////////////////////////////////
// address counter  memory				  ///
/////////////////////////////////////////

always @ (posedge clk_27)

begin

	if (!vert)	
		begin
			vid_address <= address_0;
		end
		
		else
		
		begin	
		if (frame)
			vid_address <= vid_address + 1;
		end
		
end



//////////////////////////////////////////////
// latch video data and address 				 ///
//////////////////////////////////////////////

always @ (negedge clk_27)

begin

/////////////////////////////////////////
// odd bytes memory frame load 		  ///
/////////////////////////////////////////
	if ( vid_ldll )
		
			begin
			address_cam <= vid_address[17:2]; // low byte 
			data_caml[7:0] <= video_in; // y value
			end
			
		else
		
			if ( vid_ldlh )
		
			begin
			address_cam <= vid_address[17:2]; // low byte 
			data_caml[15:8] <= video_in; // Cb value
			end
			
//		else
		
//			if ( vid_ldhl )
//		
//			begin
//			address_cam <= vid_address[17:2]; // high byte
//			data_caml[23:16] <= video_in;
//			end
			
		else
		
			if ( vid_ldhh )
		
			begin
			address_cam <= vid_address[17:2]; // high byte
			data_caml[23:16] <= video_in; // cr value
			end
			
		else

/////////////////////////////////////////
// even bytes memory frame load 		  ///
/////////////////////////////////////////			
		
		if ( vid_udll )
		
			begin
			address_cam <= vid_address[17:2]; // low byte
			data_camh[7:0] <= video_in; // y value
			end
			
		else
		
			if ( vid_udlh )
		
			begin
			address_cam <= vid_address[17:2]; // low byte
			data_camh[15:8] <= video_in; // cb value
			end
			
//		else
//						
//			if ( vid_udhl )
//		
//			begin
//			address_cam <= vid_address[17:2]; // high byte
//			data_camh[23:16] <= video_in;
//			end
			
		else
							
			if ( vid_udhh )
		
			begin
			address_cam <= vid_address[17:2]; // high byte
			data_camh[23:16] <= video_in; //cr value
			end

	end

endmodule	
	