`timescale 1ns/1ns
`include "apb_arch.svh"

module apb_slave (apbif.slave sbus);
  enum logic [1:0] {IDLE, SETUP, ACCESS} s_state, s_nxt_state;

  //logic [`ADDR_WIDTH-1:0] addr_compare; // comparison register for maximum address

  logic                   enable_reg;   // used to prevent glitching issue in the next state logic

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **         Internal Register Definition          **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
/*  always_ff @(posedge sbus.clk or negedge sbus.rst_n) 
  begin
    if(~sbus.rst_n) 
    begin
      addr_compare   <= '0;
    end 
    else if ((s_nxt_state == SETUP) & (|sbus.strobe))
    begin
      priority case (1)
        sbus.strobe[3] : addr_compare <= (sbus.addr+1)<<2;
        sbus.strobe[2] : addr_compare <= ((sbus.addr+1)<<1) + sbus.addr;
        sbus.strobe[1] : addr_compare <= (sbus.addr+1)<<1;
        sbus.strobe[0] : addr_compare <= sbus.addr;
      endcase
    end
  end*/

  always_ff @(posedge sbus.clk or negedge sbus.rst_n) 
  begin
    if(~sbus.rst_n) 
    begin
      enable_reg  <= '0;
    end 
    else if (sbus.enable) 
    begin
      enable_reg  <= '1;
    end
    else
    begin
      enable_reg  <= '0;
    end
  end
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
        if (sbus.sel & ~sbus.enable) // modified to prevent glitching issue in the next state logic
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
        if (sbus.sel & sbus.enable & ~enable_reg) // modified to prevent glitching issue in the next state logic
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
        if (sbus.trnsfr)
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
        sbus.ready        <= '0;
        sbus.slverr       <= '0;
        sbus.rdata        <= '0;

        sbus.mem_wr       <= '0;
        sbus.mem_rd       <= '0;
        sbus.mem_be       <= '0;
        sbus.mem_address  <= '0;
        sbus.mem_data_in  <= '0;
      end

      SETUP:
      begin
        sbus.ready        <= '0;
        sbus.slverr       <= '0;
        sbus.rdata        <= '0;
        sbus.mem_be       <= sbus.strobe;

        if (sbus.addr >= `MEM_SIZE)
        begin
          sbus.mem_wr       <= '0;
          sbus.mem_rd       <= '0;
          sbus.mem_address  <= '0;
          sbus.mem_data_in  <= '0;          
        end
        else if (sbus.write)
        begin
          sbus.mem_wr       <= '1;
          sbus.mem_rd       <= '0;
          sbus.mem_address  <= sbus.addr;
          sbus.mem_data_in  <= sbus.wdata;
        end

        else
        begin
          sbus.mem_wr       <= '0;
          sbus.mem_rd       <= '1;
          sbus.mem_address  <= sbus.addr;
          sbus.mem_data_in  <= '0;
        end
      end

      ACCESS:
      begin
        if (sbus.sel & sbus.enable)
        begin
          sbus.ready          <= '1;
          sbus.mem_be         <= sbus.strobe;

          //if (addr_compare > `MEM_BYTE)
          if (sbus.addr >= `MEM_SIZE)
          begin
            sbus.slverr       <= '1;
            sbus.rdata        <= '0;

            sbus.mem_wr       <= '0;
            sbus.mem_rd       <= '0;
            sbus.mem_address  <= '0;
            sbus.mem_data_in  <= '0;
          end

          else if (sbus.write)
          begin
            sbus.slverr       <= '0;
            sbus.rdata        <= '0;

            sbus.mem_wr       <= '1;
            sbus.mem_rd       <= '0;
            sbus.mem_address  <= sbus.addr;
            sbus.mem_data_in  <= sbus.wdata;
          end

          else
          begin
            sbus.slverr       <= '0;
            sbus.rdata        <= sbus.mem_data_out;

            sbus.mem_wr       <= '0;
            sbus.mem_rd       <= '1;
            sbus.mem_address  <= sbus.addr;
            sbus.mem_data_in  <= '0;
          end
        end

        else
        begin
          sbus.ready        <= '0;
          sbus.slverr       <= '0;
          sbus.rdata        <= '0;

          sbus.mem_wr       <= '0;
          sbus.mem_address  <= '0;
          sbus.mem_data_in  <= '0;
        end
      end
    endcase

  end
endmodule