`timescale 1ns/1ps
module fcast #(

	parameter OPERAND_WIDTH 		= 32,
	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter BIASING_CONSTANT 	= 8'b0111_1111
	)
	
	(
		input 														fpu_clk,   
		input 														fpu_rst_n,
		input 														fcast_en_i,	 
		input				[OPERAND_WIDTH-1:0] 	fcast_op_i,

		output reg 												fcast_sign_o,
		output reg 	[EXPONENT_WIDTH-1:0] 	fcast_exp_o,
		output reg	[FRACTION_WIDTH-1:0] 	fcast_frac_o,
		output reg 	[2:0]									fcast_grs_bit_o,
		output reg 												fcast_ready_o,
		output reg 												fcast_overflow_o

	);

	localparam 	[1:0] 											START  = 2'b00;
	localparam	[1:0] 											SHIFT  = 2'b01;
	localparam 	[1:0] 											CALC   = 2'b10;

	reg 				[1:0] 											fcast_state;
	reg 				[1:0] 											fcast_next_state;
			
	reg 				[OPERAND_WIDTH-1:0]					shifted_op;
	reg 				[$clog2(OPERAND_WIDTH):0]		shift;
			
	wire 				[OPERAND_WIDTH-1:0]					op_unsigned;


	/*------------------------Getting the Absolute Value of Operand-------------------------*/
	assign op_unsigned 	= fcast_op_i[OPERAND_WIDTH-1] ? -fcast_op_i : fcast_op_i;
	/*------------------------Getting the Absolute Value of Operand-------------------------*/

	/*-----------Defining State Register----------*/
	always @(posedge fpu_clk or negedge fpu_rst_n) 
	begin
		if(~fpu_rst_n) 
		begin
			fcast_state 		<= START;
		end
		else
		begin
			fcast_state 	 	<= fcast_next_state;
		end
	end	
	/*-----------Defining State Register----------*/

	/*------------Defining Internal Register--------------*/	
	always @(posedge fpu_clk or negedge fpu_rst_n) 
	begin
		if(~fpu_rst_n) 
		begin
			shifted_op 			<= 0;
		end
		else if(fcast_next_state == SHIFT)
		begin
			shifted_op 			<= op_unsigned << shift;
		end
		else if(fcast_next_state == CALC)
		begin
			shifted_op 			<= shifted_op;
		end
		else
		begin
			shifted_op 			<= 0;
		end
	end
	/*------------Defining Internal Register--------------*/

	/*--------Defining Next State & Output Logic----------*/
	always @(*) 
	begin
	case (fcast_state)
		START:
		begin
			fcast_sign_o 					<= 0;
			fcast_exp_o 					<= 0; 
			fcast_frac_o 					<= 0;
			fcast_grs_bit_o 			<= 0;
			fcast_overflow_o 			<= 0;
			fcast_ready_o 				<= 0;

			if(fcast_en_i)
			begin
				//$display("			fcast module enabled:: \t@time %0t", $realtime());
				fcast_next_state 	<= SHIFT;
			end
			else
			begin
				fcast_next_state 	<= START;
			end
		end

		SHIFT:
		begin
			fcast_sign_o 					<= 0;
			fcast_exp_o 					<= 0; 
			fcast_frac_o 					<= 0;
			fcast_grs_bit_o 			<= 0;
			fcast_overflow_o 			<= 0;
			fcast_ready_o 				<= 0;
			
			if(fcast_en_i)
			begin
				fcast_next_state 	<= CALC;
			end
			else
			begin
				fcast_next_state 	<= SHIFT;
			end	
		end

		CALC:
		begin
			if (fcast_en_i)
			begin

				fcast_sign_o 					<= fcast_op_i[OPERAND_WIDTH-1];
				fcast_exp_o 					<= BIASING_CONSTANT + OPERAND_WIDTH - shift;
				fcast_frac_o 					<= shifted_op[OPERAND_WIDTH-1:EXPONENT_WIDTH+1];
				fcast_grs_bit_o 			<= shifted_op[EXPONENT_WIDTH+1:EXPONENT_WIDTH-1];
				fcast_ready_o					<= 1;

				if (shift < 9)	
				begin
					fcast_overflow_o 		<= 1;
				end
				else
				begin
					fcast_overflow_o 		<= 0;
				end
				fcast_next_state 			<= CALC;
			end

			else
			begin
				fcast_sign_o 					<= 0;
				fcast_exp_o 					<= 0; 
				fcast_frac_o 					<= 0;
				fcast_grs_bit_o 			<= 0;
				fcast_overflow_o 			<= 0;
				fcast_ready_o 				<= 0;
				fcast_next_state 			<= START;				
			end
		end

		default:
		begin
			fcast_sign_o 						<= 0;
			fcast_exp_o 						<= 0; 
			fcast_frac_o 						<= 0;
			fcast_grs_bit_o 				<= 0;
			fcast_overflow_o 				<= 0;
			fcast_ready_o 					<= 0;
			fcast_next_state 				<= START;			
		end 
		
	endcase
	end
	/*--------Defining Next State & Output Logic----------*/

	/*-------------Amount of Shifting Calculation--------------*/
	always @(*) 
	begin
		if(fcast_en_i)
		begin
			casex (op_unsigned)
				32'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 2;
				32'b001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 3;
				32'b0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 4;
				32'b0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 5;
				32'b0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 6;
				32'b0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 7;
				32'b0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 8;
				32'b0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 9;
				32'b0000_0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 10;
				32'b0000_0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 11;
				32'b0000_0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx : shift <= 12;
				32'b0000_0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx : shift <= 13;
				32'b0000_0000_0000_01xx_xxxx_xxxx_xxxx_xxxx : shift <= 14;
				32'b0000_0000_0000_001x_xxxx_xxxx_xxxx_xxxx : shift <= 15;
				32'b0000_0000_0000_0001_xxxx_xxxx_xxxx_xxxx : shift <= 16;
				32'b0000_0000_0000_0000_1xxx_xxxx_xxxx_xxxx : shift <= 17;
				32'b0000_0000_0000_0000_01xx_xxxx_xxxx_xxxx : shift <= 18;
				32'b0000_0000_0000_0000_001x_xxxx_xxxx_xxxx : shift <= 19;
				32'b0000_0000_0000_0000_0001_xxxx_xxxx_xxxx : shift <= 20;
				32'b0000_0000_0000_0000_0000_1xxx_xxxx_xxxx : shift <= 21;
				32'b0000_0000_0000_0000_0000_01xx_xxxx_xxxx : shift <= 22;
				32'b0000_0000_0000_0000_0000_001x_xxxx_xxxx : shift <= 23;
				32'b0000_0000_0000_0000_0000_0001_xxxx_xxxx : shift <= 24;
				32'b0000_0000_0000_0000_0000_0000_1xxx_xxxx : shift <= 25;
				32'b0000_0000_0000_0000_0000_0000_01xx_xxxx : shift <= 26;
				32'b0000_0000_0000_0000_0000_0000_001x_xxxx : shift <= 27;
				32'b0000_0000_0000_0000_0000_0000_0001_xxxx : shift <= 28;
				32'b0000_0000_0000_0000_0000_0000_0000_1xxx : shift <= 29;
				32'b0000_0000_0000_0000_0000_0000_0000_01xx : shift <= 30;
				32'b0000_0000_0000_0000_0000_0000_0000_001x : shift <= 31;
				32'b0000_0000_0000_0000_0000_0000_0000_0001 : shift <= 32;
				default 																		: shift <= 0;
			endcase
		end
		else
		begin
			shift <= 0;
		end
	end
/*-------------Amount of Shifting Calculation--------------*/

endmodule