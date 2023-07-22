module fcast_tb #(
	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter BIASING_CONSTANT 	= 8'b0111_1111
	);

	bit 														fpu_clk;
	bit 														fpu_rst_n ;
	bit 														fcast_en_i;
	bit 		[OPERAND_WIDTH-1:0] 		fcast_op_i;
	
	logic  													fcast_sign_o;
	logic  	[EXPONENT_WIDTH-1:0] 		fcast_exp_o;
	logic 	[FRACTION_WIDTH-1:0] 		fcast_frac_o;
	logic 	[2:0]										fcast_grs_bit_o;
	logic 													fcast_ready_o;
	logic  													fcast_overflow_o;

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

		fcast2float(32'b0000_0000_1111_1111_1111_1000_1011_0010);

		fcast2float(32'b1111_1111_0000_0000_0000_0111_0100_1110);

		fcast2float(32'b0000_0000_0000_1111_1111_1000_0011_1011);

		fcast2float(32'b1011_1111_1111_0000_0000_0111_1100_0101);

		fcast2float(32'b0000_1101_0000_1111_1111_1000_0011_1011);

		fcast2float(32'b1111_0010_1111_0000_0000_0111_1100_0101);

		fcast2float(32'b1111_0010_1111_0000_0000_0111_1100_0101);

		fcast2float(32'b0111_1111_1111_1111_1111_1111_1111_1111);

		#100 $finish;
	end

	task fcast2float(input bit [OPERAND_WIDTH-1:0] operand);

		@(posedge fpu_clk);
		fcast_en_i <= 1;
		fcast_op_i <= operand;
		wait(fcast_ready_o)
		$display("***********************************************");
		$display("INPUT   	 : %b_%b_%b_%b_%b_%b_%b_%b",fcast_op_i[31:28],fcast_op_i[27:24],fcast_op_i[23:20],fcast_op_i[19:16],fcast_op_i[15:12],fcast_op_i[11:8],fcast_op_i[7:4],fcast_op_i[3:0]);
		$display("SIGN    	 : %b",fcast_sign_o);
		$display("EXPONENT	 : %b",fcast_exp_o);
		$display("FRACTION	 : %b_%b_%b_%b_%b_%b",fcast_frac_o[22:20],fcast_frac_o[19:16],fcast_frac_o[15:12],fcast_frac_o[11:8],fcast_frac_o[7:4],fcast_frac_o[3:0]);
		$display("fcast_overflow_o : %b",fcast_overflow_o);
		$display("IEEE 754         : %b%b%b",fcast_sign_o, fcast_exp_o, fcast_frac_o);
		$display("GRS_BIT          : %b",fcast_grs_bit_o);
		$display("***********************************************");
		repeat(3) @(posedge fpu_clk);
		fcast_en_i <= 0;
		fcast_op_i <= 0;

	endtask : fcast2float


	fcast #(

		.OPERAND_WIDTH 			(OPERAND_WIDTH 		 ),
		.EXPONENT_WIDTH  		(EXPONENT_WIDTH  	 ),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 	 ),	
		.SIGNIFICAND_WIDTH 	(SIGNIFICAND_WIDTH ), 
		.BIASING_CONSTANT 	(BIASING_CONSTANT  )
	) 
	converter	(
		.fpu_clk							(fpu_clk					),
		.fpu_rst_n 						(fpu_rst_n 				),
		.fcast_en_i						(fcast_en_i				),
		
		.fcast_op_i						(fcast_op_i				),
		.fcast_sign_o 				(fcast_sign_o 		),
		.fcast_exp_o 					(fcast_exp_o 			),
		.fcast_frac_o					(fcast_frac_o			),
		.fcast_grs_bit_o 			(fcast_grs_bit_o 	),
		.fcast_ready_o				(fcast_ready_o		),
		.fcast_overflow_o			(fcast_overflow_o	)
	);

endmodule