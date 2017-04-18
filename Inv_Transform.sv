module Inv_Transform(	input logic clk, reset, start,
											input logic [3:0] inputSize,
											output logic done,
											input logic [9:0] memAddrWrite[3:0], memAddrRead[3:0],
											input logic writeEn[3:0],
											input shortint dataIn[3:0],
											output shortint dataOut[3:0]);

			logic [3:0] s_inputSize;
			logic [9:0] s_memAddrWrite[3:0], s_memAddrRead[3:0];
			logic s_writeEn[3:0];
			shortint s_dataIn[3:0], s_dataOut[3:0];

			logic [3:0] counter;

			always_ff @(posedge clk)
				begin
					s_inputSize <= inputSize;

					s_memAddrWrite[0] <= memAddrWrite[0];
					s_memAddrWrite[1] <= memAddrWrite[1];
					s_memAddrWrite[2] <= memAddrWrite[2];
					s_memAddrWrite[3] <= memAddrWrite[3];

					s_memAddrRead[0] <= memAddrRead[0];
					s_memAddrRead[1] <= memAddrRead[1];
					s_memAddrRead[2] <= memAddrRead[2];
					s_memAddrRead[3] <= memAddrRead[3];

					s_writeEn[0] <= writeEn[0];
					s_writeEn[1] <= writeEn[1];
					s_writeEn[2] <= writeEn[2];
					s_writeEn[3] <= writeEn[3];

					s_dataIn[0] <= dataIn[0];
					s_dataIn[1] <= dataIn[1];
					s_dataIn[2] <= dataIn[2];
					s_dataIn[3] <= dataIn[3];

					dataOut[0] <= s_dataOut[0];
					dataOut[1] <= s_dataOut[1];
					dataOut[2] <= s_dataOut[2];
					dataOut[3] <= s_dataOut[3];
				end

			Inv_Transform_main Inv_Transform_main(
						.clk(clk), .reset(reset), .start(start),
						.inputSize(s_inputSize), .done(done), .memAddrWrite(s_memAddrWrite),
						.memAddrRead(s_memAddrRead), .writeEn(s_writeEn), .dataIn(s_dataIn),
						.dataOut(s_dataOut));

endmodule

module Inv_Transform_main(	input logic clk, reset, start,
											input logic [3:0] inputSize,
											output logic done,
											input logic [9:0] memAddrWrite[3:0], memAddrRead[3:0],
											input logic writeEn[3:0],
											input shortint dataIn[3:0],
											output shortint dataOut[3:0]);

  shortint dataIn_a[3:0], dataIn_b[3:0], dataCol_a[3:0], dataCol_b[3:0], dataOut_a[3:0], dataOut_b[3:0];
	shortint dataOutRow[31:0], dataOutCol[31:0];
  shortint qIn_a[3:0], qIn_b[3:0], qCol_a[3:0], qCol_b[3:0], qOut_a[3:0], qOut_b[3:0];
	logic [9:0] addrIn_a[3:0], addrIn_b[3:0], addrCol_a[3:0], addrCol_b[3:0], addrOut_a[3:0], addrOut_b[3:0];
	logic weIn_a[3:0], weIn_b[3:0], weCol_a[3:0], weCol_b[3:0], weOut_a[3:0], weOut_b[3:0];
	logic doneRow, startCol, doneCol;
	shortint dataOut_1D[31:0];
	logic [3:0] sizeRowOut, sizeColIn, sizeColOut;
	logic [5:0] rowRow, rowCol;

	assign addrIn_a = memAddrWrite;
	assign dataIn_a = dataIn;
	assign weIn_a = writeEn;

	assign addrOut_b = memAddrRead;
	assign dataOut = qOut_b;

	// assign dataOut = qOut_b;
	//assign addrCol_b = memAddrRead;

	generate
		genvar i;
		for (i = 0; i < 4; i = i + 1)
			begin: Memory

				assign weIn_b[i] = 1'b0;
				assign weCol_b[i] = 1'b0;
				assign weOut_b[i] = 1'b0;


				trueDualRAM trueDualRAMInput(
							.data_a(dataIn_a[i]), .data_b(dataIn_b[i]),
							.addr_a(addrIn_a[i]), .addr_b(addrIn_b[i]),
							.we_a(weIn_a[i]), .we_b(weIn_b[i]), .clk(clk),
							.q_a(qIn_a[i]), .q_b(qIn_b[i]));

				trueDualRAM trueDualRAMCol(
							.data_a(dataCol_a[i]), .data_b(dataCol_b[i]),
							.addr_a(addrCol_a[i]), .addr_b(addrCol_b[i]),
							.we_a(weCol_a[i]), .we_b(weCol_b[i]), .clk(clk),
							.q_a(qCol_a[i]), .q_b(qCol_b[i]));

				trueDualRAM trueDualRAMOut(
							.data_a(dataOut_a[i]), .data_b(dataOut_b[i]),
							.addr_a(addrOut_a[i]), .addr_b(addrOut_b[i]),
							.we_a(weOut_a[i]), .we_b(weOut_b[i]), .clk(clk),
							.q_a(qOut_a[i]), .q_b(qOut_b[i]));
			end
	endgenerate

	Inv_Transform_1D Inv_Transform_1D_Row(
				.clk(clk), .reset(reset), .start(start),
				.sizeIn(inputSize), .done(doneRow),
				.sizeOut(sizeRowOut), .rowOut(rowRow),
				.memAddrRead(addrIn_b), .dataIn(qIn_b), .dataOut(dataOutRow));

	outputRegToMem rowToCol(
				.clk(clk), .reset(reset), .start(doneRow),
				.dataIn(dataOutRow), .sizeIn(sizeRowOut), .rowIn(rowRow),
				.done(startCol), .sizeOut(sizeColIn), .memAddr(addrCol_a),
				.writeEn(weCol_a), .dataOut(dataCol_a));

	Inv_Transform_1D Inv_Transform_1D_Col(
				.clk(clk), .reset(reset), .start(startCol),
				.sizeIn(sizeColIn), .done(doneCol),
				.sizeOut(sizeColOut), .rowOut(rowCol),
				.memAddrRead(addrCol_b), .dataIn(qCol_b), .dataOut(dataOutCol));

	outputRegToMem ColToOut(
				.clk(clk), .reset(reset), .start(doneCol),
				.dataIn(dataOutCol), .sizeIn(sizeColOut), .rowIn(rowCol),
				.done(done), .sizeOut(sizeOut), .memAddr(addrOut_a),
				.writeEn(weOut_a), .dataOut(dataOut_a));

endmodule




// IDCT_1D
// computes the 1D IDCT on the rows or columns of an array
// for the first 1D IDCT round and bitshift are (64, 7)
// for the second 1D IDCT round and bitshift are (2048, 12)
module Inv_Transform_1D #(parameter round = 64, bitshift = 7)
							(	input logic clk, reset, start,
								input logic [3:0] sizeIn,
								output logic done,
								output logic [3:0] sizeOut,
								output logic [5:0] rowOut,
								output logic [9:0] memAddrRead[3:0],
								input shortint dataIn[3:0],
								output shortint dataOut[31:0]);

	//////////////////////////////////////////////////////////////////////////////
	// Instantiating Stuff
	//////////////////////////////////////////////////////////////////////////////

	logic [5:0] row;

	int z[31:0]; // registers to store intermediate values in

	shortint multIn[15:0];
	byte constants[15:0];	// inputs to the multipliers
	int multOut[15:0]; // outputs of multipliers

	int butIn0[15:0], butIn1[15:0]; // inputs to butterfly units
	int butOut0[15:0], butOut1[15:0]; // outputs of butterfly units

	int adderIn0[15:0], adderIn1[15:0]; // inputs to adders
	int adderOut[15:0]; // outputs of adders

	// Creating 16 adders, multipliers, and butterfly units
	generate
		genvar i;
		for (i = 0; i < 16; i = i + 1)
			begin: addMultButter
				assign adderOut[i] = adderIn0[i] + adderIn1[i];
				assign multOut[i] = multIn[i] * constants[i];

				butterfly butterfly(
							.I0(butIn0[i]), .I1(butIn1[i]),
				 			.E0(butOut0[i]), .E1(butOut1[i]));
			end
	endgenerate

	//////////////////////////////////////////////////////////////////////////////
	// State logic
	//////////////////////////////////////////////////////////////////////////////

	typedef enum logic[3:0] {S4, S8, S16a, S16b, S16c, S32a, S32b, S32c} statetype;
	statetype state, nextstate;

	logic [4:0] iterations; // Used for rounds of 16/32

	// state register
	always_ff @(posedge clk, posedge reset)
		if(reset)
			begin
				state <= S4;
				iterations <= 1'b0;
				row <= 1'b0;
				done <= 1'b0;
			end
		else
			begin
				state <= nextstate;
				if(nextstate == S4)
					begin
						iterations <= 1'b0;
						if(row == (sizeIn<<2) - 1)
							begin
								done <= 1'b1;
								row <= 1'b0;
								sizeOut <= sizeIn;
								rowOut <= row;
							end
						else
							row <= row + 1'b1;
					end
				else iterations <= iterations + 1'b1;
			end

	// nextstate logic
	always_comb
		case (state)
			S4: 	nextstate = (sizeIn == 4'b0001) ? S4 : S8;
			S8: 	nextstate = (sizeIn == 4'b0010) ? S4 : S16a;
			S16a: nextstate = S16b;
			S16b: nextstate = (iterations == 5'd4) ? S16c : S16b;
			S16c: nextstate = (sizeIn == 4'b0100) ? S4 : S32a;
			S32a: nextstate = S32b;
			S32b: nextstate = (iterations == 5'd20) ? S32c : S32b;
			S32c: nextstate = S4;
			default: nextstate = S4;
		endcase

	//////////////////////////////////////////////////////////////////////////////
	// Input Memory Address Logic
	//////////////////////////////////////////////////////////////////////////////

	logic [4:0] memAddr[3:0];

	generate
		for (i = 0; i < 4; i = i + 1)
			begin: memAddr_to_memAddrRead
						assign memAddrRead[i] = memAddr[i] + (row<<2);
			end
	endgenerate

	always_comb
		case(state)
			S4: begin
						memAddr[0] = 5'b0;
						if(sizeIn == 4'b0001)
							begin
								memAddr[1] = 5'd1;
								memAddr[2] = 5'd2;
								memAddr[3] = 5'd3;
							end
						else if(sizeIn == 4'b0010)
							begin
								memAddr[1] = 5'd2;
								memAddr[2] = 5'd4;
								memAddr[3] = 5'd6;
							end
						else if(sizeIn == 4'b0100)
							begin
								memAddr[1] = 5'd4;
								memAddr[2] = 5'd8;
								memAddr[3] = 5'd12;
							end
						else
							begin
								memAddr[1] = 5'd8;
								memAddr[2] = 5'd16;
								memAddr[3] = 5'd24;
							end
					end
			S8: begin
						if(sizeIn == 4'b0010)
							begin
								memAddr[0] = 5'd1;
								memAddr[1] = 5'd3;
								memAddr[2] = 5'd5;
								memAddr[3] = 5'd7;
							end
						else if(sizeIn == 4'b0100)
							begin
								memAddr[0] = 5'd2;
								memAddr[1] = 5'd6;
								memAddr[2] = 5'd10;
								memAddr[3] = 5'd14;
							end
						else
							begin
								memAddr[0] = 5'd4;
								memAddr[1] = 5'd12;
								memAddr[2] = 5'd20;
								memAddr[3] = 5'd28;
							end
					end
			S16a, S16b, S16c: begin
				// memAddr[0] = ((iterations-2)<<1  + 1);
				memAddr[0] = 5'd4;
				memAddr[1] = 5'd12;
				memAddr[2] = 5'd20;
				memAddr[3] = 5'd28;
				end
				// begin
				// 			if(sizeIn == 2'b10)
				// 				begin
				// 					memAddr[0] = ((iterations-2)<<2 + 1);
				// 					memAddr[1] = ((iterations-2)<<2 + 3);
				// 				end
				// 			else
				// 				begin
				// 					memAddr[0] = ((iterations-2)<<3 + 2);
				// 					memAddr[1] = ((iterations-2)<<3 + 6);
				// 				end
				// 		end
			S32a, S32b, S32c: begin
				// memAddr[0] = ((iterations-2)<<1  + 1);
				memAddr[0] = 5'd4;
				memAddr[1] = 5'd12;
				memAddr[2] = 5'd20;
				memAddr[3] = 5'd28;
				end
			default:
				begin
					memAddr[0] = 5'd0;
					memAddr[1] = 5'd1;
					memAddr[2] = 5'd2;
					memAddr[3] = 5'd3;
				end
	endcase

	//////////////////////////////////////////////////////////////////////////////
	// Multiplier logic
	//////////////////////////////////////////////////////////////////////////////

	// Multiplier inputs
	// 1D 4 need 4 inputs mapped to 6 multipliers
	// 1D 8 need 4 inputs mapped to 16 multipliers
	// 1D 16 need 2 inputs mapped to 16 multipliers
	// 1D 32 need 1 input mapped to 16 multipliers

	// Creating arrays to assign from
	shortint dataIn_4[5:0], dataIn_8[15:0], dataIn_16[15:0], dataIn_32[15:0];

	// Inputs for 4
	assign dataIn_4[3:0] = dataIn[3:0]; // First 4 are just straight
	assign dataIn_4[4] = dataIn[1]; // Need additional multiplies for odd values
	assign dataIn_4[5] = dataIn[3];

	generate
		// Inputs for 8
		for (i = 0; i < 4; i = i + 1) begin: dataIn_8_assigning
				assign dataIn_8[i*4] = dataIn[i];
				assign dataIn_8[1+i*4] = dataIn[i];
				assign dataIn_8[2+i*4] = dataIn[i];
				assign dataIn_8[3+i*4] = dataIn[i];
			end
		for (i = 0; i < 8; i = i + 1) begin: dataIn_16_assigning
					assign dataIn_16[i] = dataIn[0];
					assign dataIn_16[i+8] = dataIn[1];
				end
		for (i = 0; i < 16; i = i + 1) begin: dataIn_32_assigning
					assign dataIn_32[i] = dataIn[0];
				end
	endgenerate

	// mult input assigment
	always_comb
		case (state)
			S4: begin
						multIn[5:0] = dataIn_4[5:0];
						multIn[15:6] = dataIn_8[15:6];
					end
			S8: 	multIn[15:0] = dataIn_8[15:0];
			S16a: multIn[15:0] = dataIn_16[15:0];
			S16b: multIn[15:0] = dataIn_16[15:0];
			S16c: multIn[15:0] = dataIn_16[15:0];
			S32a: multIn[15:0] = dataIn_32[15:0];
			S32b: multIn[15:0] = dataIn_32[15:0];
			S32c: multIn[15:0] = dataIn_32[15:0];
			default: multIn[15:0] = dataIn_8[15:0];
		endcase

	//////////////////////////////////////////////////////////////////////////////
	// Constant Logic
	//////////////////////////////////////////////////////////////////////////////

	logic [4:0] LUTaddr_a, LUTaddr_b;
	logic [31:0] LUT0q_a, LUT0q_b, LUT1q_a, LUT1q_b;

	constantLUT0 constantLUT0(
				.addr_a(LUTaddr_a), .addr_b(LUTaddr_b), .clk(clk),
				.q_a(LUT0q_a), .q_b(LUT0q_b));

	constantLUT1 constantLUT1(
				.addr_a(LUTaddr_a), .addr_b(LUTaddr_b), .clk(clk),
				.q_a(LUT1q_a), .q_b(LUT1q_b));

	assign LUTaddr_a = iterations<<1;
	assign LUTaddr_b = LUTaddr_a + 1'b1;

	typedef byte constant_t[3:0]; // Used for casting to a signed type

	assign constants[3:0] = constant_t'(LUT0q_a);
	assign constants[7:4] = constant_t'(LUT0q_b);
	assign constants[11:8] = constant_t'(LUT1q_a);
	assign constants[15:12] = constant_t'(LUT1q_b);

	//////////////////////////////////////////////////////////////////////////////
	// Adder Logic
	//////////////////////////////////////////////////////////////////////////////

	always_comb
		case(state)
			S4: 	begin
							adderIn0[0] = multOut[1];
							adderIn0[1] = multOut[4];
							adderIn1[0] = multOut[3];
							adderIn1[1] = multOut[5];

							// Set the reset
							adderIn0[15:2] = z[15:2];
							adderIn1[15:2] = z[15:2];
						end
			S8: 	begin
							// First set of additions coming from multiplier outputs
							adderIn0[7:0] = multOut[7:0];
							adderIn1[7:0] = multOut[15:8];

							// Second set coming from first set
							adderIn0[11:8] = adderOut[3:0];
							adderIn1[11:8] = adderOut[7:4];

							// Set the reset
							adderIn0[15:12] = z[15:12];
							adderIn1[15:12] = z[15:12];
						end
			S16a: begin
							adderIn0[7:0] = multOut[7:0];
							adderIn1[7:0] = multOut[15:8];

							// Set the reset
							adderIn0[15:8] = z[15:8];
							adderIn1[15:8] = z[15:8];
						end
			S16b: begin
							adderIn0[7:0] = multOut[7:0];
							adderIn1[7:0] = multOut[15:8];

							adderIn0[15:8] = z[15:8];
							adderIn1[15:8] = adderOut[7:0];
						end
			S16c: begin
							adderIn0[7:0] = multOut[7:0];
							adderIn1[7:0] = multOut[15:8];

							adderIn0[15:8] = z[15:8];
							adderIn1[15:8] = adderOut[7:0];
						end
			S32b, S32c: begin
							adderIn0[15:0] = z[31:16];
							adderIn1[15:0] = multOut[15:0];
						end
			default: begin
							adderIn0 = z[31:16];
							adderIn1 = z[31:16];
						end
		endcase

	//////////////////////////////////////////////////////////////////////////////
	// Butterfly Logic
	//////////////////////////////////////////////////////////////////////////////

	always_comb
		case(state)
			S4: 	begin
							butIn0[0] = multOut[0]; // The even butterfly
							butIn1[0] = multOut[2];

							butIn0[1] = butOut0[0];
							butIn0[2] = butOut1[0];
							butIn1[1] = adderOut[1];
							butIn1[2] = adderOut[0];

							// Set the reset
							butIn0[15:3] = z[15:3];
							butIn1[15:3] = z[15:3];
						end
			S8: 	begin
							butIn0[3:0] = z[3:0];
							butIn1[3:0] = adderOut[11:8];

							// Set the reset
							butIn0[15:4] = z[15:4];
							butIn1[15:4] = z[15:4];
							end
			S16c: begin
							butIn0[7:0] = z[7:0];
							butIn1[7:0] = adderOut[15:8];

							// Set the reset
							butIn0[15:8] = z[15:8];
							butIn1[15:8] = z[15:8];
						end
			S32c: begin
							butIn0[15:0] = z[15:0];
							butIn1[15:0] = adderOut[15:0];
						end
			default: begin
							butIn0[15:0] = z[15:0];
							butIn1[15:0] = z[15:0];
						end
		endcase

	//////////////////////////////////////////////////////////////////////////////
	// z Register Logic
	//////////////////////////////////////////////////////////////////////////////

	always_ff @(posedge clk)
			case(state)
			S4: 	begin
							z[1:0] <= butOut0[2:1];
							for (int i = 0; i < 2; i++)
								z[3-i] <= butOut1[i + 1];
							z[31:4] <= z[31:4];
						end
			S8: 	begin
							z[3:0] <= butOut0[3:0];
							for (int i = 0; i < 4; i++)
								z[7-i] <= butOut1[i];
							z[31:8] <= z[31:8];
						end
			S16a: begin
							z[7:0] <= z[7:0];
							z[15:8] <= adderOut[7:0];
							z[31:16] <= z[31:16];
						end
			S16b: begin
							z[7:0] <= z[7:0];
							z[15:8] <= adderOut[15:8];
							z[31:16] <= z[31:16];
						end
			S16c: begin
							z[7:0] <= butOut0[7:0];
							for (int i = 0; i < 8; i++)
								z[15-i] <= butOut1[i];
							z[31:16] <= z[31:16];
						end
			S32a: begin
							z[15:0] <= z[15:0];
							z[31:16] <= multOut[15:0];
						end
			S32b: begin
							z[15:0] <= z[15:0];
							z[31:16] <= adderOut[15:0];
						end
			S32c: begin
							z[15:0] <= butOut0[15:0];
							for (int i = 0; i < 16; i++)
								z[31-i] <= butOut1[i];
						end
			default: z[31:0] <= z[31:0];
		endcase

	//////////////////////////////////////////////////////////////////////////////
	// Output Logic
	//////////////////////////////////////////////////////////////////////////////

		generate
			for (i = 0; i < 32; i = i + 1)
				begin: outputLogic
					assign dataOut[i] = ((z[i] + round) >> bitshift);
				end
		endgenerate

endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// outputRegToMem
// takes the output from the 1D transform and transposes it for the next stage
////////////////////////////////////////////////////////////////////////////////
module outputRegToMem(input logic clk, reset, start,
											input shortint dataIn[31:0],
											input logic [3:0] sizeIn,
											input logic [4:0] rowIn,
											output logic done,
											output logic [3:0] sizeOut,
											output logic [9:0] memAddr[3:0],
											output logic writeEn[3:0],
											output logic dataOut[3:0]);

	shortint z[31:0];
	logic [1:0] memNum;
	logic [4:0] iteration;
	logic [3:0] size;
	logic running;

	genvar i;

	assign memNum = rowIn[1:0];

	generate
		for (i = 0; i < 4; i = i + 1)
			begin: memAddresses
				assign writeEn[i] = running;
				assign memAddr[i] = (2'(i + memNum) + (iteration << (sizeIn + 1'b1)) + rowIn);
				assign dataOut[i] = z[i + (iteration << 2)];
			end
	endgenerate

	always_ff @(posedge clk)
		begin
			z[31:0] <= start ? dataIn[31:0] : z[31:0];
			size <= sizeIn;
		end

	always_ff @(posedge clk, posedge reset)
		begin
			if (reset)
				begin
					iteration <= 2'b0;
					running <= 1'b0;
					done <= 1'b0;
				end
			else if (running)
				begin
					if (iteration == (size - 1'b1))
						begin

							iteration <= 2'b0;

							if (rowIn == (sizeIn << 2) - 1)
								begin
									done <= 1'b1;
									sizeOut <= size;
								end

							if (start) running <= 1'b1;
							else running <= 1'b0;

						end
					else
						begin
							iteration <= iteration + 1'b1;
							running <= 1'b1;
						end
				end
			else
				begin
					if (start)
						begin
							iteration <= 2'b0;
							running <= 1'b1;
						end
				end
		end

endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Butterfly
// Basic butterfly unit for 32 bit data
////////////////////////////////////////////////////////////////////////////////
module butterfly( input int I0, I1,
									output int E0, E1);

	assign E0 = I0 + I1;
	assign E1 = I0 - I1;

endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// Constant Look Up Tables
// Currently this is really small and inefficient
// http://quartushelp.altera.com/14.1/mergedProjects/msgs/msgs/iaopt_ram_uninferred_due_to_size.htm
////////////////////////////////////////////////////////////////////////////////
module constantLUT0 #(parameter data_width = 32, addr_width = 5)
								(input [(addr_width-1):0] addr_a, addr_b,
									input clk,
									output reg [(data_width-1):0] q_a, q_b);

 reg [data_width-1:0] rom[2**addr_width-1:0];
 initial // Read the memory contents in the file
 //dual_port_rom_init.txt.
	 begin
	 $readmemh("constantLUT0.txt", rom);
	 end
 always @ (posedge clk)
	 begin
	 q_a <= rom[addr_a];
	 q_b <= rom[addr_b];
	 end

endmodule

module constantLUT1 #(parameter data_width = 32, addr_width = 5)
								(input [(addr_width-1):0] addr_a, addr_b,
									input clk,
									output reg [(data_width-1):0] q_a, q_b);

 reg [data_width-1:0] rom[2**addr_width-1:0];
 initial // Read the memory contents in the file
 //dual_port_rom_init.txt.
	 begin
	 $readmemh("constantLUT1.txt", rom);
	 end
 always @ (posedge clk)
	 begin
	 q_a <= rom[addr_a];
	 q_b <= rom[addr_b];
	 end

endmodule

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// True Dual Port RAM
////////////////////////////////////////////////////////////////////////////////
module trueDualRAM #(parameter DATA_WIDTH = 16, ADDR_WIDTH = 10)
									(input [(DATA_WIDTH-1):0] data_a, data_b,
									 input [(ADDR_WIDTH-1):0] addr_a, addr_b,
									 input we_a, we_b, clk,
									 output reg [(DATA_WIDTH-1):0] q_a, q_b);

	// Declare the RAM variable
 	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

 	always @ (posedge clk)
	 	begin // Port A
		 	if (we_a)
			 	begin
				 	ram[addr_a] <= data_a;
				 	q_a <= data_a;
			 	end
		 	else
			 	q_a <= ram[addr_a];
 		end

	always @ (posedge clk)
	 	begin // Port b
		 	if (we_b)
		 		begin
					ram[addr_b] <= data_b;
					q_b <= data_b;
				end
			else
				q_b <= ram[addr_b];
		end
endmodule
