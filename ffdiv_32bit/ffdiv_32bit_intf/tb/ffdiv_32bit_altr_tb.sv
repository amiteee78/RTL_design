module ffdiv_32bit_altr_tb #(

		parameter OPERAND_WIDTH 			= 32,
		parameter EXP_WIDTH 					=  8,
		parameter SIGNIFICAND_WIDTH 	= 24,
		parameter PRECISION_WIDTH 		= SIGNIFICAND_WIDTH+3
	);

		bit 															clk;    			// Clock
		bit 															rst_n;  			// Asynchronous reset active low

		bit 	[OPERAND_WIDTH-1:0]					op_1;
		bit 	[OPERAND_WIDTH-1:0]					op_2;
	
		bit 															div_start;
	
		logic 														sign;
		logic [EXP_WIDTH-1:0] 						biased_exp;
		logic [SIGNIFICAND_WIDTH-2:0] 		fraction;
		logic 														div_ready;
		logic	[$clog2(OPERAND_WIDTH)-1:0] count; 						// (cycles needed to get div_result)

		int 	count_sum;
		int 	run_count = 1;		
		initial
		begin
			forever
			begin
				#5 clk = ~clk;
			end
		end


		ffdiv1_32bit_altr #(
											.OPERAND_WIDTH 		(OPERAND_WIDTH 		),
											.EXP_WIDTH 				(EXP_WIDTH				),
											.SIGNIFICAND_WIDTH(SIGNIFICAND_WIDTH),
											.PRECISION_WIDTH 	(PRECISION_WIDTH 	)
			) 

			ffdiv32bit 	(
										.clk 					(clk 					),
										.rst_n 				(rst_n 				),

										.op_1 				(op_1 				),
										.op_2 				(op_2 				),

										.div_start 		(div_start 		),

										.sign 				(sign 				),
										.biased_exp 	(biased_exp 	),
										.fraction 		(fraction			),
										.div_ready 		(div_ready		),
										.count 				(count 				)
										
							 		);

		initial
		begin

			repeat(4) @(posedge clk);

			for (int i =0; i < run_count; i++)
			begin
				@(posedge clk);
				//op_2 					<= 32'b001101000_00100000000000000000000;
				//op_2 					<= 32'b100000000_00011000000000000000000;
				op_1 					<= 32'b110100001_10000000000000000000000;
				//op_2 					<= 32'b011000010_00100000000000000000000;
				op_2 					<= 32'b110000000_01111111111111111111111;			
				//divident 			<= 24'h8A00_00 + i*24'h00FF_FF;
				//divisor 			<= 24'hFFFF_FF - i*24'h00FF_FF;

				rst_n 				<= 1'b1;
				div_start 		<= 1'b1;

				wait(div_ready);

				$display("DIV_RESULT:: \t\t%1b_%8b_%23b \t@count %d \t@time %0t ns", sign, biased_exp, fraction, count ,$realtime());
				count_sum = count_sum + count;
				@(posedge clk);
				rst_n 				<= 1'b0;
				div_start 		<= 1'b0;
			end
			$display("Average Cycles Needed :: %0d", count_sum/run_count);
			#10 $finish(1);

		end

endmodule