module gray2bin_tb;

parameter WIDTH = 4;

logic clk_i = 0;
logic rst_i = 1;

logic [WIDTH-1:0] in_data_i;
logic [WIDTH-1:0] out_data_o;


// Instantiate DUT

   gray2bin #(
      .WIDTH(WIDTH)
   ) g2b (
   .*
   );

initial begin


   rst_i <= 1; #4;
   rst_i <= 0;
   in_data_i <= 4'h0;
   #2;
   in_data_i <= 4'h1;
   #2;
   in_data_i <= 4'h2;
   #2;
   in_data_i <= 4'h3;
   #2;
   in_data_i <= 4'h4;
   #2;
   in_data_i <= 4'h5;
   #2;
   in_data_i <= 4'h6;
   #2;
   in_data_i <= 4'h7;
   #2;
   in_data_i <= 4'h8;
   #2;
   in_data_i <= 4'h9;
   #2;
   in_data_i <= 4'hA;
   #2;
   in_data_i <= 4'hB;
   #2;
   in_data_i <= 4'hC;
   #2;
   in_data_i <= 4'hD;
   #2;
   in_data_i <= 4'hE;
   #2;
   in_data_i <= 4'hF;
   #2;
end

always begin
   clk_i <= ~clk_i; #1;
end

endmodule
