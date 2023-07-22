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
`timescale 1ns/1ps

module fpu_enc #(
		parameter OPERAND_WIDTH 		= 32,
		parameter EXPONENT_WIDTH  	= 8,
		parameter FRACTION_WIDTH 		= 23,
		parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
		parameter BIASING_CONSTANT 	= 8'b0111_1111	
	)
	(
		input 																fpu_clk,
		input 																fpu_rst_n,
		input 																fpu_enc_en_i,
		input 			[2:0]											fpu_round_mode_i,
		input 			[4:0] 										fpu_out_type_i,

		input       [OPERAND_WIDTH-1:0]       fpu_res_nan_i,
					
		/*------------------Signals From fround-----------------*/
		input 																fround_en_i,
		input 			[OPERAND_WIDTH-1:0]				fround_int_i,
		input 																fround_zero_i,
		input 																fround_ovf_i,
		/*------------------Signals From fround-----------------*/

		/*------------------Signals From fcast-----------------*/
		input 																fcast_sign_i,
		input 			[EXPONENT_WIDTH-1:0]			fcast_biased_exp_i,
		input 			[FRACTION_WIDTH-1:0]			fcast_frac_i,
		input 			[2:0] 										fcast_grs_i,
		input 																fcast_ovf_i,
		/*------------------Signals From fcast-----------------*/

		/*------------------Signals From faddsub-----------------*/
		input 																faddsub_sign_i,
		input 			[EXPONENT_WIDTH-1:0]			faddsub_biased_exp_i,
		input 			[FRACTION_WIDTH-1:0]			faddsub_frac_i,
		input 			[2:0] 										faddsub_grs_i,
		/*------------------Signals From faddsub-----------------*/

		/*------------------Signals From fmuldiv-----------------*/
		input 																fmuldiv_sign_i,
		input 			[EXPONENT_WIDTH-1:0]			fmuldiv_biased_exp_i,
		input 			[FRACTION_WIDTH-1:0]			fmuldiv_frac_i,
		input 			[2:0] 										fmuldiv_grs_i,
		input 																fmuldiv_exp_ovf_i,
		/*------------------Signals From fmuldiv-----------------*/

		/*------------------Signals From fcomp-----------------*/
		input 																fcomp_en_i,
		input 			[OPERAND_WIDTH-1:0]				fcomp_res_i,
		/*------------------Signals From fcomp-----------------*/

		output reg 														fpu_enc_ready_o,
		output reg 	[OPERAND_WIDTH-1:0]				fpu_result_o,

		output reg														fpu_enc_zf_o,
		output reg														fpu_enc_ovf_o,
		output reg														fpu_enc_uf_o,
		output reg														fpu_enc_inf_o,
		output reg														fpu_enc_nanf_o
	);

	localparam 											START 		= 1'b0;
	localparam 											ENCODE 		= 1'b1; 											

	reg 			 			 											enc_state;
	reg 			 			 											enc_next_state;

	reg 				[FRACTION_WIDTH-1:0]			rounded_frac;
	reg 				[EXPONENT_WIDTH-1:0]			rounded_exp;
	reg 				[4:0] 										enc_flag;
	reg 				[OPERAND_WIDTH-1:0] 			fpu_result_reg;

	wire 																	exp_inc;
	wire 																	rs_or;

	wire 																	sign_mxd;
	wire 				[FRACTION_WIDTH-1:0]			frac_mxd;
	wire 				[EXPONENT_WIDTH-1:0]			exp_mxd;
	wire 				[2:0]                     grs_mxd;

	/*-----------------Generating Muxed Signals from Arithmatic Modules & Rounding Mode Signals------------------*/
	assign exp_inc 			 			= &frac_mxd;
	assign rs_or 				 			= grs_mxd[1] | grs_mxd[0];

	assign sign_mxd 			 		= fcast_sign_i | faddsub_sign_i | fmuldiv_sign_i;
	assign frac_mxd 			 		= fcast_frac_i | faddsub_frac_i | fmuldiv_frac_i;
	assign exp_mxd  					= fcast_biased_exp_i | faddsub_biased_exp_i | fmuldiv_biased_exp_i;
	assign grs_mxd 						= fcast_grs_i | faddsub_grs_i | fmuldiv_grs_i;
	/*-----------------Generating Muxed Signals from Arithmatic Modules & Rounding Mode Signals------------------*/

	always @(posedge fpu_clk or negedge fpu_rst_n) 
	begin
		if(~fpu_rst_n) 
		begin
			enc_state <= START;
		end 
		else 
		begin
			enc_state <= enc_next_state;
		end
	end
	/*-----------------Defining Internal Register------------------*/

	/*-----------------Defining Internal Register------------------*/
	always @(posedge fpu_clk or negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			enc_flag   			<= '0;
			fpu_result_reg 	<= '0;
		end

		else if (enc_next_state == ENCODE)
		begin
			if (fpu_out_type_i[4] | fpu_out_type_i[1]) // NaN
			begin
				enc_flag   <= 5'b10000;
			end
			else if ((&rounded_exp) & (|rounded_frac) & fpu_out_type_i[0]) //NaN from Finite op
			begin
				enc_flag   <= 5'b10100;
			end
			else if (fpu_out_type_i[3] | fpu_out_type_i[2]) //inf
			begin
				enc_flag   <= 5'b00001;
			end
			else if ((&rounded_exp) & (~(|rounded_frac)) & fpu_out_type_i[0]) //INF from Finite op
			begin
				enc_flag   <= 5'b00101;
			end
			else if ((~(|rounded_exp)) & (|rounded_frac)) //Underflow
			begin
				enc_flag   <= 5'b00010;
			end
			else if (fround_zero_i | ((fcomp_res_i == 0) & fcomp_en_i)) // zero flag by fround/fcomp
			begin
				$display("****************************CHECK****************************");
				enc_flag   <= {1'b0, 1'b1, 3'b00};
			end
			else if (~(|rounded_exp) & ~(|rounded_frac) & (~fround_en_i) & ~(fcomp_en_i))  //ZeroFlag by finite op
			begin
				//$display("CHECK");
				enc_flag   <= {1'b0, 1'b1, fmuldiv_exp_ovf_i, 2'b00};
			end
			else // Rounding/Casting overflow
			begin
				enc_flag   <= {2'b00, (fround_ovf_i | fcast_ovf_i), 2'b00};
			end

			case (fpu_out_type_i)
				5'b10000 : fpu_result_reg <= fpu_res_nan_i;
				5'b01000 : fpu_result_reg <= 32'h7F80_0000;
				5'b00100 : fpu_result_reg <= 32'hFF80_0000;
				5'b00010 : fpu_result_reg <= 32'h7FC0_0000;
				5'b00001 : fpu_result_reg <= {sign_mxd, rounded_exp, rounded_frac} | fround_int_i | fcomp_res_i;
			endcase

		end

/*		else
		begin
			enc_flag   			<= 0;
			fpu_result_reg 	<= 0;	
		end*/
	end
	/*-----------------Defining Internal Register------------------*/

	/*-----------------Defining Next State Logic & Output Logic------------------*/
	always @(*) 
	begin
		case (enc_state)
			START:
			begin
				fpu_enc_nanf_o 		<= 0;
				fpu_enc_zf_o   		<= 0;
				fpu_enc_ovf_o  		<= 0;
				fpu_enc_uf_o   		<= 0;
				fpu_enc_inf_o  		<= 0;

				fpu_result_o      <= 0;
				fpu_enc_ready_o		<= 0;

				if (fpu_enc_en_i)
				begin
					enc_next_state 	<= ENCODE;
				end
				else
				begin
					enc_next_state 	<= START;
				end				
			end

			ENCODE:
			begin
				{fpu_enc_nanf_o, fpu_enc_zf_o, fpu_enc_ovf_o, fpu_enc_uf_o, fpu_enc_inf_o} <= enc_flag;
				fpu_result_o 			<= fpu_result_reg;
				fpu_enc_ready_o		<= 1;
				
				if (fpu_enc_en_i)
				begin
					enc_next_state 	<= ENCODE;
				end
				else
				begin
					enc_next_state 	<= START;
				end	
			end

			default :
			begin
				fpu_enc_nanf_o 		<= 0;
				fpu_enc_zf_o   		<= 0;
				fpu_enc_ovf_o  		<= 0;
				fpu_enc_uf_o   		<= 0;
				fpu_enc_inf_o  		<= 0;

				fpu_result_o      <= 0;
				fpu_enc_ready_o		<= 0;
				enc_next_state 		<= START;
			end				
		endcase
	end
	/*-----------------Defining Next State Logic & Output Logic------------------*/

	/*----------------------------Rounding------------------------------*/
	always @(*) 
	begin

		if (fpu_enc_en_i & rs_or)
		begin

			case (fpu_round_mode_i)
				3'b000: // ROUND to nearest EVEN
				begin
					rounded_frac 		<=	frac_mxd + grs_mxd[2];
					rounded_exp			<= 	exp_mxd + exp_inc;
				end
				3'b001: // ROUND towards ZERO
				begin
					rounded_frac		<= frac_mxd;
					rounded_exp 		<= exp_mxd;
				end
				3'b010: // ROUND to DOWN
				begin
					rounded_frac 		<=	frac_mxd + sign_mxd;
					rounded_exp			<= 	exp_mxd + (sign_mxd & exp_inc);
				end
				3'b011: // ROUND to UP
				begin
					rounded_frac 		<=	frac_mxd + (!sign_mxd);
					rounded_exp			<= 	exp_mxd + ((!sign_mxd) & exp_inc);
				end
				3'b100: // ROUND to NEAREST MAX
				begin
					rounded_frac 		<=	frac_mxd + 1;
					rounded_exp			<= 	exp_mxd + exp_inc;
				end
				default : 
				begin
					rounded_frac 		<= 	frac_mxd;
					rounded_exp 		<= 	exp_mxd;
				end
			endcase
		end
			
		else if (fpu_enc_en_i & ~rs_or)
		begin
			rounded_frac 		<= frac_mxd;
			rounded_exp 		<= exp_mxd;
		end
		else
		begin
			rounded_frac		<= 0;
			rounded_exp		  <= 0;
		end
	end
	/*----------------------------Rounding------------------------------*/
endmodule