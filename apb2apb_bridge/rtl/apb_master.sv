`timescale 1ns/1ns
`include "apb_arch.svh"

module apb_master (apbif.master mbus);

  enum logic [1:0] {IDLE, SETUP, ACCESS} m_state, m_nxt_state;

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **           State Register Definition           **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  always_ff @(posedge mbus.clk or negedge mbus.rst_n) 
  begin
    if(~mbus.rst_n) 
    begin
      m_state   <= IDLE;
    end 
    else 
    begin
      m_state   <= m_nxt_state;
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

    unique case (m_state)
    
      IDLE :
      begin
        if (mbus.start & ~mbus.ready)
        begin
          m_nxt_state     <= SETUP;
        end

        else
        begin
          m_nxt_state     <= IDLE;
        end
      end

      SETUP :
      begin
        m_nxt_state       <= ACCESS;
      end

      ACCESS :
      begin
        if (mbus.ready)
        begin
          m_nxt_state     <= IDLE;
        end

        else
        begin
          m_nxt_state     <= ACCESS;
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

endmodule