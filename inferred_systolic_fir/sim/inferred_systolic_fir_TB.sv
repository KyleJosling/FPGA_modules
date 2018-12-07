`timescale 1ns/1ns

module inferred_systolic_fir_TB;

   logic clk;
   logic reset;

   integer i = 0;
   integer f;

   logic   [17:0]  samples [255:0];
   logic   [17:0]  sample_i;
   logic   [39:0]  sample_o;


   // Instantiate DUT
   inferred_systolic_fir #(
      .TAPS              (8),
      .COEFF_WIDTH       (18),
      .DATA_WIDTH        (18),
      .CHAINOUT_WIDTH    (40)

   ) DUT (

      .clk_i    (clk      ),
      .rst_i    (reset    ),

      .data_i   (sample_i ),
      .data_o   (sample_o )

   );
   

   initial begin
      f = $fopen("vecgen/output.txt","w");
      reset <= 0;
      $readmemh("vecgen/samples1.mem", samples);
   end

   always_ff @(posedge clk) begin

      sample_i <= samples[i];
      i++;
      $fwrite(f, "%h\n", sample_o);

      if (i == 16*4) begin
         $finish;
      end
   end
    
    
   always begin
       clk <= 1'b1; #2.5;
       clk <= 1'b0; #2.5;
   end

endmodule
