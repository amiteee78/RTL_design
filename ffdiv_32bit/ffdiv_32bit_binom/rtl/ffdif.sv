`include "ffdiv_arch.svh"

interface ffdif (

  input   logic                                clk,    // Clock
  input   logic                                rst_n,  // Asynchronous reset active low

  input   logic                                en,
  input   logic [`OPERAND_WIDTH-1:0]           operand1,
  input   logic [`OPERAND_WIDTH-1:0]           operand2,

  output  logic [$clog2(`OPERAND_WIDTH)-1:0]   itr_count,
  output  logic [`OPERAND_WIDTH-1:0]           result,
  output  logic [`FLAG_SIZE-1:0]               flag,

  output  logic                                ready

  );

  /********Interfacing with decoding & iteration logic modules*********/
  logic                                 sign1;         
  logic                                 sign2;

  logic [`UNB_EXP_WIDTH-1:0]            unb_exp1;          
  logic [`UNB_EXP_WIDTH-1:0]            unb_exp2;

  logic [`SIGNIFICAND_WIDTH-1:0]        sgfnd1;        
  logic [`SIGNIFICAND_WIDTH-1:0]        sgfnd2;

  logic                                 is_denorm1;     
  logic                                 is_denorm2;

  logic                                 is_norm1;       
  logic                                 is_norm2;

  logic [`OPERAND_WIDTH-1:0]            res_nan;       
  logic                                 res_indet;
  logic                                 res_inf;  
  logic                                 res_zero;

  logic                                 dec_valid;

  /**********************Interfacing with Output***********************/

  logic                                 sign;
  logic [`EXPONENT_WIDTH-1:0]           exp;
  logic [`FRACTION_WIDTH-1:0]           frac;

  logic                                 nanf;  
  logic                                 ovf;  
  logic                                 inf;  
  logic                                 uf;    
  logic                                 zf;

  modport top_bus (

    input   clk,
    input   rst_n,
    
    input   en,
    input   operand1,
    input   operand2,
    
    output  itr_count,
    output  result,
    output  flag,
    
    output  ready

  );

  modport decode_bus (

    input     clk,    
    input     rst_n,  
    input     en,

    input     operand1,
    input     operand2,

    input     ready,

    output    sign1,
    output    sign2,

    output    unb_exp1,
    output    unb_exp2,

    output    sgfnd1,
    output    sgfnd2,

    output    is_denorm1,
    output    is_denorm2,

    output    is_norm1,
    output    is_norm2,         

    output    res_nan,
    output    res_indet,
    output    res_inf,
    output    res_zero,

    output    dec_valid

  );

  modport division_bus (

    input     clk,    
    input     rst_n,  
    input     en,

    output    ready,

    input     sign1,
    input     sign2,

    input     unb_exp1,
    input     unb_exp2,

    input     sgfnd1,
    input     sgfnd2,

    input     is_denorm1,
    input     is_denorm2,

    input     is_norm1,
    input     is_norm2,         

    input     res_nan,
    input     res_indet,
    input     res_inf,
    input     res_zero,

    input     dec_valid,

    output    itr_count,
    output    sign,
    output    exp,
    output    frac,
    output    nanf,
    output    ovf, 
    output    inf, 
    output    uf,  
    output    zf

  );

endinterface