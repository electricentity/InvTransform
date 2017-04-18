
module testbench_4();

    // 14 bits of input
    logic clk, done, start, reset;
    shortint dataIn[3:0], y[0:3], r[0:3], d_1[0:3], d_2[0:3], d[0:3], dataIn_reversed[3:0];
    shortint dataOut[31:0];
    logic [9:0] memAddrRead[3:0], memAddrWrite[3:0];
    logic writeEn[3:0];
    logic [3:0] size;
    logic [4:0] memAddr[3:0];

    logic [1:0] state, nextstate;

    assign size = 4'd1;
    assign start = 1;
    assign r = dataOut[3:0];

    shortint i;

    typedef shortint data_t[3:0];

    // Creating 16 adders, multipliers, and butterfly units
    generate
      genvar j;
      for (j = 0; j < 4; j = j + 1)
        begin: orderFlipping
          assign dataIn[j] = dataIn_reversed[3-j];
          assign memAddrWrite[j] = memAddr[j] + (state<<2);
          assign writeEn[j] = 1'b1;
        end
    endgenerate

    always_comb begin
      memAddr[0] = 5'd0;
      memAddr[1] = 5'd1;
      memAddr[2] = 5'd2;
      memAddr[3] = 5'd3;
    end

    always_comb
  		case (state)
  			2'b0: nextstate = 2'b01;
        2'b01: nextstate = 2'b10;
        2'b10: nextstate = 2'b11;
  			default: nextstate = 2'b00;
  		endcase

      Inv_Transform_main Inv_Transform(
            .clk(clk), .reset(reset), .start(start),
            .inputSize(size), .done(done), .memAddrWrite(memAddrWrite),
            .memAddrRead(memAddrRead), .writeEn(writeEn), .dataIn(dataIn),
            .dataOut(dataOut));

    // Logic for reading in vectors
    logic [127:0] vectors[500:0];
    logic [0:127] currentvec;
    logic [15:0] vectornum, errors;

    // read test vector file and initialize test
    initial begin
        $readmemb("4Transform.tv", vectors);
        state = 2'b0; vectornum = 0; errors = 0;
        #2; state = 2'b0; vectornum = 0; currentvec = vectors[vectornum];
        #3; state = 2'b0; vectornum = 0; #5; reset = 1; #5; reset = 0;

        // state = 2'b0; vectornum = 0; errors = 0;
        // currentvec = vectors[vectornum];
        // #11; reset = 1; #5; reset = 0; #5;
    end

    // generate a clock to sequence tests
    always begin
        clk = 1; #5;
        clk = 0; #5;
    end

    // apply test
    always @(posedge clk)
        begin

          state <= nextstate;

          d = d_2;
          d_2 = d_1;
        	d_1 = y;

          // set test vectors when required
          currentvec = vectors[vectornum];

          dataIn_reversed = data_t'(currentvec[0:63]);
          y = data_t'(currentvec[64:127]);

        // end the test
        if (currentvec[0] === 1'bx)
            begin
                $display("Test completed with %d errors", errors);
                $stop;
            end
        end

    // check if test was sucessful and apply next one
    always @(negedge clk)
        begin
			  $display("Vectornum =%d ", vectornum);
			  //if (r[0] !== y[0] || r[1] !== y[1] || r[2] !== y[2] || r[3] !== y[3])
			  if (r !== d)
					begin
							errors = errors + 1;
							$display("Error: Vectornum =%d ", vectornum);
					$display("                    actual                expected");
					for (i = 0; i < 4; i = i + 1) begin
						$display("%d -> %d (%b)| %d (%b)", i, r[i], r[i], d[i], d[i]);
					end

					end
			  vectornum = vectornum + 1;
			end
endmodule

module testbench_4_noMem();

    // 14 bits of input
    logic clk, done, start, reset;
    shortint dataIn[3:0], y[0:3], r[0:3], d[0:3], dataIn_reversed[3:0];
    shortint dataOut[31:0];
    logic [9:0] memAddrRead[3:0];
    logic [3:0] size;

    assign size = 4'd1;
    assign start = 1;
    assign r = dataOut[3:0];

    shortint i;

    typedef shortint data_t[3:0];

    // Creating 16 adders, multipliers, and butterfly units
    generate
      genvar j;
      for (j = 0; j < 4; j = j + 1)
        begin: orderFlipping
          assign dataIn[j] = dataIn_reversed[3-j];
        end
    endgenerate

	  Inv_Transform_1D IDCT_1D(clk, reset, start, size, done, memAddrRead, dataIn, dataOut);

    // Logic for reading in vectors
    logic [127:0] vectors[500:0];
    logic [0:127] currentvec;
    logic [15:0] vectornum, errors;

    // read test vector file and initialize test
    initial begin
        $readmemb("4Transform.tv", vectors);
        vectornum = 0; errors = 0; reset = 1; #5; reset = 0; #5;
    end

    // generate a clock to sequence tests
    always begin
        clk = 0; #5;
        clk = 1; #5;
    end

    // apply test
    always @(posedge clk)
        begin

        	d = y;

          // set test vectors when required
          currentvec = vectors[vectornum];

          dataIn_reversed = data_t'(currentvec[0:63]);
          y = data_t'(currentvec[64:127]);

        // end the test
        if (currentvec[0] === 1'bx)
            begin
                $display("Test completed with %d errors", errors);
                $stop;
            end
        end

    // check if test was sucessful and apply next one
    always @(negedge clk)
        begin
			  $display("Vectornum =%d ", vectornum);
			  //if (r[0] !== y[0] || r[1] !== y[1] || r[2] !== y[2] || r[3] !== y[3])
			  if (r !== d)
					begin
							errors = errors + 1;
							$display("Error: Vectornum =%d ", vectornum);
					$display("                    actual                expected");
					for (i = 0; i < 4; i = i + 1) begin
						$display("%d -> %d (%b)| %d (%b)", i, r[i], r[i], d[i], d[i]);
					end

					end
			  vectornum = vectornum + 1;
			end
endmodule
