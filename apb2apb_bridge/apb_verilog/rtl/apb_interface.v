module apb_interface #(
    parameter BASE_ADDR  = 32'h0000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE   = 256,
    parameter WAIT_CYCLE = 1
  )

	(
    input                           clk,    // Clock
    input                           rst_n,  // Asynchronous reset active low

    input                           start,

    // Address & Data Channel
    input                           wr,
    input         [ADDR_WIDTH-1:0]  address,
    input         [DATA_WIDTH-1:0]  wdata,
    output  	    [DATA_WIDTH-1:0]  rdata
  );

  	// APB Interface

    wire	                  psel;
    wire	                  penable;
    wire	                  pwrite;
    wire	[ADDR_WIDTH-1:0]  paddr;
    wire	[DATA_WIDTH-1:0]  pwdata;
    wire	                  pready;
    wire	                  pslverr;
    wire	[DATA_WIDTH-1:0]  prdata;

    apb_master #(
	  	.BASE_ADDR   (BASE_ADDR ),
	  	.ADDR_WIDTH  (ADDR_WIDTH), 
	  	.DATA_WIDTH  (DATA_WIDTH), 
	  	.MEM_SIZE    (MEM_SIZE  ), 
	  	.WAIT_CYCLE  (WAIT_CYCLE) 
  	) 
  	apb_master_0 (
  		.clk			(clk		),
			.rst_n		(rst_n	),	
			.start		(start	),	
			
			.wr				(wr			),
			.address	(address),		
			.wdata		(wdata	),	
			.rdata		(rdata	),	
			
			.psel			(psel		),
			.penable	(penable),		
			.pwrite		(pwrite	),	
			.paddr		(paddr	),	
			.pwdata		(pwdata	),	
			.pready		(pready	),	
			.pslverr	(pslverr),		
			.prdata		(prdata	)		
  	);

  	apb_slave #(
	  	.BASE_ADDR  (BASE_ADDR  ),
	  	.ADDR_WIDTH (ADDR_WIDTH ),
	  	.DATA_WIDTH (DATA_WIDTH ),
	  	.MEM_SIZE   (MEM_SIZE   ),
	  	.WAIT_CYCLE (WAIT_CYCLE )
	  ) 
  	apb_slave_0 (
    	.clk			(clk		),
			.rst_n		(rst_n	),		
			
			.psel			(psel		),
			.penable	(penable),		
			.pwrite		(pwrite	),	
			.paddr		(paddr	),	
			.pwdata		(pwdata	),	
			.pready		(pready	),	
			.pslverr	(pslverr),		
			.prdata		(prdata	)	
  	);

endmodule