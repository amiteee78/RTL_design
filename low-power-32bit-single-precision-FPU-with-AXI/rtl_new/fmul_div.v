`timescale 1ns/1ps
module fmul_div #(

	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter PRCSN_WIDTH       = SIGNIFICAND_WIDTH+2,
	parameter BIASING_CONSTANT 	= 8'b0111_1111
	)
	(
		input 														fpu_clk,   
		input 														fpu_rst_n,
		input 														fmuldiv_en_i,
		input 														fmuldiv_sel_i,

		input 														fmuldiv_sign1_i,
		input 	[EXPONENT_WIDTH-1:0]			fmuldiv_exp1_i,
		input 	[SIGNIFICAND_WIDTH-1:0]		fmuldiv_scfnd1_i,

		input 														fmuldiv_sign2_i,
		input 	[EXPONENT_WIDTH-1:0]			fmuldiv_exp2_i,
		input 	[SIGNIFICAND_WIDTH-1:0]		fmuldiv_scfnd2_i,

		output reg 												fmuldiv_sign_o,
		output reg 	[EXPONENT_WIDTH-1:0] 	fmuldiv_exp_o,
		output reg	[FRACTION_WIDTH-1:0] 	fmuldiv_frac_o,
		output reg 	[2:0]									fmuldiv_grs_bit_o,
		output reg 												fmuldiv_ready_o,
		output reg 												fmuldiv_exp_ovf_o

		//output reg 	[2*SIGNIFICAND_WIDTH-1:0]     	fmuldiv_check //only for check

	);

	localparam 	[2:0] 													START			= 3'b000;
	localparam 	[2:0] 													FSFT 			= 3'b001;
	localparam 	[2:0] 													FMUL 			= 3'b010;
	localparam  [2:0] 													FDIV 			= 3'b011;
	localparam  [2:0] 													EADJST 	  = 3'b100;
	localparam  [2:0] 													DFSFT 	  = 3'b101;
	localparam  [2:0] 													FADJST 	  = 3'b110;
	localparam  [2:0] 													CALC			= 3'b111;


	reg 				[2:0]														fmuldiv_state;
	reg 				[2:0]														fmuldiv_next_state;

	reg 				[SIGNIFICAND_WIDTH-1:0] 				sfcnd1;
	reg 				[SIGNIFICAND_WIDTH-1:0] 				sfcnd2;
	reg 				[$clog2(OPERAND_WIDTH)-1:0]			frac_shift1;				
	reg 				[$clog2(OPERAND_WIDTH)-1:0]			frac_shift2;
	reg 				[$clog2(OPERAND_WIDTH)-1:0]			dfrac_shift;

	reg 				[2*SIGNIFICAND_WIDTH-1:0]     	fmul_res;
	reg 				[$clog2(SIGNIFICAND_WIDTH)-1:0] muldiv_count;

	reg 				[2*PRCSN_WIDTH+1:0] 						fdiv_rem;
	reg 				[PRCSN_WIDTH-1:0]  	 	 					fdiv_res;

	reg																					fmuldiv_exp_ovf_reg;
	reg																					fmuldiv_sign_reg   ;	

	wire 																				is1_denorm;
	wire 																				is2_denorm;

	reg 				[2*EXPONENT_WIDTH-1:0] 					expnt1;
	reg 				[2*EXPONENT_WIDTH-1:0] 					expnt2;


	wire 																				is1_norm;
	wire 																				is2_norm;

	wire 																				is2_inf;

	wire 				[SIGNIFICAND_WIDTH:0] 					sftd_multplr;
	wire				[2*SIGNIFICAND_WIDTH-1:0] 			pos_multpcnd;
	wire				[2*SIGNIFICAND_WIDTH-1:0] 			neg_multpcnd;
	wire				[2*SIGNIFICAND_WIDTH-1:0] 			pos_two_multpcnd;
	wire				[2*SIGNIFICAND_WIDTH-1:0] 			neg_two_multpcnd;

	wire 																				is_rem_neg;

	wire 																				fmul_adjst;
	wire 																				fdiv_adjst;
	wire 																				is_neg_unb_exp;
	reg 																				is_res_zero;

	reg 																				is_res_denorm;
	reg 																				is_neg_exp_ovf;
	reg 																				is_pos_exp_ovf;

	/*------------------Differentiating Normalized & Denormalized Input------------------*/

	assign is1_denorm 			= fmuldiv_en_i & (~fmuldiv_scfnd1_i[SIGNIFICAND_WIDTH-1] & (|fmuldiv_scfnd1_i)) ;
	assign is2_denorm 			= fmuldiv_en_i & (~fmuldiv_scfnd2_i[SIGNIFICAND_WIDTH-1] & (|fmuldiv_scfnd2_i)) ;
		
	assign is1_norm 				= fmuldiv_en_i & fmuldiv_scfnd1_i[SIGNIFICAND_WIDTH-1] ;
	assign is2_norm 				= fmuldiv_en_i & fmuldiv_scfnd2_i[SIGNIFICAND_WIDTH-1] ;	

	/*------------------Differentiating Normalized & Denormalized Input------------------*/

	/*-------------Generating Necessary Signals for Booth Encoding--------------*/
	assign 	pos_multpcnd     	= fmuldiv_en_i ? sfcnd1 : 0;
	assign 	neg_multpcnd     	= fmuldiv_en_i ? -sfcnd1 : 0;
	assign 	pos_two_multpcnd 	= fmuldiv_en_i ? {sfcnd1, 1'b0} : 0;
	assign 	neg_two_multpcnd 	= fmuldiv_en_i ? -{sfcnd1, 1'b0} : 0;

	assign  sftd_multplr  		= fmuldiv_en_i ? {sfcnd2,1'b0} >> muldiv_count : 0;

	assign  fmul_adjst 				= fmul_res[2*SIGNIFICAND_WIDTH-1];
	/*-------------Generating Necessary Signals for Booth Encoding--------------*/

	assign  is_neg_unb_exp    = expnt1[2*EXPONENT_WIDTH-1];
  
	assign 	is_rem_neg 				= fdiv_rem[2*PRCSN_WIDTH+1];
	assign  fdiv_adjst 				= ~fdiv_res[PRCSN_WIDTH-1];

	assign  is2_inf           = fmuldiv_en_i & (&fmuldiv_exp2_i) & ~(|fmuldiv_scfnd2_i[FRACTION_WIDTH-1:0]);

	/*-----------Defining State Register----------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			fmuldiv_state  <= START;
		end
		else
		begin
			fmuldiv_state  <= fmuldiv_next_state;
		end
	end
	/*-----------Defining State Register----------*/

	/*------------Defining Internal Register--------------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			sfcnd1   						<= 0;
			sfcnd2   						<= 0;
			expnt1 							<= 0;
			expnt2 							<= 0;
			muldiv_count 				<= 0;
			fmul_res   					<= 0;

			fdiv_rem 						<= 0;
			fdiv_res 						<= 0;

			fmuldiv_exp_ovf_reg <= 0;
			fmuldiv_sign_reg   	<= 0;
			is_res_zero 				<= 0;

		end

		else if (fmuldiv_next_state == FSFT)
		begin
			sfcnd1   						<= fmuldiv_scfnd1_i << frac_shift1;
			sfcnd2  						<= fmuldiv_scfnd2_i << frac_shift2;
			fmuldiv_sign_reg    <= fmuldiv_sign1_i ^ fmuldiv_sign2_i;
			
			if (fmuldiv_sel_i)
			begin
				fdiv_rem      <= {4'h0, fmuldiv_scfnd1_i, {{PRCSN_WIDTH}{1'b0}}} << frac_shift1;
			end
			else
			begin
				fdiv_rem      <= 0;
			end

			muldiv_count 	<= 0;
			fmul_res   		<= 0;			
			fdiv_res 			<= 0;

			if (is1_denorm)
			begin
				expnt1 <= 16'hFF82 - {8'h00, frac_shift1};
			end
			else if (is1_norm)
			begin
				expnt1 <= {8'h00,fmuldiv_exp1_i} - 16'h007F;
			end
			else
			begin
				expnt1 <= {8'h00,fmuldiv_exp1_i};
			end

			if (is2_denorm)
			begin
				expnt2 <= 16'hFF82 - {8'h00, frac_shift2};
			end
			else if (is2_norm)
			begin
				expnt2 <= {8'h00,fmuldiv_exp2_i} - 16'h007F;
			end
			else
			begin
				expnt2 <= {8'h00,fmuldiv_exp2_i};
			end				
		end

		else if (fmuldiv_next_state == FMUL)
		begin
			sfcnd1 				<= sfcnd1;
			sfcnd2 				<= sfcnd2;
			muldiv_count 	<= muldiv_count + 2;

			if (muldiv_count == 0)
			begin
				expnt1 			<= expnt1 + expnt2;
			end
			else
			begin
				expnt1 			<= expnt1;
			end
			
			if((sftd_multplr[2:0] == 3'b001) | (sftd_multplr[2:0] == 3'b010))
			begin
				fmul_res 		<= fmul_res +  (pos_multpcnd << muldiv_count);
			end

			else if(sftd_multplr[2:0] == 3'b011)
			begin
				fmul_res 		<= fmul_res +  (pos_two_multpcnd << muldiv_count);
			end

			else if(sftd_multplr[2:0] == 3'b100)
			begin
				fmul_res		 	<= fmul_res +  (neg_two_multpcnd << muldiv_count);	
			end

			else if((sftd_multplr[2:0] == 3'b101) | (sftd_multplr[2:0] == 3'b110))
			begin
				fmul_res 		<= fmul_res +  (neg_multpcnd << muldiv_count);
			end

			else
			begin
				fmul_res 		<= fmul_res;
			end

		end

		else if (fmuldiv_next_state == FDIV)
		begin
			muldiv_count 	<= muldiv_count + 1;

			if (muldiv_count == 0)
			begin
				expnt1 			<= expnt1 - expnt2;
			end
			else
			begin
				expnt1 			<= expnt1;
			end

			if (is_rem_neg)
			begin
				fdiv_rem <= {fdiv_rem, 1'b0} + {4'h0, sfcnd2, 1'b0, {{PRCSN_WIDTH}{1'b0}}};
			end
			else
			begin
				fdiv_rem <= {fdiv_rem, 1'b0} - {4'h0, sfcnd2, 1'b0, {{PRCSN_WIDTH}{1'b0}}};
			end

			fdiv_res    <= {fdiv_res, ~is_rem_neg};			
		end

		else if ((fmuldiv_next_state == EADJST) & (~fmuldiv_sel_i))
		begin

			/*For mult only*/
			expnt1      <= expnt1 + fmul_adjst;
			fmul_res    <= fmul_res << (~fmul_adjst);			
		end

		else if ((fmuldiv_next_state == EADJST) & (fmuldiv_sel_i))
		begin

			/*For div only*/
			expnt1      <= expnt1 - fdiv_adjst; // needs to be changed
			fdiv_res    <= fdiv_res << fdiv_adjst; // needs to be changed
		end

		else if (fmuldiv_next_state == DFSFT)
		begin
			is_res_zero <= (~(|fmul_res)) & (~(|fdiv_res));
		end

		else if (fmuldiv_next_state == FADJST)
		begin
			if ((is_res_denorm | is_neg_exp_ovf) & (fmuldiv_sel_i))
			begin
					fdiv_res 	<= fdiv_res >> dfrac_shift;
			end

			else if ((is_res_denorm | is_neg_exp_ovf) & (~fmuldiv_sel_i))
			begin
					fmul_res 	<= fmul_res >> dfrac_shift;
			end
			else
			begin
				fdiv_res    <= fdiv_res << 1;
				fmul_res    <= fmul_res << 1;
			end

			if (is_res_denorm | is_neg_exp_ovf | is_res_zero)
			begin
				expnt1 			<= 0;
			end
			else if (is_pos_exp_ovf)
			begin
				expnt1    <= 16'h00FF;
			end
			else
			begin
				expnt1    <= expnt1 + BIASING_CONSTANT;
			end

			fmuldiv_exp_ovf_reg <= is_neg_exp_ovf | is_pos_exp_ovf;
			is_res_zero 				<= 0;
		end

		else if (fmuldiv_next_state == START)
		begin
			sfcnd1   						<= 0;
			sfcnd2   						<= 0;
			expnt1 							<= 0;
			expnt2 							<= 0;
			muldiv_count 				<= 0;
			fmul_res 						<= 0;
			fmuldiv_exp_ovf_reg <= 0;
			fmuldiv_sign_reg   	<= 0;
			is_res_zero 				<= 0;		 
		end
	end

	/*------------Defining Internal Register--------------*/

	/*--------Defining Next State & Output Logic----------*/

	always @(*) 
	begin

		case (fmuldiv_state)

			START:
			begin
				fmuldiv_sign_o			<= 0;
				fmuldiv_exp_o				<= 0;
				fmuldiv_frac_o			<= 0;
				fmuldiv_grs_bit_o		<= 0;
				fmuldiv_ready_o			<= 0;
				fmuldiv_exp_ovf_o   <= 0;

				if (fmuldiv_en_i)
				begin
					//$display("			fmuldiv module enabled:: \t@time %0t", $realtime());
					fmuldiv_next_state <= FSFT;
				end
				else
				begin
					fmuldiv_next_state <= START;
				end
			end			

			FSFT:
			begin
				fmuldiv_sign_o			<= 0;
				fmuldiv_exp_o				<= 0;
				fmuldiv_frac_o			<= 0;
				fmuldiv_grs_bit_o		<= 0;
				fmuldiv_ready_o			<= 0;
				fmuldiv_exp_ovf_o   <= 0;

				if (fmuldiv_en_i & fmuldiv_sel_i)
				begin
					fmuldiv_next_state <= FDIV;
				end
				else if (fmuldiv_en_i & ~fmuldiv_sel_i)
				begin
					fmuldiv_next_state <= FMUL;
				end
				else
				begin
					fmuldiv_next_state <= FSFT;
				end
			end

			FMUL:
			begin
				fmuldiv_sign_o			<= 0;
				fmuldiv_exp_o				<= 0;
				fmuldiv_frac_o			<= 0;
				fmuldiv_grs_bit_o		<= 0;
				fmuldiv_ready_o			<= 0;
				fmuldiv_exp_ovf_o   <= 0;

				if (fmuldiv_en_i & ~(|sftd_multplr))
				begin
					fmuldiv_next_state <= EADJST;
				end
				else
				begin
					fmuldiv_next_state <= FMUL;
				end
			end

			FDIV:
			begin
				fmuldiv_sign_o			<= 0;
				fmuldiv_exp_o				<= 0;
				fmuldiv_frac_o			<= 0;
				fmuldiv_grs_bit_o		<= 0;
				fmuldiv_ready_o			<= 0;
				fmuldiv_exp_ovf_o   <= 0;

				if (is2_inf)
				begin
					fmuldiv_next_state <= CALC;
				end

				else if (fmuldiv_en_i & (muldiv_count >= PRCSN_WIDTH+1))
				begin
					fmuldiv_next_state <= EADJST;
				end
				else
				begin
					fmuldiv_next_state <= FDIV;
				end
			end

			EADJST:
			begin
				fmuldiv_sign_o			<= 0;
				fmuldiv_exp_o				<= 0;
				fmuldiv_frac_o			<= 0;
				fmuldiv_grs_bit_o		<= 0;
				fmuldiv_ready_o			<= 0;
				fmuldiv_exp_ovf_o   <= 0;

				if (fmuldiv_en_i)
				begin
					fmuldiv_next_state <= DFSFT;
				end
				else
				begin
					fmuldiv_next_state <= EADJST;
				end
			end

			DFSFT:
			begin
				fmuldiv_sign_o			<= 0;
				fmuldiv_exp_o				<= 0;
				fmuldiv_frac_o			<= 0;
				fmuldiv_grs_bit_o		<= 0;
				fmuldiv_ready_o			<= 0;
				fmuldiv_exp_ovf_o   <= 0;

				if (fmuldiv_en_i)
				begin
					fmuldiv_next_state <= FADJST;
				end
				else
				begin
					fmuldiv_next_state <= DFSFT;
				end
			end

			FADJST:
			begin
				fmuldiv_sign_o			<= 0;
				fmuldiv_exp_o				<= 0;
				fmuldiv_frac_o			<= 0;
				fmuldiv_grs_bit_o		<= 0;
				fmuldiv_ready_o			<= 0;
				fmuldiv_exp_ovf_o   <= 0;

				if (fmuldiv_en_i)
				begin
					fmuldiv_next_state <= CALC;
				end
				else
				begin
					fmuldiv_next_state <= FADJST;
				end
			end

			CALC:
			begin
				fmuldiv_sign_o			<= fmuldiv_sign_reg;
				
				fmuldiv_exp_ovf_o   <= fmuldiv_exp_ovf_reg;
				//fmuldiv_check 			<= sfcnd1 * sfcnd2; // only for check;

				if (fmuldiv_sel_i & is2_inf)
				begin
					fmuldiv_exp_o				<= 0;
					fmuldiv_frac_o			<= 0;
					fmuldiv_grs_bit_o		<= 0;
				end

				else if (fmuldiv_sel_i & ~is2_inf)
				begin
					fmuldiv_exp_o				<= expnt1[EXPONENT_WIDTH-1:0];
					fmuldiv_frac_o			<= fdiv_res[PRCSN_WIDTH-1:3];
					fmuldiv_grs_bit_o		<= fdiv_res[3:1];
				end

				else
				begin
					fmuldiv_exp_o				<= expnt1[EXPONENT_WIDTH-1:0];
					fmuldiv_frac_o			<= fmul_res[2*SIGNIFICAND_WIDTH-1:SIGNIFICAND_WIDTH+1];				
					fmuldiv_grs_bit_o		<= fmul_res[SIGNIFICAND_WIDTH+1:SIGNIFICAND_WIDTH-1];
				end

				
				if (fmuldiv_en_i)
				begin
					fmuldiv_ready_o			<= 1;
					fmuldiv_next_state 	<= CALC;
				end
				else
				begin
					fmuldiv_ready_o			<= 0;
					fmuldiv_next_state  <= START;
				end

			end

			default:
			begin
				fmuldiv_sign_o			<= 0;
				fmuldiv_exp_o				<= 0;
				fmuldiv_frac_o			<= 0;
				fmuldiv_grs_bit_o		<= 0;
				fmuldiv_ready_o			<= 0;
				fmuldiv_exp_ovf_o   <= 0;
				fmuldiv_next_state 	<= START;				
			end
		endcase
	
	end

	/*--------Defining Next State & Output Logic----------*/


	/*-----------------Calculation of Input Denorm Fraction Shifting------------------*/
	always @(*) 
	begin
		if (is1_denorm)
		begin
			casex (fmuldiv_scfnd1_i)

				24'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx : frac_shift1 <= 1;
				24'b001x_xxxx_xxxx_xxxx_xxxx_xxxx : frac_shift1 <= 2;
				24'b0001_xxxx_xxxx_xxxx_xxxx_xxxx : frac_shift1 <= 3;
				24'b0000_1xxx_xxxx_xxxx_xxxx_xxxx : frac_shift1 <= 4;
				24'b0000_01xx_xxxx_xxxx_xxxx_xxxx : frac_shift1 <= 5;
				24'b0000_001x_xxxx_xxxx_xxxx_xxxx : frac_shift1 <= 6;
				24'b0000_0001_xxxx_xxxx_xxxx_xxxx : frac_shift1 <= 7;
				24'b0000_0000_1xxx_xxxx_xxxx_xxxx : frac_shift1 <= 8;
				24'b0000_0000_01xx_xxxx_xxxx_xxxx : frac_shift1 <= 9;
				24'b0000_0000_001x_xxxx_xxxx_xxxx : frac_shift1 <= 10;
				24'b0000_0000_0001_xxxx_xxxx_xxxx : frac_shift1 <= 11;
				24'b0000_0000_0000_1xxx_xxxx_xxxx : frac_shift1 <= 12;
				24'b0000_0000_0000_01xx_xxxx_xxxx : frac_shift1 <= 13;
				24'b0000_0000_0000_001x_xxxx_xxxx : frac_shift1 <= 14;
				24'b0000_0000_0000_0001_xxxx_xxxx : frac_shift1 <= 15;
				24'b0000_0000_0000_0000_1xxx_xxxx : frac_shift1 <= 16;
				24'b0000_0000_0000_0000_01xx_xxxx : frac_shift1 <= 17;
				24'b0000_0000_0000_0000_001x_xxxx : frac_shift1 <= 18;
				24'b0000_0000_0000_0000_0001_xxxx : frac_shift1 <= 19;
				24'b0000_0000_0000_0000_0000_1xxx : frac_shift1 <= 20;
				24'b0000_0000_0000_0000_0000_01xx : frac_shift1 <= 21;
				24'b0000_0000_0000_0000_0000_001x : frac_shift1 <= 22;
				24'b0000_0000_0000_0000_0000_0001 : frac_shift1 <= 23;
				default 												  : frac_shift1 <= 0;														
			endcase			
		end

		else
		begin
			frac_shift1 <= 0;
		end
		/*-------------------------------------------------------------------------------*/

		/*-------------------------------------------------------------------------------*/
		if (is2_denorm)
		begin
			casex (fmuldiv_scfnd2_i)

				24'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx : frac_shift2 <= 1;
				24'b001x_xxxx_xxxx_xxxx_xxxx_xxxx : frac_shift2 <= 2;
				24'b0001_xxxx_xxxx_xxxx_xxxx_xxxx : frac_shift2 <= 3;
				24'b0000_1xxx_xxxx_xxxx_xxxx_xxxx : frac_shift2 <= 4;
				24'b0000_01xx_xxxx_xxxx_xxxx_xxxx : frac_shift2 <= 5;
				24'b0000_001x_xxxx_xxxx_xxxx_xxxx : frac_shift2 <= 6;
				24'b0000_0001_xxxx_xxxx_xxxx_xxxx : frac_shift2 <= 7;
				24'b0000_0000_1xxx_xxxx_xxxx_xxxx : frac_shift2 <= 8;
				24'b0000_0000_01xx_xxxx_xxxx_xxxx : frac_shift2 <= 9;
				24'b0000_0000_001x_xxxx_xxxx_xxxx : frac_shift2 <= 10;
				24'b0000_0000_0001_xxxx_xxxx_xxxx : frac_shift2 <= 11;
				24'b0000_0000_0000_1xxx_xxxx_xxxx : frac_shift2 <= 12;
				24'b0000_0000_0000_01xx_xxxx_xxxx : frac_shift2 <= 13;
				24'b0000_0000_0000_001x_xxxx_xxxx : frac_shift2 <= 14;
				24'b0000_0000_0000_0001_xxxx_xxxx : frac_shift2 <= 15;
				24'b0000_0000_0000_0000_1xxx_xxxx : frac_shift2 <= 16;
				24'b0000_0000_0000_0000_01xx_xxxx : frac_shift2 <= 17;
				24'b0000_0000_0000_0000_001x_xxxx : frac_shift2 <= 18;
				24'b0000_0000_0000_0000_0001_xxxx : frac_shift2 <= 19;
				24'b0000_0000_0000_0000_0000_1xxx : frac_shift2 <= 20;
				24'b0000_0000_0000_0000_0000_01xx : frac_shift2 <= 21;
				24'b0000_0000_0000_0000_0000_001x : frac_shift2 <= 22;
				24'b0000_0000_0000_0000_0000_0001 : frac_shift2 <= 23;
				default 												  : frac_shift2 <= 0;														
			endcase			
		end

		else
		begin
			frac_shift2 <= 0;
		end
	end	
	/*-----------------Calculation of Input Denorm Fraction Shifting------------------*/

	/*-----------------Calculation of Output Denorm Fraction Shifting------------------*/

	always @(*) 
	begin

		if ((fmuldiv_state == DFSFT) )
		begin

			is_res_denorm     <= ((expnt1 >= 16'hFF6B) & (expnt1 < 16'hFF82) & (is_neg_unb_exp == 1));
			is_pos_exp_ovf  	<= ((expnt1 > 16'h007F) & (is_neg_unb_exp == 0));
			is_neg_exp_ovf  	<= ((expnt1 < 16'hFF6B) & (is_neg_unb_exp == 1));
			
			case (expnt1)
				16'hFF81 : dfrac_shift <= 0;
				16'hFF80 : dfrac_shift <= 1;
				16'hFF7F : dfrac_shift <= 2;
				16'hFF7E : dfrac_shift <= 3;
				16'hFF7D : dfrac_shift <= 4;
				16'hFF7C : dfrac_shift <= 5;
				16'hFF7B : dfrac_shift <= 6;
				16'hFF7A : dfrac_shift <= 7;
				16'hFF79 : dfrac_shift <= 8;
				16'hFF78 : dfrac_shift <= 9;
				16'hFF77 : dfrac_shift <= 10;
				16'hFF76 : dfrac_shift <= 11;
				16'hFF75 : dfrac_shift <= 12;
				16'hFF74 : dfrac_shift <= 13;
				16'hFF73 : dfrac_shift <= 14;
				16'hFF72 : dfrac_shift <= 15;
				16'hFF71 : dfrac_shift <= 16;
				16'hFF70 : dfrac_shift <= 17;
				16'hFF6F : dfrac_shift <= 18;
				16'hFF6E : dfrac_shift <= 19;
				16'hFF6D : dfrac_shift <= 20;
				16'hFF6C : dfrac_shift <= 21;
				16'hFF6B : dfrac_shift <= 22;
				16'hFF6A : dfrac_shift <= 23;
				16'hFF69 : dfrac_shift <= 24;					
			
				default  : dfrac_shift <= 25;
			endcase
		end

		else
		begin
			is_res_denorm 	<= 0;
			is_pos_exp_ovf 	<= 0;
			is_neg_exp_ovf  <= 0;
			dfrac_shift 		<= 0;
		end
	
	end
	/*-----------------Calculation of Output Denorm Fraction Shifting------------------*/


endmodule