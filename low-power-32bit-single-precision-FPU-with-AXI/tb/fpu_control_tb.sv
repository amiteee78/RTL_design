/*
	fpu_op_i[6] = COMP
	fpu_op_i[5] = DIV
	fpu_op_i[4] = MULT
	fpu_op_i[3] = SUB
	fpu_op_i[2] = ADD
	fpu_op_i[1] = CAST
	fpu_op_i[0] = ROUND
*/

module fpu_control_tb ();

	bit 							fpu_clk;    
	bit 							fpu_rst_n;  
	bit 							fpu_en_i;

	bit 			[6:0] 	fpu_op_i;


	bit 							fpu_dec_ready_i;
	bit 							fpu_enc_ready_i;

	logic 						fpu_dec_en_o;
	logic 						fpu_enc_en_o;

	logic 		[6:0] 	fpu_mod_en_o;


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
		fpu_rst_n 			<= 1;
/*		fpu_en_i 				<= 1;
		fpu_op_i    		<= 7'b000_0010;

		wait(fpu_dec_en_o);
		repeat(3) @(posedge fpu_clk);
		fpu_dec_ready_i <= 1;
		repeat(1) @(posedge fpu_clk);
		fpu_dec_ready_i <= 0;

		wait(fpu_enc_en_o);
		repeat(5) @(posedge fpu_clk);
		fpu_enc_ready_i <= 1;

		@(posedge fpu_clk);
		fpu_en_i 				<= 0;
		fpu_dec_ready_i <= 0;
		fpu_enc_ready_i <= 0;*/

		fcontrol(7'b000_0001);
		fcontrol(7'b000_0010);
		fcontrol(7'b000_0100);
		fcontrol(7'b000_1000);
		fcontrol(7'b001_0000);
		fcontrol(7'b010_0000);
		fcontrol(7'b100_0000);
		#20 $finish;
	end

	task fcontrol(input bit [6:0] operation);

		@(posedge fpu_clk);
		fpu_en_i 				<= 1;
		fpu_op_i    		<= operation;

		wait(fpu_dec_en_o);
		repeat(3) @(posedge fpu_clk);
		fpu_dec_ready_i <= 1;
		repeat(1) @(posedge fpu_clk);
		fpu_dec_ready_i <= 0;

		wait(fpu_enc_en_o);
		repeat(5) @(posedge fpu_clk);
		fpu_enc_ready_i <= 1;

		@(posedge fpu_clk);
		fpu_en_i 				<= 0;
		fpu_dec_ready_i <= 0;
		fpu_enc_ready_i <= 0;		
	
	endtask : fcontrol

	fpu_control fpu_con (

		.fpu_clk					(fpu_clk				   ),	
		.fpu_rst_n				(fpu_rst_n			   ),	
		.fpu_en_i 				(fpu_en_i 			   ),	

		.fpu_op_i 				(fpu_op_i 			   ),	

		.fpu_dec_ready_i	(fpu_dec_ready_i   ),	
		.fpu_enc_ready_i	(fpu_enc_ready_i   ),	

		.fpu_dec_en_o			(fpu_dec_en_o		   ),
		.fpu_enc_en_o			(fpu_enc_en_o		   ),

		.fpu_mod_en_o			(fpu_mod_en_o		   )

	);

endmodule