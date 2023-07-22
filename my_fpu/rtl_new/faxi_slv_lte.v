/*
freg_o[0] === OPERAND1_REG ------------------------>> (WR)
freg_o[1] === OPERAND2_REG ------------------------>> (WR)
freg_o[2] === FRM_OP_REG   ------------------------>> (WR)
freg_o[3] === FCS_REG 		 ------------------------>> (WR)
freg_o[4] === FRES_REG 		 ------------------------>> (RO)
*/
`timescale 1ns/1ps

module faxi_slv_lte #(

	parameter OPERAND_WIDTH = 32,
	parameter BASE_ADDR  		= 32'h0000_0000,
	parameter ADDR_WIDTH 		= 32,
	parameter DATA_WIDTH 		= 32,
	parameter STRB_WIDTH 		= DATA_WIDTH/8

	)

	(
		input 												aclk,  
		input 												arst_n,


		/*----------------Write Address Channel----------------*/
		input 	wire 									awvalid_i,
		input 	wire [ADDR_WIDTH-1:0]	awaddr_i,
		output 	reg 									awready_o,
		/*----------------Write Address Channel----------------*/
	
		/*-----------------Write Data Channel------------------*/
		input 	wire 									wvalid_i,
		input 	wire [DATA_WIDTH-1:0]	wdata_i,
		input 	wire [STRB_WIDTH-1:0] wstrb_i,
		output 	reg 									wready_o,
		/*-----------------Write Data Channel------------------*/

		/*---------------Write response Channel----------------*/
		input 	wire 									bready_i,
		output 	reg  [1:0]						bresp_o,
		output 	reg										bvalid_o,
		/*---------------Write response Channel----------------*/

		/*-----------------Read Address Channel----------------*/
		input 	wire 									arvalid_i,
		input 	wire [ADDR_WIDTH-1:0]	araddr_i,
		output 	reg 									arready_o,
		/*-----------------Read Address Channel----------------*/
	
		/*------------------Read Data Channel------------------*/
		input 	wire 									rready_i,		
		output	reg 									rvalid_o,
		output	reg [DATA_WIDTH-1:0]	rdata_o,
		output 	reg [1:0]							rresp_o,
		/*------------------Read Data Channel------------------*/

		/*------------------Interfacing with FPU------------------*/
		input  			[OPERAND_WIDTH-1:0]  fpu_result_i,
		input        									   fpu_res_ready_i,
		input 			[4:0]								 fpu_flag_i,
		output  	[DATA_WIDTH-1:0] 		 freg_o_0,
		output  	[DATA_WIDTH-1:0] 		 freg_o_1,
		output  	[DATA_WIDTH-1:0] 		 freg_o_2,
		output  	[DATA_WIDTH-1:0] 		 freg_o_3,
		output  	[DATA_WIDTH-1:0] 		 freg_o_4
		/*------------------Interfacing with FPU------------------*/		
	);


	localparam 	[2:0] 						IDLE 	= 3'b000;
	localparam 	[2:0] 						AWVAL =	3'b001;
	localparam 	[2:0] 						ARVAL = 3'b010;
	localparam 	[2:0] 						WRITE = 3'b011;
	localparam 	[2:0] 						READ  = 3'b100;
	localparam 	[2:0] 						WRESP = 3'b101;
					
	reg 				[2:0] 						axi_state;
	reg 				[2:0] 						axi_next_state;
	reg                 [DATA_WIDTH-1:0]            freg_o[BASE_ADDR:BASE_ADDR+4];

	wire 				[7:0] 						strb_data1;
	wire 				[7:0] 						strb_data2;
	wire 				[7:0] 						strb_data3;
	wire 				[7:0] 						strb_data4;

	/*----------------Defining State Register-----------------*/

	always @(posedge aclk, negedge arst_n)
	begin
		if (~arst_n)
		begin
			axi_state 	<= IDLE;
		end

		else
		begin
			axi_state 	<= axi_next_state;
		end
	end

	/*----------------Defining State Register-----------------*/

	/*----------------Defining Memory Register----------------*/

	always @(posedge aclk, negedge arst_n)
	begin
		if (~arst_n)
		begin
			freg_o[BASE_ADDR] 	<= 0;
			freg_o[BASE_ADDR+1] <= 0;
			freg_o[BASE_ADDR+2] <= 0;
			freg_o[BASE_ADDR+3] <= 0;
			freg_o[BASE_ADDR+4] <= 0;

		end

		else if ((axi_next_state == WRITE) & (awvalid_i & wvalid_i) & (awaddr_i < (BASE_ADDR + 32'h4)))
		begin
			freg_o[awaddr_i]   <= wdata_i & {strb_data4, strb_data3, strb_data2, strb_data1}; 
		end

		else if (fpu_res_ready_i )
		begin
			freg_o[BASE_ADDR + 32'h3]   <= fpu_flag_i;
			freg_o[BASE_ADDR + 32'h4]   <= fpu_result_i;
		end

	end

	/*----------------Defining Memory Register----------------*/

	/*-----------------Defining Read Register-----------------*/
	always @(posedge aclk, negedge arst_n)
	begin
		if (~arst_n)
		begin
			rdata_o 		<= 0;
		end

		else if ((axi_next_state == READ) & (arvalid_i) & (araddr_i < (BASE_ADDR + 32'h5)))
		begin
			rdata_o 		<= freg_o[araddr_i];
		end
		else
		begin
			rdata_o 		<= 0;
		end
	end
	/*-----------------Defining Read Register-----------------*/

	/*---------------Defining Next State Logic----------------*/

	always @(*) 
	begin
		
		case (axi_state)

			IDLE:
			begin

				awready_o 					<= 1'b0;
				wready_o 						<= 1'b0;
				bvalid_o 						<= 1'b0;
				bresp_o 						<= 2'b00;

				arready_o 					<= 1'b0;
				rvalid_o 						<= 1'b0;
				rresp_o 						<= 2'b00;

				if (~(awvalid_i | arvalid_i))
				begin
					axi_next_state 		<= IDLE;
				end
				else if (awvalid_i)
				begin
					axi_next_state 		<= AWVAL;
				end
				else
				begin
					axi_next_state 		<= ARVAL;
				end
			end

			AWVAL:
			begin

				wready_o 						<= 1'b0;
				bvalid_o 						<= 1'b0;
				bresp_o 						<= 2'b00;

				arready_o 					<= 1'b0;
				rvalid_o 						<= 1'b0;
				rresp_o 						<= 2'b00;

				if (awvalid_i & wvalid_i)
				begin
					awready_o 				<= 1'b1;
					axi_next_state 		<= WRITE;
				end
				else
				begin
					awready_o 				<= 1'b0;
					axi_next_state 		<= AWVAL;
				end
			end

			ARVAL:
			begin

				awready_o 					<= 1'b0;
				wready_o 						<= 1'b0;
				bvalid_o 						<= 1'b0;
				bresp_o 						<= 2'b00;

				rvalid_o 						<= 1'b0;
				rresp_o 						<= 2'b00;

				if (arvalid_i)
				begin
					arready_o 				<= 1'b1;
					axi_next_state 		<= READ;
				end
				else
				begin
					arready_o 				<= 1'b0;
					axi_next_state 		<= ARVAL;
				end
			end

			WRITE:
			begin

				awready_o 					<= 1'b0;
				bvalid_o 						<= 1'b0;
				bresp_o 						<= 2'b00;

				arready_o 					<= 1'b0;
				rvalid_o 						<= 1'b0;
				rresp_o 						<= 2'b00;

				if (awvalid_i & wvalid_i)
				begin
					wready_o 					<= 1'b1;
					axi_next_state 		<= WRESP;
				end
				else
				begin
					wready_o 					<= 1'b0;
					axi_next_state 		<= WRITE;
				end
			end

			READ:
			begin

				awready_o 					<= 1'b0;
				wready_o 						<= 1'b0;
				bvalid_o 						<= 1'b0;
				bresp_o 						<= 2'b00;
	
				arready_o 					<= 1'b0;

				if (arvalid_i)
				begin
					rvalid_o 					<= 1'b1;
					if (araddr_i < (BASE_ADDR + 32'h8))
					begin
						rresp_o 				<= 2'b00;
					end
					else
					begin
						rresp_o 				<= 2'b10;
					end

					if (rready_i)
					begin
						axi_next_state 	<= IDLE;
					end
					else
					begin
						axi_next_state 	<= READ;
					end
				end

				else
				begin
					rresp_o 					<= 2'b00;
					rvalid_o 					<= 1'b0;
					axi_next_state 		<= READ;
				end				
			end

			WRESP:
			begin

				awready_o 					<= 1'b0;
				wready_o 						<= 1'b0;

				arready_o 					<= 1'b0;
				rvalid_o 						<= 1'b0;
				rresp_o 						<= 2'b00;

				if (awvalid_i & wvalid_i)
				begin

					if (awaddr_i < (BASE_ADDR + 32'h8))
					begin
						bvalid_o 				<= 1'b1;
						bresp_o 				<= 2'b00;
					end

					else
					begin
						bvalid_o 				<= 1'b1;
						bresp_o 				<= 2'b10;						
					end

					if (bready_i)
					begin
						axi_next_state 	<= IDLE;
					end
					else
					begin
						axi_next_state 	<= WRESP;
					end
				end

				else
				begin
					bvalid_o 				 	<= 1'b0;
					bresp_o 				 	<= 2'b00;	
					axi_next_state 		<= WRESP;
				end
			end

			default:
			begin
				axi_next_state 	 		<= IDLE;
			end

		endcase
	end
	/*---------------Defining Next State Logic----------------*/

	assign strb_data1 	= (wstrb_i[0] == 1'b1 ) ? 8'hFF : 8'h00;
	assign strb_data2 	= (wstrb_i[1] == 1'b1 ) ? 8'hFF : 8'h00;
	assign strb_data3 	= (wstrb_i[2] == 1'b1 ) ? 8'hFF : 8'h00;
	assign strb_data4 	= (wstrb_i[3] == 1'b1 ) ? 8'hFF : 8'h00;
	
	assign freg_o_0 = freg_o[BASE_ADDR];
	assign freg_o_1 = freg_o[BASE_ADDR+1];
	assign freg_o_2 = freg_o[BASE_ADDR+2];
	assign freg_o_3 = freg_o[BASE_ADDR+3];
	assign freg_o_4 = freg_o[BASE_ADDR+4];

endmodule