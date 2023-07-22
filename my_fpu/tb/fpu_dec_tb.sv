/*
	fpu_out_type_i[4] = NAN
	fpu_out_type_i[3] = POS_inf
	fpu_out_type_i[2] = NEG_inf
	fpu_out_type_i[1] = INDET
	fpu_out_type_i[0] = FINITE

	fpu_op_i[6] = COMP
	fpu_op_i[5] = DIV
	fpu_op_i[4] = MULT
	fpu_op_i[3] = SUB
	fpu_op_i[2] = ADD
	fpu_op_i[1] = CAST
	fpu_op_i[0] = ROUND
*/

/*
fpu_round_mode_i ROUND to nearest EVEN = 3'b000;
fpu_round_mode_i ROUND towards ZERO		 = 3'b001;
fpu_round_mode_i ROUND to DOWN 				 = 3'b010;
fpu_round_mode_i ROUND to UP 					 = 3'b011;
fpu_round_mode_i ROUND to NEAREST MAX  = 3'b100;
*/

// 
//**********Opcode Value of Round to Integer  = 00001
//**********Opcode Value of Cast to Float 		= 00010
//**********Opcode Value of Addition 					= 00011
//**********Opcode Value of Subtraction 			= 00100
//**********Opcode Value of Multiplication 		= 00101
//**********Opcode Value of Division 					= 00110
//**********Opcode Value of Compare 					= 00111 
//


module fpu_dec_tb #(
	parameter OPERAND_WIDTH     = 32,
	parameter EXPONENT_WIDTH 		= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter BIASING_CONSTANT 	= 8'b0111_1111,
	parameter OPCODE_WIDTH 			= 5
	);


	bit		 															fpu_clk;
	bit		 															fpu_rst_n;
	bit 																fpu_dec_en_i;

	bit		[OPCODE_WIDTH-1:0]						fpu_opcode_i;
	bit		[OPERAND_WIDTH-1:0]						fpu_operand1_i;
	bit		[OPERAND_WIDTH-1:0]						fpu_operand2_i;

	logic	[4:0] 												fpu_res_type_o;
	logic 															fpu_dec_ready_o;

	logic																fpu_dec_sign1_o;
	logic	[EXPONENT_WIDTH-1:0]					fpu_dec_exp1_o;
	logic	[SIGNIFICAND_WIDTH-1:0] 			fpu_dec_sfgnd1_o;

	logic																fpu_dec_sign2_o;
	logic	[EXPONENT_WIDTH-1:0]					fpu_dec_exp2_o;	
	logic	[SIGNIFICAND_WIDTH-1:0] 			fpu_dec_sfgnd2_o;

	logic	[6:0] 												fpu_op_o;



	initial begin

		repeat(5) @(posedge fpu_clk);
		fpu_rst_n    		= 1;

		//*************OperandA = Positive Infinity and OperandB = Positive Infinity
		decoding(5'b00001, 32'b011110111_00000000000000000000000, 32'b011111111_10000010000000000000000);
		decoding(5'b00010, 32'b011110111_00000000000000000000000, 32'b011111111_10000010000000000000000);
		decoding(5'b00011, 32'b011110111_00000000000000000000000, 32'b011111111_10000010000000000000000);
		decoding(5'b00100, 32'b011110111_00000000000000000000000, 32'b011111111_10000010000000000000000);
		decoding(5'b00101, 32'b011110111_00000000000000000000000, 32'b011111111_10000010000000000000000);
		decoding(5'b00110, 32'b011110111_00000000000000000000000, 32'b011111111_10000010000000000000000);
		decoding(5'b00111, 32'b011110111_00000000000000000000000, 32'b011111111_10000010000000000000000);

		//*************OperandA = Positive Infinity and OperandB = Positive Infinity
		decoding(5'b00001, 32'b011111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00010, 32'b011111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00011, 32'b011111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00100, 32'b011111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00101, 32'b011111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00110, 32'b011111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00111, 32'b011111111_00000000000000000000000, 32'b011111111_00000000000000000000000);

		//*************OperandA = Positive Infinity and OperandB = Negative Infinity
		decoding(5'b00001, 32'b011111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00010, 32'b011111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00011, 32'b011111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00100, 32'b011111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00101, 32'b011111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00110, 32'b011111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00111, 32'b011111111_00000000000000000000000, 32'b111111111_00000000000000000000000);


		//*************OperandA = Negative Infinity and OperandB = Positive Infinity
		decoding(5'b00001, 32'b111111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00010, 32'b111111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00011, 32'b111111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00100, 32'b111111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00101, 32'b111111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00110, 32'b111111111_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00111, 32'b111111111_00000000000000000000000, 32'b011111111_00000000000000000000000);


		//*************OperandA = Negative Infinity and OperandB = Negative Infinity	
		decoding(5'b00001, 32'b111111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00010, 32'b111111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00011, 32'b111111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00100, 32'b111111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00101, 32'b111111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00110, 32'b111111111_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00111, 32'b111111111_00000000000000000000000, 32'b111111111_00000000000000000000000);

		//*************OperandA = Positive Infinity and OperandB = Zero
		decoding(5'b00001, 32'b011111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00010, 32'b011111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00011, 32'b011111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00100, 32'b011111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00101, 32'b011111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00110, 32'b011111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00111, 32'b011111111_00000000000000000000000, 32'b000000000_00000000000000000000000);

		//*************OperandA = Zero and OperandB = Positive Infinity
		decoding(5'b00001, 32'b000000000_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00010, 32'b000000000_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00011, 32'b000000000_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00100, 32'b000000000_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00101, 32'b000000000_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00110, 32'b000000000_00000000000000000000000, 32'b011111111_00000000000000000000000);
		decoding(5'b00111, 32'b000000000_00000000000000000000000, 32'b011111111_00000000000000000000000);

		//*************OperandA = Negative Infinity and OperandB = Zero
		decoding(5'b00001, 32'b111111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00010, 32'b111111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00011, 32'b111111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00100, 32'b111111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00101, 32'b111111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00110, 32'b111111111_00000000000000000000000, 32'b000000000_00000000000000000000000);
		decoding(5'b00111, 32'b111111111_00000000000000000000000, 32'b000000000_00000000000000000000000);

		//*************OperandA = Zero and OperandB = Negative Infinity
		decoding(5'b00001, 32'b000000000_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00010, 32'b000000000_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00011, 32'b000000000_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00100, 32'b000000000_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00101, 32'b000000000_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00110, 32'b000000000_00000000000000000000000, 32'b111111111_00000000000000000000000);
		decoding(5'b00111, 32'b000000000_00000000000000000000000, 32'b111111111_00000000000000000000000);

		//*************OperandA = Positive Infinity and OperandB = Positive Finite Number
		fpu_operand1_i		= 32'b011111111_00000000000000000000000;
		fpu_operand2_i		= 32'b011100111_00000000000000000000000;

		decoding(5'b00001, 32'b011111111_00000000000000000000000, 32'b011100111_00000000000000000000000);
		decoding(5'b00010, 32'b011111111_00000000000000000000000, 32'b011100111_00000000000100000000000);
		decoding(5'b00011, 32'b011111111_00000000000000000000000, 32'b011100110_01000010011000000000000);
		decoding(5'b00100, 32'b011111111_00000000000000000000000, 32'b011100011_10000000000000000000000);
		decoding(5'b00101, 32'b011111111_00000000000000000000000, 32'b001100110_00000000000000000000000);
		decoding(5'b00110, 32'b011111111_00000000000000000000000, 32'b011100110_10100000000000000000001);
		decoding(5'b00111, 32'b011111111_00000000000000000000000, 32'b001010011_00100110000000000010001);

		//*************OperandA = Positive Finite Number and OperandB = Positive Infinity
		fpu_operand1_i		= 32'b011000111_00000000000000000000000;
		fpu_operand2_i		= 32'b011111111_00000000000000000000000;

		//*************OperandA = Positive Infinity and OperandB = Negative Finite Number
		fpu_operand1_i		= 32'b011111111_00000000000000000000000;
		fpu_operand2_i		= 32'b111100111_00000000000000000000000;

		//*************OperandA =  Negative Finite Number and OperandB = Positive Infinity
		fpu_operand1_i		= 32'b111000111_00000000000000000000000;
		fpu_operand2_i		= 32'b011111111_00000000000000000000000;

		//*************OperandA =  Negative infinity Number and OperandB = Positive Finite Number
		fpu_operand1_i		= 32'b111111111_00000000000000000000000;
		fpu_operand2_i		= 32'b011100111_00000000000000000000000;

		//*************OperandA =  Positive Finite Number and OperandB = Negative infinity Number
		fpu_operand1_i		= 32'b011000111_00000000000000000000000;
		fpu_operand2_i		= 32'b111111111_00000000000000000000000;

		//*************OperandA =  Negative infinity Number and OperandB =  Negative Finite Number 
		fpu_operand1_i		= 32'b111111111_00000000000000000000000;
		fpu_operand2_i		= 32'b111100111_00000000000000000000000;

		//*************OperandA =   Negative Finite Number and OperandB = Negative infinity Number 
		fpu_operand1_i		= 32'b111000111_00000000000000000000000;
		fpu_operand2_i		= 32'b111111111_00000000000000000000000;

		//*************OperandA =   Positive Finite Number and OperandB = Positive infinity Number 
		fpu_operand1_i		= 32'b011000111_00000000000000000000000;
		fpu_operand2_i		= 32'b011111111_00000000000000000000000;

		//*************OperandA = Positive Finite Number and OperandB = Positive Finite Number 
		fpu_operand1_i		= 32'b011000111_00000000000000000000000;
		fpu_operand2_i		= 32'b001111111_00000000000000000000000;

		//*************OperandA = Positive Finite Number and OperandB = Negative Finite Number 
		fpu_operand1_i		= 32'b011000111_00000000000000000000000;
		fpu_operand2_i		= 32'b101111111_00000000000000000000000;

		//*************OperandA = Zero and OperandB = Positive Finite Number 
		fpu_operand1_i		= 32'b000000000_00000000000000000000000;
		fpu_operand2_i		= 32'b001111111_00000000000000000000000;

		//*************OperandA = Zero  and OperandB = Zero
		fpu_operand1_i		= 32'b000000000_00000000000000000000000;
		fpu_operand2_i		= 32'b000000000_00000000000000000000000;

		//*************OperandA = OperandB = Positive Finite Number 
		fpu_operand1_i		= 32'b000111110_00000000100000000000000;
		fpu_operand2_i		= 32'b000111110_00000000100000000000000;


		
		//*************OperandA = -OperandB =  Finite Number 
		fpu_operand1_i		= 32'b000111110_00000000100000000000000;
		fpu_operand2_i		= 32'b100111110_00000000100000000000000;



		//*************OperandA = Zero and OperandB = Positive Finite Number 
		fpu_operand1_i		= 32'b000000000_00000000000000000000000;
		fpu_operand2_i		= 32'b000111110_00000000100000000000000;


		#20
		$finish;
	end

	initial
	begin
		forever
		begin
			#5 fpu_clk = ~fpu_clk;
		end
	end

	fpu_dec#(
		.EXPONENT_WIDTH 		(EXPONENT_WIDTH 		),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 		),
		.SIGNIFICAND_WIDTH 	(SIGNIFICAND_WIDTH 	),
		.OPERAND_WIDTH      (OPERAND_WIDTH      ),
		.BIASING_CONSTANT 	(BIASING_CONSTANT 	),
		.OPCODE_WIDTH 			(OPCODE_WIDTH 			)
		)  
	decodingr(

		.fpu_clk 					 		(fpu_clk 							),
		.fpu_rst_n 				 		(fpu_rst_n 						),
		.fpu_dec_en_i 				(fpu_dec_en_i 				),
		.fpu_opcode_i 			 	(fpu_opcode_i 				),
		.fpu_operand1_i 		 	(fpu_operand1_i 			),
		.fpu_operand2_i 		 	(fpu_operand2_i 			),
		.fpu_res_type_o 	 		(fpu_res_type_o 	 	  ),
		.fpu_dec_ready_o 			(fpu_dec_ready_o			),
		.fpu_dec_sign1_o  		(fpu_dec_sign1_o  		),
		.fpu_dec_exp1_o	 			(fpu_dec_exp1_o	 			),
		.fpu_dec_sfgnd1_o 		(fpu_dec_sfgnd1_o 		),
		.fpu_dec_sign2_o 		 	(fpu_dec_sign2_o 			),
		.fpu_dec_exp2_o	 			(fpu_dec_exp2_o	 			),
		.fpu_dec_sfgnd2_o 		(fpu_dec_sfgnd2_o 		),
		.fpu_op_o							(fpu_op_o 						)
	);

	task decoding(input [OPCODE_WIDTH-1:0] i_fpu_opcode_i, [OPERAND_WIDTH-1:0]i_fpu_operand1_i, [OPERAND_WIDTH-1:0]i_fpu_operand2_i);

		repeat(2) @(posedge fpu_clk);
		fpu_opcode_i   			= i_fpu_opcode_i   ;
		fpu_operand1_i			= i_fpu_operand1_i;
		fpu_operand2_i			= i_fpu_operand2_i;
		fpu_dec_en_i        = 1'b1;

		wait(fpu_dec_ready_o);
		$display("*******************************************");
		$display("OPERAND_1        	= %b " , fpu_operand1_i  );
		$display("OPERAND_2        	= %b " , fpu_operand2_i  );
		$display("fpu_dec_sign1_o  	= %b " , fpu_dec_sign1_o );
		$display("fpu_dec_sign2_o  	= %b " , fpu_dec_sign2_o );
		$display("fpu_dec_exp1_o   	= %b " , fpu_dec_exp1_o  );
		$display("fpu_dec_exp2_o   	= %b " , fpu_dec_exp2_o  );
		$display("fpu_dec_sfgnd1_o  	= %b " , fpu_dec_sfgnd1_o );
		$display("fpu_dec_sfgnd2_o  	= %b " , fpu_dec_sfgnd2_o );

		if 	   (fpu_op_o==7'b1000000)		$display("fpu_op_o     		= %b (Compare)" , 				fpu_op_o		);//, $time);
		else if(fpu_op_o==7'b0100000)		$display("fpu_op_o     		= %b (Division)" , 			fpu_op_o		);//, $time);
		else if(fpu_op_o==7'b0010000)		$display("fpu_op_o     		= %b (Multiplication)" , fpu_op_o		);//, $time);
		else if(fpu_op_o==7'b0001000)		$display("fpu_op_o     		= %b (Subtract)" , 			fpu_op_o		);//, $time);
		else if(fpu_op_o==7'b0000100)		$display("fpu_op_o     		= %b (Addition)" , 			fpu_op_o		);//, $time);
		else if(fpu_op_o==7'b0000010)		$display("fpu_op_o     		= %b (Cast to float)" , 	fpu_op_o		);//, $time);
		else 	 													$display("fpu_op_o     		= %b (Rounding)" , 			fpu_op_o		);//, $time);


		if 	 		(fpu_res_type_o==5'b10000)   $display("fpu_res_type_o    	= %b   (QNAN)" , 					fpu_res_type_o );
		else if	(fpu_res_type_o==5'b01000)   $display("fpu_res_type_o    	= %b   (POS_INF)" , 				fpu_res_type_o );
		else if	(fpu_res_type_o==5'b00100)   $display("fpu_res_type_o    	= %b   (NEG_INF)" , 				fpu_res_type_o );
		else if	(fpu_res_type_o==5'b00010)   $display("fpu_res_type_o    	= %b   (INDET)" , 					fpu_res_type_o );
		else 	 												 	  	 $display("fpu_res_type_o    	= %b   (FINITE_or_ZERO)" ,	fpu_res_type_o );
		$display("*******************************************");

		repeat(7) @(posedge fpu_clk);
		fpu_opcode_i  	= 0;
		fpu_operand1_i  = 0;
		fpu_operand2_i  = 0;
		fpu_dec_en_i    = 0;

	endtask : decoding

endmodule