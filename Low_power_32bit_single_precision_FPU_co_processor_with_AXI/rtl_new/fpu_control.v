/*
	fpu_op_i[6] = COMP
	fpu_op_i[5] = DIV
	fpu_op_i[4] = MULT
	fpu_op_i[3] = SUB
	fpu_op_i[2] = ADD
	fpu_op_i[1] = CAST
	fpu_op_i[0] = ROUND
*/
`timescale 1ns/1ps

module fpu_control (
	input 							fpu_clk,  
	input 							fpu_rst_n,
	input 							fpu_en_i, 
	
	input 			[6:0] 	fpu_op_i,

	input 							fpu_dec_ready_i,
	input 							fpu_enc_ready_i,
	
	output reg 					fpu_dec_en_o,
	output reg 					fpu_enc_en_o,

	output reg 	[6:0] 	fpu_mod_en_o
	
	);

	localparam 	[1:0]  	IDLE 		= 2'b00;
	localparam 	[1:0]  	DECODE 	= 2'b01;
	localparam 	[1:0] 	OP_SEL  = 2'b10;  
	localparam 	[1:0]  	ENCODE  = 2'b11;

	reg 				[1:0]		fpu_state;
	reg 				[1:0]  	fpu_next_state;

	/*--------------Defining State Register--------------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			fpu_state 	<= IDLE;
		end

		else
		begin
			fpu_state 	<= fpu_next_state;
		end
	end
	/*--------------Defining State Register--------------*/

	/*--------------Defining Next State Logic & Output Logic--------------*/	
	always @(*) 
	begin
		
		case (fpu_state)

			IDLE:
			begin
				fpu_dec_en_o 		<= 0;
				fpu_enc_en_o  	<= 0;
				fpu_mod_en_o 		<= 0;

				if (fpu_en_i)
				begin
					fpu_next_state <= DECODE;
				end
				else
				begin
					fpu_next_state <= IDLE;
				end
			end

			DECODE:
			begin

				fpu_dec_en_o   	<= fpu_en_i;
				fpu_enc_en_o  	<= 0;
				fpu_mod_en_o 		<= 0;

				if (fpu_en_i & fpu_dec_ready_i)
				begin
					fpu_next_state 	<= OP_SEL;
				end
				else
				begin
					fpu_next_state 	<= DECODE;
				end
			end

			OP_SEL:
			begin

				if (fpu_en_i)
				begin
					fpu_dec_en_o   	<= 1;
					fpu_enc_en_o  	<= 0;
					fpu_mod_en_o 		<= fpu_op_i;

					fpu_next_state 	<= ENCODE;					
				end

				else
				begin
					fpu_dec_en_o   	<= 0;
					fpu_enc_en_o  	<= 0;
					fpu_mod_en_o 		<= 0;

					fpu_next_state 	<= OP_SEL;					
				end
			end

			ENCODE:
			begin

				if (fpu_en_i)
				begin
					fpu_enc_en_o  	<= 1;
					fpu_mod_en_o 		<= fpu_op_i;

					fpu_dec_en_o   	<= ~fpu_enc_ready_i;			
				end

				else
				begin
					fpu_enc_en_o  	<= 0;
					fpu_mod_en_o 		<= 0;
					fpu_dec_en_o   	<= 0;							
				end

				if (fpu_enc_ready_i)
				begin
					fpu_next_state 	<= IDLE;						
				end
				else
				begin
					fpu_next_state 	<= ENCODE;						
				end
			end
		
			default:
			begin
					fpu_dec_en_o   	<= 0;
					fpu_enc_en_o  	<= 0;
					fpu_mod_en_o 		<= 0;
					fpu_next_state 	<= IDLE;				
			end
		endcase
	end
	/*--------------Defining Next State Logic & Output Logic--------------*/	

endmodule