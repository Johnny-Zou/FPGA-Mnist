module finalProject(
	KEY,
	CLOCK_50,
	LEDR,
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B,   						//	VGA Blue[9:0]

	//I2C controller
	FPGA_I2C_SCLK,
	FPGA_I2C_SDAT,
	TD_CLK27,
	TD_DATA,
	TD_HS,
	TD_RESET_N,
	TD_VS,
	HEX0,
	SW,

	);
	input CLOCK_50;
	input [2:0] KEY;
		//key 0 is reset
		//key 1 is the next button when you are beginning
		//key 2 is a test key
	input [8:0] SW;

	output [9:0] LEDR;
		// ouput whatever number it is
	output [6:0] HEX0;

	//vga outputs
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	wire doneLoadingImage;
	wire resetn;
	reg go;

	//video and i2c
	inout FPGA_I2C_SCLK;
	inout FPGA_I2C_SDAT;
	input TD_CLK27;
	input [7:0] TD_DATA;
	input TD_HS;
	output TD_RESET_N;
	input TD_VS;

	wire done_First;
	wire done_Second;
	wire done_Output;
	wire done_Selecting;
	wire done_Drawing;

	//enable signals
	wire load_firstLayer, load_secondLayer, load_outputLayer, load_result;

	wire load_resetFirstLayer, load_resetSecondLayer, load_resetOutputLayer;

	wire load_drawing, load_resetNumbers;

	//addresses
	wire [9:0] imageRAM_address;
	wire [15:0] layer1_weight_address;
	wire [5:0] layer1_result_address;

	wire [10:0] layer2_weight_address;
	wire [4:0] layer2_result_address;

	wire [8:0] layerOutput_weight_address;
	wire [3:0] layerOutput_result_address;

	//data
	wire [14:-17] imgRAMdata;
	wire [14:-17] layer1RAMdata;
	wire [14:-17] layer2RAMdata;
	wire [14:-17] layerOutputRAMdata;

	wire [14:-17] resultRAM_1_input;
	wire [14:-17] resultRAM_1_output;

	wire [14:-17] resultRAM_2_input;
	wire [14:-17] resultRAM_2_output;

	wire [14:-17] resultRAM_OUTPUT_input;
	wire [14:-17] resultRAM_OUTPUT_output;

	wire [9:0] resultingNumber;

	wire [23:0] drawingColor;
	wire drawPulse;
	wire [7:0] position_x;
	wire [6:0] position_y;

	
	wire [3:0] state;


	//loading image module
	wire [14:-17] imgRAM_dataInB;
	wire [14:-17] imgRAMdataB;
	wire [9:0] imageRAM_addressB;
	wire writeImageB;
	wire beginLoadingImage;

	assign resetn = KEY[0];
	assign TD_RESET_N = resetn;

	reg [4:0] waitTimer;


	//selecting images
	wire [7:0] img0RAM,img1RAM,img2RAM,img3RAM,img4RAM,img5RAM,img6RAM,img7RAM,img8RAM,img9RAM;
	wire [9:0] SelectImageRAM_address;

	always @(posedge CLOCK_50) begin
		if (!resetn) begin
			// reset
			go <= 1'b0;
			waitTimer <= 5'd0;
		end
		else if (doneLoadingImage) begin
			if(waitTimer == 5'd30)begin
				go <= 1'b1;
			end
			else begin
				waitTimer = waitTimer + 1;
			end
		end
		else begin
			go <= 1'b0;
			waitTimer <= 5'd0;
		end
	end

	imageLoad img(
		.beginLoadingImage(beginLoadingImage),
		.TD_CLK27(TD_CLK27),
		.resetn(resetn),
		.imgRAM_dataInB(imgRAM_dataInB),
		.imageRAM_addressB(imageRAM_addressB),
		.writeImageB(writeImageB),
		.doneLoadingImage(doneLoadingImage),
		.TD_VS(TD_VS),
		.TD_HS(TD_HS),
		.TD_DATA(TD_DATA),
		.SW(SW[8:0]),
	);

	I2C_programmer i2cprog_0(
		.RESET(resetn),			//  27 MHz clock enable 
		.i2c_clk(TD_CLK27),		//  27 Mhz clk from DE2
		.I2C_SCLK(FPGA_I2C_SCLK),		// I2C clock 40K
		.TRN_END(),
		.ACK(),
		.ACK_enable(),
		.I2C_SDATA(FPGA_I2C_SDAT)		// bi directional serial data 
	);

	control C0(
		//inputs

		.clk(CLOCK_50),
		.resetn(resetn),
		.go(go),
		.testkey(KEY[2]),

		.done_First(done_First),
		.done_Second(done_Second),
		.done_Output(done_Output),
		.done_Selecting(done_Selecting),
		.done_Drawing(done_Drawing),

		//outputs
		.beginLoadingImage(beginLoadingImage),
		.load_firstLayer(load_firstLayer),
		.load_secondLayer(load_secondLayer),
		.load_outputLayer(load_outputLayer),
		.load_result(load_result),

		.load_resetFirstLayer(load_resetFirstLayer),
		.load_resetSecondLayer(load_resetSecondLayer),
		.load_resetOutputLayer(load_resetOutputLayer),
		.load_drawing(load_drawing),
		.load_resetNumbers(load_resetNumbers),
		.state(state)
	);//-------

	dataPath D0(
		//inputs
		.clk(CLOCK_50),
		.resetn(resetn),

		.done_First(done_First),
		.done_Second(done_Second),
		.done_Output(done_Output),
		.done_Selecting(done_Selecting),
		.done_Drawing(done_Drawing),

		.load_firstLayer(load_firstLayer),
		.load_secondLayer(load_secondLayer),
		.load_outputLayer(load_outputLayer),
		.load_result(load_result),


		.load_resetFirstLayer(load_resetFirstLayer),
		.load_resetSecondLayer(load_resetSecondLayer),
		.load_resetOutputLayer(load_resetOutputLayer),
		.load_resetNumbers(load_resetNumbers),

		.load_drawing(load_drawing),

		.imageRAM_address(imageRAM_address),
		.layer1_weight_address(layer1_weight_address),
		.layer1_result_address(layer1_result_address),

		.layer2_weight_address(layer2_weight_address),
		.layer2_result_address(layer2_result_address),

		.layerOutput_weight_address(layerOutput_weight_address),
		.layerOutput_result_address(layerOutput_result_address),

		.imgRAMdata(imgRAMdata),
		.layer1RAMdata(layer1RAMdata),
		.layer2RAMdata(layer2RAMdata),
		.layerOutputRAMdata(layerOutputRAMdata),

		.resultRAM_1_input(resultRAM_1_input),
		.resultRAM_1_output(resultRAM_1_output),
		.resultRAM_2_input(resultRAM_2_input),
		.resultRAM_2_output(resultRAM_2_output),
		.resultRAM_OUTPUT_input(resultRAM_OUTPUT_input),
		.resultRAM_OUTPUT_output(resultRAM_OUTPUT_output),
		.resultingNumber(resultingNumber),

		.drawPulse(drawPulse),
		.drawingColor(drawingColor),
		.position_x(position_x),
		.position_y(position_y),

		.img0RAM(img0RAM),
		.img1RAM(img1RAM),
		.img2RAM(img2RAM),
		.img3RAM(img3RAM),
		.img4RAM(img4RAM),
		.img5RAM(img5RAM),
		.img6RAM(img6RAM),
		.img7RAM(img7RAM),
		.img8RAM(img8RAM),
		.img9RAM(img9RAM),
		.SelectImageRAM_address(SelectImageRAM_address)
	);

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(drawingColor),
			.x(position_x),
			.y(position_y),
			.plot(drawPulse),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 8;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	//instantiate RAM modules
	imgRAM_readOnly imgRAM(
		//port A
		.inputData(32'b0), //doesnt matter wont need to store into here
		.outputData(imgRAMdata),
		.address(imageRAM_address),
		.writeEnable(1'b0), //always low as do not need to write to this RAM module
		.clock(CLOCK_50),

		//port B
		.inputDataB(imgRAM_dataInB),
		.outputDataB(imgRAMdataB),
		.addressB(imageRAM_addressB),
		.writeEnableB(writeImageB),
		.clock27(TD_CLK27)

	);

	weightRAM_layer1 weightRAM_1(
		.inputData(32'b0), //doesnt matter wont need to store into here
		.outputData(layer1RAMdata), //
		.address(layer1_weight_address),
		.writeEnable(1'b0), //always low as do not need to write to this RAM module
		.clock(CLOCK_50)
	);

	resultRAM_layer1 resultRAM_1(
		.inputData(resultRAM_1_input), //new input data
		.outputData(resultRAM_1_output), //ouput data to go into the 2nd layer inputs
		.address(layer1_result_address),
		.writeEnable(load_firstLayer), //always high when on load_first_layer as do not need to write to this RAM module
		.clock(CLOCK_50)
	);


	weightRAM_layer2 weightRAM_2(
		.inputData(32'b0),
		.outputData(layer2RAMdata),
		.address(layer2_weight_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	resultRAM_layer2 resultRAM_2(
		.inputData(resultRAM_2_input),
		.outputData(resultRAM_2_output),
		.address(layer2_result_address),
		.writeEnable(load_secondLayer),
		.clock(CLOCK_50)
	);


	weightRAM_outputLayer weightRAM_output(
		.inputData(32'b0),
		.outputData(layerOutputRAMdata),
		.address(layerOutput_weight_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	resultRAM_outputLayer resultRAM_output(
		.inputData(resultRAM_OUTPUT_input),
		.outputData(resultRAM_OUTPUT_output),
		.address(layerOutput_result_address),
		.writeEnable(load_outputLayer),
		.clock(CLOCK_50)
	);

	imageRAM0 imageram0(
		.inputData(8'b0),
		.outputData(img0RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	imageRAM1 imageram1(
		.inputData(8'b0),
		.outputData(img1RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	imageRAM2 imageram2(
		.inputData(8'b0),
		.outputData(img2RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	imageRAM3 imageram3(
		.inputData(8'b0),
		.outputData(img3RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	imageRAM4 imageram4(
		.inputData(8'b0),
		.outputData(img4RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	imageRAM5 imageram5(
		.inputData(8'b0),
		.outputData(img5RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	imageRAM6 imageram6(
		.inputData(8'b0),
		.outputData(img6RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	imageRAM7 imageram7(
		.inputData(8'b0),
		.outputData(img7RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	imageRAM8 imageram8(
		.inputData(8'b0),
		.outputData(img8RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);

	imageRAM9 imageram9(
		.inputData(8'b0),
		.outputData(img9RAM),
		.address(SelectImageRAM_address),
		.writeEnable(1'b0),
		.clock(CLOCK_50)
	);


	//assign the LEDR
	assign LEDR[9:0] = resultingNumber[9:0];

	hex_decoder hex0(state,HEX0);

endmodule

module control(
	clk,
	resetn,
	go,
	testkey,

	done_First,
	done_Second,
	done_Output,
	done_Selecting,
	done_Drawing,

	beginLoadingImage,
	load_firstLayer,
	load_secondLayer,
	load_outputLayer,
	load_result,

	load_resetFirstLayer,
	load_resetSecondLayer,
	load_resetOutputLayer,
	load_drawing,
	load_resetNumbers,
	state,
	);

	input clk;
	input resetn;
	input go;
	input testkey;

	//signals from the datapath
	input done_First;
	input done_Second;
	input done_Output;
	input done_Selecting;
	input done_Drawing;

	//outputs here
	output reg beginLoadingImage;

	output reg load_firstLayer;
	output reg load_secondLayer;
	output reg load_outputLayer;
	output reg load_result;

	output reg load_resetFirstLayer;
	output reg load_resetSecondLayer;
	output reg load_resetOutputLayer;
	output reg load_drawing;
	output reg load_resetNumbers;

	output [3:0] state;
	assign state = current_state;

	//states
	reg [3:0] current_state, next_state;

	//states here
	localparam			load_imageRAM 					= 4'd1,
						load_firstResultRAM				= 4'd2,
						load_resetFirst 				= 4'd3,
						load_secondResultRAM			= 4'd4,
						load_resetSecond 				= 4'd5,
						load_outputRAM					= 4'd6,
						load_resetOutput 				= 4'd7,
						display_mostLikely				= 4'd8,
						draw_image						= 4'd9,
						startOver						= 4'd10;

	always@(*)
	begin: state_table
		case(current_state)
			load_imageRAM: next_state = (go || ~testkey) ? load_firstResultRAM : load_imageRAM;

			load_firstResultRAM: next_state = done_First ? load_resetFirst : load_firstResultRAM;
			load_resetFirst: next_state = load_secondResultRAM;

			load_secondResultRAM: next_state = done_Second ? load_resetSecond : load_secondResultRAM;
			load_resetSecond: next_state = load_outputRAM;

			load_outputRAM: next_state = done_Output ? load_resetOutput : load_outputRAM;
			load_resetOutput: next_state = display_mostLikely;

			display_mostLikely: next_state = done_Selecting ? draw_image : display_mostLikely;
			draw_image: next_state = done_Drawing ? startOver : draw_image;
			startOver: next_state = load_imageRAM;

			default: next_state = load_imageRAM;
		endcase
	end

	always @(*) 
	begin: enable_signals
		// By default make all our signals 0
		beginLoadingImage = 1'b0;
        load_firstLayer = 1'b0;
        load_secondLayer = 1'b0;
        load_outputLayer = 1'b0;

        load_resetFirstLayer = 1'b0;
		load_resetSecondLayer = 1'b0;
		load_resetOutputLayer = 1'b0;

        load_result = 1'b0;
        load_drawing = 1'b0;
        load_resetNumbers = 1'b0;

        case(current_state)
			load_imageRAM: begin
				beginLoadingImage = 1'b1;
			end
			load_firstResultRAM: begin
				load_firstLayer = 1'b1;
			end
			load_resetFirst: begin
				load_resetFirstLayer = 1'b1;
			end
			load_secondResultRAM: begin
				load_secondLayer = 1'b1;
			end 
			load_resetSecond: begin
				load_resetSecondLayer = 1'b1;
			end
			load_outputRAM: begin
				load_outputLayer = 1'b1;
			end
			load_resetOutput: begin
				load_resetOutputLayer = 1'b1;
			end
			display_mostLikely: begin
				load_result = 1'b1;
			end
			draw_image: begin
				load_drawing = 1'b1;
			end
			startOver: begin
				load_resetNumbers = 1'b1;
			end
		endcase
	end // send the enable signals

	always@(posedge clk)
	begin: state_FFs
		if(!resetn)begin
			current_state <= load_imageRAM;
		end
		else begin
			current_state <= next_state;
		end
	end // state_FFs
endmodule

module dataPath(
	clk,
	resetn,
	done_First,
	done_Second,
	done_Output,
	done_Selecting,
	done_Drawing,

	load_firstLayer,
	load_secondLayer,
	load_outputLayer,
	load_result,

	load_resetFirstLayer,
	load_resetSecondLayer,
	load_resetOutputLayer,
	load_drawing,
	load_resetNumbers,

	imageRAM_address,
	layer1_weight_address,
	layer1_result_address,

	layer2_weight_address,
	layer2_result_address,

	layerOutput_weight_address,
	layerOutput_result_address,

	//input data
	imgRAMdata,
	layer1RAMdata,
	layer2RAMdata,
	layerOutputRAMdata,

	resultRAM_1_output,
	resultRAM_2_output,
	resultRAM_OUTPUT_output,

	//ouput data
	resultRAM_1_input,
	resultRAM_2_input,
	resultRAM_OUTPUT_input,

	resultingNumber,


	drawPulse,
	drawingColor,
	position_x,
	position_y,

	img0RAM,
	img1RAM,
	img2RAM,
	img3RAM,
	img4RAM,
	img5RAM,
	img6RAM,
	img7RAM,
	img8RAM,
	img9RAM,
	SelectImageRAM_address

	);
	input clk,resetn;
	
	input load_firstLayer,load_secondLayer,load_outputLayer,load_result;
	input load_resetFirstLayer, load_resetSecondLayer, load_resetOutputLayer;
	input load_drawing;
	input load_resetNumbers;

	//output addresses
	output reg [9:0] imageRAM_address;
	output reg [15:0] layer1_weight_address;
	output reg [5:0] layer1_result_address;

	output reg [10:0] layer2_weight_address;
	output reg [4:0] layer2_result_address;

	output reg [8:0] layerOutput_weight_address;
	output reg [3:0] layerOutput_result_address;

	//input data
	input signed [14:-17] imgRAMdata; //img ram
	input signed [14:-17] layer1RAMdata; // layer 1 weights
	input signed [14:-17] layer2RAMdata;
	input signed [14:-17] layerOutputRAMdata;

	input signed [14:-17] resultRAM_1_output; // result layer 1
	input signed [14:-17] resultRAM_2_output;
	input signed [14:-17] resultRAM_OUTPUT_output;

	//output data
	output [14:-17] resultRAM_1_input; //input into the result layer 1
	output [14:-17] resultRAM_2_input;
	output [14:-17] resultRAM_OUTPUT_input;


	//ledr data
	output reg [9:0] resultingNumber;

	//done signals
	output reg done_First;
	output reg done_Second;
	output reg done_Output;
	output reg done_Selecting;
	output reg done_Drawing;

	reg signed [29:-34] tempResultRAM_1;
	reg signed [29:-34] tempResultRAM_2;
	reg signed [29:-34] tempResultRAM_Output;

	assign resultRAM_1_input = tempResultRAM_1[14:-17];
	assign resultRAM_2_input = tempResultRAM_2[14:-17];
	assign resultRAM_OUTPUT_input = tempResultRAM_Output[14:-17];


	reg completeCalculation, maxCalculation, increment, increment_address, maxCalculation_wait,clockCycleReset, doneResettingForDrawing,donePositionSet,firstPixel;

	//max
	reg signed [14:-17] currentMaxVal = 32'b10000000000000000000000000000000;
	reg [3:0] maxAddress = 4'b0;

	//drawing stuff
	output reg drawPulse;
	output reg [7:0] position_x;
	output reg [6:0] position_y;

	output reg[23:0] drawingColor;

	//drawing selected image
	input [7:0] img0RAM,img1RAM,img2RAM,img3RAM,img4RAM,img5RAM,img6RAM,img7RAM,img8RAM,img9RAM;

	output reg [9:0] SelectImageRAM_address;
	reg doneResettingForDrawingSelect,donePositionSetSelecting,draw_Selected;


	always@(*)begin
		if(load_drawing == 1'b1)begin
			drawingColor = {imgRAMdata[-1:-8],imgRAMdata[-1:-8],imgRAMdata[-1:-8]};
		end
		else begin
			if(maxAddress == 4'd1)begin
				drawingColor = {img0RAM[7:0],img0RAM[7:0],img0RAM[7:0]};
			end
			else if(maxAddress == 4'd2)begin
				drawingColor = {img1RAM[7:0],img1RAM[7:0],img1RAM[7:0]};
			end
			else if(maxAddress == 4'd3)begin
				drawingColor = {img2RAM[7:0],img2RAM[7:0],img2RAM[7:0]};
			end
			else if(maxAddress == 4'd4)begin
				drawingColor = {img3RAM[7:0],img3RAM[7:0],img3RAM[7:0]};
			end
			else if(maxAddress == 4'd5)begin
				drawingColor = {img4RAM[7:0],img4RAM[7:0],img4RAM[7:0]};
			end
			else if(maxAddress == 4'd6)begin
				drawingColor = {img5RAM[7:0],img5RAM[7:0],img5RAM[7:0]};
			end
			else if(maxAddress == 4'd7)begin
				drawingColor = {img6RAM[7:0],img6RAM[7:0],img6RAM[7:0]};
			end
			else if(maxAddress == 4'd8)begin
				drawingColor = {img7RAM[7:0],img7RAM[7:0],img7RAM[7:0]};
			end
			else if(maxAddress == 4'd9)begin
				drawingColor = {img8RAM[7:0],img8RAM[7:0],img8RAM[7:0]};
			end
			else if(maxAddress == 4'd10)begin
				drawingColor = {img9RAM[7:0],img9RAM[7:0],img9RAM[7:0]};
			end
			else begin
				//default
				drawingColor = {imgRAMdata[-1:-8],imgRAMdata[-1:-8],imgRAMdata[-1:-8]};
			end
		end
	end

	always@(posedge clk)
	begin: addressCounter
		if(!resetn)begin
			currentMaxVal = 32'b10000000000000000000000000000000;
			maxAddress = 4'b0;
			imageRAM_address <= 0;
			layer1_weight_address <= 0;
			layer1_result_address <= 0;

			done_First <= 0;
			done_Second <= 0;
			done_Output <= 0;
			done_Selecting <= 0;
			done_Drawing <= 0;

			layer2_weight_address <= 0;
			layer2_result_address <= 0;

			layerOutput_weight_address <= 0;
			layerOutput_result_address <= 0;

			tempResultRAM_1 <= 64'd0;
			tempResultRAM_2 <= 64'd0;
			tempResultRAM_Output <= 64'd0;

			completeCalculation <= 1'b0;
			maxCalculation <= 1'b0;
			increment <= 1'b0;
			increment_address <= 1'b0;
			maxCalculation_wait <= 1'b0;
			clockCycleReset <= 1'b0;
			doneResettingForDrawing <= 1'b0;
			donePositionSet <= 1'b0;
			firstPixel <= 1'b0;

			position_x <= 8'b0;
			position_y <= 7'b0;

			doneResettingForDrawingSelect <= 0;
			donePositionSetSelecting <= 0;
			draw_Selected <= 0;
		end
		else begin
			if(load_firstLayer)begin //if loading first state
				if(increment) begin
					if(layer1_weight_address == 16'd50175)begin
						done_First = 1'b1;
					end
					else begin
						tempResultRAM_1 <= 0;
						imageRAM_address <= 10'd0;
						layer1_weight_address <= layer1_weight_address + 1;
					end
					increment <= 1'b0;
				end
				else if(increment_address)begin
					if(layer1_weight_address != 16'd50175)begin
						layer1_result_address <= layer1_result_address + 1; //increment here
					end
					increment_address <= 1'b0;
					increment <= 1'b1;
				end
				else if(maxCalculation_wait)begin //wait one clock cycle for the value to be stored in RAM module
					maxCalculation_wait <= 1'b0;
					increment_address <= 1'b1;
				end
				else if(maxCalculation)begin
					if(tempResultRAM_1[29] == 1'b1)begin
						tempResultRAM_1 <= 0;
					end
					else begin
						tempResultRAM_1 <= tempResultRAM_1;
					end
					maxCalculation <= 1'b0;
					maxCalculation_wait <= 1'b1;
				end
				else if(completeCalculation)begin
					tempResultRAM_1 <= tempResultRAM_1 + (imgRAMdata * layer1RAMdata);

					completeCalculation <= 1'b0;
					maxCalculation <= 1'b1;
				end
				else begin
					if(imageRAM_address == 10'd783)begin		//0 - 784 has 785 address, if its the last one, go back to 0
						completeCalculation <= 1'b1;
					end
					else begin
						//layer1_weights are counted here
						if(layer1_weight_address == 16'd50175)begin
							//do nothing
						end
						else begin
							layer1_weight_address <= layer1_weight_address + 1;
						end
						imageRAM_address <= imageRAM_address + 1;
					end
					//calculation here
					tempResultRAM_1 <= tempResultRAM_1 + (imgRAMdata * layer1RAMdata);
				end
			end
			else if(load_resetFirstLayer)begin
				layer1_result_address <= 6'd0;
				completeCalculation <= 1'b0;
				maxCalculation <= 1'b0;
				increment <= 1'b0;
				increment_address <= 1'b0;
				maxCalculation_wait <= 1'b0;
			end
			else if(load_secondLayer) begin // if loading second state
				if(increment)begin
					if(layer2_weight_address == 11'd2047)begin
						done_Second = 1'b1;
					end
					else begin
						tempResultRAM_2 <= 0;
						layer1_result_address <= 6'd0;
						layer2_weight_address <= layer2_weight_address + 1;
					end
					increment <= 1'b0;
				end
				else if(increment_address)begin
					if(layer2_weight_address != 11'd2047)begin
						layer2_result_address <= layer2_result_address + 1; //increment here
					end
					increment_address <= 1'b0;
					increment <= 1'b1;
				end
				else if(maxCalculation_wait)begin //wait one clock cycle for the value to be stored in RAM module
					maxCalculation_wait <= 1'b0;
					increment_address <= 1'b1;
				end
				else if(maxCalculation)begin                                  //loop through the result address
					if(tempResultRAM_2[29] == 1'b1) begin
						tempResultRAM_2 <= 0;
					end
					else begin
						tempResultRAM_2 <= tempResultRAM_2;
					end
					maxCalculation <= 1'b0;
					maxCalculation_wait <= 1'b1;
				end
				else if(completeCalculation)begin
					tempResultRAM_2 <= tempResultRAM_2 + (resultRAM_1_output * layer2RAMdata);

					completeCalculation <= 1'b0;
					maxCalculation <= 1'b1;
				end
				else begin
					if(layer1_result_address == 6'd63)begin		//0 - 63 has 64 address, if its the last one, go back to 0					
						completeCalculation <= 1'b1;
					end
					else begin
						//layer2_weights are counted here
						if(layer2_weight_address == 11'd2047)begin
							//do nothing
						end
						else begin
							layer2_weight_address <= layer2_weight_address + 1;
						end
						layer1_result_address <= layer1_result_address + 1;
					end	
					//calculation here
					tempResultRAM_2 <= tempResultRAM_2 + (resultRAM_1_output * layer2RAMdata);
				end
			end
			else if(load_resetSecondLayer)begin
				layer2_result_address <= 0;
				completeCalculation <= 1'b0;
				maxCalculation <= 1'b0;
				increment <= 1'b0;
				increment_address <= 1'b0;
				maxCalculation_wait <= 1'b0;
			end
			else if(load_outputLayer) begin // if loading output state
				if(increment)begin
					if(layerOutput_weight_address == 9'd319)begin //0-319 has 320 addresses
						done_Output = 1'b1;
					end
					else begin
						tempResultRAM_Output <= 0;
						layer2_result_address <= 5'd0;
						layerOutput_weight_address <= layerOutput_weight_address + 1;
					end
					increment <= 1'b0;
				end
				else if(increment_address)begin
					if(layerOutput_weight_address != 9'd319)begin 
						layerOutput_result_address <= layerOutput_result_address + 1; //increment here
					end

					increment_address <= 1'b0;
					increment <= 1'b1;
				end
				else if(maxCalculation_wait)begin //wait one clock cycle for the value to be stored in RAM module
					maxCalculation_wait <= 1'b0;
					increment_address <= 1'b1;
				end
				else if(maxCalculation)begin                                  //loop through the result address
					if(tempResultRAM_Output[29] == 1'b1)begin
						tempResultRAM_Output <= 0;
					end
					else begin
						tempResultRAM_Output <= tempResultRAM_Output;
					end
					maxCalculation <= 1'b0;
					maxCalculation_wait <= 1'b1;
				end
				else if(completeCalculation)begin
					tempResultRAM_Output <= tempResultRAM_Output + (resultRAM_2_output * layerOutputRAMdata);

					completeCalculation <= 1'b0;
					maxCalculation <= 1'b1;
				end
				else begin
					if(layer2_result_address == 5'd31)begin		//0 - 31 has 32 address, if its the last one, go back to 0
						completeCalculation <= 1'b1;
					end
					else begin
						//layer2_weights are counted here
						if(layerOutput_weight_address == 9'd319)begin //0-319 has 320 addresses
							//do nothing
						end
						else begin
							layerOutput_weight_address <= layerOutput_weight_address + 1;
						end
						layer2_result_address <= layer2_result_address + 1;
					end
					//caculation here
					tempResultRAM_Output <= tempResultRAM_Output + (resultRAM_2_output * layerOutputRAMdata);
				end
			end
			else if(load_resetOutputLayer)begin
				layerOutput_result_address <= 0;
				completeCalculation <= 1'b0;
				maxCalculation <= 1'b0;
				increment <= 1'b0;
				increment_address <= 1'b0;
				maxCalculation_wait <= 1'b0;
				clockCycleReset <= 1'b0;
			end
			else if(load_result)begin //determine the max
				if(draw_Selected)begin
					//counter to loop through the x and y coordinates
					//read the imageRAM and set the color 
					if(donePositionSetSelecting)begin
						drawPulse <= 1'b1;
						donePositionSetSelecting <= 1'b0;
						if(position_x == 8'd55 && position_y == 7'd27)begin
							done_Selecting <= 1'b1;
							draw_Selected <= 1'b0;
						end
					end
					else if(doneResettingForDrawingSelect)begin
						drawPulse <= 1'b0;
						if(firstPixel)begin
							firstPixel <= 1'b0;
						end
						else begin
							if(position_x == 8'd55)begin
								position_x <= 8'd28;
								position_y <= position_y + 1;
							end
							else begin
								position_x <= position_x + 1;
							end
							SelectImageRAM_address <= SelectImageRAM_address + 1;
						end
						donePositionSetSelecting <= 1'b1;
					end
					else begin
						//reset the image address
						position_x <= 8'd28;
						position_y <= 7'b0;
						SelectImageRAM_address <= 0;
						doneResettingForDrawingSelect <= 1'b1;
						firstPixel <= 1'b1;
					end
				end
				if(layerOutput_result_address == 4'd11)begin
					if(maxAddress == 4'd1)begin
						resultingNumber <= 10'b0000000001;
					end
					else if(maxAddress == 4'd2)begin
						resultingNumber <= 10'b0000000010;
					end
					else if(maxAddress == 4'd3)begin
						resultingNumber <= 10'b0000000100;
					end
					else if(maxAddress == 4'd4)begin
						resultingNumber <= 10'b0000001000;
					end
					else if(maxAddress == 4'd5)begin
						resultingNumber <= 10'b0000010000;
					end
					else if(maxAddress == 4'd6)begin
						resultingNumber <= 10'b0000100000;
					end
					else if(maxAddress == 4'd7)begin
						resultingNumber <= 10'b0001000000;
					end
					else if(maxAddress == 4'd8)begin
						resultingNumber <= 10'b0010000000;
					end
					else if(maxAddress == 4'd9)begin
						resultingNumber <= 10'b0100000000;
					end
					else if(maxAddress == 4'd10)begin
						resultingNumber <= 10'b1000000000;
					end
					draw_Selected <= 1'b1;
				end
				else if(clockCycleReset)begin
					if(resultRAM_OUTPUT_output >= currentMaxVal)begin
						currentMaxVal <= resultRAM_OUTPUT_output;
						maxAddress <= layerOutput_result_address;
					end
					layerOutput_result_address <= layerOutput_result_address + 1;
				end
				else begin
					clockCycleReset <= 1'b1;
				end
			end
			else if(load_drawing)begin
				//counter to loop through the x and y coordinates
				//read the imageRAM and set the color 
				if(donePositionSet)begin
					drawPulse <= 1'b1;
					donePositionSet <= 1'b0;
					if(position_x == 8'd27 && position_y == 7'd27)begin
						done_Drawing <= 1'b1;
					end
				end
				else if(doneResettingForDrawing)begin
					drawPulse <= 1'b0;
					if(firstPixel)begin
						firstPixel <= 1'b0;
					end
					else begin
						if(position_x == 8'd27)begin
							position_x <= 8'b0;
							position_y <= position_y + 1;
						end
						else begin
							position_x <= position_x + 1;
						end
						imageRAM_address <= imageRAM_address + 1;
					end
					donePositionSet <= 1'b1;
				end
				else begin
					//reset the image address
					position_x <= 8'b0;
					position_y <= 7'b0;
					imageRAM_address <= 0;
					doneResettingForDrawing <= 1'b1;
					firstPixel <= 1'b1;
				end
			end
			else if(load_resetNumbers)begin
				currentMaxVal = 32'b10000000000000000000000000000000;
				maxAddress = 4'b0;
				imageRAM_address <= 0;
				layer1_weight_address <= 0;
				layer1_result_address <= 0;

				done_First <= 0;
				done_Second <= 0;
				done_Output <= 0;
				done_Selecting <= 0;
				done_Drawing <= 0;

				layer2_weight_address <= 0;
				layer2_result_address <= 0;

				layerOutput_weight_address <= 0;
				layerOutput_result_address <= 0;

				tempResultRAM_1 <= 64'd0;
				tempResultRAM_2 <= 64'd0;
				tempResultRAM_Output <= 64'd0;

				completeCalculation <= 1'b0;
				maxCalculation <= 1'b0;
				increment <= 1'b0;
				increment_address <= 1'b0;
				maxCalculation_wait <= 1'b0;
				clockCycleReset <= 1'b0;
				doneResettingForDrawing <= 1'b0;
				donePositionSet <= 1'b0;
				firstPixel <= 1'b0;

				position_x <= 8'b0;
				position_y <= 7'b0;

				resultingNumber <= 0;
				drawPulse <= 0;

				doneResettingForDrawingSelect <= 0;
				donePositionSetSelecting <= 0;
				draw_Selected <= 0;
			end
		end
	end
endmodule

module imageLoad(beginLoadingImage,TD_CLK27,resetn,imgRAM_dataInB,imageRAM_addressB,writeImageB,doneLoadingImage,TD_VS,TD_HS,TD_DATA,SW);
	input beginLoadingImage;
	input TD_CLK27;
	input resetn;
	input [8:0] SW;

	output reg [14:-17] imgRAM_dataInB;
	output reg [9:0] imageRAM_addressB;
	output reg writeImageB;
	output reg doneLoadingImage;

	//camera stuff
	input TD_VS;
	input TD_HS;
	input [7:0] TD_DATA;

	wire[15:0] 	address_cam;
	wire [17:0] vid_address;
	wire[23:0]	data_caml;  // data from camera
  	wire[23:0]	data_camh;

 	wire 			vid_ldll;
	wire 			vid_ldlh;
	wire 			vid_ldhh;
	wire 			vid_udll;
	wire 			vid_udlh;
	wire 			vid_udhh;
	wire			we_cam;



	camera  cam_0(
		.clk_27(TD_CLK27),		// 27 Mhz clock
		.vid_vs(TD_VS),			// vertical sync
		.vid_hs(TD_HS),			// horizontal sync
		.video_in(TD_DATA),		// video in data from camera

		.address_cam(address_cam),
		.vid_address(vid_address),
		.data_caml(data_caml),
		.data_camh(data_camh),

		.vid_ldll(vid_ldll),
		.vid_ldlh(vid_ldlh),
		.vid_ldhh(vid_ldhh),
		.vid_udll(vid_udll),
		.vid_udlh(vid_udlh),
		.vid_udhh(vid_udhh),
		
		.we_cam(we_cam)
	);


	reg [9:0] r_countx;
	reg [8:0] r_county;

	reg startFrame,newFrame;

	reg [4:0] waitTimer;

	//wait to be in sync to clock 27 signal
	always @(posedge TD_CLK27) begin
		if (!resetn) begin
			// reset
			startFrame <= 1'b0;
			doneLoadingImage <= 1'b0;
			newFrame <= 1'b0;
			waitTimer <= 5'd0;
		end
		else if(doneLoadingImage)begin
			if(!beginLoadingImage)begin
				doneLoadingImage <= 1'b0; //resets
			end
		end
		else if(newFrame)begin
			if(imageRAM_addressB == 10'd784)begin
				//done looping through addresses
				doneLoadingImage <= 1'b1;
				newFrame <= 1'b0;
			end
		end
		else if(startFrame)begin
			if(address_cam == 16'd0)begin
				newFrame <= 1'b1;
				startFrame <= 1'b0;
			end
		end
		else if(beginLoadingImage)begin
			if(waitTimer == 5'd30)begin
				startFrame <= 1'b1;
			end
			else begin
				waitTimer <= waitTimer + 1;
			end
		end
		else begin//not beginLoadingImage
			startFrame <= 1'b0;
			doneLoadingImage <= 1'b0;
			newFrame <= 1'b0;
			waitTimer <= 5'd0;
		end
	end

	// Simple coord counters
	always @(posedge TD_CLK27)
	begin
		if (!resetn || address_cam == 16'd0) begin
			r_countx <= 0;
		    r_county <= 0;
		    imageRAM_addressB <= 0;
		end
		else if (vid_ldll) begin
	    	if (r_countx == 311) begin
	    		r_countx <= 0;
	    		r_county <= r_county + 9'd1;
	    	end
	    	else begin
	    		r_countx <= r_countx + 9'd1;
	    	end
	    
		    if(newFrame)begin
	    	//address stuff
			   	if(r_countx < 28 && r_county < 28)begin
				  	writeImageB <= 1'b1;
				  	if(SW[8] == 1'b1)begin
				  		if(data_caml[7:0] <= {SW[7:4],4'b0})begin
					  		imgRAM_dataInB[14:-17] <= {15'b0,8'd255,9'b0};
					  	end
					  	else if(data_caml[7:0] >= {SW[3:0],4'b0})begin
					  		imgRAM_dataInB[14:-17] <= {15'b0,8'd0,9'b0};
					  	end
					  	else begin
					  		imgRAM_dataInB[14:-17] <= {15'b0,(!data_caml[7:0]),9'b0};
					  	end
				  	end
				  	else begin
				  		imgRAM_dataInB[14:-17] <= {15'b0,data_caml[7:0],9'b0};
				  	end

				  	

				  	// imgRAM_dataInB[14:-17] <= {15'b0,data_caml[7:0],9'b0};
				  	
				  	//colour is 32 bits
				  	// colour [-1:-8]
				  	// imgRAM-dataInB[14:-17]

				  	imageRAM_addressB <= imageRAM_addressB + 1; //increment the address for the RAM
				end
				else begin
				  	writeImageB <= 1'b0;
				  	imgRAM_dataInB[14:-17] <= {15'b0,(!data_camh[7:0]),9'b0};
				end
		    end
		    else begin
		    	writeImageB <= 1'b0; //when not newFrame then do not write to the image RAM
		    end
		end
	end
endmodule

// 10 bit address
module imgRAM_readOnly(inputData,outputData,address,writeEnable,clock,inputDataB,outputDataB,addressB,writeEnableB,clock27);

	//port A stuff
	input [14:-17] inputData;
	input [9:0] address;
		//10 bit address accounts for 1024 locations
		//10 bit address to account 785 locations 0 - 784

	input writeEnable, clock;
	output reg [14:-17] outputData;

	reg [14:-17] IMG_ram [783:0];
		//0 should be the first bit
		//1 is first pixel in the img
		//784 is the last pixel

	always @(posedge clock) begin
		if(writeEnable)begin
			IMG_ram[address] <= inputData;
		end
		outputData <= IMG_ram[address];
	end

	initial begin
	    $readmemh("image.hex", IMG_ram);
	end

	//port B stuff
	input [14:-17] inputDataB;
	input [9:0] addressB;
	input writeEnableB, clock27;

	output reg[14:-17] outputDataB;

	always @(posedge clock27) begin
		if(writeEnableB)begin
			IMG_ram[addressB] <= inputDataB;
		end
		outputDataB <= IMG_ram[addressB];
	end



endmodule

module weightRAM_layer1(inputData,outputData,address,writeEnable,clock);
	input [14:-17] inputData;
		//32 bit data
			// [11] is the sign bit
	input [15:0] address;
		//16 bit address to account for all 65535 addresses
			//785 * 64 nodes = 50240 addresses needed
				//0 - 50175
	input writeEnable, clock;
	output reg [14:-17] outputData;

	reg [14:-17] layer1_ram [50175:0];
		//0 should be the first bit
		//1 is first pixel in the img
		//784 is the last pixel


	initial begin
	    $readmemh("weight1.hex", layer1_ram);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			layer1_ram[address] <= inputData;
		end
		outputData <= layer1_ram[address];
	end
endmodule

//this contains 64  of 32 bit data
module resultRAM_layer1(inputData,outputData,address,writeEnable,clock);
	input [14:-17] inputData;
		//32 bit data
			// [31] is the sign bit
	input [5:0] address;
		//6 bit address to account for all 64 addresses
	input writeEnable, clock;
	output reg [14:-17] outputData;

	reg [14:-17] layer1Result_ram [64:0];
		//0 should be the first bit
		//1 is first pixel in the img
		//784 is the last pixel

	always @(posedge clock) begin
		if(writeEnable)begin
			layer1Result_ram[address] <= inputData;
		end
		outputData <= layer1Result_ram[address];
	end
endmodule

//32 nodes
module weightRAM_layer2(inputData,outputData,address,writeEnable,clock);
	input [14:-17] inputData;
	input [10:0] address;
		//11 bit address to account 2048 locations
			//64 * 32 = 2048 addresses needed
				//0 - 2047

	input writeEnable, clock;
	output reg [14:-17] outputData;

	reg [14:-17] layer2_ram [2047:0];
		//0 should be the first bit
		//1 is first pixel in the img
		//784 is the last pixel

	initial begin
	    $readmemh("weight2.hex", layer2_ram);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			layer2_ram[address] <= inputData;
		end
		outputData <= layer2_ram[address];
	end
endmodule

//this contains 32 of 32 bit data
module resultRAM_layer2(inputData,outputData,address,writeEnable,clock);
	input [14:-17] inputData;
		//32 bit data
			// [31] is the sign bit
			// []
	input [4:0] address;
		//5 bit address to account for all 32 addresses
	input writeEnable, clock;
	output reg [14:-17] outputData;

	reg [14:-17] layer2Result_ram [32:0];
		//0 should be the first bit
		//1 is first pixel in the img
		//784 is the last pixel

	always @(posedge clock) begin
		if(writeEnable)begin
			layer2Result_ram[address] <= inputData;
		end
		outputData <= layer2Result_ram[address];
	end
endmodule

module weightRAM_outputLayer(inputData,outputData,address,writeEnable,clock);
	input [14:-17] inputData;
	input [8:0] address;
		//9 bit address to account 512 locations
			// need 32 * 10 nodes for 0-319 or 320 addresses

	input writeEnable, clock;
	output reg [14:-17] outputData;

	reg [14:-17] output_ram [319:0];
		//0 should be the first bit
		//1 is first pixel in the img
		//784 is the last pixel

	initial begin
	    $readmemh("weightOutput.hex", output_ram);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			output_ram[address] <= inputData;
		end
		outputData <= output_ram[address];
	end
endmodule

module resultRAM_outputLayer(inputData,outputData,address,writeEnable,clock);
	input [14:-17] inputData;
	input [3:0] address;
		//4 bit address to account 16 locations
			// need 10 for 0-10

	input writeEnable, clock;
	output reg [14:-17] outputData;

	reg [14:-17] outputResult_ram [16:0];
		//0 should be the first bit
		//1 is first pixel in the img
		//784 is the last pixel

	always @(posedge clock) begin
		if(writeEnable)begin
			outputResult_ram[address] <= inputData;
		end
		outputData <= outputResult_ram[address];
	end
endmodule

//modules for infeered ram of the stored

module 	imageRAM0 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM0 [783:0];

	initial begin
	    $readmemh("0.hex", image_RAM0);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM0[address] <= inputData;
		end
		outputData <= image_RAM0[address];
	end

endmodule

module 	imageRAM1 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM1 [783:0];

	initial begin
	    $readmemh("1.hex", image_RAM1);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM1[address] <= inputData;
		end
		outputData <= image_RAM1[address];
	end

endmodule

module 	imageRAM2 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM2 [783:0];

	initial begin
	    $readmemh("2.hex", image_RAM2);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM2[address] <= inputData;
		end
		outputData <= image_RAM2[address];
	end

endmodule

module 	imageRAM3 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM3 [783:0];

	initial begin
	    $readmemh("3.hex", image_RAM3);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM3[address] <= inputData;
		end
		outputData <= image_RAM3[address];
	end

endmodule

module 	imageRAM4 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM4 [783:0];

	initial begin
	    $readmemh("4.hex", image_RAM4);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM4[address] <= inputData;
		end
		outputData <= image_RAM4[address];
	end

endmodule

module 	imageRAM5 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM5 [783:0];

	initial begin
	    $readmemh("5.hex", image_RAM5);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM5[address] <= inputData;
		end
		outputData <= image_RAM5[address];
	end

endmodule

module 	imageRAM6 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM6 [783:0];

	initial begin
	    $readmemh("6.hex", image_RAM6);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM6[address] <= inputData;
		end
		outputData <= image_RAM6[address];
	end

endmodule

module 	imageRAM7 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM7 [783:0];

	initial begin
	    $readmemh("7.hex", image_RAM7);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM7[address] <= inputData;
		end
		outputData <= image_RAM7[address];
	end

endmodule

module 	imageRAM8 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM8 [783:0];

	initial begin
	    $readmemh("8.hex", image_RAM8);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM8[address] <= inputData;
		end
		outputData <= image_RAM8[address];
	end

endmodule

module 	imageRAM9 (inputData,outputData,address,writeEnable,clock);
	input [7:0] inputData;
	input [9:0] address;

	input writeEnable, clock;
	output reg [7:0]outputData;

	reg[7:0] image_RAM9 [783:0];

	initial begin
	    $readmemh("9.hex", image_RAM9);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			image_RAM9[address] <= inputData;
		end
		outputData <= image_RAM9[address];
	end

endmodule


module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule
