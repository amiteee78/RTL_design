`timescale 1ns/1ns
`include "apb_arch.svh"

module apb_mem (memif.mem membus);

  genvar k,m;
  reg   [`MEM_WIDTH-1:0]  ram [`MEM_DEPTH-1:0] [0:`MEM_SIZE-1];

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **             Memory Initialization             **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  initial
  begin
    for (int i = 0; i < `MEM_DEPTH; i++) 
    begin
      for (int j = 0; j < `MEM_SIZE; j++) 
      begin
        ram[i][j] = '0; 
      end
    end
  end

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **               Memory Write Access             **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  generate
    for (k = 0; k < `MEM_DEPTH; k++)
    begin
      always_ff @(posedge membus.clk)
      begin
        if (membus.mem_wr)
        begin 
          if (membus.mem_be[k])
          begin
            ram[k][membus.mem_address] <= membus.mem_data_in[(`MEM_WIDTH*k)+`MEM_WIDTH-1:(`MEM_WIDTH*k)];
          end
        end
      end
    end 
  endgenerate

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **               Memory Read Access              **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

  generate
    for (m = 0; m < `MEM_DEPTH; m++) 
    begin
      always_comb
      begin
        if (membus.mem_rd)
        begin
          membus.mem_data_out[(`MEM_WIDTH*m)+`MEM_WIDTH-1:(`MEM_WIDTH*m)] = ram[m][membus.mem_address];
        end
        else
        begin
          membus.mem_data_out[(`MEM_WIDTH*m)+`MEM_WIDTH-1:(`MEM_WIDTH*m)] = '0;
        end
      end
    end
  endgenerate

endmodule