`timescale 1ns/1ns
`include "ffdiv_arch.svh"

module ffdiv_32bit (ffdif.division_bus div_bus);

  enum logic [2:0] {IDLE, SETUP, ITERATE, ROUND, ENCODE} ffdiv_state, ffdiv_nxt_state;

  logic   [`PRECISION_WIDTH-1:0]        div_i;
  logic   [`PRECISION_WIDTH-4:0]        div_i_low;

  logic   [`PRECISION_WIDTH-1:0]        qnt_i;
  logic   [`PRECISION_WIDTH-4:0]        qnt_i_low;

  logic   [`PRECISION_WIDTH-1:0]        prev_qnt;
  logic   [`PRECISION_WIDTH-1:0]        qnt_diff;

  logic   [`SIGNIFICAND_WIDTH:0]        qnt_rounded;

  logic                                 is_operands_finite;  

  logic                                 ffdiv_res_sign;
  logic   [`UNB_EXP_WIDTH-1:0]          ffdiv_unb_exp;
  logic   [$clog2(`OPERAND_WIDTH)-1:0]  ffdiv_dnrm_frc_shift;
  logic                                 ffdiv_sgfcnd_cmp;

  logic                                 is_ffdiv_res_nan;
  logic                                 is_ffdiv_negexp_ovf;
  logic                                 is_ffdiv_posexp_ovf;
  logic                                 is_ffdiv_res_denorm;

  assign ffdiv_sgfcnd_cmp       = div_bus.en & (div_bus.sgfnd1 < div_bus.sgfnd2); // significand comparison for dividend adjustment
  assign is_operands_finite     = div_bus.en & (div_bus.is_norm1 | div_bus.is_denorm1) & (div_bus.is_norm2 | div_bus.is_denorm2);
  assign is_ffdiv_res_nan       = div_bus.en & (|div_bus.res_nan);

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **           State Register Definition           **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

  always_ff @(posedge div_bus.clk or negedge div_bus.rst_n) 
  begin
    if(~div_bus.rst_n) 
    begin
      ffdiv_state     <= IDLE;
    end 
    else 
    begin
      ffdiv_state     <= ffdiv_nxt_state;
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

    unique case (ffdiv_state)

      IDLE :
      begin
        if (div_bus.en & div_bus.dec_valid)
        begin
          ffdiv_nxt_state   = SETUP;
        end

        else
        begin
          ffdiv_nxt_state   = IDLE;
        end
      end

      SETUP :
      begin
        if (div_bus.en & is_operands_finite)
        begin
          ffdiv_nxt_state   = ITERATE;
        end

        else if (div_bus.en & ~is_operands_finite)
        begin
          ffdiv_nxt_state   = ROUND;
        end

        else
        begin
          ffdiv_nxt_state   = SETUP;
        end        
      end

      ITERATE :
      begin
        if (div_bus.en & (|qnt_diff[`PRECISION_WIDTH-1:`PRECISION_WIDTH-`SIGNIFICAND_WIDTH-2])) //previously it was 1
        begin
          ffdiv_nxt_state   = ITERATE;
        end

        else if (div_bus.en & ~(|qnt_diff[`PRECISION_WIDTH-1:`PRECISION_WIDTH-`SIGNIFICAND_WIDTH-2])) //previously it was 1
        begin
          ffdiv_nxt_state   = ROUND;
        end

        else
        begin
          ffdiv_nxt_state   = SETUP;
        end
      end

      ROUND :
      begin
        if (div_bus.en)
        begin
          ffdiv_nxt_state   = ENCODE;
        end

        else
        begin
          ffdiv_nxt_state   = ROUND;
        end    
      end

      ENCODE :
      begin
        if (div_bus.en)
        begin
          ffdiv_nxt_state   = IDLE;
        end

        else
        begin
          ffdiv_nxt_state   = ENCODE;
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
    
    unique case (ffdiv_state)
    
      IDLE :
      begin
        ffdiv_dnrm_frc_shift   = '0;
        ffdiv_res_sign         = '0;
        is_ffdiv_negexp_ovf    = '0;
        is_ffdiv_posexp_ovf    = '0;
        is_ffdiv_res_denorm    = '0;
        div_bus.ready          = '0;

      end

      SETUP :
      begin
        ffdiv_dnrm_frc_shift   = '0;
        ffdiv_res_sign         = '0;
        is_ffdiv_negexp_ovf    = '0;
        is_ffdiv_posexp_ovf    = '0;
        is_ffdiv_res_denorm    = '0;
        div_bus.ready          = '0;
      end

      ITERATE :
      begin
        ffdiv_dnrm_frc_shift   = '0;
        ffdiv_res_sign         = '0;
        is_ffdiv_negexp_ovf    = '0;
        is_ffdiv_posexp_ovf    = '0;
        is_ffdiv_res_denorm    = '0;
        div_bus.ready          = '0;       
      end

      ROUND :
      begin
        ffdiv_dnrm_frc_shift   = '0;
        ffdiv_res_sign         = '0;
        is_ffdiv_negexp_ovf    = '0;
        is_ffdiv_posexp_ovf    = '0;
        is_ffdiv_res_denorm    = '0;
        div_bus.ready          = '0;
      end

      ENCODE :
      begin

        ffdiv_dnrm_frc_shift   = -ffdiv_unb_exp + `NORM_EXP_MIN; // fraction shifting for denormalized number 
        ffdiv_res_sign         = div_bus.sign1 ^ div_bus.sign2;
        is_ffdiv_negexp_ovf    = is_operands_finite & (ffdiv_unb_exp < `DENORM_EXP_MIN) & (ffdiv_unb_exp[`UNB_EXP_WIDTH-1]); // for finite operation negative exponent overflow occurs if (unbiased exponent < - 149)
        is_ffdiv_posexp_ovf    = is_operands_finite & (ffdiv_unb_exp > `UNB_EXP_WIDTH'(`BIASING_CONSTANT)) & (~ffdiv_unb_exp[`UNB_EXP_WIDTH-1]); // for finite operation positive exponent overflow occurs if (unbiased exponent > 127)
        is_ffdiv_res_denorm    = is_operands_finite & (ffdiv_unb_exp >= `DENORM_EXP_MIN) & (ffdiv_unb_exp <= `DENORM_EXP_MAX) & (ffdiv_unb_exp[`UNB_EXP_WIDTH-1]); // for finite operation denormalized number appears if (-149 < unbiased exponent < -127)          
        div_bus.ready          = '1;
      end
    endcase
  end

  /******************************************************************************/
  /*  ************************************************************************  */
  /*  **                                                                    **  */
  /*  **          Output Registers & Internal Registers Definition          **  */
  /*  **                                                                    **  */
  /*  ************************************************************************  */
  /******************************************************************************/

  always_ff @(negedge div_bus.clk or negedge div_bus.rst_n) 
  begin
    if(~div_bus.rst_n) 
    begin
      {div_i, div_i_low}    <= '0;
      {qnt_i, qnt_i_low}    <= '0;

      prev_qnt              <= '0;
      qnt_diff              <= '0;
      qnt_rounded           <= '0;
      ffdiv_unb_exp         <= '0;

      div_bus.itr_count     <= '0;

      div_bus.sign          <= '0;
      div_bus.exp           <= '0;  
      div_bus.frac          <= '0;

      div_bus.nanf          <= '0; 
      div_bus.ovf           <= '0; 
      div_bus.inf           <= '0; 
      div_bus.uf            <= '0;   
      div_bus.zf            <= '0;      
        
    end

    else if (ffdiv_state == SETUP)
    begin
      qnt_i                 <= {2'b00,div_bus.sgfnd1,{{`PRECISION_WIDTH-`SIGNIFICAND_WIDTH-2}{1'b0}}} << ffdiv_sgfcnd_cmp;  // Divident placed with proper alignment (divident = a)
      div_i                 <= {2'b00,div_bus.sgfnd2,{{`PRECISION_WIDTH-`SIGNIFICAND_WIDTH-2}{1'b0}}};                      // Divisor placed with proper alignment  (divisor  = 1+X)
      prev_qnt              <= '1;
      qnt_diff              <= '1;      
      ffdiv_unb_exp         <= (div_bus.unb_exp1 - div_bus.unb_exp2) - ffdiv_sgfcnd_cmp;                                    // unbiased exponent adjusted for aligned divisor less than aligned divident 
    end

    else if (ffdiv_state == ITERATE)
    begin
      div_bus.itr_count     <= div_bus.itr_count + 1; // calculation of number of iterations
      prev_qnt              <= qnt_i;
      qnt_diff              <= prev_qnt ^ qnt_i;
      {div_i, div_i_low}    <= div_i * ({2'b01, {{`PRECISION_WIDTH-2}{1'b0}}} - div_i); // next_iteration = current_iteration * (2 - current_iteration)
      {qnt_i, qnt_i_low}    <= qnt_i * ({2'b01, {{`PRECISION_WIDTH-2}{1'b0}}} - div_i); // next_quotient  = current_quotient  * (2 - current_iteration)
    end

    else if (ffdiv_state == ROUND)
    begin
      ffdiv_unb_exp         <= ffdiv_unb_exp + qnt_rounded[`SIGNIFICAND_WIDTH]; // unbiased exponent adjusted after rounding
      qnt_rounded           <= qnt_i[`PRECISION_WIDTH-3:`GBIT] + (qnt_i[`GBIT] & (|qnt_i[`RBIT:`SBIT])); // rounded quotient (rounded to the nearest max)
    end

    else if (ffdiv_state == ENCODE)
    begin

      if (is_ffdiv_res_nan) // nan from input
      begin
        {div_bus.sign, div_bus.exp, div_bus.frac} <= div_bus.res_nan;
      end
      else if (div_bus.res_indet) // indet from input
      begin
        div_bus.sign        <= ffdiv_res_sign;
        div_bus.exp         <= '1;
        div_bus.frac        <= `FRACTION_WIDTH'h400000; // (real indefinite form)
      end
      else if (is_ffdiv_posexp_ovf | div_bus.res_inf) // inf from input or output
      begin
        div_bus.sign        <= ffdiv_res_sign;
        div_bus.exp         <= '1;
        div_bus.frac        <= '0; //qnt_rounded[`FRACTION_WIDTH-1:0] (making hard inf for positive exponent overflow)        
      end
      else if (is_ffdiv_negexp_ovf | div_bus.res_zero) // zero from input/output
      begin
        div_bus.sign        <= ffdiv_res_sign;
        div_bus.exp         <= '0;
        div_bus.frac        <= '0;  
      end
      else if (is_ffdiv_res_denorm) // denormalized number
      begin
        div_bus.sign        <= ffdiv_res_sign;
        div_bus.exp         <= '0;
        div_bus.frac        <= qnt_rounded >> ffdiv_dnrm_frc_shift; // scaled fraction for denormalized numbers      
      end
      else // normalized number
      begin
        div_bus.sign        <= ffdiv_res_sign;
        div_bus.exp         <= ffdiv_unb_exp + `UNB_EXP_WIDTH'(`BIASING_CONSTANT);
        div_bus.frac        <= qnt_rounded[`FRACTION_WIDTH-1:0];        
      end

      /*******************************NaNF--OVF--INF--UF--ZF**************************************/
      div_bus.nanf          <= is_ffdiv_res_nan | div_bus.res_indet;
      div_bus.ovf           <= is_ffdiv_posexp_ovf | is_ffdiv_negexp_ovf;
      div_bus.inf           <= is_ffdiv_posexp_ovf | div_bus.res_inf;
      div_bus.uf            <= is_ffdiv_res_denorm;
      div_bus.zf            <= is_ffdiv_negexp_ovf | div_bus.res_zero;  
    end

    else
    begin

      ffdiv_unb_exp         <= '0;
      
      div_bus.itr_count     <= '0;
      div_bus.sign          <= '0;
      div_bus.exp           <= '0;
      div_bus.frac          <= '0;

      div_bus.nanf          <= '0;
      div_bus.ovf           <= '0;
      div_bus.inf           <= '0;
      div_bus.uf            <= '0;
      div_bus.zf            <= '0;
    end
  end

endmodule