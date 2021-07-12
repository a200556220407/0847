
`timescale 1ns/1ps
module sync_gray
  (/*autoarg*/
   // Outputs
   cnt_s, cnt_d,
   // Inputs
   clk_s, rst_s, en_s, clk_d, rst_d
   );

   parameter CntWidth  = 8;
   parameter CntTarget = (1 << CntWidth);
   parameter FastGray = 1;
   
   // Input Declarations
   input                    clk_s;
   input                    rst_s;
   input                    en_s;
   input                    clk_d;
   input                    rst_d;
   
   // Output Declarations
   output [CntWidth-1:0]    cnt_s;
   output [CntWidth-1:0]    cnt_d;

   //-------------------------------------------------------------------//

   wire [CntWidth:0] 	    max_value = (1 << CntWidth);
   wire [CntWidth-1:0] 	    hole      = (max_value - CntTarget);
   wire [CntWidth-1:0] 	    hole_bot  = (CntTarget>>1);
   wire [CntWidth-1:0] 	    hole_top  = (max_value - hole_bot);

   wire [CntWidth-1:0] 	    cnt_gray_sync;
   
   reg [CntWidth-1:0] 	    R_cnt_s;
   reg [CntWidth-1:0] 	    R_cnt_s_gray;
   
   //Function to generate a gray code for a non-power-of-2 binary code.
   function [CntWidth-1:0] bin2gray;
      input [CntWidth-1:0]  B;
      reg [CntWidth-1:0]    g_v;
      reg [CntWidth-1:0]    B_adj;
      begin
         if(B >= hole_bot)
           B_adj = B + hole;
         else
           B_adj = B;
         // ----- basic ----- //
         g_v = B_adj ^ (B_adj>>1);
         // ----------------- //
         bin2gray = g_v;
      end
   endfunction // bin2gray
   
   //Function to generate a non-power-of-2 binary code for a gray code.
   function [CntWidth-1:0] gray2bin;
      input [CntWidth-1:0] G;
      reg [CntWidth:0] 	   b_v;
      reg [CntWidth-1:0]   B_adj;
      reg [CntWidth-1:0]   B;
      integer 		   i;
      begin      
         // ----- basic ----- //
         b_v[CntWidth] = 1'b0;
         for (i = CntWidth-1; i >= 0; i = i-1) b_v[i] = G[i] ^ b_v[i+1];
         B = b_v[CntWidth-1:0];
         // ----------------- //
         if (B >= hole_top)
           B_adj = B - hole;
         else
           B_adj = B;
         gray2bin = B_adj;
      end
   endfunction // gray2bin
   
   //---------------------------------------------------------------//

   wire [CntWidth-1:0] next_cnt_s = (R_cnt_s == (CntTarget-1))? 0 : R_cnt_s+1;

   always @(posedge clk_s or posedge rst_s) begin
      if(rst_s)
        R_cnt_s <= #1 {CntWidth{1'b0}};
      else if (en_s) begin
	 R_cnt_s <= #1 next_cnt_s;
      end
   end

   generate
      if (FastGray) begin
	 always @(posedge clk_s or posedge rst_s) begin
	    if(rst_s)
              R_cnt_s_gray <= #1 {CntWidth{1'b0}};
	    else if (en_s)
              R_cnt_s_gray <= #1 bin2gray(next_cnt_s);
	 end
      end
      else begin
	 always @(posedge clk_s or posedge rst_s) begin
	    if(rst_s)
              R_cnt_s_gray <= #1 {CntWidth{1'b0}};
	    else
              R_cnt_s_gray <= #1 bin2gray(R_cnt_s);
	 end
      end
   endgenerate
   
   sync_2ff #
     (CntWidth) 
   I_SYNC_2FF 
     (
      .clk_d(clk_d),
      .rst_d(rst_d),
      .data_s(R_cnt_s_gray), 
      .data_d(cnt_gray_sync));

   assign cnt_s = R_cnt_s;
   assign cnt_d = gray2bin(cnt_gray_sync);

   
endmodule 

