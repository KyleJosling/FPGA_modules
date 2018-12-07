module inferred_systolic_fir #(
      parameter TAPS = 44,
      parameter COEFF_WIDTH = 18,
      parameter DATA_WIDTH = 18,
      parameter CHAINOUT_WIDTH = 42// COEFF_WIDTH+DATA_WIDTH+log2(TAPS)
   )
   (
      input  logic clk_i,
      input  logic rst_i,

      input  logic [DATA_WIDTH-1:0]       data_i, 
      output logic [CHAINOUT_WIDTH-1:0]   data_o 

   );
    
   `include "coeff.svh"

   // One DSP block for two taps with 18 bit coefficients
   localparam NUM_DSP = TAPS/2;
   
   // Arrays that hold chainout adder values and tap delay values
   logic [CHAINOUT_WIDTH-1:0] chain_array [NUM_DSP-1:0]; 
   logic [DATA_WIDTH-1:0]     samples [TAPS:0];
   
   // Flopped input data
   logic [DATA_WIDTH-1:0]     data_dly;

   always @(posedge clk_i or posedge rst_i) begin

      if (rst_i) begin
         data_dly <= 0;
      end else begin
         data_dly <= data_i;
      end

   end
   
   assign samples[0] = data_dly;

   // Generate input tap delay
   genvar k;
   generate

      for (k = 0; k < TAPS; k++) begin: line_delay 
         
         dflop2 #(
               .DATA_WIDTH (18)
            ) flop_k (
               .clk        (clk_i),
               .aclr       (rst_i),
               .ena        (~rst_i),// TODO - add valid
               .in         (samples[k]),
               .out        (samples[k+1])
            );
      end
   endgenerate


   // First DSP block
   dsp_block #(

         .COEFF_A          (coeff_array[0]),
         .COEFF_B          (coeff_array[1]),
         .DATA_WIDTH       (DATA_WIDTH),
         .COEFF_WIDTH      (COEFF_WIDTH),
         .CHAININ_WIDTH    (36),
         .CHAINOUT_WIDTH   (37)

   ) dsp_block0 (
         .clk_i            (clk_i),
         .clr_i            (rst_i),
         .en_i             (~rst_i),
         .a_i              (samples[0]),
         .b_i              (samples[1]),
         .chain_i          (36'b0),
         .chain_o          (chain_array[0])
   );

   // Generate DSP blocks 
   genvar i;
   generate
      
      for (i = 1; i < NUM_DSP; i++) begin: dsp_blocks
         
         dsp_block #(
            .COEFF_A          (coeff_array[2*i]),
            .COEFF_B          (coeff_array[2*i+1]),
            .DATA_WIDTH       (DATA_WIDTH),
            .COEFF_WIDTH      (COEFF_WIDTH)
         ) dsp_block_i (
            .clk_i            (clk_i),
            .clr_i            (rst_i),
            .en_i             (~rst_i),// TODO - add valid
            .a_i              (samples[2*i]),
            .b_i              (samples[2*i+1]),
            .chain_i          (chain_array[i-1]),
            .chain_o          (chain_array[i])
         );
      
      // Have to specify chainin and chainout width for each DSP block
		defparam	dsp_block_i.CHAININ_WIDTH = (i<2 ) ? DATA_WIDTH+COEFF_WIDTH+1:
                                           (i<3 ) ? DATA_WIDTH+COEFF_WIDTH+2:
                                           (i<5 ) ? DATA_WIDTH+COEFF_WIDTH+3:
                                           (i<9 ) ? DATA_WIDTH+COEFF_WIDTH+4:
                                           (i<17) ? DATA_WIDTH+COEFF_WIDTH+5:
                                           (i<33) ? DATA_WIDTH+COEFF_WIDTH+6:
                                           (i<65) ? DATA_WIDTH+COEFF_WIDTH+7:
                                           (i<129)? DATA_WIDTH+COEFF_WIDTH+8: DATA_WIDTH+COEFF_WIDTH+9;
												
		defparam	dsp_block_i.CHAINOUT_WIDTH =(i<2  )? DATA_WIDTH+COEFF_WIDTH+2:
                                           (i<4 ) ? DATA_WIDTH+COEFF_WIDTH+3:
                                           (i<8 ) ? DATA_WIDTH+COEFF_WIDTH+4:
                                           (i<16) ? DATA_WIDTH+COEFF_WIDTH+5:
                                           (i<32) ? DATA_WIDTH+COEFF_WIDTH+6:
                                           (i<64) ? DATA_WIDTH+COEFF_WIDTH+7:
                                           (i<128)? DATA_WIDTH+COEFF_WIDTH+8: DATA_WIDTH+COEFF_WIDTH+9;
      end
   endgenerate

   assign data_o = chain_array[NUM_DSP-1]; 

endmodule

