`timescale 1ns/1ns

module startup_fsm_TB; 

    logic   clk;
    logic   reset;
    logic   rx_locked;
    logic   rx_dpa_locked;
    
    logic   pll_areset;
    logic   rx_reset;
    logic   rx_fifo_reset;
    logic   rx_cda_reset;

    
    startup_fsm  #(
        .CLOCK_PERIOD(5)
    ) DUT (
        .clk (clk),
        .usr_reset (reset),
        
        .rx_locked(rx_locked),
        .rx_dpa_locked(rx_dpa_locked),
        .pll_areset(pll_areset),
        .rx_reset(rx_reset),
        .rx_fifo_reset(rx_fifo_reset),
        .rx_cda_reset(rx_cda_reset)

    );
    
    // Test regular operation
    initial begin

            rx_dpa_locked <= 1'b0;
            rx_locked <= 1'b0;

            // Reset sequence
            reset <= 1'b1; #10000;
            reset <= 1'b0; #12500;

            // Test PLL stability
            rx_locked <= 1'b1; #10;
            rx_locked <= 1'b0; #10;
            rx_locked <= 1'b1; #10;
            rx_locked <= 1'b0; #10;
            rx_locked <= 1'b1; #10;
            rx_locked <= 1'b0; #10;
            rx_locked <= 1'b1; #20000;

            // Wait a little while till DPA is done
            #30;
            rx_dpa_locked <= 1'b1;
            #30;
            $finish;
        end

    always begin
            // 200 MHz
            clk <= 1; #2.5;
            clk <= 0; #2.5;
        end

endmodule
