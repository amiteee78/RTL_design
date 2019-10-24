`timescale 1ns/1ns
`include "apb_arch.svh"

module apb_bridge_tb ();

  logic                       clk;   
  logic                       rst_n; 
  logic                       strb;  
  logic                       trnsfr;
  // Address & Data Channel (APB Master)
  logic                       wr;
  logic [`ADDR_WIDTH-1:0]     address;
  logic [`DATA_WIDTH-1:0]     data_in;
  logic [`DATA_WIDTH-1:0]     data_out;
  // Address & Data Channel (Memory)
  logic                       mem_wr;
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
    #2000 $finish(1);
  end

  final
  begin
    $display("Simulation Finished");
  end  

endmodule