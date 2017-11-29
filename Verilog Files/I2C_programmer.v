

 //-----------------------------------------------------
 // Design Name : encoder_using_case
 // File Name   : encoder_using_case.v
 // Function    : Encoder using Case
 // Coder       : Fred Aulich
 // last update Dec 19th 2013 changed the way program clock is set up SCLK  and SDO
 //-----------------------------------------------------
 module I2C_programmer(
 

 RESET,			//  2 MHz clock enable 
 i2c_clk,		//  27 Mhz clk from DE2
 I2C_SCLK,		// I2C clock 40K
 TRN_END,
 ACK,
 ACK_enable,
 I2C_SDATA		// bi directional serial data 
 );
 
 output	I2C_SCLK;
 output  TRN_END;
 output	ACK;
 output  ACK_enable;
 inout   I2C_SDATA;
 
 input i2c_clk;
 input RESET; // 27 MHz clock enable
 
 
 
 ///////////////////////////////
 //// internal register ////////
 ///////////////////////////////
 
 reg [15:0] mi2c_clk_div;  // clock divider
 reg [23:0] SD;				// serial shift register I2C data
 reg [6:0] SD_COUNTER;		// shift counter
 
 reg mi2c_ctrl_clk;			// output 40k clock
 reg SCLK;						// serial clock variable
 reg TRN_END;					// end of each serial load
 reg SDO;
 reg CLOCK;
////////////////////////////////////////////////////////////////////
/// module for loading values to the video and audio register  /////
////////////////////////////////////////////////////////////////////

 i2c_av_cfg  u0 (
			.clk(mi2c_ctrl_clk),
			.reset(RESET),
			.mend(TRN_END),
			.mack(ACK),
			.mgo(GO),
			.SCLK(SCLK),
			.mstep(mstep),
			.i2c_data(data_23)			
			);
			
////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////
 
wire I2C_SCLK = !TRN_END ? SCLK : 1;
 wire I2C_SDATA = ACK_enable ? SDO : 1'bz;
 
 reg ACK_enable;
 reg ACK1,ACK2,ACK3;
 wire ACK = ACK1 | ACK2 | ACK3;
 wire [23:0] data_23;
 wire GO;
 wire[3:0] mstep;
 
 parameter clk_freq = 27000000;  // 27 Mhz
 parameter i2c_freq = 40000;     // 40 Khz


	
 ///////////////////////////////////////////////////////
 ////// I2C clock (50 Mhz)used for DE2 video in chip ///
 ///////////////////////////////////////////////////////
	
  always @ (posedge i2c_clk or negedge RESET)
  begin
		if (!RESET)
		begin
			mi2c_clk_div <= 0;
			mi2c_ctrl_clk <= 0;
		end
		
		else
		
		begin
		
			if (mi2c_clk_div <  (clk_freq/i2c_freq) )  // keeps dividing until reaches desired frequency
			mi2c_clk_div <= mi2c_clk_div + 1;
			
			else
			begin 
					mi2c_clk_div <= 0;
					mi2c_ctrl_clk <= ~mi2c_ctrl_clk;
			end
		end
	end
	
	always @(negedge RESET or posedge CLOCK) begin
	if (!RESET) SD_COUNTER =  7 'b1111111;
	else begin
	if (GO==0)
		SD_COUNTER=0;
		else
		if ((SD_COUNTER < 7 'b1110111) & (TRN_END ==0)) SD_COUNTER = SD_COUNTER + 1;
	end
	end
	
 ///////////////////////////////////////////
 // counter to serially shift bits into  ///
 // I2C data register                    ///
 ///////////////////////////////////////////
 
 always @ (negedge RESET or posedge CLOCK) begin
 
 if (!RESET) begin ACK1 = 0; ACK2 = 0; ACK3 = 0; TRN_END = 1;  ACK_enable = 1; SCLK = 1; SDO = 1; end
 else
 case (SD_COUNTER)
 
 
	
	7'd0	: begin ACK1 = 0; ACK2 = 0; ACK3 = 0; TRN_END = 0; SDO = 1; SCLK = 1; ACK_enable =1; end
		7'd1	: begin SD= (data_23); SDO = 0; end
		// begin load
		// slave address
		7'd2	: begin SDO = SD[23]; SCLK = 0; end 		
		7'd3	: begin SDO = SD[23]; SCLK = 1; end
		7'd4	: begin SDO = SD[23]; SCLK = 1; end
		7'd5	: begin SDO = SD[23]; SCLK = 0; end
		
		7'd6	: begin SDO = SD[22]; SCLK = 0; end
		7'd7	: begin SDO = SD[22]; SCLK = 1; end
		7'd8	: begin SDO = SD[22]; SCLK = 1; end
		7'd9  : begin SDO = SD[22]; SCLK = 0; end
		
		7'd10	: begin SDO = SD[21]; SCLK = 0; end
		7'd11	: begin SDO = SD[21]; SCLK = 1; end
		7'd12	: begin SDO = SD[21]; SCLK = 1; end
		7'd13 : begin SDO = SD[21]; SCLK = 0; end
		
		7'd14	: begin SDO = SD[20]; SCLK = 0; end
		7'd15 : begin SDO = SD[20]; SCLK = 1; end
		7'd16 : begin SDO = SD[20]; SCLK = 1; end
		7'd17 : begin SDO = SD[20]; SCLK = 0; end
		
		7'd18 : begin SDO = SD[19]; SCLK = 0; end
		7'd19 : begin SDO = SD[19]; SCLK = 1; end
		7'd20 : begin SDO = SD[19]; SCLK = 1; end
		7'd21	: begin SDO = SD[19]; SCLK = 0; end
		
		7'd22 : begin SDO = SD[18]; SCLK = 0; end
		7'd23 : begin SDO = SD[18]; SCLK = 1; end
		7'd24 : begin SDO = SD[18]; SCLK = 1; end
		7'd25 : begin SDO = SD[18]; SCLK = 0; end
		
		7'd26	: begin SDO = SD[17]; SCLK = 0; end
		7'd27	: begin SDO = SD[17]; SCLK = 1; end
		7'd28	: begin SDO = SD[17]; SCLK = 1; end
		7'd29 : begin SDO = SD[17]; SCLK = 0; end
		
		7'd30 : begin SDO = SD[16]; SCLK = 0; end
		7'd31 : begin SDO = SD[16]; SCLK = 1; end
		7'd32 : begin SDO = SD[16]; SCLK = 1; end
		7'd33	: begin SDO = SD[16]; SCLK = 0; end
		// acknowledge cycle begin
		7'd34 : begin SDO = 0; SCLK = 0; end
		7'd35 : begin SDO = 0; SCLK = 1; end
		7'd36 : begin SDO = 0; SCLK = 1; end
		7'd37 : begin ACK1=I2C_SDATA; SCLK = 0; ACK_enable = 0 ;  end // tri state 
		7'd38 : begin ACK1=I2C_SDATA; SCLK = 0; ACK_enable = 0 ; end
		7'd39 : begin SDO = 0; SCLK = 0; ACK_enable = 1 ; end
		// sub address
		7'd40	: begin SDO = SD[15]; SCLK = 0; end 		
		7'd41	: begin SDO = SD[15]; SCLK = 1; end
		7'd42	: begin SDO = SD[15]; SCLK = 1; end
		7'd43	: begin SDO = SD[15]; SCLK = 0; end
		
		7'd44	: begin SDO = SD[14]; SCLK = 0; end
		7'd45	: begin SDO = SD[14]; SCLK = 1; end
		7'd46	: begin SDO = SD[14]; SCLK = 1; end
		7'd47 : begin SDO = SD[14]; SCLK = 0; end
		
		7'd48	: begin SDO = SD[13]; SCLK = 0; end
		7'd49	: begin SDO = SD[13]; SCLK = 1; end
		7'd50	: begin SDO = SD[13]; SCLK = 1; end
		7'd51 : begin SDO = SD[13]; SCLK = 0; end
		
		7'd52	: begin SDO = SD[12]; SCLK = 0; end
		7'd53 : begin SDO = SD[12]; SCLK = 1; end
		7'd54 : begin SDO = SD[12]; SCLK = 1; end
		7'd55 : begin SDO = SD[12]; SCLK = 0; end
		
		7'd56 : begin SDO = SD[11]; SCLK = 0; end
		7'd57 : begin SDO = SD[11]; SCLK = 1; end
		7'd58 : begin SDO = SD[11]; SCLK = 1; end
		7'd59	: begin SDO = SD[11]; SCLK = 0; end
		
		7'd60 : begin SDO = SD[10]; SCLK = 0; end
		7'd61 : begin SDO = SD[10]; SCLK = 1; end
		7'd62 : begin SDO = SD[10]; SCLK = 1; end
		7'd63 : begin SDO = SD[10]; SCLK = 0; end
		
		7'd64	: begin SDO = SD[9]; SCLK = 0; end
		7'd65	: begin SDO = SD[9]; SCLK = 1; end
		7'd66	: begin SDO = SD[9]; SCLK = 1; end
		7'd67 : begin SDO = SD[9]; SCLK = 0; end
		
		7'd68 : begin SDO = SD[8]; SCLK = 0; end
		7'd69 : begin SDO = SD[8]; SCLK = 1; end
		7'd70 : begin SDO = SD[8]; SCLK = 1; end
		7'd71	: begin SDO = SD[8]; SCLK = 0; end
		// acknowledge cycle begin
		7'd72 : begin SDO = 0; SCLK = 0; end
		7'd73 : begin SDO = 0; SCLK = 1; end
		7'd74 : begin SDO = 0; SCLK = 1; end
		7'd75 : begin ACK1=I2C_SDATA; SCLK = 0; ACK_enable = 0 ;  end // tri state 
		7'd76 : begin ACK1=I2C_SDATA; SCLK = 0; ACK_enable = 0 ; end
		7'd77 : begin SDO = 0; SCLK = 0; ACK_enable = 1 ; end
		// data
		7'd78	: begin SDO = SD[7]; SCLK = 0; end 		
		7'd79	: begin SDO = SD[7]; SCLK = 1; end
		7'd80	: begin SDO = SD[7]; SCLK = 1; end
		7'd81	: begin SDO = SD[7]; SCLK = 0; end
		
		7'd82	: begin SDO = SD[6]; SCLK = 0; end
		7'd83	: begin SDO = SD[6]; SCLK = 1; end
		7'd84	: begin SDO = SD[6]; SCLK = 1; end
		7'd85 : begin SDO = SD[6]; SCLK = 0; end
		
		7'd86	: begin SDO = SD[5]; SCLK = 0; end
		7'd87	: begin SDO = SD[5]; SCLK = 1; end
		7'd88	: begin SDO = SD[5]; SCLK = 1; end
		7'd89 : begin SDO = SD[5]; SCLK = 0; end
		
		7'd90	: begin SDO = SD[4]; SCLK = 0; end
		7'd91 : begin SDO = SD[4]; SCLK = 1; end
		7'd92 : begin SDO = SD[4]; SCLK = 1; end
		7'd93 : begin SDO = SD[4]; SCLK = 0; end
		
		7'd94 : begin SDO = SD[3]; SCLK = 0; end
		7'd95 : begin SDO = SD[3]; SCLK = 1; end
		7'd96 : begin SDO = SD[3]; SCLK = 1; end
		7'd97	: begin SDO = SD[3]; SCLK = 0; end
		
		7'd98 : begin SDO = SD[2]; SCLK = 0; end
		7'd99 : begin SDO = SD[2]; SCLK = 1; end
		7'd100: begin SDO = SD[2]; SCLK = 1; end
		7'd101: begin SDO = SD[2]; SCLK = 0; end
		
		7'd102: begin SDO = SD[1]; SCLK = 0; end
		7'd103: begin SDO = SD[1]; SCLK = 1; end
		7'd104: begin SDO = SD[1]; SCLK = 1; end
		7'd105: begin SDO = SD[1]; SCLK = 0; end
		
		7'd106: begin SDO = SD[0]; SCLK = 0; end
		7'd107: begin SDO = SD[0]; SCLK = 1; end
		7'd108: begin SDO = SD[0]; SCLK = 1; end
		7'd109: begin SDO = SD[0]; SCLK = 0; end
		// acknowledge cycle begin
		7'd110: begin SDO = 0; SCLK = 0; end
		7'd111: begin SDO = 0; SCLK = 1; end
		7'd112: begin SDO = 0; SCLK = 1; end
		7'd113: begin ACK1=I2C_SDATA; SCLK = 0; ACK_enable = 0 ;  end // tri state 
		7'd114: begin ACK1=I2C_SDATA; SCLK = 0; ACK_enable = 0 ; end
		7'd115: begin SDO = 0; SCLK = 0; ACK_enable = 1 ; end
		// stop
		7'd116: begin SCLK = 1'b0; SDO = 1'b0; end 
		7'd117: SCLK = 1'b1;
		7'd118: begin SDO = 1'b1; TRN_END = 1'b1; end
		
		endcase
		end
			
 ///////////////////////////////////////////
 // directing signals to GPIO bus //////////
 ///////////////////////////////////////////

 always 	CLOCK <= mi2c_ctrl_clk;

 endmodule

	
	