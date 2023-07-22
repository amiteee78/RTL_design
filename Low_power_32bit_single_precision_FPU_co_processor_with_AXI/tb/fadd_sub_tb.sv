module fadd_sub_tb #(
	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter BIASING_CONSTANT 	= 8'b0111_1111
	);

	bit 														fpu_clk;
	bit 														fpu_rst_n ;
	bit 														faddsub_en_i;
	bit 		 												faddsub_sel_i;

	bit 														faddsub_sign1_i;
	bit 	[EXPONENT_WIDTH-1:0]			faddsub_exp1_i;
	bit 	[SIGNIFICAND_WIDTH-1:0]		faddsub_scfnd1_i;
	
	bit 														faddsub_sign2_i;
	bit 	[EXPONENT_WIDTH-1:0]			faddsub_exp2_i;
	bit 	[SIGNIFICAND_WIDTH-1:0]		faddsub_scfnd2_i;
	
	logic  													faddsub_sign_o;
	logic  	[EXPONENT_WIDTH-1:0] 		faddsub_exp_o;
	logic 	[FRACTION_WIDTH-1:0] 		faddsub_frac_o;
	logic 	[2:0]										faddsub_grs_bit_o;
	logic 													faddsub_ready_o;

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

		faddsub(32'b1_10011011_11111010000111001011001, 32'b1_10011011_11110011110011101000101, 0);
		faddsub(32'b0_10101011_01111010000111001011001, 32'b1_10111001_10110011110001101000101, 0);
		faddsub(32'b0_10011011_10101010000101000011001, 32'b0_10011010_01100010110011101000101, 1);

		faddsub(32'b0_00000000_00101010000111010010001, 32'b0_10011010_01100010110011101000101, 1);
		#100 $finish;
	end

	task faddsub(input bit [OPERAND_WIDTH-1:0] op1, input bit [OPERAND_WIDTH-1:0] op2, input bit op_type);
	
		@(posedge fpu_clk);
		faddsub_en_i 	<= 1;
		faddsub_sel_i <= op_type;

		faddsub_sign1_i		<= op1[OPERAND_WIDTH-1];
		faddsub_exp1_i		<= op1[OPERAND_WIDTH-2:OPERAND_WIDTH-EXPONENT_WIDTH-1];
		faddsub_scfnd1_i	<= {|op1[OPERAND_WIDTH-2:OPERAND_WIDTH-EXPONENT_WIDTH-1], op1[FRACTION_WIDTH-1:0]};

		faddsub_sign2_i	<= op2[OPERAND_WIDTH-1];
		faddsub_exp2_i	<= op2[OPERAND_WIDTH-2:OPERAND_WIDTH-EXPONENT_WIDTH-1];
		faddsub_scfnd2_i	<= {|op2[OPERAND_WIDTH-2:OPERAND_WIDTH-EXPONENT_WIDTH-1], op2[FRACTION_WIDTH-1:0]};

		wait(faddsub_ready_o);
		repeat(3) @(posedge fpu_clk);
		faddsub_en_i 	<= 0;
		faddsub_sel_i <= 0;		

	endtask : faddsub

	fadd_sub #(

		.OPERAND_WIDTH 			(OPERAND_WIDTH 		 ),
		.EXPONENT_WIDTH  		(EXPONENT_WIDTH  	 ),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 	 ),	
		.SIGNIFICAND_WIDTH 	(SIGNIFICAND_WIDTH ), 
		.BIASING_CONSTANT 	(BIASING_CONSTANT  )
	) 
	adder	(
		.fpu_clk 							(fpu_clk 						),
		.fpu_rst_n 						(fpu_rst_n 					),
		.faddsub_en_i					(faddsub_en_i				),
		.faddsub_sel_i				(faddsub_sel_i			),
					
		.faddsub_sign1_i			(faddsub_sign1_i		),
		.faddsub_exp1_i				(faddsub_exp1_i			),
		.faddsub_scfnd1_i			(faddsub_scfnd1_i		),
		.faddsub_sign2_i			(faddsub_sign2_i		),
		.faddsub_exp2_i				(faddsub_exp2_i			),
		.faddsub_scfnd2_i			(faddsub_scfnd2_i		),

		.faddsub_sign_o				(faddsub_sign_o			),
		.faddsub_exp_o				(faddsub_exp_o			),
		.faddsub_frac_o				(faddsub_frac_o			),
		.faddsub_grs_bit_o		(faddsub_grs_bit_o	),
		.faddsub_ready_o			(faddsub_ready_o		)
	
	);

endmodule