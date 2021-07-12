// use as axi stream to fifo
// output port
// wr_en      write fifo enable 
// m_tdata    write fifo data
// m_tready   write fifo full reversal

// use as axi stream to axi stream
// output port
// m_tvalid   axi stream valid
// m_tdata    axi stream data
// m_tready   axi stream ready

`timescale 1ns/1ps
module axis2fifo
  (
   /*AUTOARG*/
   // Outputs
   wr_en, m_tvalid, m_tdata, s_tready,
   // Inputs
   clk, rst, m_tready, s_tdata, s_tvalid
   );

   parameter C_DATA_W = 16;

   input clk;
   input rst;
   output wr_en;
   output m_tvalid;
   output [C_DATA_W-1:0] m_tdata;
   input 		 m_tready;

   input [C_DATA_W-1:0]  s_tdata;
   input 		 s_tvalid;
   output 		 s_tready;

   reg [C_DATA_W-1:0] 	 m_tdata;
   reg 			 m_tvalid;
   wire 		 s_valid;
   wire 		 m_valid;

   assign s_valid = s_tvalid & s_tready;
   assign m_valid = m_tvalid & m_tready;
   assign s_tready = m_tready;
   assign wr_en = m_valid;

   always@(posedge clk)
     begin
	if(rst)
	  m_tvalid <= #1 {C_DATA_W{1'h0}};
  	else if(s_valid)
	  m_tvalid <= #1 1'h1;
  	else if(m_valid)
	  m_tvalid <= #1 1'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  m_tdata <= #1 {C_DATA_W{1'h0}};
  	else if(s_valid)
	  m_tdata <= #1 s_tdata;
     end

endmodule

