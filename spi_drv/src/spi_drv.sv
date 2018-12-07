// Concept of operations:
//
//  This module is used to implement a SPI master. The host will want to transmit a certain number of SCLK pulses
//  this number will be placed in the n_clks port and will always be less than or equal to SPI_MAXLEN.
//
//  The data to be transmitted on MOSI will be placed on the tx_data port. The first bit of data to be transmitted
//  will be bit tx_data[n_clks-1] and the last bit transmitted will be tx_data[0]
//
//  On completion of the SPI transaction rx_miso will have the data of the MISO at each positive edge of SCLK
//  rx_miso[n_clks-1] will be the first edge and rx_miso[0] will be the last edge.
//
//  When the host wants to issue a SPI transaction the host will hold the start_cmd pin high until it receives
//  a transition of spi_drv_rdy from 1 to 0. As long as start_cmd is high a valid n_clks and tx_data will be
//  available on the ports.
//  The host will know the SPI transaction has completed when spi_drv_rdy goes high again, rx_miso should remain
//  as is until another start_cmd transition has been made.
//
//  In terms of timing, we want SCLK to have to have a frequency equal to frequency of clk divided by  CLK_DIVIDE.
//  SCLK will also have a 50% duty cycle. CLK_DIVIDE will always be an even number that is at least 4.
//  The output MOSI must have valid data on that output before the positive edge of SCLK, ideally half an
//  SCLK period.
//
//  MISO will change on the positive edge of SCLK.
//
//  Timing diagram of n_clks = 4
//  SCLK        ________/-\_/-\_/-\_/-\______ 
//  MOSI        ======= 3 | 2 | 1 | 0 =======
//  MISO        ======= 3 | 2 | 1 | 0 =======
//  SS_N        ------\_______________/------

`timescale 1ns/1ns

module spi_drv #(
    parameter integer               CLK_DIVIDE  = 100, // Clock divider to indicate frequency of SCLK
    parameter integer               SPI_MAXLEN  = 32   // SPI core data width
)(
    input                           clk,
    input                           reset_n,
    
    // Host side interface 
    input                           start_cmd,     // Start SPI transfer pulse
    input  [$clog2(SPI_MAXLEN):0]   n_clks,        // Number of pulses of SCLK for the SPI transaction
    input  [SPI_MAXLEN-1:0]         tx_data,       // Data to be transmitted out on the MOSI
    output                          spi_drv_rdy,   // Ready bit
    output [SPI_MAXLEN-1:0]         rx_miso,       // Output rx data from MISO
    
    // SPI Pins
    output                          SCLK,          // SPI clock sent to the slave
    output                          MOSI,          // Master out slave in pin (data output to the slave)
    input                           MISO,          // Master in slave out pin (data input from the slave)
    output                          SS_N           // Slave select, will be 0 during a SPI transaction
);


// Internal logic
logic [2:0] spi_state;

logic [$clog2(SPI_MAXLEN):0]  n_clks_reg;
logic [SPI_MAXLEN-1:0]        tx_data_reg;
logic [SPI_MAXLEN-1:0]        rx_miso_reg;
logic                         spi_drv_rdy_reg;

logic       SCLK_reg;
logic       SS_N_reg;

logic [8:0] clk_counter;
logic [8:0] n_counter;


localparam [2:0]
      AWAIT_START = 7'b0000001,
      WAIT_HALF   = 7'b0000010,
      DO_TXN      = 7'b0000100;


always_ff @(posedge clk) begin
   
   // Reset everything
   if (!reset_n) begin

      spi_state <= AWAIT_START;

   end else begin

      case (spi_state) 
         
         // Wait for a start command
         AWAIT_START:
            begin
               if (start_cmd) begin
                  
                  // Drive clock and slave select
                  SS_N_reg <= 1'b0;
                  SCLK_reg <= 1'b0;
                  
                  // Capture the data on the interface
                  tx_data_reg <= tx_data;
                  n_clks_reg  <= n_clks;
                  
                  // Drive ready low
                  spi_drv_rdy_reg <= 1'b0;
                  
                  // Reset counters
                  clk_counter <= 0;
                  n_counter <= 0;
                  
                  // Next state
                  spi_state <= WAIT_HALF; 
               end else begin
                  // Drive ready high when no start command
                  spi_drv_rdy_reg <= 1'b1;
               end
            end
            
         // Start transaction half of SCLK's cycle before enabling SCLK
         WAIT_HALF:
            begin
               
               // Increment clock counter
               clk_counter <= clk_counter + 1'b1;

               if (clk_counter == (CLK_DIVIDE/2)-1) begin
                  clk_counter <= 0;
                  spi_state <= DO_TXN;

                  rx_miso_reg <= {rx_miso_reg[SPI_MAXLEN-2:0],MISO}; 

               end
            end

         // Transmit/receive data
         DO_TXN:
            begin


               // Increment clock counter
               clk_counter <= clk_counter + 1'b1; 

               // When counter is at half drive the clock
               if (clk_counter == (CLK_DIVIDE/2)-1) begin
                  SCLK_reg <= ~SCLK_reg; 
               // Drive the clock again and reset
               end else if (clk_counter == CLK_DIVIDE-1) begin
                  SCLK_reg <= ~SCLK_reg; 
                  clk_counter <= 0;
                  n_counter <= n_counter + 1'b1;
                  
                  // Capture MISO and shift
                  rx_miso_reg <= {rx_miso_reg[SPI_MAXLEN-2:0],MISO};
                  // Shift tx input for MOSI
                  tx_data_reg <= {tx_data_reg[SPI_MAXLEN-2:0], 1'b0};

                  // Done the transaction
                  if (n_counter == n_clks_reg-1) begin
                     spi_state <= AWAIT_START;
                  end
               end 
            end

      endcase
   end
end

// Multiplex MOSI to right tx_data_reg value
assign SCLK = SCLK_reg;
assign MOSI = tx_data_reg[n_clks-1];
assign SS_N = SS_N_reg;

assign spi_drv_rdy = spi_drv_rdy_reg;
assign rx_miso = rx_miso_reg;
endmodule
