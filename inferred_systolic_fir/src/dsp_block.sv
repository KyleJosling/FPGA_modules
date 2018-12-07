// DSP Block with chainout adder
module dsp_block #(

      parameter COEFF_A = 0,
      parameter COEFF_B = 0,
      parameter DATA_WIDTH = 18,
      parameter COEFF_WIDTH = 18,
      parameter CHAININ_WIDTH = 40,
      parameter CHAINOUT_WIDTH = 40

   ) (

      input  logic clk_i,
      input  logic clr_i,
      input  logic en_i,
      input  logic signed [DATA_WIDTH-1:0] a_i,
      input  logic signed [DATA_WIDTH-1:0] b_i,
      input  logic signed [CHAININ_WIDTH-1:0] chain_i,
      output logic signed [CHAINOUT_WIDTH-1:0] chain_o

    );
	 
    // Parameters have to be assigned to logic to be instantiated as coefficients in DSP block
	logic signed [COEFF_WIDTH-1:0] coeff_a;
   logic signed [COEFF_WIDTH-1:0] coeff_b;
    
    initial begin
        coeff_a <= COEFF_A;
        coeff_b <= COEFF_B;
    end
    
    // Flopped input values
    logic signed [DATA_WIDTH-1:0] a_reg;
    logic signed [DATA_WIDTH-1:0] b_reg;
    
    logic signed [CHAINOUT_WIDTH-1:0] sa;

    always_ff @(posedge clk_i or posedge clr_i) begin
        
        if (clr_i) begin
            a_reg       <= 0;
            b_reg       <= 0;
            sa          <= 0;
            chain_o     <= 0;
        end else if (en_i) begin
            a_reg       <= a_i;
            b_reg       <= b_i;
            sa          <= chain_i  + a_reg*coeff_a; // Form systolic structures from individual multiply-adders
            chain_o    <= sa + b_reg*coeff_b;
        end

    end

endmodule
