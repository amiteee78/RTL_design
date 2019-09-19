/*

APB Master Module is designed using Finite State Machine having 3 always block...
  1. A sequential block to define the state register.
  2. A combinational block to define the next state logic.
  3. A combinational block to define the output logic.

Binary encoding is used to define the transition among three different states.

*/

module apb_master
  #(
    parameter BASE_ADDR   = 32'h0000_0000,
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,
    parameter MEM_SIZE    = 256,
    parameter WAIT_CYCLE  = 1
  ) 
  (
    input                           clk,    // Clock
    input                           rst_n,  // Asynchronous reset active low

    input                           start,

    // Address & Data Channel
    input                           wr,
    input         [ADDR_WIDTH-1:0]  address,
    input         [DATA_WIDTH-1:0]  wdata,
    output  reg   [DATA_WIDTH-1:0]  rdata,

    // APB Interface

    output  reg                     psel,
    output  reg                     penable,
    output  reg                     pwrite,
    output  reg   [ADDR_WIDTH-1:0]  paddr,
    output  reg   [DATA_WIDTH-1:0]  pwdata,

    input                           pready,
    input                           pslverr,
    input         [DATA_WIDTH-1:0]  prdata  
  );

  localparam  [1:0] IDLE     = 2'b00;
  localparam  [1:0] SETUP    = 2'b01;
  localparam  [1:0] ACCESS   = 2'b10;


  reg   [1:0]             apb_state;
  reg   [1:0]             apb_next_state;

  reg   [1:0]             wait_count;

  // Defining State Register

  always @(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin

      apb_state       <= IDLE;
      psel            <= 1'b0;
      penable         <= 1'b0;
      pwrite          <= 1'b0;
      paddr           <= 32'h0000_0000;
      pwdata          <= 32'h0000_0000;
      wait_count      <= 2'b00;

      rdata           <= 32'h0000_0000;
    end

    else
    begin

      if(wait_count < WAIT_CYCLE-1 && apb_state == ACCESS)
      begin
        wait_count    <= wait_count + 1;
        apb_state     <= apb_state;
      end

      else
      begin
        wait_count      <= 2'b00;
        apb_state       <= apb_next_state;
      end
      
    end
  end

  // Definig Next State Logic

  always @(apb_state or pready or pslverr or prdata or start)
  begin
    //apb_next_state  <= 2'b00;

    case (apb_state)

      IDLE :    begin
                  if(start & ~pready)
                  begin
                    apb_next_state    <= SETUP;
                  end

                  else
                  begin
                    apb_next_state    <= IDLE;
                  end
                  
                end

      SETUP   :   begin
                    apb_next_state    <= ACCESS;
                  end

      ACCESS :   begin
                  if(pready)
                  begin
                    apb_next_state  <= IDLE;
                  end

                  else
                  begin
                    apb_next_state  <= ACCESS;
                  end
                end
    
    endcase
  end

  // Defining Output Logic

  always @(apb_state or pready or pslverr or prdata or wr or wdata or address)
  begin

    case (apb_state)

      IDLE :    begin
                  if(~pready)
                  begin
                    psel        <= 1'b0;
                    penable     <= 1'b0;
                    pwrite      <= 1'b0;
                    paddr       <= 32'h0000_0000;
                    pwdata      <= 32'h0000_0000;                   
                  end

                  else
                  begin
                    psel        <= psel   ;
                    penable     <= penable;
                    pwrite      <= pwrite ;
                    paddr       <= paddr  ;
                    pwdata      <= pwdata ;                    
                  end

                end

      SETUP  :  begin
                  psel        <= 1'b1;
                  penable     <= 1'b0;
                  paddr       <= address;

                  if(wr)
                  begin
                    pwrite    <= 1'b1;
                    pwdata    <= wdata;
                  end

                  else
                  begin
                    pwrite    <= 1'b0;
                  end
                end

      ACCESS :  begin
                  psel        <= 1'b1;
                  penable     <= 1'b1;

                  if(pready)
                  begin
                    rdata     <= prdata;
                  end

                  else
                  begin
                    rdata     <= rdata;
                  end
                end
    
    endcase
  end
 
endmodule