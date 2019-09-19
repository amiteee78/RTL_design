/*********************************************************/
/*  ***************************************************  */
/*  **                                               **  */
/*  **         Architecture Specifications           **  */
/*  **                                               **  */
/*  ***************************************************  */
/*********************************************************/

`ifndef BASE_ADDR
  `define BASE_ADDR 32'h0000_0100
`endif

`ifndef ADDR_WIDTH
  `define ADDR_WIDTH 32
`endif

`ifndef DATA_WIDTH
  `define DATA_WIDTH 32
`endif

`ifndef MEM_SIZE
  `define MEM_SIZE 256
`endif

`ifndef MEM_WIDTH
  `define MEM_WIDTH 32
`endif

`ifndef MEM_DEPTH
  `define MEM_DEPTH 4
`endif