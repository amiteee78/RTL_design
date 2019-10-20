`include "apb_arch.svh"

interface apbif (
    input   logic                       clk,    // Clock
    input   logic                       rst_n,  // Asynchronous reset active low
    input   logic                       start,  // Start of transfer
    input   logic                       trnsfr, // Continue transfer

    // Address & Data Channel
    input   logic                       wr,
    input   logic [`ADDR_WIDTH-1:0]     address,
    input   logic [`DATA_WIDTH-1:0]     data_in,
    output  logic [`DATA_WIDTH-1:0]     data_out
  );

  logic                     sel;
  logic                     enable;
  logic                     write;
  logic [`STRB_SIZE-1:0]    strobe;
  logic [`ADDR_WIDTH-1:0]   addr;
  logic [`DATA_WIDTH-1:0]   wdata;
  logic                     ready;
  logic                     slverr;
  logic [`DATA_WIDTH-1:0]   rdata;

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **           APB Bridge Module Port              **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  modport bridge (
    input    clk,
    input    rst_n,
    input    trnsfr,

    // Address & Data Channel
    input    wr,
    input    address,
    input    data_in,
    output   data_out  
  );

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **           APB Master Module Port              **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  modport master (
    input    clk,    
    input    rst_n,  
    input    trnsfr,

    // Address & Data Channel (CPU)
    input    wr,
    input    address,
    input    data_in,
    output   data_out,

    // APB Interface
    output   sel,
    output   enable,
    output   write,
    output   strobe,
    output   addr,
    output   wdata,

    input    ready,
    input    slverr,
    input    rdata  
  );

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **            APB Slave Module Port              **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  modport slave (
    input    clk,    
    input    rst_n,  
    // Address & Data Channel (Memory)
    output   wr,
    output   address,
    output   data_in,
    input    data_out,
    // APB Interface
    input    sel,
    input    enable,
    input    write,
    input    strobe,
    input    addr,
    input    wdata,

    output   ready,
    output   slverr,
    output   rdata  
  );

  /*********************************************************/
  /*  ***************************************************  */
  /*  **                                               **  */
  /*  **              Memory Module Port               **  */
  /*  **                                               **  */
  /*  ***************************************************  */
  /*********************************************************/
  modport mem (
    input  clk,
    input  rst_n,
    // Memory Access
    input  wr,
    input  address,
    input  data_in,
    output data_out
  );

endinterface