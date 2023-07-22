module axi_slave_tb #(
	parameter BASE_ADDR  = 32'hFFFF_0000,
	parameter ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 32,
	parameter STRB_WIDTH = DATA_WIDTH/8

	);

	bit 												aclk;    // Clock
	bit 												arst_n;  // Asynchronous reset active low


	/*----------------Write Address Channel----------------*/
	bit 												awvalid;
	bit 			[ADDR_WIDTH-1:0]	awaddr;
	logic 											awready;
	/*----------------Write Address Channel----------------*/

	/*-----------------Write Data Channel------------------*/
	bit 												wvalid;
	bit 			[DATA_WIDTH-1:0]	wdata;
	bit 			[STRB_WIDTH-1:0] 	wstrb;
	logic 											wready;
	/*-----------------Write Data Channel------------------*/

	/*---------------Write response Channel----------------*/
	bit 												bready;
	logic  		[1:0]							bresp;
	logic												bvalid;
	/*---------------Write response Channel----------------*/

	/*-----------------Read Address Channel----------------*/
	bit 												arvalid;
	bit 			[ADDR_WIDTH-1:0]	araddr;
	logic 											arready;
	/*-----------------Read Address Channel----------------*/

	/*------------------Read Data Channel------------------*/
	bit													rready;	
	logic 											rvalid;
	logic 		[DATA_WIDTH-1:0]	rdata;
	logic 		[1:0]							rresp;
	/*------------------Read Data Channel------------------*/


	initial
	begin
		forever
		begin
			#5 aclk = ~aclk;
		end
	end

	initial
	begin

		repeat(5) @(posedge aclk);
		arst_n 		<= 1'b1;

		/*------Back to back write------*/
		for (int i = 0; i < 6; i++)
		begin
			axi_slave_write(32'h0000_0003+i, 32'hDEADBEEF, (2**i)-1);
		end
		/*------Back to back write------*/

		/*------Back to back read-------*/
		for (int i = 0; i < 6; i++)
		begin
			axi_slave_read(32'h0000_0003+i);
		end
		/*------Back to back read-------*/

		/*----Sequential write read-----*/
		for (int i = 0; i < 9; i++)
		begin
			axi_slave_write(32'h0000_0000+i, 32'hDEADBEEF, (2**(i%5)-1));
			axi_slave_read(32'h0000_0000+i);
		end		
		/*----Sequential write read-----*/
		/*-----Write override read------*/
		for (int i = 0; i < 6; i++)
		begin
			axi_slave_write_ovr_read(32'h0000_0003+i, 32'hDEADBEEF, (2**i)-1);
		end		
		/*-----Write override read------*/
		/*------Back to back read-------*/
		for (int i = 0; i < 6; i++)
		begin
			axi_slave_read(32'h0000_0003+i);
		end
		/*------Back to back read-------*/
		#50 $finish;
	end

	task axi_slave_write(input bit [ADDR_WIDTH-1:0] addr, input bit [DATA_WIDTH-1:0] data, input bit [3:0] strobe);

		@(posedge aclk);
		awvalid 	<= 1'b1;
		wvalid 		<= 1'b1;
		wstrb 		<= strobe;
		awaddr 		<= BASE_ADDR + addr;
		wait(awready);
		wdata 		<= data;
		wait(wready);
		$display("\nWrite Address:: %h \tWrite Data:: %h \tStrobe:: %b \t@time %0t", addr, wdata, strobe, $realtime());
		wait(bvalid);
		@(posedge aclk);
		bready 		<= 1'b1;
		@(posedge aclk);
		bready 		<= 1'b0;
		awvalid 	<= 1'b0;
		wvalid 		<= 1'b0;
		@(posedge aclk);		
	
	endtask : axi_slave_write


	task axi_slave_read(input bit [ADDR_WIDTH-1:0] addr);
	
		@(posedge aclk);
		arvalid 	<= 1'b1;
		araddr 		<= BASE_ADDR + addr;
		wait(arready);

		wait(rvalid);
		$display("\nRead Address:: %h \tRead Data:: %h \t@time %0t", addr, rdata, $realtime());
		@(posedge aclk);
		rready 		<= 1'b1;
		@(posedge aclk);
		rready 		<= 1'b0;
		arvalid 	<= 1'b0;
		@(posedge aclk);

	endtask : axi_slave_read

	task axi_slave_write_ovr_read(input bit [ADDR_WIDTH-1:0] addr, input bit [DATA_WIDTH-1:0] data, input bit [3:0] strobe);

		@(posedge aclk);
		awvalid 	<= 1'b1;
		arvalid 	<= 1'b1;
		wvalid 		<= 1'b1;
		wstrb 		<= strobe;
		awaddr 		<= BASE_ADDR + addr;
		araddr 		<= BASE_ADDR + addr;
		wait(awready);
		wdata 		<= data;
		wait(wready);
		$display("\nWrite Address:: %h \tWrite Data:: %h \tStrobe:: %b \t@time %0t", addr, wdata, strobe, $realtime());
		wait(bvalid);
		@(posedge aclk);
		bready 		<= 1'b1;
		@(posedge aclk);
		bready 		<= 1'b0;
		awvalid 	<= 1'b0;
		arvalid 	<= 1'b0;
		wvalid 		<= 1'b0;
		@(posedge aclk);		
	
	endtask : axi_slave_write_ovr_read

	axi_slave_lite #(

		.BASE_ADDR  (BASE_ADDR  ), 
		.ADDR_WIDTH (ADDR_WIDTH ), 
		.DATA_WIDTH (DATA_WIDTH ), 
		.STRB_WIDTH (STRB_WIDTH ) 
	)
	axi_slv_lt (

		.aclk				(aclk			),
		.arst_n			(arst_n		),
		
		.awvalid		(awvalid	),
		.awaddr			(awaddr		),
		.awready		(awready	),
		
		.wvalid			(wvalid		),
		.wdata			(wdata		),
		.wstrb			(wstrb		),
		.wready			(wready		),
		
		.bready			(bready		),
		.bresp			(bresp		),
		.bvalid			(bvalid		),
		
		.arvalid		(arvalid	),
		.araddr			(araddr		),
		.arready		(arready	),
		
		.rready			(rready		),
		.rvalid			(rvalid		),
		.rdata			(rdata		),
		.rresp			(rresp		) 

		);
endmodule