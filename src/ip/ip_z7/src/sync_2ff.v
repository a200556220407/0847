
`timescale 1ns/1ps
module sync_2ff
  (/*AUTOARG*/
   // Outputs
   data_d,
   // Inputs
   clk_d, rst_d, data_s
   );

   parameter Width       = 1;
   parameter Reset_value = 0;
   
   // Input Declarations
   input                 clk_d;
   input                 rst_d;
   input [Width-1:0] 	 data_s;

   // Output Declarations
   output [Width-1:0] 	 data_d;

   //---------------------------------------------------------------//
   
   reg [Width-1:0] 	 data_d;
   reg [Width-1:0] 	 data_sync;

   wire 		 reset_val = Reset_value[0];
   always @(posedge clk_d or posedge rst_d) begin
      if (rst_d) begin
	 data_sync <= #1 {Width{reset_val}};
	 data_d    <= #1 {Width{reset_val}};
      end
      else begin	 
	 data_sync <= #1 data_s;
	 data_d    <= #1 data_sync;
      end
   end

endmodule 
