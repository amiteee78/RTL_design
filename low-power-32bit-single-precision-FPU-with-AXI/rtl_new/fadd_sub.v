`timescale 1ns/1ps
module fadd_sub #(

	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter BIASING_CONSTANT 	= 8'b0111_1111
	)
	(
		input 														fpu_clk,   
		input 														fpu_rst_n,
		input 														faddsub_en_i,
		input 														faddsub_sel_i,

		input 														faddsub_sign1_i,
		input 	[EXPONENT_WIDTH-1:0]			faddsub_exp1_i,
		input 	[SIGNIFICAND_WIDTH-1:0]		faddsub_scfnd1_i,

		input 														faddsub_sign2_i,
		input 	[EXPONENT_WIDTH-1:0]			faddsub_exp2_i,
		input 	[SIGNIFICAND_WIDTH-1:0]		faddsub_scfnd2_i,

		output reg 												faddsub_sign_o,
		output reg 	[EXPONENT_WIDTH-1:0] 	faddsub_exp_o,
		output reg	[FRACTION_WIDTH-1:0] 	faddsub_frac_o,
		output reg 	[2:0]									faddsub_grs_bit_o,
		output reg 												faddsub_ready_o

	);

	localparam 	[2:0] 											START  = 3'b000;
	localparam  [2:0] 											EDIFF  = 3'b001;
	localparam	[2:0] 											FSHIFT = 3'b010;
	localparam 	[2:0] 											ADD    = 3'b011;
	localparam  [2:0] 											EINC   = 3'b100; 
	localparam 	[2:0] 											ESCALE = 3'b101;
	localparam 	[2:0] 											ADJUST = 3'b110;
	localparam  [2:0] 											CALC   = 3'b111;

	reg 				[2:0] 											faddsub_state;
	reg 				[2:0] 											faddsub_next_state;

	wire 				[OPERAND_WIDTH-5:0] 				ext_sgnfcnd1;
	wire 				[OPERAND_WIDTH-5:0] 				ext_sgnfcnd2;

	wire 				[EXPONENT_WIDTH-1:0] 				exp_diff;
	reg 	      [$clog2(OPERAND_WIDTH)-1:0] frac_shift;
	reg 				[OPERAND_WIDTH-5:0] 				addsub_reg1;
	reg 				[OPERAND_WIDTH-5:0] 				addsub_reg2;
	reg 				[EXPONENT_WIDTH-1:0] 				exp_inc;
	reg 				[EXPONENT_WIDTH-1:0] 				exp_adjst;
	reg 																		addsub_sign_reg;
	reg 				[$clog2(OPERAND_WIDTH)-1:0] exp_scale;
	wire 				[EXPONENT_WIDTH-1:0] 				biased_exp;
	wire 				[OPERAND_WIDTH-5:0] 				addsub_abs;
	wire 				[1:0]												add_or_sub;
	wire 																		addsub_ext_bit;
	wire 																		addsub_sign;
	wire 																		is_addsub_zero;


	/*--------------------Generation of Significand for Addition/Subtraction Process---------------------*/
	assign ext_sgnfcnd1 = {{2{1'b0}}, faddsub_scfnd1_i, {2{1'b0}}};
	assign ext_sgnfcnd2 = {{2{1'b0}}, faddsub_scfnd2_i, {2{1'b0}}};
	/*--------------------Generation of Significand for Addition/Subtraction Process---------------------*/

	assign exp_diff   		= (faddsub_exp1_i > faddsub_exp2_i) ? faddsub_exp1_i - faddsub_exp2_i - (~|faddsub_exp2_i) : (faddsub_exp2_i > faddsub_exp1_i) ? faddsub_exp2_i - faddsub_exp1_i - (~|faddsub_exp1_i) : 0;
	assign biased_exp 		= (faddsub_exp1_i > faddsub_exp2_i) ? faddsub_exp1_i : faddsub_exp2_i;
	assign add_or_sub 		= faddsub_en_i ? {faddsub_sign1_i, faddsub_sel_i ^ faddsub_sign2_i} : 0;
	assign addsub_sign 		= addsub_reg1[OPERAND_WIDTH-5];
	assign addsub_abs  		= addsub_reg1[OPERAND_WIDTH-5] ? -addsub_reg1 : addsub_reg1;
	assign addsub_ext_bit = addsub_abs[OPERAND_WIDTH-6];
	assign is_addsub_zero = faddsub_en_i & ~(|addsub_reg1);

	/*frac_shift has to be confined within 30*/

	/*-----------Defining State Register----------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			faddsub_state  <= START;
		end
		else
		begin
			faddsub_state  <= faddsub_next_state;
		end
	end
	/*-----------Defining State Register----------*/

	/*------------Defining Internal Register--------------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			addsub_reg1 			<= 0;
			addsub_reg2 			<= 0;
			exp_inc 					<= 0;
			exp_adjst 				<= 0;
			addsub_sign_reg 	<= 0;
		end

		else if (faddsub_next_state == START)
		begin
			addsub_reg1 			<= 0;
			addsub_reg2 			<= 0;
			exp_inc 					<= 0;
			exp_adjst 				<= 0;
			addsub_sign_reg 	<= 0;			
		end
		else if ((faddsub_next_state == FSHIFT) & (faddsub_exp1_i > faddsub_exp2_i))
		begin
			addsub_reg1	<= ext_sgnfcnd1;
			addsub_reg2  <= ext_sgnfcnd2 >> frac_shift;
		end
		else if ((faddsub_next_state == FSHIFT) & (faddsub_exp2_i > faddsub_exp1_i))
		begin
			addsub_reg1  <= ext_sgnfcnd1 >> frac_shift;
			addsub_reg2	<= ext_sgnfcnd2;
		end
		else if ((faddsub_next_state == FSHIFT) & (faddsub_exp2_i == faddsub_exp1_i))
		begin
			addsub_reg1	<= ext_sgnfcnd1;
			addsub_reg2	<= ext_sgnfcnd2;
		end
		else if (faddsub_next_state == ADD)
		begin
			case (add_or_sub)
				2'b00 : addsub_reg1 <= addsub_reg1 + addsub_reg2;
				2'b01 : addsub_reg1 <= addsub_reg1 - addsub_reg2;
				2'b10 : addsub_reg1 <= -addsub_reg1 + addsub_reg2;
				2'b11 : addsub_reg1 <= -addsub_reg1 - addsub_reg2;
				default : addsub_reg1 <= addsub_reg1;
			endcase
		end
		else if (faddsub_next_state == EINC)
		begin
			if (is_addsub_zero)
			begin
				exp_inc 	<= 0;
			end
			else
			begin
				addsub_reg1 <= addsub_abs >> addsub_ext_bit;
				exp_inc			<= biased_exp + addsub_ext_bit;
			end

			addsub_sign_reg 		<= addsub_sign;
		end

		else if (faddsub_next_state == ADJUST)
		begin
			if (exp_inc == 0)
			begin
				exp_adjst   	<= exp_inc + addsub_reg1[FRACTION_WIDTH+2];
				addsub_reg1 	<= addsub_reg1;
			end

			else if (exp_inc >= (exp_scale + 1))
			begin
				exp_adjst  		<= exp_inc - exp_scale;
				addsub_reg1   <= addsub_reg1 << exp_scale;   
			end

			else
			begin
				exp_adjst     <= 0;
				addsub_reg1   <= addsub_reg1 << (exp_inc -1);
			end
			addsub_sign_reg <= addsub_sign_reg;
		end
		else
		begin
			addsub_reg1 		<= addsub_reg1;
			addsub_reg2 		<= addsub_reg2;
			exp_inc 				<= exp_inc;
			exp_adjst 			<= exp_adjst;
			addsub_sign_reg <= addsub_sign_reg;
		end
	end
	/*------------Defining Internal Register--------------*/

	/*--------Defining Next State & Output Logic----------*/
	always @(*) 
	begin

		case (faddsub_state)

			START:
			begin
				faddsub_sign_o			<= 0;
				faddsub_exp_o				<= 0;
				faddsub_frac_o			<= 0;
				faddsub_grs_bit_o		<= 0;
				faddsub_ready_o			<= 0;

				if (faddsub_en_i)
				begin
					//$display("			faddsub module enabled:: \t@time %0t", $realtime());
					faddsub_next_state <= EDIFF;
				end
				else
				begin
					faddsub_next_state <= START;
				end
			end

			EDIFF:
			begin
				faddsub_sign_o			<= 0;
				faddsub_exp_o				<= 0;
				faddsub_frac_o			<= 0;
				faddsub_grs_bit_o		<= 0;
				faddsub_ready_o			<= 0;

				if (faddsub_en_i)
				begin
					faddsub_next_state <= FSHIFT;
				end
				else
				begin
					faddsub_next_state <= EDIFF;
				end
			end

			FSHIFT:
			begin
				faddsub_sign_o			<= 0;
				faddsub_exp_o				<= 0;
				faddsub_frac_o			<= 0;
				faddsub_grs_bit_o		<= 0;
				faddsub_ready_o			<= 0;

				if (faddsub_en_i)
				begin
					faddsub_next_state <= ADD;
				end
				else
				begin
					faddsub_next_state <= FSHIFT;
				end
			end

			ADD:
			begin
				faddsub_sign_o			<= 0;
				faddsub_exp_o				<= 0;
				faddsub_frac_o			<= 0;
				faddsub_grs_bit_o		<= 0;
				faddsub_ready_o			<= 0;

				if (faddsub_en_i)
				begin
					faddsub_next_state <= EINC;
				end
				else
				begin
					faddsub_next_state <= ADD;
				end
			end

			EINC:
			begin
				faddsub_sign_o			<= 0;
				faddsub_exp_o				<= 0;
				faddsub_frac_o			<= 0;
				faddsub_grs_bit_o		<= 0;
				faddsub_ready_o			<= 0;

				if (faddsub_en_i)
				begin
					faddsub_next_state <= ESCALE;
				end
				else
				begin
					faddsub_next_state <= EINC;
				end				
			end

			ESCALE:
			begin
				faddsub_sign_o			<= 0;
				faddsub_exp_o				<= 0;
				faddsub_frac_o			<= 0;
				faddsub_grs_bit_o		<= 0;
				faddsub_ready_o			<= 0;

				if (faddsub_en_i)
				begin
					faddsub_next_state <= ADJUST;
				end
				else
				begin
					faddsub_next_state <= ESCALE;
				end		
			end

			ADJUST:
			begin
				faddsub_sign_o			<= 0;
				faddsub_exp_o				<= 0;
				faddsub_frac_o			<= 0;
				faddsub_grs_bit_o		<= 0;
				faddsub_ready_o			<= 0;

				if (faddsub_en_i)
				begin
					faddsub_next_state <= CALC;
				end
				else
				begin
					faddsub_next_state <= ADJUST;
				end		
			end

			CALC:
			begin
				faddsub_sign_o			<= addsub_sign_reg;
				faddsub_exp_o				<= exp_adjst;
				faddsub_frac_o			<= addsub_reg1[SIGNIFICAND_WIDTH:2];
				faddsub_grs_bit_o		<= addsub_reg1[2:0];
				

				if (faddsub_en_i)
				begin
					faddsub_ready_o			<= 1;
					faddsub_next_state 	<= CALC;
				end
				else
				begin
					faddsub_ready_o			<= 0;
					faddsub_next_state 	<= START;
				end		
			end
		
			default:
			begin
				faddsub_sign_o			<= 0;
				faddsub_exp_o				<= 0;
				faddsub_frac_o			<= 0;
				faddsub_grs_bit_o		<= 0;
				faddsub_ready_o			<= 0;

				faddsub_next_state 	<= START;				
			end
		endcase
	
	end
	/*--------Defining Next State & Output Logic----------*/

	/*-----------------Calculation of Fraction Shifting------------------*/
	always @(*) 
	begin
		if (faddsub_en_i & ((faddsub_state == EDIFF) | (faddsub_state == FSHIFT)))
		begin
			case (exp_diff)

				0  : frac_shift <= 0;
				1  : frac_shift <= 1;
				2  : frac_shift <= 2;
				3  : frac_shift <= 3;
				4  : frac_shift <= 4;
				5  : frac_shift <= 5;
				6  : frac_shift <= 6;
				7  : frac_shift <= 7;
				8  : frac_shift <= 8;
				9  : frac_shift <= 9;
				10 : frac_shift <= 10;
				11 : frac_shift <= 11;
				12 : frac_shift <= 12;
				13 : frac_shift <= 13;
				14 : frac_shift <= 14;
				15 : frac_shift <= 15;
				16 : frac_shift <= 16;
				17 : frac_shift <= 17;
				18 : frac_shift <= 18;
				19 : frac_shift <= 19;
				20 : frac_shift <= 20;
				21 : frac_shift <= 21;
				22 : frac_shift <= 22;
				23 : frac_shift <= 23;
				24 : frac_shift <= 24;
				25 : frac_shift <= 25;
				26 : frac_shift <= 26;

				default : frac_shift <= 27;
			endcase			
		end

		else
		begin
			frac_shift <= 0;
		end
	end
	/*-----------------Calculation of Fraction Shifting------------------*/

	/*-----------------Calculation of Exponent Scaling------------------*/
	always @(*) 
	begin
		if (faddsub_en_i & ((faddsub_state == ESCALE) | (faddsub_state == ADJUST)))
		begin
			casex (addsub_reg1)

				28'b00_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xx : exp_scale <= 0;
				28'b00_01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xx : exp_scale <= 1;
				28'b00_001x_xxxx_xxxx_xxxx_xxxx_xxxx_xx : exp_scale <= 2;
				28'b00_0001_xxxx_xxxx_xxxx_xxxx_xxxx_xx : exp_scale <= 3;
				28'b00_0000_1xxx_xxxx_xxxx_xxxx_xxxx_xx : exp_scale <= 4;
				28'b00_0000_01xx_xxxx_xxxx_xxxx_xxxx_xx : exp_scale <= 5;
				28'b00_0000_001x_xxxx_xxxx_xxxx_xxxx_xx : exp_scale <= 6;
				28'b00_0000_0001_xxxx_xxxx_xxxx_xxxx_xx : exp_scale <= 7;
				28'b00_0000_0000_1xxx_xxxx_xxxx_xxxx_xx : exp_scale <= 8;
				28'b00_0000_0000_01xx_xxxx_xxxx_xxxx_xx : exp_scale <= 9;
				28'b00_0000_0000_001x_xxxx_xxxx_xxxx_xx : exp_scale <= 10;
				28'b00_0000_0000_0001_xxxx_xxxx_xxxx_xx : exp_scale <= 11;
				28'b00_0000_0000_0000_1xxx_xxxx_xxxx_xx : exp_scale <= 12;
				28'b00_0000_0000_0000_01xx_xxxx_xxxx_xx : exp_scale <= 13;
				28'b00_0000_0000_0000_001x_xxxx_xxxx_xx : exp_scale <= 14;
				28'b00_0000_0000_0000_0001_xxxx_xxxx_xx : exp_scale <= 15;
				28'b00_0000_0000_0000_0000_1xxx_xxxx_xx : exp_scale <= 16;
				28'b00_0000_0000_0000_0000_01xx_xxxx_xx : exp_scale <= 17;
				28'b00_0000_0000_0000_0000_001x_xxxx_xx : exp_scale <= 18;
				28'b00_0000_0000_0000_0000_0001_xxxx_xx : exp_scale <= 19;
				28'b00_0000_0000_0000_0000_0000_1xxx_xx : exp_scale <= 20;
				28'b00_0000_0000_0000_0000_0000_01xx_xx : exp_scale <= 21;
				28'b00_0000_0000_0000_0000_0000_001x_xx : exp_scale <= 22;
				28'b00_0000_0000_0000_0000_0000_0001_xx : exp_scale <= 23;

				default 																: exp_scale	<= 0; 															
			endcase			
		end
		else
		begin
			exp_scale <= 0;
		end
	end	
	/*-----------------Calculation of Exponent Scaling------------------*/

endmodule