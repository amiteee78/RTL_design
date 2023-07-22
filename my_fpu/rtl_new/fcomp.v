`timescale 1ns/1ps
module fcomp #(

	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23
	)
	(

		input 														fpu_clk,   
		input 														fpu_rst_n,
		input 														fcomp_en_i,

		input 														fcomp_sign1_i,
		input 	[EXPONENT_WIDTH-1:0]			fcomp_exp1_i,
		input 	[FRACTION_WIDTH-1:0]			fcomp_frac1_i,

		input 														fcomp_sign2_i,
		input 	[EXPONENT_WIDTH-1:0]			fcomp_exp2_i,
		input 	[FRACTION_WIDTH-1:0]			fcomp_frac2_i,


		output reg 	[OPERAND_WIDTH-1:0] 	fcomp_res_o,
		output reg 												fcomp_ready_o	
	);

	localparam 	 												START = 1'b0;
	localparam 	 												COMP  = 1'b1;

	reg 				 												fcomp_state;
	reg 				 												fcomp_next_state;

	reg 				[OPERAND_WIDTH-1:0] 		fcomp_res_reg;

	wire 																op1_greater;
	wire 																op1_less;
	wire 																sign_diff;
	wire 																both_pos;
	wire 																both_neg;
	wire 																both_zero;


	assign op1_greater = fcomp_en_i & (((fcomp_exp1_i > fcomp_exp2_i)) | ((fcomp_exp1_i == fcomp_exp2_i) & (fcomp_frac1_i > fcomp_frac2_i)));
	assign op1_less    = fcomp_en_i & (((fcomp_exp1_i < fcomp_exp2_i)) | ((fcomp_exp1_i == fcomp_exp2_i) & (fcomp_frac1_i < fcomp_frac2_i)));
	assign sign_diff   = fcomp_en_i & (fcomp_sign1_i ^ fcomp_sign2_i);
	assign both_pos    = fcomp_en_i & ~(fcomp_sign1_i | fcomp_sign2_i);
	assign both_neg    = fcomp_en_i & (fcomp_sign1_i & fcomp_sign2_i);
	assign both_zero   = ~((|fcomp_exp1_i) | (|fcomp_exp2_i) | (|fcomp_frac1_i) | (|fcomp_frac2_i));

	always @(posedge fpu_clk, negedge fpu_rst_n) 
	begin
	 	if (~fpu_rst_n) 
	 	begin
	 		fcomp_res_reg <= 32'h0000_0000;
	 	end

	 	else if (fcomp_next_state == COMP)
	 	begin
		 	if (both_zero)
		 	begin
		 		fcomp_res_reg <= 32'h0000_0000;
		 	end 
		 	else if (((both_pos & op1_greater) | (both_neg & op1_less))) 
		 	begin
		 		fcomp_res_reg <= 32'h0000_0001;
		 	end
		 	else if (((both_pos & op1_less) | (both_neg & op1_greater)))
		 	begin
		 		fcomp_res_reg <= 32'hFFFF_FFFF;
		 	end
		 	else if (fcomp_sign1_i & ~fcomp_sign2_i)
		 	begin
		 		fcomp_res_reg <= 32'hFFFF_FFFF;
		 	end
		 	else if (~fcomp_sign1_i & fcomp_sign2_i)
		 	begin
		 		fcomp_res_reg <= 32'h0000_0001;
		 	end	 		
	 	end

/*	 	else if ((fcomp_next_state == COMP) & both_zero)
	 	begin
	 		fcomp_res_reg <= '0;
	 	end 
	 	else if ((fcomp_next_state == COMP) & ((both_pos & op1_greater) | (both_neg & op1_less))) 
	 	begin
	 		fcomp_res_reg <= 1;
	 	end
	 	else if ((fcomp_next_state == COMP) & ((both_pos & op1_less) | (both_neg & op1_greater)))
	 	begin
	 		fcomp_res_reg <= -1;
	 	end
	 	else if ((fcomp_next_state == COMP) & fcomp_sign1_i & ~fcomp_sign2_i)
	 	begin
	 		fcomp_res_reg <= -1;
	 	end
	 	else if ((fcomp_next_state == COMP) & ~fcomp_sign1_i & fcomp_sign2_i)
	 	begin
	 		fcomp_res_reg <= 1;
	 	end
	 	else
	 	begin
	 		fcomp_res_reg <= '0;
	 	end*/	 	
	end


	/*-----------Defining State Register----------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			fcomp_state 	<= START;
		end
		else
		begin
			fcomp_state 	<= fcomp_next_state;
		end		
	end
	/*-----------Defining State Register----------*/	

	always @(*) 
	begin

		case (fcomp_state)

			START:
			begin
				fcomp_res_o   <= 0;
				fcomp_ready_o <= 0;

				if (fcomp_en_i)
				begin
					//$display("			fcomp module enabled:: \t@time %0t", $realtime());
					fcomp_next_state <= COMP;
				end
				else
				begin
					fcomp_next_state <= START;
				end
			end

			COMP:
			begin

				fcomp_res_o  <= fcomp_res_reg;
				if (fcomp_en_i)
				begin
					fcomp_ready_o 		<= 1;
					fcomp_next_state 	<= COMP;
				end
				else
				begin
					fcomp_ready_o 		<= 0;
					fcomp_next_state 	<= START;	 				
				end
			end
		
			default:
			begin 
				fcomp_res_o   		<= 0;
				fcomp_ready_o 		<= 0;
				fcomp_next_state 	<= START;	 			
			end
		endcase

	end 

endmodule