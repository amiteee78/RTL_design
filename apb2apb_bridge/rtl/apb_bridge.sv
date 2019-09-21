`timescale 1ns/1ns
`include "apb_arch.svh"

module apb_bridge (apbif.bridge ibus);

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **           Interface object creation           **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  apbif pbus (

    ibus.clk,
    ibus.rst_n,
    ibus.start,
    ibus.wr,

    ibus.address,
    ibus.data_in,
    ibus.data_out
  );

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **         Master & Slave Instantiation          **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/

  apb_master pmaster (.mbus(pbus));
  apb_slave  pslave  (.sbus(pbus));


endmodule