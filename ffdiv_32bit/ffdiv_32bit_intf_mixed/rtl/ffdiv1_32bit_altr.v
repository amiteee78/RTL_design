/*******************Floating Point Divider by Binomial Series Expansion********************/
/*****************(Two Independent Multiplications with Quadratic Convergence)******************/

module ffdiv1_32bit_altr #(

		parameter OPERAND_WIDTH 			= 32,
		parameter EXP_WIDTH 					=  8,
		parameter SIGNIFICAND_WIDTH 	= 24,
		parameter PRECISION_WIDTH 		= SIGNIFICAND_WIDTH+4
	)

	(
		input 																			clk,    						// Clock
		input 																			rst_n,  						// Asynchronous reset active low
		
		input 				[OPERAND_WIDTH-1:0]						op_1,
		input 				[OPERAND_WIDTH-1:0]						op_2,
				
		input 																			div_start,
		
		output 	reg 																sign,
		output 	reg 	[EXP_WIDTH-1:0] 							biased_exp,
		output 	reg		[SIGNIFICAND_WIDTH-2:0] 			fraction,
		output 	reg																	div_ready,
		output 	reg 	[$clog2(PRECISION_WIDTH)-1:0] count 							// (cycles needed to get div_result)
	);

	localparam 	[2:0] 												IDLE		= 3'b000;
	localparam 	[2:0] 												START 		= 3'b001;
	localparam 	[2:0] 												ITERATE 	= 3'b011;
	localparam  [2:0] 												EXP_OVF 	= 3'b010;
	localparam  [2:0] 												ENCODE 		= 3'b110;
						
	reg		 			[2:0] 												div_state;
	reg 				[2:0] 												div_next_state;

	reg 				[PRECISION_WIDTH-1:0] 				div_i;
	reg 				[PRECISION_WIDTH-1:0] 				qnt_i;

	reg 				[PRECISION_WIDTH-1:0] 				prev_qnt;
	reg 				[PRECISION_WIDTH-1:0] 				qnt_diff;
	reg 				[PRECISION_WIDTH-4:0] 				div_i_low; 
	reg 				[PRECISION_WIDTH-4:0] 				qnt_i_low;




	reg 				[$clog2(OPERAND_WIDTH)-1:0] 	exp_shift1;
	reg 				[$clog2(OPERAND_WIDTH)-1:0] 	exp_shift2;
	reg 				[$clog2(OPERAND_WIDTH)-1:0] 	dnrm_frc_shft;

	reg 				[2*EXP_WIDTH-1:0] 						unbiased_exp_1;
	reg 				[2*EXP_WIDTH-1:0] 						unbiased_exp_2;

	wire 				[2*EXP_WIDTH-1:0] 						unbiased_exp_div;

	wire 																			is1_nan;
	wire 																			is2_nan;

	wire 																			is1_inf;
	wire 																			is2_inf;

	wire 																			is2_zero;

	wire 																			is1_denorm;
	wire 																			is2_denorm;

	wire 																			is1_norm;
	wire 																			is2_norm;
	wire 																			is_neg_div_exp;

	wire 				[SIGNIFICAND_WIDTH-1:0] 			significand_1;
	wire 				[SIGNIFICAND_WIDTH-1:0] 			significand_2;
	wire				[SIGNIFICAND_WIDTH-1:0] 			significand;
	wire 				[EXP_WIDTH-1:0] 							exp_1;
	wire 				[EXP_WIDTH-1:0] 							exp_2;

	wire 																			is_neg_exp_ovf;
	wire 																			is_pos_exp_ovf;
	wire 																			is_out_denorm;


	/*********************************************************************************************************************************************/
	assign is1_nan 					= ((&op_1[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1]) & (|op_1[SIGNIFICAND_WIDTH-2:0])) 	? 1'b1 : 1'b0;
	assign is2_nan 					= ((&op_2[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1]) & (|op_2[SIGNIFICAND_WIDTH-2:0])) 	? 1'b1 : 1'b0;
				
	assign is1_inf 					= ((&op_1[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1]) & ~(|op_1[SIGNIFICAND_WIDTH-2:0])) 	? 1'b1 : 1'b0;
	assign is2_inf 					= ((&op_2[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1]) & ~(|op_2[SIGNIFICAND_WIDTH-2:0])) 	? 1'b1 : 1'b0;
				
	assign is1_zero 				=	(~(|op_1[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1]) & ~(|op_1[SIGNIFICAND_WIDTH-2:0])) ? 1'b1 : 1'b0;
	assign is2_zero 				=	(~(|op_2[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1]) & ~(|op_2[SIGNIFICAND_WIDTH-2:0])) ? 1'b1 : 1'b0;
		
	assign is1_denorm 			= (~(|op_1[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1]) & (|op_1[SIGNIFICAND_WIDTH-2:0])) 	? 1'b1 : 1'b0;
	assign is2_denorm 			= (~(|op_2[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1]) & (|op_2[SIGNIFICAND_WIDTH-2:0])) 	? 1'b1 : 1'b0;
		
	assign is1_norm 				= ~(is1_nan | is1_inf | is1_zero | is1_denorm) ? 1'b1 : 1'b0;
	assign is2_norm 				= ~(is2_nan | is2_inf | is2_zero | is2_denorm) ? 1'b1 : 1'b0;
	
	assign unbiased_exp_div = (significand_1 > significand_2) ? (unbiased_exp_1 - unbiased_exp_2) : (unbiased_exp_1 - unbiased_exp_2) + 16'hFFFF;

	assign is_neg_div_exp 	= unbiased_exp_div[2*EXP_WIDTH-1];


	assign exp_1 						= op_1[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1];
	assign exp_2 						= op_2[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1];
	assign significand_1 		= {|op_1[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1], op_1[SIGNIFICAND_WIDTH-2:0]};
	assign significand_2 		= {|op_2[OPERAND_WIDTH-2:SIGNIFICAND_WIDTH-1], op_2[SIGNIFICAND_WIDTH-2:0]};

	assign significand 			= (|qnt_diff[PRECISION_WIDTH-1:1]) ? 0 : qnt_i[PRECISION_WIDTH-3:PRECISION_WIDTH-26] + {23'h0, {(qnt_i[PRECISION_WIDTH-3:PRECISION_WIDTH-26] & (|qnt_i[PRECISION_WIDTH-27:0]))}};

	assign is_neg_exp_ovf 	= (unbiased_exp_div < 16'hFF6B) & (is_neg_div_exp == 1);
	assign is_pos_exp_ovf 	= (unbiased_exp_div > 16'h007F) & (is_neg_div_exp == 0);
	assign is_out_denorm 		= (unbiased_exp_div >= 16'hFF6B) & (unbiased_exp_div < 16'hFF82) & (is_neg_div_exp == 1);
	/*********************************************************************************************************************************************/

	// Defining State Register & Internal Registers

	always @(posedge clk or negedge rst_n) 
	begin
		if(~rst_n) 
		begin
			div_state 	  		<= IDLE;
			div_ready 	  		<= '0;
			count 			  		<= '0;

			div_i 						<= '0;
			qnt_i 						<= '0;

			prev_qnt 					<= '1;
			qnt_diff 					<= '1;

			div_i_low 				<= '0;
			qnt_i_low 				<= '0;

			unbiased_exp_1		<= '0;
			unbiased_exp_2 		<= '0;

			sign 							<= '0;
			biased_exp 				<= '0;

		end 

		else
		begin
			div_state 						<= div_next_state;
			
			if (div_next_state == START)
			begin 

				if (is1_denorm)
				begin
					qnt_i 						<= {3'b000,significand_1,{{PRECISION_WIDTH-SIGNIFICAND_WIDTH-3}{1'b0}}} << exp_shift1;
					unbiased_exp_1		<= 16'hFF82 - {8'h00, exp_shift1};
				end
				else if (is1_norm)
				begin
					qnt_i 						<= 	{3'b000,significand_1,{{PRECISION_WIDTH-SIGNIFICAND_WIDTH-3}{1'b0}}};
					unbiased_exp_1  	<= {8'h00,exp_1} - 16'h007F;
				end

				if (is2_denorm)
				begin
					div_i 						<= {3'b000,significand_2,{{PRECISION_WIDTH-SIGNIFICAND_WIDTH-3}{1'b0}}} << exp_shift2;
					unbiased_exp_2		<= 16'hFF82 - {8'h00, exp_shift2};
				end
				else if (is2_norm)
				begin
					div_i 						<= 	{3'b000,significand_2,{{PRECISION_WIDTH-SIGNIFICAND_WIDTH-3}{1'b0}}};
					unbiased_exp_2  	<= {8'h00,exp_2} - 16'h007F;
				end

			end

			else if (div_next_state == ITERATE)
			begin

				count 								<= count + 1;
				prev_qnt 							<= qnt_i;
				qnt_diff 							<= prev_qnt ^ qnt_i;

				{div_i, div_i_low} 		<= div_i * ({2'b01, {{PRECISION_WIDTH-2}{1'b0}}} - div_i);
				{qnt_i, qnt_i_low} 		<= qnt_i * ({2'b01, {{PRECISION_WIDTH-2}{1'b0}}} - div_i);

			end

			else if (div_next_state == ENCODE)
			begin

				sign  						<= op_1[OPERAND_WIDTH-1] ^ op_2[OPERAND_WIDTH-1];

				if (is_pos_exp_ovf | is2_zero)
				begin
					biased_exp 			<= 8'hFF;
				end

				else if (is1_zero | is_neg_exp_ovf | is_out_denorm)
				begin
					biased_exp 			<= 8'h00;
				end

				else
				begin
					biased_exp 			<= unbiased_exp_div + 16'h007F;
				end

			end
			else
			begin
				count <= count;
			end
		end
	end

	// Defining Next State Logic

	always @(*) 

	begin
		
		div_next_state 	<= 3'bxxx;

		case (div_state)

			IDLE	: begin

									if (div_start)
									begin
										div_next_state 	<= START;
									end

									else
									begin
										div_next_state 	<= IDLE;
									end

								end

			START 	: begin
										if (unbiased_exp_div < 16'hFF6B && is_neg_div_exp == 1)
										begin
											div_next_state  	<= EXP_OVF; // Neg_exponent_overflow
										end
										else
										begin
											div_next_state 	  <= 	ITERATE;
										end
								end

			ITERATE : begin

									if (|qnt_diff[PRECISION_WIDTH-1:1])
									begin
										div_next_state 			<= ITERATE;	
									end

									else
									begin
										div_next_state 			<= ENCODE;
									end

								end

			EXP_OVF : begin
									div_next_state 				<= ENCODE;
								end

			ENCODE 	: begin
									div_next_state 				<= ENCODE;
								end
			default : begin
									div_next_state 				<= IDLE;
								end
		endcase
	end


	// Defining Output Logic

	always @(*) 

	begin
		
		case (div_state)

			IDLE	: begin

									div_ready 			<= 0;
									fraction 				<= 0;
									dnrm_frc_shft 	<= 0;

									if (is1_denorm)
									begin

										casex (significand_1)

											24'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx : exp_shift1 <= 1;
											24'b001x_xxxx_xxxx_xxxx_xxxx_xxxx : exp_shift1 <= 2;
											24'b0001_xxxx_xxxx_xxxx_xxxx_xxxx : exp_shift1 <= 3;
											24'b0000_1xxx_xxxx_xxxx_xxxx_xxxx : exp_shift1 <= 4;
											24'b0000_01xx_xxxx_xxxx_xxxx_xxxx : exp_shift1 <= 5;
											24'b0000_001x_xxxx_xxxx_xxxx_xxxx : exp_shift1 <= 6;
											24'b0000_0001_xxxx_xxxx_xxxx_xxxx : exp_shift1 <= 7;
											24'b0000_0000_1xxx_xxxx_xxxx_xxxx : exp_shift1 <= 8;
											24'b0000_0000_01xx_xxxx_xxxx_xxxx : exp_shift1 <= 9;
											24'b0000_0000_001x_xxxx_xxxx_xxxx : exp_shift1 <= 10;
											24'b0000_0000_0001_xxxx_xxxx_xxxx : exp_shift1 <= 11;
											24'b0000_0000_0000_1xxx_xxxx_xxxx : exp_shift1 <= 12;
											24'b0000_0000_0000_01xx_xxxx_xxxx : exp_shift1 <= 13;
											24'b0000_0000_0000_001x_xxxx_xxxx : exp_shift1 <= 14;
											24'b0000_0000_0000_0001_xxxx_xxxx : exp_shift1 <= 15;
											24'b0000_0000_0000_0000_1xxx_xxxx : exp_shift1 <= 16;
											24'b0000_0000_0000_0000_01xx_xxxx : exp_shift1 <= 17;
											24'b0000_0000_0000_0000_001x_xxxx : exp_shift1 <= 18;
											24'b0000_0000_0000_0000_0001_xxxx : exp_shift1 <= 19;
											24'b0000_0000_0000_0000_0000_1xxx : exp_shift1 <= 20;
											24'b0000_0000_0000_0000_0000_01xx : exp_shift1 <= 21;
											24'b0000_0000_0000_0000_0000_001x : exp_shift1 <= 22;
											24'b0000_0000_0000_0000_0000_0001 : exp_shift1 <= 23;
											default 													: exp_shift1 <= 0;

										endcase
									end

									else
									begin
										exp_shift1 	<= 0;
									end

									if (is2_denorm)
									begin

										casex (significand_2)

											24'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx : exp_shift2 <= 1;
											24'b001x_xxxx_xxxx_xxxx_xxxx_xxxx : exp_shift2 <= 2;
											24'b0001_xxxx_xxxx_xxxx_xxxx_xxxx : exp_shift2 <= 3;
											24'b0000_1xxx_xxxx_xxxx_xxxx_xxxx : exp_shift2 <= 4;
											24'b0000_01xx_xxxx_xxxx_xxxx_xxxx : exp_shift2 <= 5;
											24'b0000_001x_xxxx_xxxx_xxxx_xxxx : exp_shift2 <= 6;
											24'b0000_0001_xxxx_xxxx_xxxx_xxxx : exp_shift2 <= 7;
											24'b0000_0000_1xxx_xxxx_xxxx_xxxx : exp_shift2 <= 8;
											24'b0000_0000_01xx_xxxx_xxxx_xxxx : exp_shift2 <= 9;
											24'b0000_0000_001x_xxxx_xxxx_xxxx : exp_shift2 <= 10;
											24'b0000_0000_0001_xxxx_xxxx_xxxx : exp_shift2 <= 11;
											24'b0000_0000_0000_1xxx_xxxx_xxxx : exp_shift2 <= 12;
											24'b0000_0000_0000_01xx_xxxx_xxxx : exp_shift2 <= 13;
											24'b0000_0000_0000_001x_xxxx_xxxx : exp_shift2 <= 14;
											24'b0000_0000_0000_0001_xxxx_xxxx : exp_shift2 <= 15;
											24'b0000_0000_0000_0000_1xxx_xxxx : exp_shift2 <= 16;
											24'b0000_0000_0000_0000_01xx_xxxx : exp_shift2 <= 17;
											24'b0000_0000_0000_0000_001x_xxxx : exp_shift2 <= 18;
											24'b0000_0000_0000_0000_0001_xxxx : exp_shift2 <= 19;
											24'b0000_0000_0000_0000_0000_1xxx : exp_shift2 <= 20;
											24'b0000_0000_0000_0000_0000_01xx : exp_shift2 <= 21;
											24'b0000_0000_0000_0000_0000_001x : exp_shift2 <= 22;
											24'b0000_0000_0000_0000_0000_0001 : exp_shift2 <= 23;
											default 													: exp_shift2 <= 0;

										endcase
									end

									else
									begin
										exp_shift2 	<= 0;
									end
									
								end

			START 	: begin

									exp_shift1 			<= 0;
									exp_shift2 			<= 0;
									div_ready 			<= 0;
									fraction 				<= 0;
									dnrm_frc_shft 	<= 0;
								end

			ITERATE : begin

									exp_shift1 			<= 0;
									exp_shift2 			<= 0;
									fraction 				<= 0;
									div_ready 			<= 0;

									if (|qnt_diff[PRECISION_WIDTH-1:1])
									begin										
										dnrm_frc_shft <= 0;
									end

									else
									begin

										case (unbiased_exp_div)

											16'hFF81 : dnrm_frc_shft <= 0;
											16'hFF80 : dnrm_frc_shft <= 1;
											16'hFF7F : dnrm_frc_shft <= 2;
											16'hFF7E : dnrm_frc_shft <= 3;
											16'hFF7D : dnrm_frc_shft <= 4;
											16'hFF7C : dnrm_frc_shft <= 5;
											16'hFF7B : dnrm_frc_shft <= 6;
											16'hFF7A : dnrm_frc_shft <= 7;
											16'hFF79 : dnrm_frc_shft <= 8;
											16'hFF78 : dnrm_frc_shft <= 9;
											16'hFF77 : dnrm_frc_shft <= 10;
											16'hFF76 : dnrm_frc_shft <= 11;
											16'hFF75 : dnrm_frc_shft <= 12;
											16'hFF74 : dnrm_frc_shft <= 13;
											16'hFF73 : dnrm_frc_shft <= 14;
											16'hFF72 : dnrm_frc_shft <= 15;
											16'hFF71 : dnrm_frc_shft <= 16;
											16'hFF70 : dnrm_frc_shft <= 17;
											16'hFF6F : dnrm_frc_shft <= 18;
											16'hFF6E : dnrm_frc_shft <= 19;
											16'hFF6D : dnrm_frc_shft <= 20;
											16'hFF6C : dnrm_frc_shft <= 21;
											16'hFF6B : dnrm_frc_shft <= 22;					
										
											default  : dnrm_frc_shft <= 0;
										endcase

									end

								end

			EXP_OVF : begin

									exp_shift1 			<= 0;
									exp_shift2 			<= 0;
									div_ready 			<= 0;
									fraction 				<= 0;
									dnrm_frc_shft 	<= 0;
								end

			ENCODE 	: begin

									exp_shift1 			<= 0;
									exp_shift2 			<= 0;
									div_ready 			<= 1;

									if (significand[SIGNIFICAND_WIDTH-1])
									begin
										if (is_out_denorm)
										begin
											fraction 	<= significand[SIGNIFICAND_WIDTH-2:0] >> dnrm_frc_shft;
										end

										else
										begin
											fraction 	<= significand[SIGNIFICAND_WIDTH-2:0];
										end										
									end

									else
									begin
										if (is_out_denorm)
										begin
											fraction 	<= {significand[SIGNIFICAND_WIDTH-2:0], 1'b0} >> dnrm_frc_shft;
										end

										else
										begin
											fraction 	<= {significand[SIGNIFICAND_WIDTH-3:0], 1'b0};
										end										
									end

								end

			default : begin

									exp_shift1 			<= 0;
									exp_shift2 			<= 0;
									div_ready 			<= 0;
									fraction 				<= 0;
									dnrm_frc_shft 	<= 0;
								end
		endcase
	end

endmodule