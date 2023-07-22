module fround_tb #(
	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter BIASING_CONSTANT 	= 8'b0111_1111		
	);
	
	bit 													fpu_clk;   
	bit 													fpu_rst_n; 
	bit 													fround_en_i;
	bit 													fround_sign_i;
	bit 	[EXPONENT_WIDTH-1:0]		fround_exp_i;
	bit 	[FRACTION_WIDTH-1:0]		fround_frac_i;

	logic [OPERAND_WIDTH-1:0] 		fround_int_o;
	logic 												fround_overflow_o;
	logic 												fround_zero_o;
	logic 												fround_ready_o;


	initial
	begin
		forever
		begin
			#5 fpu_clk = ~fpu_clk;
		end
	end

	initial
	begin

		repeat(5) @(posedge fpu_clk);
		fpu_rst_n 	<= 1;

		fround2int(1'b1, 8'b10000000, 23'b010_1101_0000_1110_0101_1001);
		fround2int(1'b1, 8'b10001000, 23'b010_1101_0000_1110_0101_1001);
		fround2int(1'b0, 8'b10011001, 23'b110_1101_0110_1110_0101_1001);
		fround2int(1'b0, 8'b10001111, 23'b111_0011_0111_1111_1111_1001);

		fround2int(1'b0, 8'b01111111, 23'b010_0101_0000_0110_0101_1011);
		fround2int(1'b1, 8'b01111110, 23'b010_1101_0000_1110_0101_1001);

		fround2int(1'b0, 8'b01111110, 23'b000_0000_0000_0000_0101_1001);
		fround2int(1'b0, 8'b01111110, 23'b000_0000_0000_0000_0000_0000);
		fround2int(1'b0, 8'b01111101, 23'b100_0010_0110_0000_0001_0011);
		fround2int(1'b0, 8'b01010101, 23'b100_1010_0110_1110_0001_0011);
		fround2int(1'b0, 8'b00000000, 23'b100_1010_0110_1110_0001_0011);

		fround2int(1'b0, 8'b10010101, 23'b111_1010_0110_1110_0001_1011);

		fround2int(1'b0, 8'b10010110, 23'b010_1110_0111_0110_1101_0011);
		fround2int(1'b0, 8'b10010111, 23'b010_1110_0111_0110_1101_0011);
		fround2int(1'b0, 8'b10011011, 23'b010_1110_0111_0110_1101_0011);

		fround2int(1'b1, 8'b10011111, 23'b010_1110_0111_0110_1101_0011);
		fround2int(1'b0, 8'b11011110, 23'b010_1110_0111_0110_1101_0011);

		#10 $finish;		
	end

	task fround2int(input bit sign, input bit [EXPONENT_WIDTH-1:0] biased_exp, input bit [FRACTION_WIDTH-1:0] frac);

		@(posedge fpu_clk);
		fround_en_i 		<= 1;
		fround_sign_i 	<= sign;
		fround_exp_i		<= biased_exp;
		fround_frac_i 	<= frac;

		wait(fround_ready_o);

		if (~(|biased_exp))
		begin
			//$display("Input floating point number:: %f", $bitstoreal({sign, biased_exp, frac}));
		end
		else
		begin
			//biased_exp = biased_exp - BIASING_CONSTANT;
			$display("Input floating point number:: %f", $bitstoshortreal({sign, biased_exp, frac}));
		end
		$display("Rounded Value:: %0d", int'(fround_int_o));
		$display("ZF:: %b", fround_zero_o);
		$display("OVF:: %b", fround_overflow_o);
		@(posedge fpu_clk);
		fround_en_i 		<= 0;
		fround_sign_i 	<= 0;
		fround_exp_i		<= 0;
		fround_frac_i 	<= 0;		
	endtask : fround2int	


	fround #(

		.OPERAND_WIDTH 			(OPERAND_WIDTH 		 ),
		.EXPONENT_WIDTH  		(EXPONENT_WIDTH  	 ),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 	 ),	
		.SIGNIFICAND_WIDTH 	(SIGNIFICAND_WIDTH ), 
		.BIASING_CONSTANT 	(BIASING_CONSTANT  )	
	) 
	rounder (

		.fpu_clk 						(fpu_clk 						),
		.fpu_rst_n 					(fpu_rst_n 					),
		.fround_en_i 				(fround_en_i 			  ),
		.fround_sign_i 			(fround_sign_i 			),
		.fround_exp_i 			(fround_exp_i 			),
		.fround_frac_i 			(fround_frac_i 			),
		.fround_int_o 			(fround_int_o 			),	
		.fround_overflow_o  (fround_overflow_o 	),	
		.fround_zero_o 			(fround_zero_o 			),
		.fround_ready_o 		(fround_ready_o 		)

	);

endmodule