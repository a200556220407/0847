// use as fifo to fifo
// output port
// wr_en    write fifo enable 
// tdata    write fifo data
// tready   write fifo full reversal

// use as fifo to axi stream
// output port
// tvalid   axi stream valid
// tdata    axi stream data
// tready   axi stream ready

// if not use data channel
// tvalid_pre use to latch data


`timescale 1ns/1ps
module fifo2axis
  (
   /*AUTOARG*/
   // Outputs
   rd_en, tvalid, tdata, tvalid_pre, wr_en,
   // Inputs
   clk, rst, fifo_q, empty, tready
   );

   parameter C_DATA_W = 16;

   input clk;
   input rst;
   output rd_en;
   input [C_DATA_W-1:0] fifo_q;
   input 		empty;
   output 		tvalid;
   input 		tready;
   output [C_DATA_W-1:0] tdata;
   output 		 tvalid_pre;
   output 		 wr_en;

   reg [C_DATA_W-1:0] 	 tdata;
   reg 			 src_valid;
   reg 			 wr_buf;
   reg [1:0] 		 cnt_en;

   assign rd_en = (~empty) && (tready || (cnt_en == 0)); 
   assign wr_en = wr_buf & tready;
   assign tvalid_pre = ((src_valid && (cnt_en == 1)) || wr_en);
   assign tvalid = wr_buf;

   always@(posedge clk)
     begin
	if(rst)
	  cnt_en <= #1 2'h0;
	else if(rd_en && (~wr_en))
	  cnt_en <= #1 cnt_en + 1'h1;
	else if((~rd_en) && wr_en)
	  cnt_en <= #1 cnt_en - 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  src_valid <= #1 1'h0;
	else if(~empty)
	  src_valid <= #1 1'h1;
	else if(src_valid && tready)
	  src_valid <= #1 1'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  wr_buf <= #1 1'h0;
	else if((cnt_en == 1) && wr_en)
	  wr_buf <= #1 1'h0;
	else if(cnt_en == 1)
	  wr_buf <= #1 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  tdata <= #1 {C_DATA_W{1'h0}};
  	else if(tvalid_pre)
	  tdata <= #1 fifo_q;
     end

endmodule

