module startup_fsm #(
      parameter CLOCK_PERIOD = 8 // Clock period in ns to calculate timeout
   )
   (
      
      input    logic    clk,
      input    logic    usr_reset,
      
      input    logic    rx_locked,
      input    logic    rx_dpa_locked,

      output   logic    pll_areset,
      output   logic    rx_reset,
      output   logic    rx_fifo_reset,
      output   logic    rx_cda_reset
		
   );


   // FSM States
   localparam [6:0]
      ASSERT_RESETS     = 7'b0000001,
      RELEASE_PLL_RESET = 7'b0000010,
      RX_LOCKED_STABLE  = 7'b0000100,
      AWAIT_DPA         = 7'b0001000,
      RX_FIFO_RESET     = 7'b0010000,
      RX_CDA_RESET      = 7'b0100000,
      FSM_DONE          = 7'b1000000;
   

   // Timeout used for stability
   // Really short arbitrary values right now 
   localparam ASSERT_TIMEOUT = 10000 / CLOCK_PERIOD; 
   localparam STABLE_TIMEOUT = 5000 / CLOCK_PERIOD;

   // Maximum number of attempts to lock PLL
   localparam LOCK_ATTEMPTS_MAX = 4'h3;
   
   // PLL Lock signals
   logic  [3:0]   rx_locked_attempts = 4'b0;
   logic          rx_locked_flag = 1'b0;

   // Timeout signals
   logic          timeout_reset = 1'b1;
   logic [15:0]   timeout_counter = 0;
   
   // Flags when various timeouts have been reached
   logic          assert_timeout = 1'b0;
   logic          stable_timeout = 1'b0;

   // State of the FSM
   logic [7:0] fsm_state = ASSERT_RESETS;


   // FSM for LVDS Initialization sequence
   always_ff @(posedge clk or posedge usr_reset) begin
      
      // Reset everything then restart FSM
      if (usr_reset == 1'b1) begin

         fsm_state      <= ASSERT_RESETS;
         timeout_reset  <= 1'b1; 

         pll_areset     <= 1'b0;
         rx_reset       <= 1'b0;
         rx_fifo_reset  <= 1'b0;
         rx_cda_reset   <= 1'b0;

      end else begin
         
         case (fsm_state)
            
            // Initial state. This state will be returned to if any timeouts occur
            ASSERT_RESETS:
               begin
                  pll_areset <= 1'b1;
                  rx_reset   <= 1'b1;

                  // Hold resets high for a lil bit
                  if (assert_timeout) begin
                     fsm_state <= RELEASE_PLL_RESET;
                     timeout_reset <= 1'b1;
                  end else begin
                     timeout_reset <= 1'b0;
                  end
               end
            
            // Release the PLL reset and wait for PLL to lock
            RELEASE_PLL_RESET:
               begin
                  pll_areset <= 1'b0;
                  timeout_reset <= 1'b1;
                  
                  // Begin checking for a stable PLL lock
                  if (rx_locked) begin

                     rx_locked_attempts <= 4'h0;
                     rx_locked_flag <= 1'b0;
                     fsm_state <= RX_LOCKED_STABLE;

                  end
               end

            // Verify the PLL lock is stable
            RX_LOCKED_STABLE:
               begin
                  // When PLL lock signal asserts, start timing
                  if (rx_locked) begin
                     
                     rx_locked_flag <= 1'b1;
                     timeout_reset <= 1'b0;

                     // Wait for timeout to confirm stability of signal
                     if (stable_timeout) begin
                        fsm_state <= AWAIT_DPA;
                        timeout_reset <= 1'b1;
                        rx_reset <= 1'b0;
                     end

                  end else begin

                     timeout_reset <= 1'b1;
                     
                     // Keep track of how many locking attempts were made
                     if (rx_locked_flag) begin
                        
                        rx_locked_attempts = rx_locked_attempts + 1'b1;
                        
                        // If too many attempts were made
                        if (rx_locked_attempts == LOCK_ATTEMPTS_MAX) begin
                            fsm_state <= ASSERT_RESETS;
                        end

                     end

                     rx_locked_flag <= 1'b0;

                  end

               end

            // Wait until dynamic phase alignment is done
            AWAIT_DPA:
               begin
                  if (rx_dpa_locked) begin
                     fsm_state <= RX_FIFO_RESET;
                  end
               end
            
            // Reset the FIFO
            RX_FIFO_RESET:
               begin
                     rx_fifo_reset <= 1'b1;
                     fsm_state <= RX_CDA_RESET; 
               end
            
            // CDA reset
            RX_CDA_RESET:
               begin
                     rx_fifo_reset <= 1'b0;
                     rx_cda_reset <= 1'b1;
                     fsm_state <= FSM_DONE; 
               end
            
            // Bring up sequence complete  
            FSM_DONE:
               begin
                     rx_cda_reset <= 1'b0;
                     timeout_reset <= 1'b1;
                    
                     // If the PLL loses lock for whatever reason, restart FSM
                     if (!rx_locked) begin
                        fsm_state <= ASSERT_RESETS;
                     end
               end
        endcase
      end
   end
   
   // Timeout counters for various stages in FSM
   always_ff @(posedge clk) begin
      
      // Reset the timeouts
      if (timeout_reset || usr_reset) begin

         timeout_counter <= 1'b0;
         assert_timeout  <= 1'b0;
         stable_timeout  <= 1'b0;

      end else begin
               
        // Timeouts
        if (timeout_counter == ASSERT_TIMEOUT) begin
           assert_timeout <= 1'b1;
        end else if (timeout_counter == STABLE_TIMEOUT) begin
           stable_timeout <= 1'b1;
        end 
        
        timeout_counter = timeout_counter + 1'b1;

      end
      
   end


endmodule
