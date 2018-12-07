`timescale 1ns/1ns

module spi_drv_TB;

parameter SPI_MAXLEN = 8;
parameter CLK_DIVIDE = 4;


logic clk;
logic rst;

logic start_cmd;
logic [$clog2(SPI_MAXLEN):0] n_clks;
logic [SPI_MAXLEN-1:0] tx_data; 
logic spi_drv_rdy; 
logic [SPI_MAXLEN-1:0] rx_miso; 
logic SCLK; 
logic MOSI; 
logic MISO; 
logic SS_N;


// Instantiate DUT
spi_drv #(
   .CLK_DIVIDE (CLK_DIVIDE), // Clock divider to indicate frequency of SCLK
   .SPI_MAXLEN (SPI_MAXLEN )  // SPI core data width
) DUT (
   .clk(clk),
   .reset_n(~rst),
   .start_cmd     (start_cmd  ),
   .n_clks        (n_clks     ),
   .tx_data       (tx_data    ),
   .spi_drv_rdy   (spi_drv_rdy),
   .rx_miso       (rx_miso    ),    
   .SCLK          (SCLK       ),       
   .MOSI          (MOSI       ),       
   .MISO          (MISO       ),       
   .SS_N          (SS_N       )        
);



initial begin
   MISO<= 0;
   rst <= 1'b1; #10;
   rst <= 1'b0; #10;

   start_cmd <= 1'b1;
   tx_data <= 8'hEA;
   n_clks  <= 5'h08; #1;
   start_cmd <= 1'b0;
   #100;
   $finish;
end

always begin
      // 50 MHz
      clk <= 1; #1;
      clk <= 0; #1;
     end

endmodule
