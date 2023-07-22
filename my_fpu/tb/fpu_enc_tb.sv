/*
	fpu_out_type_i[4] = NAN
	fpu_out_type_i[3] = POS_inf
	fpu_out_type_i[2] = NEG_inf
	fpu_out_type_i[1] = INDET
	fpu_out_type_i[0] = FINITE
*/

/*
fpu_round_mode_i ROUND to nearest EVEN = 3'b000;
fpu_round_mode_i ROUND towards ZERO		 = 3'b001;
fpu_round_mode_i ROUND to DOWN 				 = 3'b010;
fpu_round_mode_i ROUND to UP 					 = 3'b011;
fpu_round_mode_i ROUND to NEAREST MAX  = 3'b100;
*/

module fpu_enc_tb #(
	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter BIASING_CONSTANT 	= 8'b0111_1111	
	);


	bit																fpu_clk;
	bit																fpu_rst_n;
	bit																fpu_enc_en_i;
	bit			[2:0]											fpu_round_mode_i;
	bit			[4:0] 										fpu_out_type_i;
				
	/*------------------Signals From fround-----------------*/
	bit 															fround_en_i;
	bit			[OPERAND_WIDTH-1:0]				fround_int_i;
	bit																fround_zero_i;
	bit																fround_ovf_i;
	/*------------------Signals From fround-----------------*/

	/*------------------Signals From fcast-----------------*/
	bit																fcast_sign_i;
	bit			[EXPONENT_WIDTH-1:0]			fcast_biased_exp_i;
	bit			[FRACTION_WIDTH-1:0]			fcast_frac_i;
	bit			[2:0] 										fcast_grs_i;
	bit																fcast_ovf_i;
	/*------------------Signals From fcast-----------------*/

	/*------------------Signals From faddsub-----------------*/
	bit																faddsub_sign_i;
	bit			[EXPONENT_WIDTH-1:0]			faddsub_biased_exp_i;
	bit			[FRACTION_WIDTH-1:0]			faddsub_frac_i;
	bit			[2:0] 										faddsub_grs_i;
	/*------------------Signals From faddsub-----------------*/

	/*------------------Signals From fmuldiv-----------------*/
	bit																fmuldiv_sign_i;
	bit			[EXPONENT_WIDTH-1:0]			fmuldiv_biased_exp_i;
	bit			[FRACTION_WIDTH-1:0]			fmuldiv_frac_i;
	bit			[2:0] 										fmuldiv_grs_i;
	bit																fmuldiv_exp_ovf_i;
	/*------------------Signals From fmuldiv-----------------*/

	/*------------------Signals From fcomp-----------------*/
	bit 															fcomp_en_i;		
	bit 		[OPERAND_WIDTH-1:0]				fcomp_res_i;
	/*------------------Signals From fcomp-----------------*/

	logic															fpu_enc_ready_o;
	logic		[OPERAND_WIDTH-1:0]				fpu_result_o;

	logic															fpu_enc_zf_o;
	logic															fpu_enc_ovf_o;
	logic															fpu_enc_uf_o;
	logic															fpu_enc_inf_o;
	logic															fpu_enc_nanf_o;
	
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
		fpu_rst_n 			= 1;

		//****************************************
		encoding (3'b100,5'b00010,1'b0,32'b0100_1111_0000_1010_0101_1100_0011_1111,1'b0,1'b0, 1'b0,8'b0,23'b0,3'b0,1'b0,1'b0,8'b0,23'b0,3'b0,1'b0,8'b0,23'b0,3'b0,1'b0,1'b0,32'h11);
		
		encoding (3'b001,5'b01000,1'b0,32'b0,1'b1,1'b0, 1'b0,8'b0,23'b0,3'b0,1'b0,1'b0,8'b0,23'b0,3'b0,1'b0,8'b0,23'b0,3'b0,1'b0,1'b0,32'h11);

		encoding (3'b010,5'b10000,1'b0,32'b0111_1111_1111_1111_1111_1111_1111_1111,1'b0,1'b0, 1'b0,8'b0,23'b0,3'b0,1'b0,1'b0,8'b0,23'b0,3'b0,1'b0,8'b0,23'b0,3'b0,1'b0,1'b0,32'h11);

		encoding (3'b011,5'b00001,1'b1,32'b0,1'b0,1'b0,1'b0,8'b0,23'b0,3'b0,1'b0,1'b0,8'b0,23'b0,3'b0,1'b0,8'b0,23'b0,3'b0,1'b0,1'b0,32'h11);

		encoding (3'b000,5'b01000,1'b0,32'b0,1'b0,1'b0, 1'b0,8'b1111_1110,23'b1111_1111_1111_1111_1111_111,3'b111,1'b0,1'b0,8'b0,23'b0,3'b001,1'b0,8'b0,23'b0000_0000_0000_0000_0000_100,3'b111,1'b0,1'b0,32'h11);

		encoding (3'b100,5'b00100,1'b0,32'b0,1'b0,1'b0, 1'b0,8'b0000_1000,23'b0000_0000_0000_0000_0000_100,3'b011,1'b0,1'b0,8'b0,23'b0,3'b001,1'b0,8'b0,23'b0000_0000_0000_0000_0000_100,3'b111,1'b0,1'b0,32'h11);

		encoding (3'b011,5'b00001,1'b1,32'b0,1'b0,1'b0, 1'b0,8'b0000_1000,23'b0000_0000_0000_0000_0000_100,3'b011,1'b0,1'b0,8'b0,23'b0,3'b001,1'b0,8'b0,23'b0000_0000_0000_0000_0000_100,3'b111,1'b0,1'b0,32'h11);

		encoding (3'b001,5'b01000,1'b0,32'b0,1'b0,1'b0, 1'b0,8'b0000_1000,23'b0000_0000_0000_0000_0000_100,3'b011,1'b0,1'b0,8'b0,23'b0,3'b001,1'b0,8'b0,23'b0000_0000_0000_0000_0000_100,3'b111,1'b0,1'b0,32'h11);

		encoding (3'b010,5'b00100,1'b0,32'b0,1'b0,1'b0, 1'b0,8'b0000_1000,23'b0000_0000_0000_0000_0000_100,3'b011,1'b0,1'b0,8'b0,23'b0,3'b001,1'b0,8'b0,23'b0000_0000_0000_0000_0000_100,3'b111,1'b0,1'b0,32'h11);
	
		encoding (3'b100,5'b00010,1'b0,32'b0,1'b0,1'b0, 1'b0,8'b0000_1000,23'b0000_0000_0000_0000_0000_100,3'b011,1'b0,1'b0,8'b0,23'b0,3'b001,1'b0,8'b0,23'b0000_0000_0000_0000_0000_100,3'b111,1'b0,1'b0,32'h11);

		encoding (3'b000,5'b01000,1'b0,32'b0,1'b0,1'b0, 1'b0,8'b0000_1000,23'b0000_0000_0000_0000_0000_100,3'b011,1'b0,1'b0,8'b0,23'b0,3'b001,1'b0,8'b0,23'b0000_0000_0000_0000_0000_100,3'b111,1'b0,1'b0,32'h11);

		encoding (3'b011,5'b10000,1'b0,32'b0,1'b0,1'b0, 1'b0,8'b0000_1000,23'b0000_0000_0000_0000_0000_100,3'b011,1'b0,1'b0,8'b0,23'b0,3'b001,1'b0,8'b0,23'b0000_0000_0000_0000_0000_100,3'b111,1'b0,1'b0,32'h11);

		#20 $finish;
	end

task encoding (input [2:0]	afpu_round_mode_i,[4:0] afpu_out_type_i,afround_en_i, [OPERAND_WIDTH-1:0]	afround_int_i, afround_zero_i,afround_ovf_i, afcast_sign_i,[EXPONENT_WIDTH-1:0]	afcast_biased_exp_i,[FRACTION_WIDTH+1:0]	afcast_frac_i,[2:0] afcast_grs_i, afcast_ovf_i, afaddsub_sign_i,[EXPONENT_WIDTH-1:0] afaddsub_biased_exp_i,[FRACTION_WIDTH+1:0] afaddsub_frac_i, [2:0] afaddsub_grs_i,	afmuldiv_sign_i,[EXPONENT_WIDTH-1:0]	afmuldiv_biased_exp_i,[FRACTION_WIDTH+1:0]	afmuldiv_frac_i, [2:0] afmuldiv_grs_i,afmuldiv_exp_ovf_i, afcomp_en_i,[OPERAND_WIDTH-1:0]	afcomp_res_i);

	 fpu_round_mode_i			= afpu_round_mode_i;
	 fpu_out_type_i				= afpu_out_type_i;
	 fround_en_i 					= afround_en_i;
	 fround_int_i					= afround_int_i;
	 fround_zero_i				= afround_zero_i;
	 fround_ovf_i					= afround_ovf_i;
	 fcast_sign_i					= afcast_sign_i;
	 fcast_biased_exp_i		= afcast_biased_exp_i;
	 fcast_frac_i 				= afcast_frac_i;
	 fcast_grs_i					= afcast_grs_i;
	 fcast_ovf_i					= afcast_ovf_i;
	 faddsub_sign_i				= afaddsub_sign_i;
	 faddsub_biased_exp_i	= afaddsub_biased_exp_i;
	 faddsub_frac_i				= afaddsub_frac_i;
	 faddsub_grs_i				= afaddsub_grs_i;
	 fmuldiv_sign_i				= afmuldiv_sign_i;
	 fmuldiv_biased_exp_i	= afmuldiv_biased_exp_i;
	 fmuldiv_frac_i				= afmuldiv_frac_i;
	 fmuldiv_grs_i				= afmuldiv_grs_i;
	 fmuldiv_exp_ovf_i		= afmuldiv_exp_ovf_i;
	 fcomp_en_i 					= afcomp_en_i;
	 fcomp_res_i					= afcomp_res_i;

	repeat(1) @(posedge fpu_clk);
	fpu_enc_en_i = 1'b1;
	wait(fpu_enc_ready_o)

	$display("*****************************************************************");
	if((|fround_int_i) | fround_zero_i | fround_ovf_i)
	begin 
		$display("------------OPERATION:: ROUNDING------------");
		$display("fround_int_i      	= %b",fround_int_i);
		$display("fround_zero_i     	= %b",fround_zero_i);
		$display("fround_ovf_i      	= %b",fround_ovf_i);
	end
	else if(|fcomp_res_i)
	begin
		$display("------------OPERATION:: COMPARE------------");
		$display("fcomp_res_i      	= %b",fcomp_res_i);
	end
	else
	begin
		$display("input fraction  	= %b",(fcast_frac_i|faddsub_frac_i|fmuldiv_frac_i));
		$display("input exponet   	= %b",(fcast_biased_exp_i|faddsub_biased_exp_i|fmuldiv_biased_exp_i));
		$display("fpu_enc_uf_o    	= %b",fpu_enc_uf_o    		);
		$display("fpu_enc_inf_o   	= %b",fpu_enc_inf_o   		);
		$display("fpu_enc_nanf_o  	= %b",fpu_enc_nanf_o  		);
	end
	$display("fpu_result_o     	= %b",fpu_result_o				);
	$display("fpu_enc_zf_o    	= %b",fpu_enc_zf_o    		);
	$display("fpu_enc_ovf_o   	= %b",fpu_enc_ovf_o   		);

	
	$display("*****************************************************************");
	//wait(!fpu_enc_ready_o)
	repeat(1) @(posedge fpu_clk);
	fpu_enc_en_i 	= 0;
	//repeat(1) @(posedge fpu_clk);

endtask

	fpu_enc #(
		.OPERAND_WIDTH 			(OPERAND_WIDTH 			),
		.EXPONENT_WIDTH  		(EXPONENT_WIDTH  		),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 		),
		.SIGNIFICAND_WIDTH 	(SIGNIFICAND_WIDTH 	),
		.BIASING_CONSTANT 	(BIASING_CONSTANT 	)
		) 
	encoder (
		.fpu_clk							(fpu_clk 							),
		.fpu_rst_n 						(fpu_rst_n 						),
		.fpu_enc_en_i 				(fpu_enc_en_i 				),
		.fpu_round_mode_i			(fpu_round_mode_i			),
		.fpu_out_type_i				(fpu_out_type_i				),

		.fround_en_i 					(fround_en_i 					),
		.fround_int_i					(fround_int_i					),
		.fround_zero_i				(fround_zero_i				),
		.fround_ovf_i					(fround_ovf_i					),

		.fcast_sign_i					(fcast_sign_i					),
		.fcast_biased_exp_i		(fcast_biased_exp_i		),
		.fcast_frac_i					(fcast_frac_i					),
		.fcast_grs_i					(fcast_grs_i					),
		.fcast_ovf_i					(fcast_ovf_i					),

		.faddsub_sign_i 			(faddsub_sign_i				),
		.faddsub_biased_exp_i	(faddsub_biased_exp_i	),
		.faddsub_frac_i				(faddsub_frac_i				),
		.faddsub_grs_i				(faddsub_grs_i				),

		.fmuldiv_sign_i				(fmuldiv_sign_i				),
		.fmuldiv_biased_exp_i	(fmuldiv_biased_exp_i	),
		.fmuldiv_frac_i				(fmuldiv_frac_i				),
		.fmuldiv_grs_i				(fmuldiv_grs_i				),
		.fmuldiv_exp_ovf_i		(fmuldiv_exp_ovf_i		),

		.fcomp_en_i 					(fcomp_en_i 					),
		.fcomp_res_i					(fcomp_res_i					),

		.fpu_enc_ready_o			(fpu_enc_ready_o			),
		.fpu_result_o					(fpu_result_o					),

		.fpu_enc_zf_o					(fpu_enc_zf_o					),
		.fpu_enc_ovf_o				(fpu_enc_ovf_o				),
		.fpu_enc_uf_o(				fpu_enc_uf_o					),
		.fpu_enc_inf_o				(fpu_enc_inf_o				),
		.fpu_enc_nanf_o				(fpu_enc_nanf_o				)
	);

endmodule