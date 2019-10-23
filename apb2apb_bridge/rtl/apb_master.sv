/*
APB Master Module is designed using Finite State Machine having 3 always block...
  1. A sequential block to define the state register.
  2. A combinational block to define the next state logic.
  3. A combinational block to define the output logic.

Binary encoding is used to define the transitions among three different states.

----------------------------------*********************************************************-------------------------------------
----------------------------------*  ***************************************************  *-------------------------------------
----------------------------------*  **                                               **  *-------------------------------------
----------------------------------*  **                Operating States               **  *-------------------------------------
----------------------------------*  **                                               **  *-------------------------------------
----------------------------------*  ***************************************************  *-------------------------------------
----------------------------------*********************************************************-------------------------------------


                 sel=0,en=0                    sel=1,en=0                                     sel=1,en=1                 
  transfer = 0  ************  transfer = 1   *************                                   ************     ready = 0             
**----------->> **        ** ------------->> **         ** --------------------------------> **        ** <<-----------**           
**              **  IDLE  **                 **  SETUP  **                                   ** ACCESS **              ** 
**------------- **        ** <<----**        **         ** <<---------------------------**-- **        ** -------------**                
                ************       **        *************    transfer = 1, ready = 1    **  ************                  
                                   **                                                    **                                            
                                   **                                                    **
                                   **                                                    **   
                                   **                                                    **
                                   **                                                    **
                                   **----------------------------------------------------**
                                                      transfer = 0, ready = 1
*/

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
        if (mbus.trnsfr)
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
        if (mbus.ready & mbus.trnsfr)
        begin
          m_nxt_state     <= SETUP;
        end

        else if (mbus.ready & ~mbus.trnsfr)
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

  always_comb 
  begin
    
    unique case (m_state)
      IDLE:
      begin
        mbus.sel      <= '0;
        mbus.enable   <= '0;
        mbus.write    <= '0;
        mbus.strobe   <= '0;
        mbus.addr     <= '0;
        mbus.wdata    <= '0;
      end

      SETUP:
      begin
        mbus.sel      <= '1;
        mbus.enable   <= '0;
        mbus.addr     <= mbus.address;
        mbus.strobe   <= mbus.strb;
        
        if (mbus.wr)
        begin
          mbus.write     <= '1;            //write transfer enable
          mbus.wdata     <= mbus.data_in;  // write data
        end

        else
        begin
          mbus.write     <= '0;            //read transfer enable
          mbus.wdata     <= '0;          
        end
      end

      ACCESS:
      begin
        mbus.sel      <= '1;
        mbus.enable   <= '1;

        if (mbus.ready)
        begin
          mbus.data_out  <= mbus.rdata;
        end

        else
        begin
          mbus.data_out  <= '0;
        end
      end
    endcase

  end

endmodule