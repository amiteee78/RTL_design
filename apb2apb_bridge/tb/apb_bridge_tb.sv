`timescale 1ns/1ns
`include "apb_arch.svh"

typedef enum bit [1:0] {FULLWORD, HALFWORD, BYTE} dsel_type; 

module apb_bridge_tb ();

  bit                         clk;   
  bit                         rst_n; 
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

  logic [`DATA_WIDTH-1:0]     read_data_out;

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

/*  initial
  begin
    $monitor("Write Enable:: %b \t Write Adress:: %h \tWrite Data:: %h \t@time %0t ns", test_bus.mem_wr, test_bus.mem_address, test_bus.mem_data_in,  $realtime());    
    $monitor("Read  Enable:: %b \t Read  Adress:: %h \tRead  Data:: %h \t@time %0t ns", test_bus.mem_rd, test_bus.mem_address, test_bus.mem_data_out, $realtime());
  end*/

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

    repeat(5) @(posedge clk);

    for (int i = 0; i < 10; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_0012 + i, HALFWORD, `DATA_WIDTH'h510F_CB29 + i);
    end

    for (int i = 0; i < 10; i++) 
    begin
      single_read(`ADDR_WIDTH'h0000_0012 + i, HALFWORD);
    end

    repeat(5) @(posedge clk);

    for (int i = 0; i < 10; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_003D + i, BYTE, `DATA_WIDTH'h0102_1034 + i);
    end

    for (int i = 0; i < 10; i++) 
    begin
      single_read(`ADDR_WIDTH'h0000_003D + i, BYTE);
    end

    repeat(5) @(posedge clk);

    // Slave Error Test
    for (int i = 0; i < 2; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_0100 + i, FULLWORD, `DATA_WIDTH'h0102_1034 + i);
      single_read(`ADDR_WIDTH'h0000_0100 + i, FULLWORD);
    end

    for (int i = 0; i < 2; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_0200 + i, HALFWORD, `DATA_WIDTH'h0102_1034 + i);
      single_read(`ADDR_WIDTH'h0000_0200 + i, HALFWORD);
    end

    for (int i = 0; i < 2; i++) 
    begin
      single_write(`ADDR_WIDTH'h0000_0400 + i, BYTE, `DATA_WIDTH'h0102_1034 + i);
      single_read(`ADDR_WIDTH'h0000_0400 + i, BYTE);
    end

    repeat(5) @(posedge clk);

    burst_write(`ADDR_WIDTH'h0000_00B0, FULLWORD, `DATA_WIDTH'hC0D9_42F0, 8);
    burst_read(`ADDR_WIDTH'h0000_00B0, FULLWORD, 8);

    repeat(5) @(posedge clk);

    burst_write(`ADDR_WIDTH'h0000_0050, HALFWORD, `DATA_WIDTH'h3187_EFC6, 8);
    burst_read(`ADDR_WIDTH'h0000_0050, HALFWORD, 8);

    repeat(5) @(posedge clk);

    burst_write(`ADDR_WIDTH'h0000_02F0, BYTE, `DATA_WIDTH'h5B0D_0FEF, 8);
    burst_read(`ADDR_WIDTH'h0000_02F0, BYTE, 8);

    repeat(5) @(posedge clk);

    burst_write(`ADDR_WIDTH'h0000_0090, FULLWORD, `DATA_WIDTH'hFBED_4C97, 8);
    burst_read(`ADDR_WIDTH'h0000_0240, BYTE, 32);      

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
    $display("\n----------------------------------------------------------------------------------------------------------");
    $display("-----------------------------------------------------------------------------------------------------------");

    @(posedge clk);
    trnsfr  <= '1;
    wr      <= '1;
    dsel    <= dsel_sw;
    address <= address_sr;
    data_in <= data_sr;
    @(posedge clk);
    trnsfr  <= '0;
    wr      <= '0;
    repeat(3) @(posedge clk);
    $display("\nWrite Address:: %h \t Write Data:: %h \t @time %0t ns \t (%s write)", address, data_in, $realtime()-10, dsel.name());        

    $display("\n----------------------------------------------------------------------------------------------------------");
    $display("-----------------------------------------------------------------------------------------------------------");
  endtask : single_write

  task single_read(input bit [`ADDR_WIDTH-1:0] address_sr, input dsel_type dsel_sr);
    $display("\n----------------------------------------------------------------------------------------------------------");
    $display("-----------------------------------------------------------------------------------------------------------");

    @(posedge clk);
    trnsfr  <= '1;
    wr      <= '0;
    dsel    <= dsel_sr;
    address <= address_sr;
    @(posedge clk);
    trnsfr  <= '0;
    repeat(3) @(posedge clk);
    $display("\nRead Address :: %h \t Read Data :: %h \t @time %0t ns \t (%s read)", address, data_out, $realtime()-10, dsel.name());

    $display("\n----------------------------------------------------------------------------------------------------------");
    $display("----------------------------------------------------------------------------------------------------------\n");  
  endtask : single_read

  task burst_write(input bit [`ADDR_WIDTH-1:0] address_sr, input dsel_type dsel_bw, input bit [`DATA_WIDTH-1:0] data_sr, input int count);
    $display("\n----------------------------------------------------------------------------------------------------------");
    $display("-----------------------------------------------------------------------------------------------------------");

    fork
      begin
        @(posedge clk);
        trnsfr  <= '1;
        wr      <= '1;
        dsel    <= dsel_bw;
        for (int i = 0; i < count; i++) 
        begin
          address <= address_sr + i;
          data_in <= data_sr + i;
          repeat(3) @(posedge clk);
        end
        trnsfr  <= '0;        
      end
      begin
        @(posedge clk);
        for (int j = 0; j < count; j++)
        begin
          repeat(3) @(posedge clk);
          $display("\nWrite Address:: %h \t Write Data:: %h \t @time %0t ns \t (%s write)", apb2apb.pmaster.mbus.addr, apb2apb.pmaster.mbus.wdata, $realtime(), dsel.name());
        end
      end
    join

    $display("\n----------------------------------------------------------------------------------------------------------");
    $display("-----------------------------------------------------------------------------------------------------------");   
  endtask : burst_write

  task burst_read(input bit [`ADDR_WIDTH-1:0] address_sr, input dsel_type dsel_br, input int count);
    $display("\n----------------------------------------------------------------------------------------------------------");
    $display("-----------------------------------------------------------------------------------------------------------");

    fork
      begin
        @(posedge clk);
        trnsfr  <= '1;
        wr      <= '0;
        dsel    <= dsel_br;
        for (int i = 0; i < count; i++) 
        begin
          address <= address_sr + i;
          repeat(3) @(posedge clk);
        end
        trnsfr  <= '0;        
      end
      begin
        repeat(2) @(posedge clk);
        for (int j = 0; j < count; j++)
        begin
          repeat(3) @(posedge clk);
          read_data_out <= data_out;
        end
      end
      begin
        repeat(1) @(posedge clk);
        for (int j = 0; j < count; j++)
        begin
          repeat(3) @(posedge clk);
          $display("\nRead Address :: %h \t Read Data :: %h \t @time %0t ns \t (%s read)", apb2apb.pmaster.mbus.addr, read_data_out, $realtime(), dsel.name());
        end
      end
    join

    $display("\n----------------------------------------------------------------------------------------------------------");
    $display("----------------------------------------------------------------------------------------------------------\n");       
  endtask : burst_read

endmodule