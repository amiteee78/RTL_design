/*
	fpu_res_type_o[4] = NAN
	fpu_res_type_o[3] = POS_inf
	fpu_res_type_o[2] = NEG_inf
	fpu_res_type_o[1] = INDET
	fpu_res_type_o[0] = FINITE

	fpu_op_o[6] = COMP
	fpu_op_o[5] = DIV
	fpu_op_o[4] = MULT
	fpu_op_o[3] = SUB
	fpu_op_o[2] = ADD
	fpu_op_o[1] = CAST
	fpu_op_o[0] = ROUND
*/

/*
fpu_round_mode_i ROUND to nearest EVEN = 3'b000;
fpu_round_mode_i ROUND towards ZERO		 = 3'b001;
fpu_round_mode_i ROUND to DOWN 				 = 3'b010;
fpu_round_mode_i ROUND to UP 					 = 3'b011;
fpu_round_mode_i ROUND to NEAREST MAX  = 3'b100;
*/

//**********Opcode Value of Round to Integer  = 00001
//**********Opcode Value of Cast to Float 		= 00010
//**********Opcode Value of Addition 					= 00011
//**********Opcode Value of Subtraction 			= 00100
//**********Opcode Value of Multiplication 		= 00101
//**********Opcode Value of Division 					= 00110
//**********Opcode Value of Compare 					= 00111

`timescale 1ns/1ps 

module fpu_dec 
	#(
		parameter EXPONENT_WIDTH 		= 8,
		parameter FRACTION_WIDTH 		= 23,
		parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
		parameter OPERAND_WIDTH     = 32,
		parameter OPCODE_WIDTH 			= 5,
		parameter BIASING_CONSTANT 	= 8'b0111_1111
	)
	(
		//***********Global Signal**************
		input  															fpu_clk,   
		input  															fpu_rst_n,
		input 															fpu_dec_en_i, 
		//***********Operands and Opcode********
		input	[OPCODE_WIDTH-1:0]						fpu_opcode_i,
		input [OPERAND_WIDTH-1:0]						fpu_operand1_i,
		input [OPERAND_WIDTH-1:0]						fpu_operand2_i,
		//***********Decoded Output**************
		output reg [4:0] 										fpu_res_type_o,
		output reg 													fpu_dec_ready_o,	

		output reg 													fpu_dec_sign1_o,
		output reg [EXPONENT_WIDTH-1:0]			fpu_dec_exp1_o,
		output reg [SIGNIFICAND_WIDTH-1:0] 	fpu_dec_sfgnd1_o,
		output reg 													fpu_dec_sign2_o,
		output reg [EXPONENT_WIDTH-1:0]			fpu_dec_exp2_o,
		output reg [SIGNIFICAND_WIDTH-1:0] 	fpu_dec_sfgnd2_o,
		//***********One hot encoded fpu_opcode_i value**
		output reg [6:0] 										fpu_op_o,
		output reg [OPERAND_WIDTH-1:0] 			fpu_res_nan_o
	);

	localparam 	[1:0]  							START 	  = 2'b00;
	localparam  [1:0]  							READY    	= 2'b01;
  localparam  [1:0]  							WAIT     	= 2'b10;

	reg 				[1:0]  							dec_state;
	reg 				[1:0]  							dec_next_state;

	wire 														is_snan_1;
	wire 														is_snan_2;
	wire 														is_qnan_1;
	wire 														is_qnan_2;

	wire 														is_pos_inf_1;
	wire 														is_pos_inf_2;
	wire 														is_neg_inf_1;
	wire 														is_neg_inf_2;
	wire 														is_zero_1;
	wire 														is_zero_2;
	wire 														is_pos_finite_1;
	wire 														is_pos_finite_2;

	wire 														is_neg_finite_1;
	wire 														is_neg_finite_2;

	wire 														op1_sign;
	wire 														op2_sign;
	wire 	[SIGNIFICAND_WIDTH-1:0] 	op1_significand;
	wire 	[SIGNIFICAND_WIDTH-1:0] 	op2_significand;
	wire 	[EXPONENT_WIDTH-1:0]			op1_exp;
	wire 	[EXPONENT_WIDTH-1:0]			op2_exp;	

	wire 														round;
	wire 														cast;
	wire 														add;
	wire 														sub;
	wire 														mult;
	wire 														div;
	wire 														comp;

	wire 														is_indeterminate;
  wire                            is_op_positive_inf;
  wire                            is_op_negative_inf;

	assign  op1_sign  				  =	fpu_operand1_i[OPERAND_WIDTH-1];
	assign  op2_sign  				  =	fpu_operand2_i[OPERAND_WIDTH-1];

	assign  op1_exp					 	  =	fpu_operand1_i[OPERAND_WIDTH-2:FRACTION_WIDTH];
	assign  op2_exp					 	  =	fpu_operand2_i[OPERAND_WIDTH-2:FRACTION_WIDTH];
  
	assign  op1_significand		  =	{|fpu_operand1_i[OPERAND_WIDTH-2:FRACTION_WIDTH], fpu_operand1_i[FRACTION_WIDTH-1:0]};
	assign  op2_significand     =	{|fpu_operand2_i[OPERAND_WIDTH-2:FRACTION_WIDTH], fpu_operand2_i[FRACTION_WIDTH-1:0]};
  
	assign is_snan_1 					  = ((&fpu_operand1_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & ~fpu_operand1_i[FRACTION_WIDTH-1] & (|fpu_operand1_i[FRACTION_WIDTH-2:0]));
	assign is_snan_2 					  = ((&fpu_operand2_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & ~fpu_operand1_i[FRACTION_WIDTH-1] & (|fpu_operand2_i[FRACTION_WIDTH-2:0]));

	assign is_qnan_1 					  = ((&fpu_operand1_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & fpu_operand1_i[FRACTION_WIDTH-1] & (|fpu_operand1_i[FRACTION_WIDTH-2:0]));
	assign is_qnan_2 					  = ((&fpu_operand2_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & fpu_operand1_i[FRACTION_WIDTH-1] & (|fpu_operand2_i[FRACTION_WIDTH-2 :0]));
  
	assign is_pos_inf_1				  = (~fpu_operand1_i[OPERAND_WIDTH-1] & (&fpu_operand1_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & ~(|fpu_operand1_i[FRACTION_WIDTH-1:0]));
	assign is_pos_inf_2				  = (~fpu_operand2_i[OPERAND_WIDTH-1] & (&fpu_operand2_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & ~(|fpu_operand2_i[FRACTION_WIDTH-1:0]));
  
	assign is_neg_inf_1				  = (fpu_operand1_i[OPERAND_WIDTH-1] & (&fpu_operand1_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & ~(|fpu_operand1_i[FRACTION_WIDTH-1:0])) ;	
	assign is_neg_inf_2				  = (fpu_operand2_i[OPERAND_WIDTH-1] & (&fpu_operand2_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & ~(|fpu_operand2_i[FRACTION_WIDTH-1:0])) ;
  
	assign is_zero_1					  = (~(|fpu_operand1_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & ~(|fpu_operand1_i[FRACTION_WIDTH-1:0]));
	assign is_zero_2					  = (~(|fpu_operand2_i[OPERAND_WIDTH-2:FRACTION_WIDTH]) & ~(|fpu_operand2_i[FRACTION_WIDTH-1:0]));
  
  assign is_pos_finite_1      = (~op1_sign & ~(is_snan_1|is_qnan_1|is_pos_inf_1|is_neg_inf_1|is_zero_1));
  assign is_pos_finite_2      = (~op2_sign & ~(is_snan_2|is_qnan_2|is_pos_inf_2|is_neg_inf_2|is_zero_2));

  assign is_neg_finite_1      = (op1_sign  & ~(is_snan_1|is_qnan_1|is_pos_inf_1|is_neg_inf_1|is_zero_1));
  assign is_neg_finite_2      = (op2_sign  & ~(is_snan_2|is_qnan_2|is_pos_inf_2|is_neg_inf_2|is_zero_2));
 


  assign is_indeterminate     = ( ((add  | div) & ((is_pos_inf_1 & is_neg_inf_2) | (is_neg_inf_1 & is_pos_inf_2)))
                              | ((sub  | div) & ((is_pos_inf_1 & is_pos_inf_2) | (is_neg_inf_1 & is_neg_inf_2)))
                              | (mult & ((is_zero_1 & ( is_pos_inf_2 | is_neg_inf_2))|((is_pos_inf_1|is_neg_inf_1) & is_zero_2)))
                              | (div  & is_zero_2)
                              );

  assign is_op_positive_inf 	= ( ((mult | add | sub | div) & (is_pos_inf_1 & is_pos_finite_2))
                              | ((mult | add) & ((is_pos_inf_1 |is_pos_finite_1) & is_pos_inf_2))
                              | ((add  | sub) & (is_pos_inf_1 & (is_zero_2 | is_neg_finite_2 )))
                              | ((mult | div) & (is_neg_inf_1 & is_neg_finite_2 ))
                              | ((mult | sub) & (is_neg_finite_1 & is_neg_inf_2))
                              | ( mult & is_neg_inf_1 & is_neg_inf_2)
                              | ( add  & ((is_zero_1| is_neg_finite_1) & is_pos_inf_2))
                              | ( sub  & ((is_pos_inf_1 | is_zero_1| is_pos_finite_1) & is_neg_inf_2))
                              | ((round | cast) & is_pos_inf_1)
                              );

  assign is_op_negative_inf   = ( ((mult | add | sub | div) & (is_neg_inf_1 & is_pos_finite_2 ))
                              | ((mult | add) & (is_pos_finite_1 & is_neg_inf_2))
                              | ((add  | sub) & (is_neg_inf_1 & (is_zero_2 | is_neg_finite_2)))
                              | ((mult | div) & (is_pos_inf_1 & is_neg_finite_2))
                              | ((mult | sub) & ((is_neg_finite_1 | is_neg_inf_1) & is_pos_inf_2))
                              | ( mult& is_pos_inf_1 & is_neg_inf_2)
                              | ( add & ((is_neg_inf_1 | is_zero_1 | is_neg_finite_1) & is_neg_inf_2))
                              | ( sub & ((is_zero_1| is_pos_finite_1)& is_pos_inf_2)) 
                              | ((round | cast) & is_neg_inf_1)                        
                              );
	
	assign round 								= (fpu_opcode_i == 5'b00001);
	assign cast 								= (fpu_opcode_i == 5'b00010);
	assign add  								= (fpu_opcode_i == 5'b00011);
	assign sub 	 								= (fpu_opcode_i == 5'b00100);
	assign mult 								= (fpu_opcode_i == 5'b00101);
	assign div 	 								= (fpu_opcode_i == 5'b00110);
	assign comp  								= (fpu_opcode_i == 5'b00111);

	/*-------------Defining State Register-------------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if (~fpu_rst_n)
		begin
			dec_state   <= START;
		end

		else
		begin
			dec_state 	<= dec_next_state ;
		end
	end
	/*-------------Defining State Register-------------*/

	/*-------------Defining Output Register------------*/
	always @(posedge fpu_clk, negedge fpu_rst_n)
	begin
		if(~fpu_rst_n) 
		begin

			fpu_dec_sign1_o 		<= 0;
			fpu_dec_sign2_o 		<= 0;
			fpu_dec_exp1_o 			<= 0;
			fpu_dec_exp2_o 			<= 0;
			fpu_dec_sfgnd1_o 		<= 0;
			fpu_dec_sfgnd2_o 		<= 0;
			fpu_op_o 						<= 0;
			fpu_res_type_o 			<= 0;
			fpu_res_nan_o       <= 0;
			fpu_dec_ready_o 		<= 0;
		end 

		else if (dec_next_state == READY && fpu_dec_en_i == 1)
		begin

			fpu_op_o 						<= {comp,div,mult,sub,add,cast,round};
			fpu_dec_sign1_o 		<= op1_sign;
			fpu_dec_sign2_o 		<= op2_sign;
			fpu_dec_exp1_o 			<= op1_exp;
			fpu_dec_exp2_o 			<= op2_exp;
			fpu_dec_sfgnd1_o 		<= op1_significand;
			fpu_dec_sfgnd2_o 		<= op2_significand;
			fpu_dec_ready_o 		<= 1;

			if(is_snan_1 | is_snan_2 | is_qnan_1 | is_qnan_2)
			begin
				fpu_res_type_o   	<= 5'b10000;					
			end

			else if(is_indeterminate)
			begin
				fpu_res_type_o   	<= 5'b00010;
			end

			else if(is_op_positive_inf)
			begin
				fpu_res_type_o   	<= 5'b01000;
			end

			else if(is_op_negative_inf)
			begin
				fpu_res_type_o   	<= 5'b00100;
			end

			else 
			begin
				fpu_res_type_o 		<= 5'b00001;
			end

			//**********************Output NaN Calculation Starts***************//
			if(is_snan_1 & is_qnan_2)
			begin
				fpu_res_nan_o 	<= fpu_operand2_i;
			end

			else if(is_snan_2 & is_qnan_1)
			begin
				fpu_res_nan_o 	<= fpu_operand1_i;
			end

			else if((is_snan_1 & is_snan_2) & (fpu_operand1_i[FRACTION_WIDTH-1:0] > fpu_operand2_i[FRACTION_WIDTH-1:0]))
			begin 
				fpu_res_nan_o 	<= {op1_sign, op1_exp, 1'b1 ,fpu_operand1_i[FRACTION_WIDTH-2:0]};
			end

			else if((is_snan_1 & is_snan_2) & (fpu_operand1_i[FRACTION_WIDTH-1:0] <= fpu_operand2_i[FRACTION_WIDTH-1:0]))
			begin 
				fpu_res_nan_o 	<= {op2_sign, op2_exp, 1'b1 ,fpu_operand2_i[FRACTION_WIDTH-2:0]};
			end

			else if((is_qnan_1 & is_qnan_2) & (fpu_operand1_i[FRACTION_WIDTH-1:0] > fpu_operand2_i[FRACTION_WIDTH-1:0]))
			begin 
				fpu_res_nan_o 	<= fpu_operand1_i;
			end

			else if((is_qnan_1 & is_qnan_2) & (fpu_operand1_i[FRACTION_WIDTH-1:0] <= fpu_operand2_i[FRACTION_WIDTH-1:0]))
			begin 
				fpu_res_nan_o 	<= fpu_operand2_i;
			end
			else if(is_snan_1)
			begin 
				fpu_res_nan_o 	<= {op1_sign, op1_exp, 1'b1 ,fpu_operand1_i[FRACTION_WIDTH-2:0]};
			end
			else if(is_snan_2)
			begin 
				fpu_res_nan_o 	<= {op2_sign, op2_exp, 1'b1 ,fpu_operand2_i[FRACTION_WIDTH-2:0]};
			end
			else if(is_qnan_1)
			begin 
				fpu_res_nan_o 	<= fpu_operand1_i;
			end
			else if(is_qnan_2)
			begin 
				fpu_res_nan_o 	<= fpu_operand2_i;
			end
			//**********************Output NaN Calculation End***************//
		end

    else if (dec_next_state == WAIT)
    begin
      fpu_dec_ready_o     <= 0;    
    end

		else
		begin
			fpu_dec_sign1_o 		<= 0;
			fpu_dec_sign2_o 		<= 0;
			fpu_dec_exp1_o 			<= 0;
			fpu_dec_exp2_o 			<= 0;
			fpu_dec_sfgnd1_o 		<= 0;
			fpu_dec_sfgnd2_o 		<= 0;
			fpu_op_o 						<= 0;
			fpu_res_type_o 			<= 0;
			fpu_dec_ready_o 		<= 0;					
		end
	end
	/*-------------Defining Output Register------------*/

	/*-------------Defining Next State Logic------------*/
	always @(*) 
	begin
		case (dec_state)
			START: 
			begin

				if(fpu_dec_en_i)
				begin
					dec_next_state   <= READY;
				end
				else
				begin
					dec_next_state   <= START;
				end
			end

			READY : 
			begin

				if (fpu_dec_en_i)
				begin
					dec_next_state   <= WAIT;
				end

				else
				begin
					dec_next_state   <= START;
				end

			end

      WAIT :
      begin
        if (fpu_dec_en_i)
        begin
          dec_next_state  <= WAIT;
        end

        else
        begin
          dec_next_state  <= START;
        end
      end

			default : 
			begin
				dec_next_state 		<= START;				
			end
		endcase
	end
	/*-------------Defining Next State Logic------------*/

endmodule