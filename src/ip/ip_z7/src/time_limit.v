
`timescale 1ns/1ps
module time_limit
  (
   /*AUTOARG*/
   // Outputs
   rst_out,
   // Inputs
   clk, rst
   );

   // (C_DW_CNT=37)@75MHZ == 15 minutes
   parameter C_TIME_LIMIT = 0; 
   parameter C_DW_CNT = 37; 
   parameter C_RSTIN_ACTIVE = 1;
   parameter C_RSTOUT_ACTIVE = 1;

   input clk;
   input rst;
   output rst_out;

   reg [C_DW_CNT-1:0] cnt = 0 /* synthesis syn_preserve=1 */ ;
   reg 		      rst_out;
   wire 	      rst_lock;

   always@(posedge clk)
     begin
	if(~rst_lock)
	  cnt <= #1 cnt + 1'h1;
     end

   assign rst_lock = cnt[C_DW_CNT-1]; 
   assign rst_in = C_RSTIN_ACTIVE ? rst : (~rst);

   generate if(C_TIME_LIMIT == 1) begin
      always@(posedge clk)
	begin
	   if(rst_in)
	     rst_out <= #1 C_RSTOUT_ACTIVE;
	   else
	     rst_out <= #1 C_RSTOUT_ACTIVE ? rst_lock : (~rst_lock);
	end
   end
   endgenerate

   generate if(C_TIME_LIMIT == 0) begin
      always@(posedge clk)
	begin
	   if(rst_in)
	     rst_out <= #1 C_RSTOUT_ACTIVE;
	   else
	     rst_out <= #1 (~C_RSTOUT_ACTIVE);
	end
   end
   endgenerate

endmodule

