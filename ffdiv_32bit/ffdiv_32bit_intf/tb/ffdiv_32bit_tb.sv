/*
  Absolute value of the largest number that can be encoded in IEEE-754 format(32 bit) :: 3.4028235 x 10^38
  Binary representation (IEEE-754 format (32 bit)) :: X_11111110_11111111111111111111111 (MSB = 1:: -ve, MSB = 0:: +ve)

  Absolute value of the tiniest number that can be encoded in IEEE-754 format(32 bit) :: 1.4 x 10^-45
  Binary representation (IEEE-754 format (32 bit)) :: X_00000000_00000000000000000000001 (MSB = 1:: -ve, MSB = 0:: +ve)  

  For snan & qnan, order is an important issue.

  more iteration may give rise to exponent increse after rounding

*/

`timescale 1ns/1ns
`include "ffdiv_arch.svh"
module ffdiv_32bit_tb ();

  logic                                 clk;          // Clock
  logic                                 rst_n;        // Asynchronous reset active low
  logic                                 en;

  logic   [`OPERAND_WIDTH-1:0]          operand1;
  logic   [`OPERAND_WIDTH-1:0]          operand2;

  logic   [$clog2(`OPERAND_WIDTH)-1:0]  itr_count;

  logic   [`OPERAND_WIDTH-1:0]          result;
  logic   [`FLAG_SIZE-1:0]              flag;

  logic                                 ready;

  shortreal                             op1;
  shortreal                             op2;
  bit     [`OPERAND_WIDTH-1:0]          soft_division;
  bit     [`OPERAND_WIDTH-1:0]          error;

  int   count_sum;
  int   count_run;
  int   run_count = 5;

  ffdif test_bus(.*);
  ffdiv_top ffdiv32bit (.tbus(test_bus));

  initial
  begin
    forever
    begin
      #5 clk = ~clk;
    end
  end

  initial
  begin
    $dumpfile("ffdiv_32bit_tb.vcd");
    $dumpvars();
  end

  initial
  begin

    reset_n_deassert();

    for (int i =0; i < run_count; i++)
    begin
      ff_div((32'b100000000_00000000000000000000001 + i*(32'b000000001_00010000100000010000001)), (32'b100000000_00010100000000000000000 + i*(32'b000000001_00010000100000010000001)));
    end

      ff_div(32'b110000010_00100000000000000000000, 32'b110000000_10000000000000000000000);
      ff_div(32'b110000010_00100100001000000000001, 32'b110000000_11111111111111111111111);


      ff_div(32'b101011110_01111110100001111011110, 32'b100010110_01111111111111111111111);
      ff_div(32'b001011110_01101110100111001111100, 32'b100010110_11110111011101110110110);
      ff_div(32'b101011110_01101110100111001111100, 32'b000010110_11111111011101110110110);
      ff_div(32'b101011110_01000110100111111111111, 32'b100010110_11111111111101111111110);
      ff_div(32'b001010110_01000110100100001111111, 32'b100010110_11111111111111111011111);
      ff_div(32'b101111111_00101100001000000000001, 32'b011111110_11111111111111111111111);

      ff_div(32'b101110111_00101100001000000000001, 32'b011111111_11111111111111111111111);  //finite with nan

      ff_div(32'b111111111_01111111011111111111101, 32'b101101111_00001100101000000000001);  //nan with finite 

      ff_div(32'b111111000_01111111011111111111101, 32'b100001111_00001100101000000000001);  //pos overflow
      ff_div(32'b100001111_00001100101000000000001, 32'b111111000_01111111011111111111101);  //neg overflow

      ff_div(32'b011111111_01111111011111111111101, 32'b111111111_00000000000000000000000);  //nan with infinite

      ff_div(32'b011101110_01101111011111010111101, 32'b111111111_00000000000000000000000);  //finite with infinity

      ff_div(32'b111111111_00000000000000000000000, 32'b011101110_01101111011111010111101);  //infinity with finite

      ff_div(32'b100000000_00000000000000000000000, 32'b011101110_01101111011111010111101);  //zero with finite
      ff_div(32'b000000000_00000000000000000000000, 32'b011111111_00000000000000000000000);  //zero with infinite

      ff_div(32'b001111110_00001111011111010010100, 32'b000000000_00000000000000000000000);  //finite with zero
      ff_div(32'b000000000_00101110011111010010100, 32'b000000000_00000000000000000000000);  //finite with zero
      ff_div(32'b111111111_00000000000000000000000, 32'b000000000_00000000000000000000000);  //infinity with zero

      ff_div(32'b101110111_10101100000000000000001, 32'b001111111_00000000000000000000000);  //finite with one

      ff_div(32'b111111111_00000000000000000000000, 32'b011111111_00000000000000000000000);  //infinity with infinity

      ff_div(32'b0000000000_0000000000000000000000, 32'b100000000_00000000000000000000000);  // zero with zero

      ff_div(32'b011111110_11111111111111111111111, 32'b001111110_11111111111111111111111);

      ff_div(32'b011111110_11111111111111111111111, 32'b101111111_00000000000000000000000);

      ff_div(32'b000000000_00000000000000000000001, 32'b001111111_00000000000000000000001);

      ff_div(32'b000000000_00000000000000000000001, 32'b001111111_00000000000000000000000);

      ff_div(32'b000000000_00000000100111000010101, 32'b100000000_00110101011101010110010); // denorm with denorm

      ff_div(32'b000000000_11111111111111111111111, 32'b100000000_00000000000001000110011); // denorm with denorm

      ff_div(32'b000010001_11111111111111111111111, 32'b100000000_00000000000001000110011); // norm with denorm

      ff_div(32'b110000010_11111111111111111111111, 32'b100000000_00000000000111110110111); // norm with denorm

      ff_div(32'b111111111_01111111010111111101101, 32'b111111111_10111111011111111101100);  //snan with qnan

      ff_div(32'b111111111_00000011010111111101101, 32'b011111111_00011111011111111101100);  //snan with snan

      ff_div(32'b111111111_10000000010110001001101, 32'b111111111_00011111011111111100000);  //qnan with snan

      ff_div(32'b111111111_00011111011111111100000, 32'b111111111_10000000010110001001101);  //snan with qnan

      ff_div(32'b011111111_10011111011111111100000, 32'b011111111_11000000010110001001101);  //qnan with qnan

      ff_div(32'b100000000_00000000100111010010101, 32'b100000000_00000111111111010110011); // denorm with denorm

      ff_div(32'b000000000_11100110100111010010101, 32'b100000000_00000111111111111100101); // denorm with denorm

      ff_div(32'b100010000_00000000100111010010101, 32'b100000000_00000111111111111111011); // norm with denorm

      ff_div(32'b100110001_01110100100111010010111, 32'b100000000_00000111111111111111110); // norm with denorm

      ff_div(32'b100110111_01110100100111010010111, 32'b100000000_00000111111111111111111); // norm with denorm

      ff_div(32'b000110111_01110100100111010010111, 32'b101000001_11111111111111111111111); // norm with norm

      ff_div(32'b100110010_11110100110101010011111, 32'b101101001_11111111110111111111111); // norm with norm

      ff_div(32'b000110111_00110110100001011010101, 32'b101101001_11111111111111111111111); // norm with norm

      ff_div(32'b101110110_00111110111001011010101, 32'b101101001_11111111111111111111111); // norm with norm

      ff_div(32'b010010001_01101001001101001000000, 32'b010010011_01101001001101001000001); // norm with norm

      ff_div(32'b101110100_10111110000001010011101, 32'b100101001_11111111111111111101111); // norm with norm

      ff_div(32'b010000100_10011110000001010011101, 32'b111101001_11111111111111111110111); // norm with norm

      ff_div(32'b010000101_00011110000001010011101, 32'b110000000_11111111111111111111011); // norm with norm

      ff_div(32'b011000101_00011110001001111011101, 32'b010000001_11111111111111111111101); // norm with norm

      ff_div(32'b011010111_01011110001101111011101, 32'b110100111_11111111111111111111110); // norm with norm

    reset_n_assert();
    #20 $finish(1);

  end

  initial
  begin
    //$monitor("\nOPERAND_1st::  %1b_%8b_%23b (%e)\t@time %0t ns", ffdiv_operand1[`OPERAND_WIDTH-1], ffdiv_operand1[`OPERAND_WIDTH-2:`FRACTION_WIDTH], ffdiv_operand1[`FRACTION_WIDTH-1:0], $bitstoshortreal(ffdiv_operand1), $realtime());
    //$monitor("OPERAND_2nd::  %1b_%8b_%23b (%e)\t@time %0t ns", ffdiv_operand2[`OPERAND_WIDTH-1], ffdiv_operand2[`OPERAND_WIDTH-2:`FRACTION_WIDTH], ffdiv_operand2[`FRACTION_WIDTH-1:0], $bitstoshortreal(ffdiv_operand2), $realtime());
    //$monitor("\nresult:: %1b_%8b_%23b (\033[1;31m%g\033[0m)\t@time %0t ns", result[`OPERAND_WIDTH-1], result[`OPERAND_WIDTH-2:`FRACTION_WIDTH], result[`FRACTION_WIDTH-1:0], $bitstoshortreal(result), $realtime());
    //$monitor("result:: \033[1;34m%e\033[0m (from calculator)", $bitstoshortreal(ffdiv_operand1)/$bitstoshortreal(ffdiv_operand2));
    //$monitor("NaNF:: %b, OVF:: %b, INF:: %b, UF:: %b, ZF:: %b\n", flag[4], flag[3], flag[2], flag[1], flag[0]); 
  end

  final
  begin
    $display("\n***********Simulation Finished***********\n");
    $display("Count_sum:: %d", count_sum);
    $display("Count_run:: %d", count_run);
    $display("Average Latency:: \033[1;32m%.5f cycles\033[0m\n", real'(count_sum)/real'(count_run));
  end

  task reset_n_deassert();
    clk                 <= '0;
    rst_n               <= '0;
    en                  <= '0;
    operand1            <= '0;
    operand2            <= '0;    
    repeat(4) @(negedge clk);
    en                  <= '1;
    rst_n               <= '1;  
  endtask : reset_n_deassert

  task reset_n_assert();
    @(negedge clk);
    en                  <= '0;
    rst_n               <= '0;  
  endtask : reset_n_assert

  task ff_div(input logic [`OPERAND_WIDTH-1:0] opr1, input logic [`OPERAND_WIDTH-1:0] opr2);

    @(posedge clk)
    operand1            <= opr1;
    operand2            <= opr2;

    soft_division       <= $shortrealtobits($bitstoshortreal(opr1)/$bitstoshortreal(opr2));
    op1                 <= $bitstoshortreal(opr1);
    op2                 <= $bitstoshortreal(opr2);

    $display("\n------------------------------------------------------------------------------------------------");
    $display("\t\t\t\tFFDIV enabled\t@time %0t ns", $realtime());
    
    wait(ready);
    wait(~ready);

    count_sum           <= count_sum + itr_count+5;
    count_run           <= count_run + 1;

    $display("\nOPERAND_1st::  %1b_%8b_%23b (%g)", operand1[`OPERAND_WIDTH-1], operand1[`OPERAND_WIDTH-2:`FRACTION_WIDTH], operand1[`FRACTION_WIDTH-1:0], op1);
    $display("OPERAND_2nd::  %1b_%8b_%23b (%g)", operand2[`OPERAND_WIDTH-1], operand2[`OPERAND_WIDTH-2:`FRACTION_WIDTH], operand2[`FRACTION_WIDTH-1:0], op2);

    $display("\nresult:: %1b_%8b_%23b (\033[1;31m%g\033[0m)\t@time %0t ns", result[`OPERAND_WIDTH-1], result[`OPERAND_WIDTH-2:`FRACTION_WIDTH], result[`FRACTION_WIDTH-1:0], $bitstoshortreal(result), $realtime());
    $display("result:: %1b_%8b_%23b (\033[1;34m%g\033[0m)\t(from calculator)", soft_division[`OPERAND_WIDTH-1], soft_division[`OPERAND_WIDTH-2:`FRACTION_WIDTH], soft_division[`FRACTION_WIDTH-1:0], op1/op2);
    $display("NaNF:: %b, OVF:: %b, INF:: %b, UF:: %b, ZF:: %b\n", flag[4], flag[3], flag[2], flag[1], flag[0]);
    $display("NUMBER OF ITERATION NEEDED:: %0d\t(latency:: \033[1;32m%0d cycles\033[0m)", itr_count, itr_count+5); // (5 is hard coded from simulation)


    if (flag[4] | flag[3])
    begin
      $display("PERCENT ERROR:: \033[1;32mNOT APPLICABLE\033[m");
    end
    else if (flag == 1)
    begin
      $display("PERCENT ERROR:: \033[1;32m%.10f%%\033[0m", real'(int'(soft_division[`FRACTION_WIDTH-1:0] - result[`FRACTION_WIDTH-1:0]))*100);
    end
    else
    begin
      $display("PERCENT ERROR:: \033[1;32m%.10f%%\033[0m", real'(int'(soft_division[`FRACTION_WIDTH-1:0] - result[`FRACTION_WIDTH-1:0]))*100/real'(int'({|soft_division[`OPERAND_WIDTH-2:`FRACTION_WIDTH], soft_division[`FRACTION_WIDTH-1:0]})));      
    end
    $display("\n------------------------------------------------------------------------------------------------");
         
  
  endtask : ff_div

endmodule