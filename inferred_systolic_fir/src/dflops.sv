module	dflop2 # (

   parameter DATA_WIDTH = 18

   )(

   input  logic clk,
   input  logic aclr,
   input  logic ena,

   input  logic signed [DATA_WIDTH-1:0] in,
   output logic signed [DATA_WIDTH-1:0] out
   
   ); 

logic signed [DATA_WIDTH-1:0]	in_d1;
logic signed [DATA_WIDTH-1:0]	in_d2;

always @(posedge clk or posedge aclr) begin
	if (aclr == 1'b1) begin
		in_d1  <= 0;
		in_d2  <= 0;
	end
	else if (ena) begin
		in_d1   <= in;
		in_d2   <= in_d1;
	end
end


assign out = in_d2; 

endmodule
