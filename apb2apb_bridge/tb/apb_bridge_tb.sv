`timescale 1ns/1ns
`include "apb_arch.svh"

typedef enum bit [1:0] {FULLWORD, HALFWORD, BYTE} dsel_type; 

module apb_bridge_tb ();

  bit                         clk;   
  bit                         rst_n; 
  bit   [`STRB_SIZE-1:0]      strb;
  dsel_type                   dsel;  
  bit                         trnsfr;
  // Address & Data Channel (APB Master)
  bit                         wr;
  bit   [`ADDR_WIDTH-1:0]     address;
  bit   [`DATA_WIDTH-1:0]     data_in;
  logic [`DATA_WIDTH-1:0]     data_out;
  // Address & Data Channel (Memory)
  logic                       mem_wr;
  logic                       mem_rd;
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
    $dumpvars(0);
  end

  initial
  begin
    $monitor("Write Enable:: %b \t Write Adress:: %h \tWrite Data:: %h \t@time %0t ns", test_bus.mem_wr, test_bus.mem_address, test_bus.data_in,  $realtime());    
    $monitor("Read  Enable:: %b \t Read  Adress:: %h \tRead  Data:: %h \t@time %0t ns", test_bus.mem_rd, test_bus.mem_address, test_bus.data_out, $realtime());
  end

  initial
  begin
    async_reset();

    for (int i = 0; i < 10; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_00F0 + i, FULLWORD, `DATA_WIDTH'h000A_3210 + i);
    end

    for (int i = 0; i < 10; i++) 
    begin
      single_read(`ADDR_WIDTH'h0000_00F0 + i, FULLWORD);
    end

    for (int i = 0; i < 10; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_0012 + i, HALFWORD, `DATA_WIDTH'h510F_CB29 + i);
    end

    for (int i = 0; i < 10; i++) 
    begin
      single_read(`ADDR_WIDTH'h0000_0012 + i, HALFWORD);
    end

    for (int i = 0; i < 10; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_003D + i, BYTE, `DATA_WIDTH'h0102_1034 + i);
    end

    for (int i = 0; i < 10; i++) 
    begin
      single_read(`ADDR_WIDTH'h0000_003D + i, BYTE);
    end

    // Slave Error Test
    for (int i = 0; i < 2; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_0100 + i, FULLWORD, `DATA_WIDTH'h0102_1034 + i);
    end

    for (int i = 0; i < 2; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_0200 + i, HALFWORD, `DATA_WIDTH'h0102_1034 + i);
    end

    for (int i = 0; i < 2; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_0400 + i, BYTE, `DATA_WIDTH'h0102_1034 + i);
    end

/*    for (int i = 0; i < 10; i++) 
    begin
      single_read(`ADDR_WIDTH'h0000_0013 + i, FULLWORD);
    end*/

    //burst_write(`ADDR_WIDTH'h0000_00B0, `STRB_SIZE'hF, `DATA_WIDTH'hC0D9_42F0, 8);

    //burst_read(`ADDR_WIDTH'h0000_00B0, `STRB_SIZE'hF, 8);

/*    for (int i = 0; i < 8; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_006F + i, `STRB_SIZE'hF, `DATA_WIDTH'h1C06_9D4F + i);
    end
    single_read(`ADDR_WIDTH'h0000_006F, `STRB_SIZE'h1);
    single_read(`ADDR_WIDTH'h0000_006F, `STRB_SIZE'h2);
    single_read(`ADDR_WIDTH'h0000_006F, `STRB_SIZE'h4);
    single_read(`ADDR_WIDTH'h0000_006F, `STRB_SIZE'h8);*/

    #20 $finish(1);
  end

  final
  begin
    $writememh("ram.hex",memory.ram);
    $display("Simulation Finished");
  end

  task async_reset();
    repeat(5) @(posedge clk);
    rst_n   <= '1;    
  endtask : async_reset

  task single_write(input bit [`ADDR_WIDTH-1:0] address_sr, input dsel_type dsel_sw, input bit [`DATA_WIDTH-1:0] data_sr);

    @(posedge clk);
    trnsfr  <= '1;
    wr      <= '1;
    dsel    <= dsel_sw;
    address <= address_sr;
    data_in <= data_sr;
    @(posedge clk);
    trnsfr  <= '0;
    wr      <= '0;

    wait(apb2apb.pbus.ready);
    wait(~apb2apb.pbus.ready);
    
  endtask : single_write

  task single_read(input bit [`ADDR_WIDTH-1:0] address_sr, input dsel_type dsel_sr);

    @(posedge clk);
    trnsfr  <= '1;
    wr      <= '0;
    dsel    <= dsel_sr;
    address <= address_sr;
    @(posedge clk);
    trnsfr  <= '0;
    wait(apb2apb.pbus.ready);
    wait(~apb2apb.pbus.ready);
    //@(posedge clk);
  
  endtask : single_read

  task burst_write(input bit [`ADDR_WIDTH-1:0] address_sr, input dsel_type dsel_bw, input bit [`DATA_WIDTH-1:0] data_sr, input int count);

    @(posedge clk);
    trnsfr  <= '1;
    wr      <= '1;
    dsel    <= dsel_bw;
    for (int i = 0; i < count; i++) begin
 
      address <= address_sr + i;
      data_in <= data_sr + i;
      repeat(3) @(posedge clk);
      //wait(apb2apb.pbus.ready);
      //wait(~apb2apb.pbus.ready);
      //@(posedge clk);
    end

    trnsfr  <= '0;

  endtask : burst_write

  task burst_read(input bit [`ADDR_WIDTH-1:0] address_sr, input dsel_type dsel_br, input int count);
    @(posedge clk);
    trnsfr  <= '1;
    wr      <= '0;
    dsel    <= dsel_br;
    for (int i = 0; i < count; i++) begin
 
      address <= address_sr + i;
      repeat(3) @(posedge clk);
      //wait(apb2apb.pbus.ready);
      //wait(~apb2apb.pbus.ready);
      //@(posedge clk);
    end

    trnsfr  <= '0;      
  endtask : burst_read  

endmodule