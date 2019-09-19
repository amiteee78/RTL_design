module apb_intf_tb 
	#(
    parameter BASE_ADDR  = 32'h0000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE   = 32,
    parameter WAIT_CYCLE = 3
  );

	bit                           clk;
	bit                           rst_n;
	bit                           start;
	
	// Adress & Data Channel
	bit                           wr;
	bit     [ADDR_WIDTH-1:0]      address;
	bit     [DATA_WIDTH-1:0]      wdata;
	logic   [DATA_WIDTH-1:0]      rdata;

	initial 
	begin
		forever
		begin
			#5 clk = ~clk;
		end 
	end

   
	apb_interface  	#(
								  	.BASE_ADDR   (BASE_ADDR ),
								  	.ADDR_WIDTH  (ADDR_WIDTH), 
								  	.DATA_WIDTH  (DATA_WIDTH), 
								  	.MEM_SIZE    (MEM_SIZE  ), 
								  	.WAIT_CYCLE  (WAIT_CYCLE) 
									) 
	apb_intf				(
										.clk			(clk		),
										.rst_n		(rst_n	),	
										.start		(start	),	
										
										.wr				(wr			),
										.address	(address),		
										.wdata		(wdata	),	
										.rdata		(rdata	)
									);

	initial
	begin
		$shm_open("wave_database/apb_intf.shm");
		$shm_probe("ACMTF");
		repeat(5) @(posedge clk);
		rst_n 	<= 1'b1;



/*		for (int i = 0; i<= MEM_SIZE ; i++)
		begin
			@(posedge clk);
			start 	<= 1'b1;
			@(posedge clk);
			wr 			<= 1'b1;
			address <= 32'h0000_0000+i;
			wdata 	<= 32'hDEAD_0000+i;
			repeat(3) @(posedge clk);
			wr 			<= 1'b0;
			@(posedge clk)
			start 	<= 1'b0;		
		end


		repeat(10) @(posedge clk);


		for (int i = 0; i<= MEM_SIZE ; i++)
		begin
			@(posedge clk);
			start		<= 1'b1;
			@(posedge clk);
			wr 			<= 1'b0;
			address <= 32'h0000_0000+i;
			repeat(3) @(posedge clk);
			wr 			<= 1'b0;
			@(posedge clk)
			start		<= 1'b0;		
		end*/


		/*Write Access*/

		for (int i = 0; i<= MEM_SIZE ; i++)
		begin
			@(posedge clk);
			start 	<= 1'b1;
			wr 			<= 1'b1;
			address <= 32'h0000_0000+i;
			wdata 	<= 32'hDEAD_0000+i;
			repeat(WAIT_CYCLE+1) @(posedge clk);
			wr 			<= 1'b0;
			repeat(2)@(posedge clk);
			start 	<= 1'b0;		
		end

		repeat(10) @(posedge clk);

		/*Read Access*/
		for (int i = 0; i<= MEM_SIZE ; i++)
		begin
			@(posedge clk);
			start		<= 1'b1;
			wr 			<= 1'b0;
			address <= 32'h0000_0000+i;
			repeat(WAIT_CYCLE+1) @(posedge clk);
			wr 			<= 1'b0;
			repeat(2)@(posedge clk);
			start		<= 1'b0;
			@(posedge clk);
			$display("Address:: %h\t Read Value:: %h\t @time %0t", address, rdata, $time());		
		end


		#100 $finish;
		$shm_close;
	end

endmodule