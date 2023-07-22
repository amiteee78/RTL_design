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
// connectivity need to be changed

`timescale 1ns/1ps

module fpu_top  #(
	parameter OPERAND_WIDTH 		= 32,

	parameter BASE_ADDR  				= 32'h0000_0000,
	parameter ADDR_WIDTH 				= 32,
	parameter DATA_WIDTH 				= 32,
	parameter STRB_WIDTH 				= DATA_WIDTH/8,

	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter PRCSN_WIDTH       = SIGNIFICAND_WIDTH+2,
	parameter OPCODE_WIDTH 			= 5,
	parameter BIASING_CONSTANT 	= 8'b0111_1111	
	)
	(

		input 	wire									fpu_clk,   
		input 	wire									fpu_rst_n, 
		input 	wire									fpu_en_i,
		output  wire									fpu_ready_o,

		/*-----------------AXI_LITE_SLAVE_INTF-----------------*/

		/*----------------Write Address Channel----------------*/
		input 	wire 									awvalid_i,
		input 	wire [ADDR_WIDTH-1:0]	awaddr_i,
		output 	wire 									awready_o,
		/*----------------Write Address Channel----------------*/
	
		/*-----------------Write Data Channel------------------*/
		input 	wire 									wvalid_i,
		input 	wire [DATA_WIDTH-1:0]	wdata_i,
		input 	wire [STRB_WIDTH-1:0] wstrb_i,
		output 	wire 									wready_o,
		/*-----------------Write Data Channel------------------*/

		/*---------------Write response Channel----------------*/
		input 	wire 									bready_i,
		output 	wire  [1:0]						bresp_o,
		output 	wire									bvalid_o,
		/*---------------Write response Channel----------------*/

		/*-----------------Read Address Channel----------------*/
		input 	wire 									arvalid_i,
		input 	wire [ADDR_WIDTH-1:0]	araddr_i,
		output 	wire 									arready_o,
		/*-----------------Read Address Channel----------------*/
	
		/*------------------Read Data Channel------------------*/
		input 	wire 									rready_i,		
		output	wire 									rvalid_o,
		output	wire [DATA_WIDTH-1:0]	rdata_o,
		output 	wire [1:0]						rresp_o
		/*------------------Read Data Channel------------------*/
		/*-----------------AXI_LITE_SLAVE_INTF-----------------*/

	);

	wire 	[DATA_WIDTH-1:0] 	                fpu_regs [0:4];
	wire 	[OPCODE_WIDTH-1:0]					fpu_opcode;
	wire 	[OPERAND_WIDTH-1:0]					fpu_operand1;
	wire 	[OPERAND_WIDTH-1:0]					fpu_operand2;
	wire 	[2:0]								fpu_round_mode;


	/*------------Decoder Interface------------*/
	wire 															fpu_dec_en;

	wire  [4:0]												fpu_out_type;

	wire 															fpu_dec_ready;
	wire 															fpu_dec_sign1;
	wire 															fpu_dec_sign2;
	wire 	[EXPONENT_WIDTH-1:0]				fpu_dec_exp1;
	wire 	[EXPONENT_WIDTH-1:0]				fpu_dec_exp2;
	wire 	[SIGNIFICAND_WIDTH-1:0]			fpu_dec_sfgnd1;
	wire 	[SIGNIFICAND_WIDTH-1:0] 		fpu_dec_sfgnd2;

	wire 	[OPERAND_WIDTH-1:0] 				fpu_res_nan;
	wire  [6:0]												fpu_operation;
	/*------------Decoder Interface------------*/

	wire 	[6:0]												fpu_mod_en;
	wire   														fpu_enc_en;

	/*------------Encoder Interface------------*/
	wire 															fpu_enc_trig;
						
	wire 	[OPERAND_WIDTH-1:0] 				fround_int;					
	wire 										 					fround_zero;				
	wire 									   					fround_ovf;
	 
	wire 															fcast_sign; 				
	wire 	[EXPONENT_WIDTH-1:0] 				fcast_biased_exp;		
	wire 	[FRACTION_WIDTH-1:0] 				fcast_frac; 				
	wire 	[2:0] 							 				fcast_grs; 					
	wire 															fcast_ovf;
	 
	wire 															faddsub_sign;			
	wire 	[EXPONENT_WIDTH-1:0]				faddsub_biased_exp;	
	wire 	[FRACTION_WIDTH-1:0]				faddsub_frac; 			
	wire 	[2:0] 											faddsub_grs;
	
	wire 															fmuldiv_sign; 			
	wire	[EXPONENT_WIDTH-1:0]				fmuldiv_biased_exp; 
	wire 	[FRACTION_WIDTH-1:0]				fmuldiv_frac; 			
	wire 	[2:0] 											fmuldiv_grs;       
	wire 															fmuldiv_exp_ovf;

	wire  [OPERAND_WIDTH-1:0]					fcomp_res;	  
	
	wire															fpu_enc_ready;
	wire 	[OPERAND_WIDTH-1:0] 		    fpu_result;

	wire															fpu_enc_zf;
	wire															fpu_enc_ovf;
	wire															fpu_enc_uf;
	wire															fpu_enc_inf;
	wire															fpu_enc_nanf;
	wire 	[4:0] 											fpu_flag;
	
	/*------------Encoder Interface------------*/

	/*------------fround Interface------------*/
	wire 															fround_en;
	wire 		[FRACTION_WIDTH-1:0]			frnd_cmp_frac;
	wire 															fround_ready;

	/*------------fround Interface------------*/

	/*------------fcast Interface------------*/
	wire 															fcast_en;
	wire 															fcast_ready;
	/*------------fcast Interface------------*/

	/*------------faddsub Interface------------*/
	wire 															faddsub_en;
	wire 															faddsub_sel;
	wire 															faddsub_ready;
	/*------------faddsub Interface------------*/

	/*------------fmuldiv Interface------------*/
	wire 															fmuldiv_en;
	wire 															fmuldiv_sel;
	wire 															fmuldiv_ready;
	/*------------fmuldiv Interface------------*/

	/*------------fcomp Interface------------*/
	wire 															fcomp_en;
	wire 		[FRACTION_WIDTH-1:0]			fcomp_frac2;
	wire 															fcomp_ready;

	/*------------fcomp Interface------------*/	

	assign fround_en    	= fpu_mod_en[0] & fpu_out_type[0];
	assign frnd_cmp_frac  = fpu_dec_sfgnd1[FRACTION_WIDTH-1:0];

	assign fcast_en 			= fpu_mod_en[1] & fpu_out_type[0];

	assign faddsub_en 		= (fpu_mod_en[2] | fpu_mod_en[3]) & fpu_out_type[0];
	assign faddsub_sel  	= (fpu_mod_en[3] & ~fpu_mod_en[2]);

	assign fmuldiv_en 		= (fpu_mod_en[4] | fpu_mod_en[5]) & fpu_out_type[0];
	assign fmuldiv_sel  	= (fpu_mod_en[5] & ~fpu_mod_en[4]);

	assign fcomp_en      	= fpu_mod_en[6] & (fpu_out_type[0] | fpu_out_type[2] | fpu_out_type[3]);
	assign fcomp_frac2    = fpu_dec_sfgnd2[FRACTION_WIDTH-1:0];		

	assign fpu_enc_trig 	= (fcomp_ready | fround_ready | fcast_ready | faddsub_ready | fmuldiv_ready | (|fpu_out_type[4:1])) & fpu_enc_en;
	assign fpu_flag     	= {fpu_enc_nanf, fpu_enc_inf, fpu_enc_ovf, fpu_enc_uf, fpu_enc_zf};

	assign fpu_round_mode = (fpu_regs[2][7:5] == 3'b111) ? fpu_regs[3][7:5] : fpu_regs[2][7:5];
	assign fpu_opcode     = fpu_regs[2][4:0];
	assign fpu_operand1   = fpu_regs[0];
	assign fpu_operand2   = fpu_regs[1];

	assign fpu_ready_o    = fpu_enc_ready;

	faxi_slv_lte #(

		.OPERAND_WIDTH  (OPERAND_WIDTH  ),
		.BASE_ADDR  		(BASE_ADDR  		), 
		.ADDR_WIDTH 		(ADDR_WIDTH 		), 
		.DATA_WIDTH 		(DATA_WIDTH 		), 
		.STRB_WIDTH 		(STRB_WIDTH 		) 
	)
	axi_slv_lt (

		.aclk							(fpu_clk				),
		.arst_n						(fpu_rst_n			),
		
		.awvalid_i				(awvalid_i			),
		.awaddr_i					(awaddr_i				),
		.awready_o				(awready_o			),
			
		.wvalid_i					(wvalid_i				),
		.wdata_i					(wdata_i				),
		.wstrb_i					(wstrb_i				),
		.wready_o					(wready_o				),
			
		.bready_i					(bready_i				),
		.bresp_o					(bresp_o				),
		.bvalid_o					(bvalid_o				),
			
		.arvalid_i				(arvalid_i			),
		.araddr_i					(araddr_i				),
		.arready_o				(arready_o			),
			
		.rready_i					(rready_i				),
		.rvalid_o					(rvalid_o				),
		.rdata_o					(rdata_o				),
		.rresp_o					(rresp_o				),

		.fpu_result_i 		(fpu_result	  	),
		.fpu_res_ready_i	(fpu_enc_ready	),
		.fpu_flag_i 			(fpu_flag     	), 
		
		.freg_o_0  					(fpu_regs[0]       ),
		.freg_o_1  					(fpu_regs[1]       ),
		.freg_o_2  					(fpu_regs[2]       ),
		.freg_o_3  					(fpu_regs[3]       ),
		.freg_o_4  					(fpu_regs[4]       )
		);

	fpu_dec #(
		.EXPONENT_WIDTH 		(EXPONENT_WIDTH 		),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 		),
		.SIGNIFICAND_WIDTH 	(SIGNIFICAND_WIDTH 	),
		.OPERAND_WIDTH     	(OPERAND_WIDTH     	),
		.OPCODE_WIDTH 			(OPCODE_WIDTH 			),
		.BIASING_CONSTANT 	(BIASING_CONSTANT 	)
	) 
	decode_unit (

		.fpu_clk 					 		(fpu_clk 				),
		.fpu_rst_n 				 		(fpu_rst_n 			),
		.fpu_dec_en_i 				(fpu_dec_en		 	),

		.fpu_opcode_i 			 	(fpu_opcode 		),
		.fpu_operand1_i 		 	(fpu_operand1   ),
		.fpu_operand2_i 		 	(fpu_operand2   ),

		.fpu_res_type_o 	 		(fpu_out_type 	),
		.fpu_dec_ready_o 			(fpu_dec_ready 	),

		.fpu_dec_sign1_o  		(fpu_dec_sign1  ),
		.fpu_dec_exp1_o	 			(fpu_dec_exp1	 	),
		.fpu_dec_sfgnd1_o 		(fpu_dec_sfgnd1 ),
		.fpu_dec_sign2_o 		 	(fpu_dec_sign2 	),
		.fpu_dec_exp2_o	 			(fpu_dec_exp2	 	),
		.fpu_dec_sfgnd2_o 		(fpu_dec_sfgnd2 ),

		.fpu_op_o							(fpu_operation 	),
		.fpu_res_nan_o 				(fpu_res_nan    )
	);

	fpu_control	control_unit (

		.fpu_clk 					(fpu_clk 				),
		.fpu_rst_n 				(fpu_rst_n 			),
		.fpu_en_i 				(fpu_en_i 			),

		.fpu_op_i 				(fpu_operation	),

		.fpu_dec_ready_i	(fpu_dec_ready	),
		.fpu_enc_ready_i	(fpu_enc_ready	),

		.fpu_dec_en_o 		(fpu_dec_en			),
		.fpu_enc_en_o 		(fpu_enc_en 		),

		.fpu_mod_en_o 		(fpu_mod_en 		)
		);


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
		.fround_en_i 				(fround_en 					),

		.fround_sign_i 			(fpu_dec_sign1 			),
		.fround_exp_i 			(fpu_dec_exp1 			),
		.fround_frac_i 			(frnd_cmp_frac 	      ),

		.fround_int_o 			(fround_int			    ),	
		.fround_overflow_o  (fround_ovf 	      ),	
		.fround_zero_o 			(fround_zero 			  ),
		.fround_ready_o 		(fround_ready 		  )
	);

	fcast #(

		.OPERAND_WIDTH     		(OPERAND_WIDTH     	),
		.EXPONENT_WIDTH 			(EXPONENT_WIDTH 		),
		.FRACTION_WIDTH 			(FRACTION_WIDTH 		),
		.SIGNIFICAND_WIDTH 		(SIGNIFICAND_WIDTH 	),
		.BIASING_CONSTANT 		(BIASING_CONSTANT 	)
	) 
	converter (

		.fpu_clk 							(fpu_clk						),
		.fpu_rst_n 						(fpu_rst_n					),
		.fcast_en_i 					(fcast_en						),
		.fcast_op_i 					(fpu_operand1			  ),

		.fcast_sign_o 				(fcast_sign 				),
		.fcast_exp_o 					(fcast_biased_exp		),
		.fcast_frac_o					(fcast_frac 		 		),
		.fcast_grs_bit_o			(fcast_grs 			 		),
		.fcast_ready_o				(fcast_ready				),
		.fcast_overflow_o			(fcast_ovf 					)
		);

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
		.faddsub_en_i					(faddsub_en				  ),
		.faddsub_sel_i				(faddsub_sel			  ),
					
		.faddsub_sign1_i			(fpu_dec_sign1  	  ),
		.faddsub_exp1_i				(fpu_dec_exp1	 		  ),
		.faddsub_scfnd1_i			(fpu_dec_sfgnd1 	  ),
		.faddsub_sign2_i			(fpu_dec_sign2  	  ),
		.faddsub_exp2_i				(fpu_dec_exp2	 		  ),
		.faddsub_scfnd2_i			(fpu_dec_sfgnd2 	  ),

		.faddsub_sign_o				(faddsub_sign 			),
		.faddsub_exp_o				(faddsub_biased_exp	),
		.faddsub_frac_o				(faddsub_frac 			),
		.faddsub_grs_bit_o		(faddsub_grs 				),
		.faddsub_ready_o			(faddsub_ready		  )
	
	);

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
		.fmuldiv_en_i					(fmuldiv_en					),
		.fmuldiv_sel_i				(fmuldiv_sel				),
					
		.fmuldiv_sign1_i			(fpu_dec_sign1  	  ),
		.fmuldiv_exp1_i				(fpu_dec_exp1	 		  ),
		.fmuldiv_scfnd1_i			(fpu_dec_sfgnd1 	  ),
		.fmuldiv_sign2_i			(fpu_dec_sign2  	  ),
		.fmuldiv_exp2_i				(fpu_dec_exp2	 		  ),
		.fmuldiv_scfnd2_i			(fpu_dec_sfgnd2 	  ),

		.fmuldiv_sign_o				(fmuldiv_sign 			),
		.fmuldiv_exp_o				(fmuldiv_biased_exp ),
		.fmuldiv_frac_o				(fmuldiv_frac 			),
		.fmuldiv_grs_bit_o		(fmuldiv_grs        ),
		.fmuldiv_ready_o			(fmuldiv_ready			),
		.fmuldiv_exp_ovf_o 		(fmuldiv_exp_ovf    )

		//.fmuldiv_check 				( 			            )
	
	);

	fcomp #(

		.OPERAND_WIDTH 			(OPERAND_WIDTH 		 ),
		.EXPONENT_WIDTH  		(EXPONENT_WIDTH  	 ),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 	 )	
	)
	comparator (

		.fpu_clk       (fpu_clk       ),   
		.fpu_rst_n     (fpu_rst_n     ),
		.fcomp_en_i    (fcomp_en      ),  

		.fcomp_sign1_i (fpu_dec_sign1 ),  
		.fcomp_exp1_i  (fpu_dec_exp1  ), 
		.fcomp_frac1_i (frnd_cmp_frac ),

		.fcomp_sign2_i (fpu_dec_sign2 ),  
		.fcomp_exp2_i  (fpu_dec_exp2  ), 
		.fcomp_frac2_i (fcomp_frac2   ),

		.fcomp_res_o   (fcomp_res     ),
		.fcomp_ready_o (fcomp_ready   ) 		

	);	

	fpu_enc #(
		.OPERAND_WIDTH 			(OPERAND_WIDTH 		),
		.EXPONENT_WIDTH  		(EXPONENT_WIDTH  	),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 	),
		.SIGNIFICAND_WIDTH 	(SIGNIFICAND_WIDTH),
		.BIASING_CONSTANT 	(BIASING_CONSTANT )
	) 
	encoder_unit(

		.fpu_clk 							(fpu_clk 						),
		.fpu_rst_n 						(fpu_rst_n 					),
		.fpu_enc_en_i 				(fpu_enc_trig 			),
		.fpu_round_mode_i 		(fpu_round_mode		  ),
		.fpu_out_type_i 			(fpu_out_type				),
		.fpu_res_nan_i 				(fpu_res_nan        ),

		.fround_en_i 					(fround_en 					),	
		.fround_int_i  				(fround_int					),
		.fround_zero_i 				(fround_zero				), 
		.fround_ovf_i  				(fround_ovf					),
		
	
		.fcast_sign_i 				(fcast_sign 				),
		.fcast_biased_exp_i 	(fcast_biased_exp		),
		.fcast_frac_i 				(fcast_frac 				),
		.fcast_grs_i 					(fcast_grs 					),
		.fcast_ovf_i 					(fcast_ovf 					),

		.faddsub_sign_i 			(faddsub_sign 			),
		.faddsub_biased_exp_i (faddsub_biased_exp	),
		.faddsub_frac_i				(faddsub_frac 			),
		.faddsub_grs_i 				(faddsub_grs 				),

		.fmuldiv_sign_i 			(fmuldiv_sign 			),
		.fmuldiv_biased_exp_i (fmuldiv_biased_exp ),
		.fmuldiv_frac_i 			(fmuldiv_frac 			),
		.fmuldiv_grs_i 				(fmuldiv_grs        ),
		.fmuldiv_exp_ovf_i 	  (fmuldiv_exp_ovf 	  ),

		.fcomp_en_i 					(fcomp_en 					),
		.fcomp_res_i 				  (fcomp_res 					),

		.fpu_enc_ready_o 			(fpu_enc_ready 			),
		.fpu_result_o 				(fpu_result       	),

		.fpu_enc_zf_o 				(fpu_enc_zf 				),
		.fpu_enc_ovf_o 				(fpu_enc_ovf 				),
		.fpu_enc_uf_o 				(fpu_enc_uf 				),
		.fpu_enc_inf_o 				(fpu_enc_inf 				),
		.fpu_enc_nanf_o 			(fpu_enc_nanf				)
	);
	
endmodule