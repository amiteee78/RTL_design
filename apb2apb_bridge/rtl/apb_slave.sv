`timescale 1ns/1ns
`include "apb_arch.svh"

module apb_slave (apbif.slave sbus);
  enum logic [1:0] {IDLE, SETUP, ACCESS} s_state, s_nxt_state;

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **           State Register Definition           **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  always_ff @(posedge sbus.clk or negedge sbus.rst_n) 
  begin
    if(~sbus.rst_n) 
    begin
      s_state   <= IDLE;
    end 
    else 
    begin
      s_state   <= s_nxt_state;
    end
  end

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **          Next State Logic Definition          **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  always_comb 
  begin

    unique case (s_state)
      IDLE :
      begin
        if (sbus.sel)
        begin
          s_nxt_state     <= SETUP;
        end

        else
        begin
          s_nxt_state     <= IDLE;
        end
      end

      SETUP :
      begin
        if (sbus.sel & sbus.enable)
        begin
          s_nxt_state     <= ACCESS;
        end

        else
        begin
          s_nxt_state     <= SETUP;
        end
      end

      ACCESS :
      begin
        if (sbus.sel & sbus.enable)
        begin
          s_nxt_state     <= SETUP;
        end

        else
        begin
          s_nxt_state     <= IDLE;
        end
      end
    endcase

  end

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **            Output Logic Definition            **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

  always_comb 
  begin
  
    unique case (s_state)
      IDLE:
      begin
        sbus.ready    <= '0;
        sbus.slverr   <= '0;
        sbus.rdata    <= '0;
      end

      SETUP:
      begin
        sbus.ready    <= '0;
        sbus.slverr   <= '0;
        sbus.rdata    <= '0;
      end

      ACCESS:
      begin
        if (sbus.sel & sbus.enable)
        begin
          sbus.ready    <= '1;

          if (sbus.addr < sbus.strobe*()) // needs to be edited
        end

        else
        begin
          s_nxt_state     <= IDLE;
        end
      end
    endcase

  end
endmodule