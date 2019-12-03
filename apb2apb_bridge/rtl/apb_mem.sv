`timescale 1ns/1ns
`include "apb_arch.svh"

module apb_mem (memif.mem membus);

  genvar k,m;
  reg   [`MEM_WIDTH-1:0]  ram [`MEM_DEPTH-1:0] [0:`MEM_SIZE-1];
  logic [`MEM_WIDTH-1:0]  temp_wdata [`MEM_DEPTH-1:0];
  logic [`MEM_WIDTH-1:0]  temp_rdata [`MEM_DEPTH-1:0];

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
/*  generate
    for (k = 0; k < `MEM_DEPTH; k++)
    begin
      assign temp_wdata[k] = membus.mem_data_in[(`MEM_WIDTH*k)+`MEM_WIDTH-1:(`MEM_WIDTH*k)];
    end
  endgenerate

  always_ff @(posedge membus.clk) 
  begin
    if(membus.mem_wr) 
    begin
      for (int k = 0; k < `MEM_DEPTH; k++) 
      begin
        if (membus.mem_be[k])
        begin
          ram[k][membus.mem_address]  <= temp_wdata[k];
        end
      end
    end 
  end*/

  generate
    for (k = 0; k < `MEM_DEPTH; k++)
    begin
      always_ff @(posedge membus.clk)
      begin
        if (membus.mem_wr)
        begin 
          if (membus.mem_be[k])
          begin
            ram[k][membus.mem_address]  <= membus.mem_data_in[(`MEM_WIDTH*k)+`MEM_WIDTH-1:(`MEM_WIDTH*k)];
            
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
      //always_comb
      always_ff @(posedge membus.clk) 
      begin
        /*if (membus.mem_rd)
        begin
          if (membus.mem_be[m])
          begin
            temp_rdata[m]  <= ram[m][membus.mem_address];
            membus.mem_data_out[(`MEM_WIDTH*m)+`MEM_WIDTH-1:(`MEM_WIDTH*m)]  <= ram[m][membus.mem_address];
          end
          else
          begin
            temp_rdata[m]  <= '0;
            membus.mem_data_out[(`MEM_WIDTH*m)+`MEM_WIDTH-1:(`MEM_WIDTH*m)]  <= '0;
          end
        end
        else
        begin
          membus.mem_data_out[(`MEM_WIDTH*m)+`MEM_WIDTH-1:(`MEM_WIDTH*m)]  <= '0;
        end*/

        if (membus.mem_rd & membus.mem_be[m])
        begin
          temp_rdata[m]  <= ram[m][membus.mem_address];
          membus.mem_data_out[(`MEM_WIDTH*m)+`MEM_WIDTH-1:(`MEM_WIDTH*m)]  <= ram[m][membus.mem_address];
        end
        else
        begin
          temp_rdata[m]  <= '0;
          membus.mem_data_out[(`MEM_WIDTH*m)+`MEM_WIDTH-1:(`MEM_WIDTH*m)]  <= '0;
        end
      end
    end
  endgenerate

endmodule