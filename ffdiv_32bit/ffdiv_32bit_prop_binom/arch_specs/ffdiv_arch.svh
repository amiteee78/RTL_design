/*********************************************************/
/*  ***************************************************  */
/*  **                                               **  */
/*  **         Architecture Specifications           **  */
/*  **                                               **  */
/*  ***************************************************  */
/*********************************************************/

`ifndef OPERAND_WIDTH
  `define OPERAND_WIDTH 32
`endif

`ifndef EXPONENT_WIDTH
  `define EXPONENT_WIDTH 8
`endif

`ifndef UNB_EXP_WIDTH
  `define UNB_EXP_WIDTH (`EXPONENT_WIDTH+1)
`endif

`ifndef FRACTION_WIDTH
  `define FRACTION_WIDTH 23
`endif

`ifndef SIGNIFICAND_WIDTH
  `define SIGNIFICAND_WIDTH (`FRACTION_WIDTH+1)
`endif

`ifndef PRECISION_WIDTH
  `define PRECISION_WIDTH (`SIGNIFICAND_WIDTH+`EXPONENT_WIDTH)
`endif

`ifndef FLAG_SIZE
  `define FLAG_SIZE 5
`endif

`ifndef BIASING_CONSTANT
  `define BIASING_CONSTANT 127
`endif

`ifndef DENORM_EXP_MIN
  `define DENORM_EXP_MIN `UNB_EXP_WIDTH'(-149)
`endif

`ifndef DENORM_EXP_MAX
  `define DENORM_EXP_MAX `UNB_EXP_WIDTH'(-127)
`endif

`ifndef NORM_EXP_MIN
  `define NORM_EXP_MIN `UNB_EXP_WIDTH'(-126)
`endif

`ifndef GBIT
  `define GBIT `PRECISION_WIDTH - `SIGNIFICAND_WIDTH - 2
`endif

`ifndef RBIT
  `define RBIT (`GBIT - 1)
`endif

`ifndef SBIT
  `define SBIT (`RBIT - 1)
`endif