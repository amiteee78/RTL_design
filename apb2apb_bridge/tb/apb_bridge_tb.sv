`timescale 1ns/1ns
`include "apb_arch.svh"

module apb_bridge_tb ();

  bit                         clk;   
  bit                         rst_n; 
  bit   [`STRB_SIZE-1:0]      strb;  
  bit                         trnsfr;
  // Address & Data Channel (APB Master)
  bit                         wr;
  bit   [`ADDR_WIDTH-1:0]     address;
  bit   [`DATA_WIDTH-1:0]     data_in;
  logic [`DATA_WIDTH-1:0]     data_out;
  // Address & Data Channel (Memory)
  logic                       mem_wr;
  logic [`MEM_DEPTH-1:0]      mem_be;
  logic [`ADDR_WIDTH-1:0]     mem_address;
  logic [`DATA_WIDTH-1:0]     mem_data_in;
  logic [`DATA_WIDTH-1:0]     mem_data_out;

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **              DUT Instantiation                **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/ 
  apbif test_bus(.*); // Interface Object Creation
  apb_bridge apb2apb (.ibus(test_bus)); // DUT Connection with Testbench

  memif mem_bus(.*);
  apb_mem memory (.membus(mem_bus));

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **               Clock Generation                **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/ 
  initial
  begin
    forever
    begin
      #5 clk = ~clk;
    end
  end

  initial
  begin
    $dumpfile("apb_bridge_tb.vcd");
    $dumpvars();
  end

  initial
  begin
    $monitor("Write Data:: %0h \t@time %0t ns", mem_data_in, $realtime());
  end

  initial
  begin
    clk     <= '0;
    rst_n   <= '0;
    repeat(5) @(posedge clk);
    rst_n   <= '1;
    @(posedge clk);
    trnsfr  <= '1;

    @(posedge clk);
    wr      <= '1;
    strb    <= `STRB_SIZE'hF;
    address <= `ADDR_WIDTH'h0000_00A1;
    data_in <= `DATA_WIDTH'hDEAD_BBEF;

    #100 $finish(1);
  end

  final
  begin
    $display("Simulation Finished");
  end  

endmodule