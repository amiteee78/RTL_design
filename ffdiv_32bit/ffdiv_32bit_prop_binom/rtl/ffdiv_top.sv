`timescale 1ns/1ns
`include "ffdiv_arch.svh"
module ffdiv_top (ffdif.top_bus tbus);

  ffdif ffdiv_bus (

    tbus.clk,
    tbus.rst_n,
    tbus.en,

    tbus.operand1,
    tbus.operand2,

    tbus.itr_count,
    tbus.result,
    tbus.flag,
    tbus.ready
  );

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **          Output Registers Definition          **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

  always_ff @(posedge ffdiv_bus.clk or negedge ffdiv_bus.rst_n) 
  begin
    if (~ffdiv_bus.rst_n) 
    begin
      ffdiv_bus.result      <= '0;
      ffdiv_bus.flag        <= '0;
    end 
    else if (ffdiv_bus.ready)
    begin
      ffdiv_bus.result      <= {ffdiv_bus.sign, ffdiv_bus.exp, ffdiv_bus.frac};
      ffdiv_bus.flag        <= {ffdiv_bus.nanf, ffdiv_bus.ovf, ffdiv_bus.inf, ffdiv_bus.uf, ffdiv_bus.zf};
    end
  end


  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **         Submodules Instantiation              **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

      
  ffdiv_decoder decoder (.dec_bus(ffdiv_bus));

  ffdiv_32bit divider (.div_bus(ffdiv_bus));

endmodule