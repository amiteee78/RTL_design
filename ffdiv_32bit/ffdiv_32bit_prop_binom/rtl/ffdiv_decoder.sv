`timescale 1ns/1ns
`include "ffdiv_arch.svh"

module ffdiv_decoder (ffdif.decode_bus dec_bus);

  enum logic {IDLE, DECODE} dec_state, dec_nxt_state;

  logic                                 is_snan_1;
  logic                                 is_snan_2;

  logic                                 is_qnan_1;
  logic                                 is_qnan_2;

  logic                                 is_inf_1;
  logic                                 is_inf_2;

  logic                                 is_zero_1;
  logic                                 is_zero_2;

  logic                                 is_norm_1;
  logic                                 is_norm_2;

  logic                                 is_denorm_1;
  logic                                 is_denorm_2;

  logic                                 is_finite_1;
  logic                                 is_finite_2;

  logic                                 op1_sign;
  logic                                 op2_sign;

  logic [`EXPONENT_WIDTH-1:0]           op1_exp;
  logic [`EXPONENT_WIDTH-1:0]           op2_exp;

  logic [`SIGNIFICAND_WIDTH-1:0]        op1_sgfnd;
  logic [`SIGNIFICAND_WIDTH-1:0]        op2_sgfnd;

  logic [$clog2(`OPERAND_WIDTH)-1:0]    ffdiv_exp1_shift;
  logic [$clog2(`OPERAND_WIDTH)-1:0]    ffdiv_exp2_shift;


  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **          Operand Decoding (IEEE-754)          **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

  assign op1_sign             = dec_bus.operand1[`OPERAND_WIDTH-1];
  assign op2_sign             = dec_bus.operand2[`OPERAND_WIDTH-1];

  assign op1_exp              = dec_bus.operand1[`OPERAND_WIDTH-2:`FRACTION_WIDTH];
  assign op2_exp              = dec_bus.operand2[`OPERAND_WIDTH-2:`FRACTION_WIDTH];

  assign op1_sgfnd            = {|dec_bus.operand1[`OPERAND_WIDTH-2:`FRACTION_WIDTH], dec_bus.operand1[`FRACTION_WIDTH-1:0]};
  assign op2_sgfnd            = {|dec_bus.operand2[`OPERAND_WIDTH-2:`FRACTION_WIDTH], dec_bus.operand2[`FRACTION_WIDTH-1:0]};

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **            Number Range Definition            **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

  assign is_snan_1            = dec_bus.en & ((&dec_bus.operand1[`OPERAND_WIDTH-2:`FRACTION_WIDTH]) & ~dec_bus.operand1[`FRACTION_WIDTH-1] & (|dec_bus.operand1[`FRACTION_WIDTH-2:0]));
  assign is_snan_2            = dec_bus.en & ((&dec_bus.operand2[`OPERAND_WIDTH-2:`FRACTION_WIDTH]) & ~dec_bus.operand2[`FRACTION_WIDTH-1] & (|dec_bus.operand2[`FRACTION_WIDTH-2:0]));

  assign is_qnan_1            = dec_bus.en & ((&dec_bus.operand1[`OPERAND_WIDTH-2:`FRACTION_WIDTH]) & dec_bus.operand1[`FRACTION_WIDTH-1]); // real indefinite included
  assign is_qnan_2            = dec_bus.en & ((&dec_bus.operand2[`OPERAND_WIDTH-2:`FRACTION_WIDTH]) & dec_bus.operand2[`FRACTION_WIDTH-1]); // real indefintie included
  
  assign is_inf_1             = dec_bus.en & (&dec_bus.operand1[`OPERAND_WIDTH-2:`FRACTION_WIDTH]) & ~(|dec_bus.operand1[`FRACTION_WIDTH-1:0]);
  assign is_inf_2             = dec_bus.en & (&dec_bus.operand2[`OPERAND_WIDTH-2:`FRACTION_WIDTH]) & ~(|dec_bus.operand2[`FRACTION_WIDTH-1:0]);
  
  assign is_zero_1            = dec_bus.en & (~(|dec_bus.operand1[`OPERAND_WIDTH-2:`FRACTION_WIDTH]) & ~(|dec_bus.operand1[`FRACTION_WIDTH-1:0]));
  assign is_zero_2            = dec_bus.en & (~(|dec_bus.operand2[`OPERAND_WIDTH-2:`FRACTION_WIDTH]) & ~(|dec_bus.operand2[`FRACTION_WIDTH-1:0]));

  assign is_denorm_1          = dec_bus.en & (~(|dec_bus.operand1[`OPERAND_WIDTH-2:`SIGNIFICAND_WIDTH-1]) & (|dec_bus.operand1[`SIGNIFICAND_WIDTH-2:0]));
  assign is_denorm_2          = dec_bus.en & (~(|dec_bus.operand2[`OPERAND_WIDTH-2:`SIGNIFICAND_WIDTH-1]) & (|dec_bus.operand2[`SIGNIFICAND_WIDTH-2:0]));

  assign is_norm_1            = dec_bus.en & (|dec_bus.operand1[`OPERAND_WIDTH-2:`SIGNIFICAND_WIDTH-1]) & ~(&dec_bus.operand1[`OPERAND_WIDTH-2:`SIGNIFICAND_WIDTH-1]);
  assign is_norm_2            = dec_bus.en & (|dec_bus.operand2[`OPERAND_WIDTH-2:`SIGNIFICAND_WIDTH-1]) & ~(&dec_bus.operand2[`OPERAND_WIDTH-2:`SIGNIFICAND_WIDTH-1]);

  assign is_finite_1          = dec_bus.en & (is_norm_1 | is_denorm_1);
  assign is_finite_2          = dec_bus.en & (is_norm_2 | is_denorm_2);


  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **           State Register Definition           **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

  always_ff @(posedge dec_bus.clk or negedge dec_bus.rst_n) 
  begin
    if(~dec_bus.rst_n) 
    begin
      dec_state   <= IDLE;
    end 
    else 
    begin
      dec_state   <= dec_nxt_state;
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

    unique case (dec_state)
      IDLE :
      begin
        if (dec_bus.en)
        begin
          dec_nxt_state   = DECODE;
        end
        else
        begin
          dec_nxt_state   = IDLE;
        end
      end

      DECODE :
      begin
        if (dec_bus.en & dec_bus.ready)
        begin
          dec_nxt_state   = IDLE;
        end
        else
        begin
          dec_nxt_state   = DECODE;
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

    unique case (dec_state)
      IDLE :
      begin        
        ffdiv_exp1_shift      = '0;
        ffdiv_exp2_shift      = '0;
      end

      DECODE :
      begin
        /*************Leading One Detection in Significand_1**************/
        if (is_norm_1 | is_denorm_1)
        begin
          priority case (1'b1)
            op1_sgfnd[23] : ffdiv_exp1_shift      =  0;
            op1_sgfnd[22] : ffdiv_exp1_shift      =  1;
            op1_sgfnd[21] : ffdiv_exp1_shift      =  2;
            op1_sgfnd[20] : ffdiv_exp1_shift      =  3;
            op1_sgfnd[19] : ffdiv_exp1_shift      =  4;
            op1_sgfnd[18] : ffdiv_exp1_shift      =  5;
            op1_sgfnd[17] : ffdiv_exp1_shift      =  6;
            op1_sgfnd[16] : ffdiv_exp1_shift      =  7;
            op1_sgfnd[15] : ffdiv_exp1_shift      =  8;
            op1_sgfnd[14] : ffdiv_exp1_shift      =  9;
            op1_sgfnd[13] : ffdiv_exp1_shift      = 10;
            op1_sgfnd[12] : ffdiv_exp1_shift      = 11;
            op1_sgfnd[11] : ffdiv_exp1_shift      = 12;
            op1_sgfnd[10] : ffdiv_exp1_shift      = 13;
            op1_sgfnd[9]  : ffdiv_exp1_shift      = 14;
            op1_sgfnd[8]  : ffdiv_exp1_shift      = 15;
            op1_sgfnd[7]  : ffdiv_exp1_shift      = 16;
            op1_sgfnd[6]  : ffdiv_exp1_shift      = 17;
            op1_sgfnd[5]  : ffdiv_exp1_shift      = 18;
            op1_sgfnd[4]  : ffdiv_exp1_shift      = 19;
            op1_sgfnd[3]  : ffdiv_exp1_shift      = 20;
            op1_sgfnd[2]  : ffdiv_exp1_shift      = 21;
            op1_sgfnd[1]  : ffdiv_exp1_shift      = 22;
            op1_sgfnd[0]  : ffdiv_exp1_shift      = 23;
          endcase          
        end

        else
        begin
          ffdiv_exp1_shift      =  0;
        end

        /*************Leading One Detection in Significand_2**************/
        if (is_norm_2 | is_denorm_2)
        begin
          priority case (1'b1)
            op2_sgfnd[23] : ffdiv_exp2_shift      =  0;
            op2_sgfnd[22] : ffdiv_exp2_shift      =  1;
            op2_sgfnd[21] : ffdiv_exp2_shift      =  2;
            op2_sgfnd[20] : ffdiv_exp2_shift      =  3;
            op2_sgfnd[19] : ffdiv_exp2_shift      =  4;
            op2_sgfnd[18] : ffdiv_exp2_shift      =  5;
            op2_sgfnd[17] : ffdiv_exp2_shift      =  6;
            op2_sgfnd[16] : ffdiv_exp2_shift      =  7;
            op2_sgfnd[15] : ffdiv_exp2_shift      =  8;
            op2_sgfnd[14] : ffdiv_exp2_shift      =  9;
            op2_sgfnd[13] : ffdiv_exp2_shift      = 10;
            op2_sgfnd[12] : ffdiv_exp2_shift      = 11;
            op2_sgfnd[11] : ffdiv_exp2_shift      = 12;
            op2_sgfnd[10] : ffdiv_exp2_shift      = 13;
            op2_sgfnd[9]  : ffdiv_exp2_shift      = 14;
            op2_sgfnd[8]  : ffdiv_exp2_shift      = 15;
            op2_sgfnd[7]  : ffdiv_exp2_shift      = 16;
            op2_sgfnd[6]  : ffdiv_exp2_shift      = 17;
            op2_sgfnd[5]  : ffdiv_exp2_shift      = 18;
            op2_sgfnd[4]  : ffdiv_exp2_shift      = 19;
            op2_sgfnd[3]  : ffdiv_exp2_shift      = 20;
            op2_sgfnd[2]  : ffdiv_exp2_shift      = 21;
            op2_sgfnd[1]  : ffdiv_exp2_shift      = 22;
            op2_sgfnd[0]  : ffdiv_exp2_shift      = 23;
          endcase          
        end

        else
        begin
          ffdiv_exp2_shift      =  0;
        end
      end    
    endcase
  end

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **          Output Registers Definition          **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

  always_ff @(negedge dec_bus.clk or negedge dec_bus.rst_n) 
  begin
    if(~dec_bus.rst_n) 
    begin
      dec_bus.sign1         <= '0;
      dec_bus.sign2         <= '0;

      dec_bus.unb_exp1      <= '0;
      dec_bus.unb_exp2      <= '0;

      dec_bus.sgfnd1        <= '0;
      dec_bus.sgfnd2        <= '0;

      dec_bus.is_denorm1    <= '0;
      dec_bus.is_denorm2    <= '0;

      dec_bus.is_norm1      <= '0;
      dec_bus.is_norm2      <= '0;

      dec_bus.res_nan       <= '0;
      dec_bus.res_indet     <= '0;
      dec_bus.res_inf       <= '0;
      dec_bus.res_zero      <= '0;

      dec_bus.dec_valid     <= '0;
        
    end

    else if (dec_state == DECODE) 
    begin
      dec_bus.sign1         <= op1_sign;
      dec_bus.sign2         <= op2_sign;

      /********Unbiased Exponent Calculation for Normalized & Denormalized Range********/
      if (is_denorm_1)
      begin
        dec_bus.unb_exp1      <= `NORM_EXP_MIN - ffdiv_exp1_shift; // (-126 - exponent_shift)
      end
      else if (is_norm_1)
      begin
        dec_bus.unb_exp1      <= `UNB_EXP_WIDTH'(op1_exp - `BIASING_CONSTANT); // (biased exponent - biasing constant)
      end

      if (is_denorm_2)
      begin
        dec_bus.unb_exp2      <= `NORM_EXP_MIN - ffdiv_exp2_shift; // (-126 - exponent_shift)
      end
      else if (is_norm_2)
      begin
        dec_bus.unb_exp2      <= `UNB_EXP_WIDTH'(op2_exp - `BIASING_CONSTANT); // (biased exponent - biasing constant)
      end
      
      dec_bus.sgfnd1        <= op1_sgfnd << ffdiv_exp1_shift; // scaled significand_1
      dec_bus.sgfnd2        <= op2_sgfnd << ffdiv_exp2_shift; // scaled significand_2

      dec_bus.is_denorm1    <= is_denorm_1;
      dec_bus.is_denorm2    <= is_denorm_2;
      dec_bus.is_norm1      <= is_norm_1;
      dec_bus.is_norm2      <= is_norm_2;

      /**********************************************Output NaN Calculation***********************************************/
      if(is_snan_1 & is_qnan_2)
      begin
        dec_bus.res_nan     <= dec_bus.operand2;
      end

      else if(is_snan_2 & is_qnan_1)
      begin
        dec_bus.res_nan     <= dec_bus.operand1;
      end

      else if((is_snan_1 & is_snan_2) & (dec_bus.operand1[`FRACTION_WIDTH-1:0] > dec_bus.operand2[`FRACTION_WIDTH-1:0]))
      begin 
        dec_bus.res_nan     <= {op1_sign, op1_exp, 1'b1 ,dec_bus.operand1[`FRACTION_WIDTH-2:0]};
      end

      else if((is_snan_1 & is_snan_2) & (dec_bus.operand1[`FRACTION_WIDTH-1:0] <= dec_bus.operand2[`FRACTION_WIDTH-1:0]))
      begin 
        dec_bus.res_nan     <= {op2_sign, op2_exp, 1'b1 ,dec_bus.operand2[`FRACTION_WIDTH-2:0]};
      end

      else if((is_qnan_1 & is_qnan_2) & (dec_bus.operand1[`FRACTION_WIDTH-1:0] > dec_bus.operand2[`FRACTION_WIDTH-1:0]))
      begin 
        dec_bus.res_nan     <= dec_bus.operand1;
      end

      else if((is_qnan_1 & is_qnan_2) & (dec_bus.operand1[`FRACTION_WIDTH-1:0] <= dec_bus.operand2[`FRACTION_WIDTH-1:0]))
      begin 
        dec_bus.res_nan     <= dec_bus.operand2;
      end
      else if(is_snan_1)
      begin 
        dec_bus.res_nan     <= {op1_sign, op1_exp, 1'b1 ,dec_bus.operand1[`FRACTION_WIDTH-2:0]};
      end
      else if(is_snan_2)
      begin 
        dec_bus.res_nan     <= {op2_sign, op2_exp, 1'b1 ,dec_bus.operand2[`FRACTION_WIDTH-2:0]};
      end
      else if(is_qnan_1)
      begin 
        dec_bus.res_nan     <= dec_bus.operand1;
      end
      else if(is_qnan_2)
      begin 
        dec_bus.res_nan     <= dec_bus.operand2;
      end
      else
      begin
        dec_bus.res_nan     <= '0;
      end
      
      dec_bus.res_indet     <= (is_inf_1 & is_inf_2) | (is_zero_1 & is_zero_2); // inf/inf or zero/zero (Result Indeterminate form)
      
      dec_bus.res_inf       <= (is_inf_1 & is_finite_2) | ((is_inf_1 | is_finite_1) & is_zero_2); // inf/finite or inf/zero or finite/zero (Result Infinity)

      dec_bus.res_zero      <= (is_zero_1 & (is_finite_2 | is_inf_2)) | (is_finite_1 & is_inf_2); // zero/anything or finite/inf (Result Zero)
      
      dec_bus.dec_valid     <= '1;      
    end

    else
    begin
      dec_bus.dec_valid     <= '0;
    end
  end

endmodule