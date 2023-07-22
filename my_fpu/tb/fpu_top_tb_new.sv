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

module fpu_top_tb_new #(
	parameter OPERAND_WIDTH 		= 32,

	parameter BASE_ADDR  				= 32'h0000_FF00,
	parameter ADDR_WIDTH 				= 32,
	parameter DATA_WIDTH 				= 32,
	parameter STRB_WIDTH 				= DATA_WIDTH/8,

	parameter EXPONENT_WIDTH  	= 8,
	parameter FRACTION_WIDTH 		= 23,
	parameter SIGNIFICAND_WIDTH = FRACTION_WIDTH+1,
	parameter PRCSN_WIDTH       = SIGNIFICAND_WIDTH+2,
	parameter OPCODE_WIDTH 			= 5,
	parameter BIASING_CONSTANT 	= 8'b0111_1111	
	);

	typedef enum bit [4:0] {FROUND = 1, FCAST = 2, FADD = 3, FSUB = 4, FMUL = 5, FDIV = 6, FCOMP = 7} opcode;
	typedef enum bit [2:0] {RNE = 0, RTZ = 1, RDN = 2, RUP = 3, RMM = 4, DRM = 7} round_mode;

	bit 	 										fpu_clk;
	bit 	 										fpu_rst_n;
	bit 	 										fpu_en_i;
	logic 										fpu_ready_o;

	/*-----------------AXI_LITE_SLAVE_INTF-----------------*/

	/*----------------Write Address Channel----------------*/
	bit 	 										awvalid_i;
	bit 	 [ADDR_WIDTH-1:0]		awaddr_i;
	logic 	 									awready_o;
	/*----------------Write Address Channel----------------*/

	/*-----------------Write Data Channel------------------*/
	bit 											wvalid_i;
	bit [DATA_WIDTH-1:0]			wdata_i;
	bit [STRB_WIDTH-1:0]  		wstrb_i;
	logic 										wready_o;
	/*-----------------Write Data Channel------------------*/

	/*---------------Write response Channel----------------*/
	bit 											bready_i;
	logic 	  [1:0]						bresp_o;
	logic 										bvalid_o;
	/*---------------Write response Channel----------------*/

	/*-----------------Read Address Channel----------------*/
	bit 											arvalid_i;
	bit [ADDR_WIDTH-1:0]			araddr_i;
	logic 	 									arready_o;
	/*-----------------Read Address Channel----------------*/

	/*------------------Read Data Channel------------------*/
	bit 											rready_i;
	logic	 										rvalid_o;
	logic	 [DATA_WIDTH-1:0]		rdata_o;
	logic 	 [1:0]						rresp_o;
	/*------------------Read Data Channel------------------*/
	/*-----------------AXI_LITE_SLAVE_INTF-----------------*/

	
	opcode  		opcd;
	round_mode  instr_rm;
	round_mode  static_rm;

	initial 
	begin
		forever
		begin
			#5 fpu_clk = ~fpu_clk;
		end
	end

	initial
	begin

		repeat(5) @(posedge fpu_clk);
		fpu_rst_n 	<= 1;
				 
    fpu_pgrm(4.5, 2.0, FMUL, RTZ, RTZ);
    fpu_pgrm(3.5, 0.0, FDIV, RTZ, RTZ);
    fpu_pgrm(3.5, 3.4589, FDIV, RTZ, RTZ);
    fpu_pgrm(3.8, 0.3, FSUB, DRM, RUP);
		fpu_pgrm(3.987651, -87.65218198112, FDIV, DRM, RNE);
		fpu_pgrm(0.003797201, 78727282.98123, FMUL, RMM, RTZ);
		fpu_pgrm(0.0, 2351.436716, FMUL, RMM, RTZ);
		fpu_pgrm(0.98284832, 0.00177372, FSUB, RMM, RTZ);
		fpu_pgrm(698989891.271719, 0.00000000002728728, FSUB, RUP, RMM);
		fpu_pgrm(3481.90347123, -32.9810100134621, FADD, DRM, RNE);

		fpu_pgrm(-2430.81981321, -2431.96762762, FCOMP, DRM, RNE);
		fpu_pgrm(-163.87, 0.0, FROUND, DRM, RUP);
		fpu_pgrm(9831, 0.0, FCAST, RMM, RTZ);
		fpu_pgrm(4.9528235E38, 2.4, FMUL, RMM, RTZ);
		//$display("%f", $bitstoshortreal(32'b1_11111111_00001001000000000000000));
		//$display("%f", shortreal'(-inf));

		#100 $finish;
	end

	task fpu_pgrm(input shortreal operand_1, operand_2, input opcode opcd, input round_mode instr_rm, static_rm);

		$display("\n*********************************************************************************************\n");
		$display("\tOPERAND_1:: %1.50f", operand_1);
		$display("\tOPERAND_2:: %1.50f", operand_2);
		for (int i = 0; i < 4; i++) 
		begin
			@(posedge fpu_clk);
			awvalid_i 	<= 1;
			wvalid_i 		<= 1;
			if (i > 1)
			begin
				wstrb_i 		<= 4'h1;
			end
			else
			begin
				wstrb_i 		<= 4'hF;
			end

			awaddr_i 		<= BASE_ADDR + i;
			wait(awready_o);
			case (i)
				0: wdata_i 		<= (opcd == FCAST) ? operand_1 : $shortrealtobits(operand_1);
				1: wdata_i 		<= $shortrealtobits(operand_2);
				2: wdata_i    <= {instr_rm,opcd};
				3: wdata_i    <= {static_rm,5'b00000};
			endcase
			
			wait(wready_o);

			case (i)
				0: 
				begin
					$display("\nOPERAND_REG1 PROGRAMMED");
					$display("----------------------------------------------------------------------------------------------------------");
				end
				1: begin
					$display("\nOPERAND_REG2 PROGRAMMED");
					$display("----------------------------------------------------------------------------------------------------------");				
				end
				2: 
				begin
					$display("\nFRM_OPCD_REG PROGRAMMED ----->> INSTR_ROUND_MODE:: %s \tOPCODE:: %s", instr_rm.name(), opcd.name());
					$display("----------------------------------------------------------------------------------------------------------");						
				end 
				3:
				begin
					$display("\nFCSR PROGRAMMED ------------->> STATIC_ROUND_MODE:: %s", static_rm.name());
					$display("----------------------------------------------------------------------------------------------------------");
				end 
			endcase
			$display("Write Address:: %h \tWrite Data::\t%b \t@time %0t ", awaddr_i, wdata_i, $realtime());

			wait(bvalid_o);
			@(posedge fpu_clk);
			bready_i 		<= 1;
			@(posedge fpu_clk);
			bready_i 		<= 0;
			awvalid_i 	<= 0;
			wvalid_i 		<= 0;
		end


		fpu_en_i 		<= 1;
		$display("\n----------------------------------------FPU ENABLED (@time %0t)----------------------------------------", $realtime());
		$display("			*****************************************************",);
		wait(fpu_ready_o);

		$display("			*****************************************************",);
		@(posedge fpu_clk);
		fpu_en_i 		<= 0;
		$display("------------------------------------FPU OPERATION COMPLETED (@time %0t)----------------------------------\n", $realtime());
		for (int i = 3; i < 5; i++) 
		begin
			@(posedge fpu_clk);
			arvalid_i 	<= 1'b1;
			araddr_i 		<= BASE_ADDR + i;
			wait(arready_o);

			wait(rvalid_o);
			case (i)
				3:
				begin
					case (1'b1)
						rdata_o[0] : $display("FCSR READ ------------------->> ZERO FLAG ASSERTED");
						rdata_o[1] : $display("FCSR READ ------------------->> UNDERFLOW FLAG ASSERTED");
						rdata_o[2] : $display("FCSR READ ------------------->> OVERFLOW FLAG ASSERTED");
						rdata_o[3] : $display("FCSR READ ------------------->> INFINITY FLAG ASSERTED");
						rdata_o[4] : $display("FCSR READ ------------------->> NaN FLAG ASSERTED");
						default : $display("FCSR READ ------------------->> NO FLAG ASSERTED");
					endcase
					
					$display("------------------------------------------------------------------------------");
					$display("Read Address:: %h \tRead Data::\t%b \t@time %0t\n", araddr_i, rdata_o, $realtime());
				end
				4:
				begin
					case (opcd)
						FROUND : $display("FRES_REG READ --------------->> RESULT OF FLOATING POINT TO INTEGER CONVERSION");
						FCAST  : $display("FRES_REG READ --------------->> RESULT OF INTEGER TO FLOATING POINT CONVERSION");
						FADD   : $display("FRES_REG READ --------------->> RESULT OF FLOATING POINT ADDITION");
						FSUB   : $display("FRES_REG READ --------------->> RESULT OF FLOATING POINT SUBTRACTION");
						FMUL   : $display("FRES_REG READ --------------->> RESULT OF FLOATING POINT MULTIPLICATION");
						FDIV   : $display("FRES_REG READ --------------->> RESULT OF FLOATING POINT DIVISION");
						FCOMP  : $display("FRES_REG READ --------------->> RESULT OF FLOATING POINT COMPARISON");
					
					endcase
					
					$display("----------------------------------------------------------------------------------------");
					$display("Read Address:: %h \tRead Data::\t%b \t@time %0t\n", araddr_i, rdata_o, $realtime());
					if (opcd == FCOMP)
					begin
						case (rdata_o)
							1 : $display("\tOPERAND_1 is greater than OPERAND_2",);
							-1: $display("\tOPERAND_1 is less than OPERAND_2",);
							0 : $display("\tOPERAND_1 is equal to OPERAND_2",);
						endcase
					end
					else if (opcd == FROUND)
					begin
					   $display("\tFPU RESULT:: %d", int'(rdata_o));
					end
					else
					begin
						$display("\tFPU RESULT:: %1.50f", $bitstoshortreal(rdata_o));
					end	
				end
			endcase

			@(posedge fpu_clk);
			rready_i 		<= 1'b1;
			@(posedge fpu_clk);
			rready_i 		<= 1'b0;
			arvalid_i 	<= 1'b0;
		end
		$display("\n\n*********************************************************************************************\n\n");
	endtask : fpu_pgrm

	fpu_top #(
		.OPERAND_WIDTH 		  (OPERAND_WIDTH 		 ),

		.BASE_ADDR  				(BASE_ADDR  			 ), 
		.ADDR_WIDTH 				(ADDR_WIDTH 			 ), 
		.DATA_WIDTH 				(DATA_WIDTH 			 ), 
		.STRB_WIDTH 				(STRB_WIDTH 			 ),

		.EXPONENT_WIDTH  	  (EXPONENT_WIDTH  	 ),
		.FRACTION_WIDTH 		(FRACTION_WIDTH 	 ),
		.SIGNIFICAND_WIDTH  (SIGNIFICAND_WIDTH ),
		.OPCODE_WIDTH 			(OPCODE_WIDTH 		 ),
		.BIASING_CONSTANT 	(BIASING_CONSTANT  )
		)

	fpu (
		.fpu_clk 					(fpu_clk 			 ),
		.fpu_rst_n 				(fpu_rst_n 		 ),
		.fpu_en_i 				(fpu_en_i 		 ),
		.fpu_ready_o 			(fpu_ready_o 	 ),

		.awvalid_i				(awvalid_i		 ),
		.awaddr_i					(awaddr_i			 ),
		.awready_o				(awready_o		 ),
			
		.wvalid_i					(wvalid_i			 ),
		.wdata_i					(wdata_i			 ),
		.wstrb_i					(wstrb_i			 ),
		.wready_o					(wready_o			 ),
			
		.bready_i					(bready_i			 ),
		.bresp_o					(bresp_o			 ),
		.bvalid_o					(bvalid_o			 ),
			
		.arvalid_i				(arvalid_i		 ),
		.araddr_i					(araddr_i			 ),
		.arready_o				(arready_o		 ),
			
		.rready_i					(rready_i			 ),
		.rvalid_o					(rvalid_o			 ),
		.rdata_o					(rdata_o			 ),
		.rresp_o					(rresp_o			 )

		);

endmodule