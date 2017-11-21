module finalProject(KEY,CLOCK_50,LEDR);
	input CLOCK_50;
	input [1:0] KEY;
		//key 0 is reset
		//key 1 is the next button when you are beginning


	output [9:0] LEDR;
		// ouput whatever number it is

	assign resetn = KEY[0];
	assign go = ~KEY[1];

	wire done_First;
	wire done_Second;
	wire done_Output;
	wire done_Selecting;

	//enable signals
	wire load_firstLayer, load_secondLayer, load_outputLayer, load_result;

	wire load_resetFirstLayer, load_resetSecondLayer, load_resetOutputLayer;


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

	control C0(
		//inputs

		.clk(CLOCK_50),
		.resetn(resetn),
		.go(go),

		.done_First(done_First),
		.done_Second(done_Second),
		.done_Output(done_Output),
		.done_Selecting(done_Selecting),

		//outputs
		.load_firstLayer(load_firstLayer),
		.load_secondLayer(load_secondLayer),
		.load_outputLayer(load_outputLayer),
		.load_result(load_result),

		.load_resetFirstLayer(load_resetFirstLayer),
		.load_resetSecondLayer(load_resetSecondLayer),
		.load_resetOutputLayer(load_resetOutputLayer)
	);//-------

	dataPath D0(
		//inputs
		.clk(CLOCK_50),
		.resetn(resetn),

		.done_First(done_First),
		.done_Second(done_Second),
		.done_Output(done_Output),
		.done_Selecting(done_Selecting),

		.load_firstLayer(load_firstLayer),
		.load_secondLayer(load_secondLayer),
		.load_outputLayer(load_outputLayer),
		.load_result(load_result),

		.load_resetFirstLayer(load_resetFirstLayer),
		.load_resetSecondLayer(load_resetSecondLayer),
		.load_resetOutputLayer(load_resetOutputLayer),

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
		.resultingNumber(resultingNumber)

	);

	//instantiate RAM modules
	imgRAM_readOnly imgRAM(
		.inputData(32'b0), //doesnt matter wont need to store into here
		.outputData(imgRAMdata),
		.address(imageRAM_address),
		.writeEnable(1'b0), //always low as do not need to write to this RAM module
		.clock(CLOCK_50)
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

	//assign the LEDR
	assign LEDR[9:0] = resultingNumber[9:0];

endmodule

module control(
	clk,
	resetn,
	go,

	done_First,
	done_Second,
	done_Output,
	done_Selecting,

	load_firstLayer,
	load_secondLayer,
	load_outputLayer,
	load_result,

	load_resetFirstLayer,
	load_resetSecondLayer,
	load_resetOutputLayer
	);

	input clk;
	input resetn;
	input go;

	//signals from the datapath
	input done_First;
	input done_Second;
	input done_Output;
	input done_Selecting;

	//outputs here
	output reg load_firstLayer;
	output reg load_secondLayer;
	output reg load_outputLayer;
	output reg load_result;

	output reg load_resetFirstLayer;
	output reg load_resetSecondLayer;
	output reg load_resetOutputLayer;

	//states
	reg [3:0] current_state, next_state;

	//states here
	localparam			S_begin 						= 4'd0,
						S_begin_wait					= 4'd1,
						load_firstResultRAM				= 4'd2,
						load_resetFirst 				= 4'd3,
						load_secondResultRAM			= 4'd4,
						load_resetSecond 				= 4'd5,
						load_outputRAM					= 4'd6,
						load_resetOutput 				= 4'd7,
						display_mostLikely				= 4'd8;

	always@(*)
	begin: state_table
		case(current_state)
			S_begin: next_state = go ? S_begin_wait : S_begin;
			S_begin_wait: next_state = go ? S_begin_wait : load_firstResultRAM;

			load_firstResultRAM: next_state = done_First ? load_resetFirst : load_firstResultRAM;
			load_resetFirst: next_state = load_secondResultRAM;

			load_secondResultRAM: next_state = done_Second ? load_resetSecond : load_secondResultRAM;
			load_resetSecond: next_state = load_outputRAM;

			load_outputRAM: next_state = done_Output ? load_resetOutput : load_outputRAM;
			load_resetOutput: next_state = display_mostLikely;

			display_mostLikely: next_state = done_Selecting ? S_begin : display_mostLikely;
			default: next_state = S_begin;
		endcase
	end

	always @(*) 
	begin: enable_signals
		// By default make all our signals 0
        load_firstLayer = 1'b0;
        load_secondLayer = 1'b0;
        load_outputLayer = 1'b0;

        load_resetFirstLayer = 1'b0;
		load_resetSecondLayer = 1'b0;
		load_resetOutputLayer = 1'b0;

        load_result = 1'b0;
        case(current_state)
			S_begin: begin //nothing happens here, just wait for the singal to begin the calculations
				
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
		endcase
	end // send the enable signals

	always@(posedge clk)
	begin: state_FFs
		if(!resetn)begin
			current_state <= S_begin;
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

	load_firstLayer,
	load_secondLayer,
	load_outputLayer,
	load_result,

	load_resetFirstLayer,
	load_resetSecondLayer,
	load_resetOutputLayer,

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

	resultingNumber

	);
	input clk,resetn;
	
	input load_firstLayer,load_secondLayer,load_outputLayer,load_result;
	input load_resetFirstLayer, load_resetSecondLayer, load_resetOutputLayer;

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

	//ouput data
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

	reg signed [29:-34] tempResultRAM_1;
	reg signed [29:-34] tempResultRAM_2;
	reg signed [29:-34] tempResultRAM_Output;

	assign resultRAM_1_input = tempResultRAM_1[14:-17];
	assign resultRAM_2_input = tempResultRAM_2[14:-17];
	assign resultRAM_OUTPUT_input = tempResultRAM_Output[14:-17];


	reg completeCalculation, maxCalculation, increment, increment_address, maxCalculation_wait;

	//max
	reg signed [14:-17] currentMaxVal = 32'b10000000000000000000000000000000;
	reg [3:0] maxAddress = 4'b0;

	always@(posedge clk)
	begin: addressCounter
		if(!resetn)begin
			imageRAM_address <= 0;
			layer1_weight_address <= 0;
			layer1_result_address <= 0;

			done_First <= 0;
			done_Second <= 0;
			done_Output <= 0;
			done_Selecting <= 0;

			layer2_weight_address <= 0;
			layer2_result_address <= 0;

			layerOutput_weight_address <= 0;
			layerOutput_result_address <= 0;

			tempResultRAM_1 = 64'd0;
			tempResultRAM_2 = 64'd0;
			tempResultRAM_Output = 64'd0;
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
			end
			else if(load_result)begin //determine the max
				if(layerOutput_result_address == 4'd10)begin
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
					done_Selecting = 1'b1;
				end
				else begin
					if(resultRAM_OUTPUT_output >= currentMaxVal)begin
						currentMaxVal <= resultRAM_OUTPUT_output;
						maxAddress <= layerOutput_result_address;
					end
					layerOutput_result_address <= layerOutput_result_address + 1;
				end
				
			end
		end
	end

endmodule


// 10 bit address
module imgRAM_readOnly(inputData,outputData,address,writeEnable,clock);
	input [14:-17] inputData;
	input [9:0] address;
		//10 bit address accounts for 1024 locations
		//10 bit address to account 785 locations 0 - 784

	input writeEnable, clock;
	output reg [14:-17] outputData;

	reg [14:-17] IMG_ram [1024:0];
		//0 should be the first bit
		//1 is first pixel in the img
		//784 is the last pixel

	//initialize the ram block	
	initial begin
	    $readmemh("image.hex", IMG_ram);
	end

	always @(posedge clock) begin
		if(writeEnable)begin
			IMG_ram[address] <= inputData;
		end
		outputData <= IMG_ram[address];
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

	reg [14:-17] layer1_ram [65536:0];
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

	reg [14:-17] layer2_ram [2048:0];
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

	reg [14:-17] output_ram [512:0];
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