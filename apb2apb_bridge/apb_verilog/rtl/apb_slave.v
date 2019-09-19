/*

APB Slave Module is designed using Finite State Machine having 3 always block...
  1. A sequential block to define the state register.
  2. A combinational block to define the next state logic.
  3. A combinational block to define the output logic.

Binary encoding is used to define the transition among three different states.

*/

module apb_slave
  #(
    parameter BASE_ADDR  = 32'h0000_0000,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_SIZE   = 256,
    parameter WAIT_CYCLE = 1
  ) 
  (
    input                           clk,    // Clock
    input                           rst_n,  // Asynchronous reset active low
  
    // APB Interface
    input                           psel,
    input                           penable,
    input                           pwrite,
    input       [ADDR_WIDTH-1:0]    paddr,
    input       [DATA_WIDTH-1:0]    pwdata,

    output  reg                     pready,
    output  reg                     pslverr,
    output  reg   [DATA_WIDTH-1:0]  prdata
  );

  localparam  [1:0] IDLE    = 2'b00;
  localparam  [1:0] SETUP   = 2'b01;
  localparam  [1:0] ACCESS  = 2'b10;  

  reg   [1:0]             apb_state;
  reg   [1:0]             apb_next_state;
  reg   [DATA_WIDTH-1:0]  memory [0:MEM_SIZE-1];

  reg   [1:0]             wait_count;

  genvar i;
  generate
    for( i = 0; i< MEM_SIZE; i = i+1)
    begin
      always @(posedge clk or negedge rst_n)
      begin
        if(~rst_n)
        begin
          memory[i]   <= 32'h0000_0000;
        end

        else
        begin
          memory[i]   <= memory[i];
        end
      end
    end
  endgenerate

  // Defining State Register

  always @(posedge clk or negedge rst_n) 
  begin
    if(~rst_n) begin
      apb_state       <= IDLE;
      pready          <= 1'b0;
      pslverr         <= 1'b0;
      prdata          <= 32'h0000_0000;
      wait_count      <= 2'b00;
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
        wait_count    <= 2'b00;
        apb_state     <= apb_next_state;
      end

    end
  end   


  // Defining Next State Logic

  always @(apb_state or paddr or pwdata or penable or pwrite or psel)
  begin

    case (apb_state)

      IDLE   :  begin

                  if(psel & ~penable)
                  begin
                    apb_next_state    <= SETUP;
                  end

                  else    
                  begin
                    apb_next_state    <= IDLE;
                  end
                end 
 
      SETUP  :  begin 
                  
                  if(psel & penable)    
                  begin 
                    apb_next_state    <= ACCESS;
                  end
                  else
                  begin
                    apb_next_state    <= SETUP;
                  end
                end

      ACCESS :  begin

                  if(psel & penable & (paddr < MEM_SIZE))
                  begin

                    apb_next_state    <= SETUP;
                  end

                  else
                  begin
                      apb_next_state  <= IDLE;     
                  end                                           
                end
    
    endcase
  end

  // Defining Output Logic

  always @(apb_state or paddr or pwdata or penable or pwrite or psel)
  begin

    case (apb_state)

       IDLE  :  begin

                  pready                    <= 1'b0;
                  pslverr                   <= 1'b0;
                  prdata                    <= 32'h0000_0000;

                end
 
      SETUP  :  begin 

                  pready                    <= 1'b0;
                  pslverr                   <= 1'b0;

                end
                  
      ACCESS :  begin

                  if(psel & penable)
                  begin

                    pready                  <= 1'b1;

                    if(paddr < MEM_SIZE && pwrite == 1)
                    begin
                      pslverr               <= 1'b0;
                      memory[paddr]         <= pwdata;
                    end

                    else if(paddr < MEM_SIZE && pwrite == 0)
                    begin
                      pslverr               <= 1'b0;
                      prdata                <= memory[paddr];  
                    end

                    else
                    begin
                      pslverr               <= 1'b1;
                      prdata                <= 32'h0000_0000;    
                    end

                  end

                  else
                  begin
                      pslverr               <= 1'b0;
                      prdata                <= prdata;    
                  end                                           
                end
    
    endcase   
  end

endmodule