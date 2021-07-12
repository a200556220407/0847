
`timescale 1ns/1ps
module fifo2reg
  (
   /*AUTOARG*/
   // Outputs
   fifo_rdreq, fiforeg_empty,
   // Inputs
   clk, rst, fifo_empty, fiforeg_rdreq
   );

   input clk;
   input rst;

   input fifo_empty;
   output fifo_rdreq;
   input  fiforeg_rdreq;
   output fiforeg_empty;

   reg 	  fiforeg_empty;

   assign fifo_rdreq = (~fifo_empty) & fiforeg_empty;

   always@(posedge clk)
     begin
	if(rst)
	  fiforeg_empty <= #1 1'h1;
	else if(fiforeg_rdreq)
	  fiforeg_empty <= #1 1'h1;
	else if(fifo_rdreq)
	  fiforeg_empty <= #1 1'h0;
     end


endmodule

