`timescale 1ns/1ps
module fround #(

	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter BIASING_CONSTANT 	= 8'b0111_1111	
	)

	(

		input 													fpu_clk,    // Clock
		input 													fpu_rst_n,  // Asynchronous reset active low
		input 													fround_en_i,

		input 													fround_sign_i,
		input 	[EXPONENT_WIDTH-1:0]		fround_exp_i,
		input 	[FRACTION_WIDTH-1:0]		fround_frac_i,


		output 	reg [OPERAND_WIDTH-1:0] fround_int_o,
		output 	reg 										fround_overflow_o,
		output 	reg 										fround_zero_o,
		output  reg 										fround_ready_o
	
	);


	localparam 	[1:0] 												START = 2'b00;
	localparam 	[1:0] 												SHIFT = 2'b01;
	localparam 	[1:0] 												CALC  = 2'b10;
											
											
	reg 				[1:0] 												fround_state;
	reg 				[1:0] 												fround_next_state;

	reg 				[$clog2(OPERAND_WIDTH)-1:0] 	shift;
	reg  				[OPERAND_WIDTH-1:0] 				 	rounded_int;
	reg 				[FRACTION_WIDTH-1:0] 				 	rounded_frac;

	wire  																		is_num_lte_half;
	wire 																			is_num_in_half_n_one;
	wire 																			is_num_in_fr_lmt;
	wire 																			is_num_bynd_fr_lmt;
	wire 																			is_num_out_of_lmt;

	/*----------------------------Defining Various Range of Numbers--------------------------------*/
	assign is_num_lte_half 			= fround_en_i & (((fround_exp_i == 8'h7E) & ~(|fround_frac_i)) | (~(|fround_exp_i) | (fround_exp_i < 8'h7E)));
	assign is_num_in_half_n_one = fround_en_i & (fround_exp_i == 8'h7E) & (|fround_frac_i);
	assign is_num_in_fr_lmt 		= fround_en_i & ((fround_exp_i > 8'h7E) & (fround_exp_i <= 8'h95));
	assign is_num_bynd_fr_lmt 	= fround_en_i & (fround_exp_i > 8'h95) & (fround_exp_i <= 8'h9D);
	assign is_num_out_of_lmt 		= fround_en_i & (fround_exp_i > 8'h9D) & (fround_exp_i <= 8'hFE);
	/*----------------------------Defining Various Range of Numbers--------------------------------*/

	/*-----------Defining State Register----------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			fround_state 	<= START;
		end
		else
		begin
			fround_state 	<= fround_next_state;
		end		
	end
	/*-----------Defining State Register----------*/

	/*------------Defining Internal Register--------------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			rounded_int 	<= 0;
			rounded_frac  <= 0;
		end
		else if ((fround_next_state == SHIFT) & is_num_in_fr_lmt)
		begin
			rounded_int 	<= {1'b1, fround_frac_i} >> shift;
			rounded_frac 	<= fround_frac_i << (FRACTION_WIDTH - shift);
		end

		else if ((fround_next_state == SHIFT) & is_num_bynd_fr_lmt)
		begin
			rounded_int 	<= {1'b1, fround_frac_i} << shift;
		end
		else if (fround_next_state == CALC)
		begin
			rounded_int   <= rounded_int;
			rounded_frac  <= rounded_frac;
		end
		else
		begin
			rounded_int 	<= 0;
			rounded_frac  <= 0;
		end		
	end
	/*------------Defining Internal Register--------------*/

	/*--------Defining Next State & Output Logic----------*/
	always @(*) 
	begin

		case (fround_state)

			START:
			begin
				fround_int_o 				<= 0;
				fround_overflow_o 	<= 0;
				fround_zero_o 			<= 0;
				fround_ready_o 			<= 0;

				if (is_num_in_fr_lmt | is_num_bynd_fr_lmt)
				begin
					//$display("			fround module enabled:: \t@time %0t", $realtime());
					fround_next_state <= SHIFT;
				end

				else if (is_num_lte_half | is_num_in_half_n_one |is_num_out_of_lmt)
				begin
					//$display("			fround module enabled:: \t@time %0t", $realtime());
					fround_next_state <= CALC;
				end
				else
				begin
					fround_next_state <= START;
				end
			end

			SHIFT:
			begin
				fround_int_o 				<= 0;
				fround_overflow_o 	<= 0;
				fround_zero_o 			<= 0;
				fround_ready_o 			<= 0;

				if (is_num_in_fr_lmt | is_num_bynd_fr_lmt)
				begin
					fround_next_state 	<= CALC;
				end

				else
				begin
					fround_next_state 	<= SHIFT;
				end
			end

			CALC:
			begin

				if (is_num_lte_half)
				begin
					fround_int_o 				<= 0;
					fround_overflow_o 	<= 0;
					fround_zero_o 			<= 1;
					fround_ready_o 			<= 1;				
				end

				else if (is_num_in_half_n_one)
				begin

					if (fround_sign_i)
					begin
						fround_int_o 			<= -1;
					end
					else
					begin
						fround_int_o 			<= 1;
					end

					fround_overflow_o 	<= 0;
					fround_zero_o 			<= 0;
					fround_ready_o 			<= 1;					
				end

				else if (is_num_in_fr_lmt)
				begin

					if (fround_sign_i)
					begin
						fround_int_o 			<= -rounded_int - (rounded_frac[FRACTION_WIDTH-1] & (|rounded_frac[FRACTION_WIDTH-2:0]));
					end
					else
					begin
						fround_int_o 			<= rounded_int + (rounded_frac[FRACTION_WIDTH-1] & (|rounded_frac[FRACTION_WIDTH-2:0]));
					end
					
					fround_overflow_o 	<= 0;
					fround_zero_o 			<= 0;
					fround_ready_o 			<= 1;				
				end

				else if (is_num_bynd_fr_lmt)
				begin

					if (fround_sign_i)
					begin
						fround_int_o 			<= -rounded_int;
					end
					else
					begin
						fround_int_o 			<= rounded_int;
					end
					
					fround_overflow_o 	<= 0;
					fround_zero_o 			<= 0;
					fround_ready_o 			<= 1;
				end

				else if (is_num_out_of_lmt)
				begin

					if (fround_sign_i)
					begin
						fround_int_o 			<= 32'h8000_0001;
					end
					else
					begin
						fround_int_o 			<= 32'h7FFF_FFFF;
					end

					fround_overflow_o 	<= 1;
					fround_zero_o 			<= 0;
					fround_ready_o 			<= 1;					
				end
				else
				begin
					fround_int_o 				<= 0;
					fround_overflow_o 	<= 0;
					fround_zero_o 			<= 0;
					fround_ready_o 			<= 0;						
				end

				if (fround_en_i)
				begin
					fround_next_state 	<= CALC;
				end
				else
				begin
					fround_next_state 	<= START;
				end
			end
		
			default:
			begin
					fround_int_o 				<= 0;
					fround_overflow_o 	<= 0;
					fround_zero_o 			<= 0;
					fround_ready_o 			<= 0;
					fround_next_state 	<= START;	
			end
		endcase
	end
	/*--------Defining Next State & Output Logic----------*/

	/*-------------Amount of Shifting Calculation--------------*/
	always @(*) 
	begin

		if (is_num_in_fr_lmt)
		begin
			case (fround_exp_i)
				8'h7F 	:	shift <=	23;	
				8'h80 	:	shift <=	22;
				8'h81 	:	shift <=	21;
				8'h82 	:	shift <=	20;
				8'h83 	:	shift <=	19;
				8'h84 	:	shift <=	18;
				8'h85 	:	shift <=	17;
				8'h86 	:	shift <=	16;
				8'h87 	:	shift <=	15;
				8'h88 	:	shift <=	14;
				8'h89 	:	shift <=	13;
				8'h8A 	:	shift <=	12;
				8'h8B 	:	shift <=	11;
				8'h8C 	:	shift <=	10;
				8'h8D 	:	shift <=	9;
				8'h8E 	:	shift <=	8;
				8'h8F 	:	shift <=	7;
				8'h90 	:	shift <=	6;
				8'h91 	:	shift <=	5;
				8'h92 	:	shift <=	4;
				8'h93 	:	shift <=	3;
				8'h94 	:	shift <=	2;
				8'h95 	:	shift <=	1;			
				default : shift <= 	0;
			endcase	
		end

		else if (is_num_bynd_fr_lmt)
		begin
			case (fround_exp_i)
				8'h96		:	shift <= 0;	
				8'h97		:	shift <= 1;
				8'h98		:	shift <= 2;
				8'h99		:	shift <= 3;
				8'h9A		:	shift <= 4;
				8'h9B		:	shift <= 5;
				8'h9C		:	shift <= 6;
				8'h9D		:	shift <= 7;
				default : shift <= 0;
			endcase	
		end
		
		else
		begin
			shift <= 0;
		end	
	end
	/*-------------Amount of Shifting Calculation--------------*/

endmodule