`timescale 1ns/1ps

module gray2bin # (
   
   parameter WIDTH = 4 // Data width

) (
   
   input  logic clk_i,
   input  logic rst_i,

   input  logic [WIDTH-1:0] in_data_i,
   output logic [WIDTH-1:0] out_data_o

);

logic [WIDTH-1:0] in_data;
logic [WIDTH-1:0] out_data;

// Flop data to break timing
always_ff @(posedge clk_i) begin
   if (rst_i) begin
      in_data <= 0;
      out_data_o  <= 0;
   end else begin
      in_data <= in_data_i;
      out_data_o <= out_data;
   end
end

genvar i;
generate
   for (i = 0; i < WIDTH; i++) begin : conversion
      
      // MSB is passed through
      if (i == WIDTH-1) begin
         always_comb begin
            out_data[WIDTH-1] = in_data[WIDTH-1];     
         end
      end else begin
         always_comb begin
            out_data[i] = in_data[i+1] ^ in_data[i];
         end
      end

   end

endgenerate


endmodule

module gray2bina # (
   parameter WIDTH = 4 // Data width
) (
   
   input  logic clk_i,
   input  logic rst_i,

   input  logic [WIDTH-1:0] in_data_i,
   output logic [WIDTH-1:0] out_data_o

);

logic [WIDTH-1:0] in_data;
logic [WIDTH-1:0] out_data;

// Flop data to break timing
always_ff @(posedge clk_i) begin
   if (rst_i) begin
      in_data <= 0;
      out_data_o  <= 0;
   end else begin
      in_data <= in_data_i;
      out_data_o <= out_data;
   end
end

genvar i;
generate
   for (i = WIDTH-1; i >= 0; i--) begin : conversion
      
      // MSB is passed through
      if (i == WIDTH-1) begin
         always_comb begin
            out_data[WIDTH-1] = in_data[WIDTH-1];     
         end
      end else begin
         always_comb begin
            out_data[i] = out_data[i+1] ^ in_data[i];
         end
      end

   end

endgenerate


endmodule
