module fmul_div_tb #(
	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter PRCSN_WIDTH       = SIGNIFICAND_WIDTH+2,
	parameter BIASING_CONSTANT 	= 8'b0111_1111
	);

	bit 														fpu_clk;
	bit 														fpu_rst_n ;
	bit 														fmuldiv_en_i;
	bit 		 												fmuldiv_sel_i;

	bit 														fmuldiv_sign1_i;
	bit 	[EXPONENT_WIDTH-1:0]			fmuldiv_exp1_i;
	bit 	[SIGNIFICAND_WIDTH-1:0]		fmuldiv_scfnd1_i;
	
	bit 														fmuldiv_sign2_i;
	bit 	[EXPONENT_WIDTH-1:0]			fmuldiv_exp2_i;
	bit 	[SIGNIFICAND_WIDTH-1:0]		fmuldiv_scfnd2_i;
	
	logic  													fmuldiv_sign_o;
	logic  	[EXPONENT_WIDTH-1:0] 		fmuldiv_exp_o;
	logic 	[FRACTION_WIDTH-1:0] 		fmuldiv_frac_o;
	logic 	[2:0]										fmuldiv_grs_bit_o;
	logic 													fmuldiv_ready_o;
	logic 													fmuldiv_exp_ovf_o;

	logic 	[2*SIGNIFICAND_WIDTH-1:0]     	fmuldiv_check;

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

		fmuldiv(32'b1_10011011_11111010000111001011001, 32'b1_01011011_11110011110011101000101, 0);
		fmuldiv(32'b0_00100011_01111010000111001011001, 32'b1_10111011_10110011110001101000101, 0);
		fmuldiv(32'b0_00111011_10101010000101000011001, 32'b0_00001010_01100010110011101000101, 1);
		fmuldiv(32'b0_10111011_10101010000101000011001, 32'b0_01001110_01100010110011101000101, 0);
		fmuldiv(32'b0_00111011_10101010000101000011001, 32'b0_01101110_01100010110011101000101, 1);

		fmuldiv(32'b1_00000000_11111010000111001011001, 32'b1_01011011_11110011110011101000101, 0);
		fmuldiv(32'b1_01011011_11111010000111001011001, 32'b1_00000000_00110010110011101000101, 1);

		fmuldiv(32'b1_00000000_00000000000111001011001, 32'b1_00000000_00000000000011101000101, 0);
		fmuldiv(32'b1_00000000_00000000000000000011001, 32'b1_00000000_00000010000011101000101, 1);
		fmuldiv(32'b1_00000000_00000000000000000010001, 32'b1_00000000_00000010000011101000101, 0);

		fmuldiv(32'b0_01100100_11001000100100011000001, 32'b1_00010100_11111010100100011010100, 0);

		fmuldiv(32'b0_01100100_11001000100100011000001, 32'b1_00000100_11111010100100011010100, 0);

		fmuldiv(32'b0_01100100_11001000100100011000001, 32'b1_00000011_11111010100100011010100, 0);
		fmuldiv(32'b1_10100100_10001000100100011000001, 32'b1_10000100_00000000100100011010100, 0);

		fmuldiv(32'b1_00000000_00000000000000000000000, 32'b1_10000100_00000000100100011010100, 0);

		fmuldiv(32'b1_00100001_00100000000000000000000, 32'b1_10010100_10000000000000000000000, 1);
		fmuldiv(32'b1_00100001_10000000000000000000000, 32'b1_10010100_00100000000000000000000, 1);
		fmuldiv(32'b0_00111011_10101010000101000011001, 32'b0_00001010_10101010000101000011001, 1);

		fmuldiv(32'b1_00000000_00000000000000000000000, 32'b0_00001010_10101010000101000011001, 1);
		fmuldiv(32'b1_11010001_00000000000000000000000, 32'b0_11010111_10101010000101000011001, 0);
		#100 $finish;
	end

	task fmuldiv(input bit [OPERAND_WIDTH-1:0] op1, input bit [OPERAND_WIDTH-1:0] op2, input bit op_type);
	
		@(posedge fpu_clk);
		fmuldiv_en_i 			<= 1;
		fmuldiv_sel_i 		<= op_type;

		fmuldiv_sign1_i		<= op1[OPERAND_WIDTH-1];
		fmuldiv_exp1_i		<= op1[OPERAND_WIDTH-2:OPERAND_WIDTH-EXPONENT_WIDTH-1];
		fmuldiv_scfnd1_i	<= {|op1[OPERAND_WIDTH-2:OPERAND_WIDTH-EXPONENT_WIDTH-1], op1[FRACTION_WIDTH-1:0]};

		fmuldiv_sign2_i		<= op2[OPERAND_WIDTH-1];
		fmuldiv_exp2_i		<= op2[OPERAND_WIDTH-2:OPERAND_WIDTH-EXPONENT_WIDTH-1];
		fmuldiv_scfnd2_i	<= {|op2[OPERAND_WIDTH-2:OPERAND_WIDTH-EXPONENT_WIDTH-1], op2[FRACTION_WIDTH-1:0]};

		wait(fmuldiv_ready_o);
		if (fmuldiv_sel_i)
		begin
			$display("\n------------------DIVISION---------------------");
		end
		else
		begin
			$display("\n---------------MULTIPLICATION------------------");
		end
		$display("-----------------------------------------------");
		$display("SIGN_C:: %b", fmuldiv_sign_o);
		$display("EXPONENT_C:: %b", fmuldiv_exp_o);
		$display("J_BIT       FRACTION_C         | GRS");
		$display("-----       ----------           ---");
		$display("  %b    %b | %b", (|fmuldiv_exp_o) ,fmuldiv_frac_o, fmuldiv_grs_bit_o);
		$display("-----------------------------------------------");
		repeat(3) @(posedge fpu_clk);
		fmuldiv_en_i 	<= 0;
		fmuldiv_sel_i <= 0;		

	endtask : fmuldiv

	fmul_div #(

		.OPERAND_WIDTH 			(OPERAND_WIDTH 		 ),
		.EXPONENT_WIDTH  		(EXPONENT_WIDTH  	 ),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 	 ),	
		.SIGNIFICAND_WIDTH 	(SIGNIFICAND_WIDTH ),
		.PRCSN_WIDTH  			(PRCSN_WIDTH 			 ), 
		.BIASING_CONSTANT 	(BIASING_CONSTANT  )
	) 
	mult_divdr	(
		.fpu_clk 							(fpu_clk 						),
		.fpu_rst_n 						(fpu_rst_n 					),
		.fmuldiv_en_i					(fmuldiv_en_i				),
		.fmuldiv_sel_i				(fmuldiv_sel_i			),
					
		.fmuldiv_sign1_i			(fmuldiv_sign1_i		),
		.fmuldiv_exp1_i				(fmuldiv_exp1_i			),
		.fmuldiv_scfnd1_i			(fmuldiv_scfnd1_i		),
		.fmuldiv_sign2_i			(fmuldiv_sign2_i		),
		.fmuldiv_exp2_i				(fmuldiv_exp2_i			),
		.fmuldiv_scfnd2_i			(fmuldiv_scfnd2_i		),

		.fmuldiv_sign_o				(fmuldiv_sign_o			),
		.fmuldiv_exp_o				(fmuldiv_exp_o			),
		.fmuldiv_frac_o				(fmuldiv_frac_o			),
		.fmuldiv_grs_bit_o		(fmuldiv_grs_bit_o	),
		.fmuldiv_ready_o			(fmuldiv_ready_o		),
		.fmuldiv_exp_ovf_o 		(fmuldiv_exp_ovf_o  ),

		.fmuldiv_check 				(fmuldiv_check 			)
	
	);

endmodule