`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:01:17 07/18/2016 
// Design Name: 
// Module Name:    stream_out 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module fifoio2stream(/*autoarg*/
	//inout
//	control0,
    //Inputs
    log_clk, rst, dstid, sorid, txio_tready, fifoio2stream_out, 
    fifoio2stream_empty, 

    //Outputs
    txio_tuser, txio_tvalid, txio_tlast, txio_tdata, 
    txio_tkeep, fifoio2stream_reqrd);
	   
//inout [35:0]   control0;   
input          log_clk;
input          rst;
input [15:0]   dstid;
input [15:0]   sorid;
//stream interface
output [31:0]  txio_tuser;
output         txio_tvalid;
output         txio_tlast;
input          txio_tready;
output [127:0] txio_tdata;
output [7:0]   txio_tkeep;
//fifo rd interface
output         fifoio2stream_reqrd;
input [127:0]   fifoio2stream_out;
input          fifoio2stream_empty;

reg    [31:0]  txio_tuser;
reg            txio_tvalid;
reg            txio_tlast;
reg    [127:0]  txio_tdata;
reg    [7:0]   txio_tkeep;
reg            d_valid;

assign         fifoio2stream_reqrd = (!fifoio2stream_empty) && txio_tready;

always@(posedge log_clk)
  if(rst)
    d_valid <= 0;
//  else if(fifoio2stream_reqrd && fifoio2stream_out[8])//last
//    d_valid <= 0;
  else if(fifoio2stream_reqrd)
    d_valid <= 1;
  else if(d_valid && (!fifoio2stream_reqrd) && txio_tready)//empty
    d_valid <= 0;

always@(posedge log_clk)
  if(rst)
    txio_tvalid <= 0;
 // else if(d_valid && (!fifoio2stream_out[8]) && txio_tready)
 else if(d_valid && txio_tready)
    txio_tvalid <= 1;
  else if(txio_tvalid && (!d_valid) && txio_tready)
    txio_tvalid <= 0;

always@(posedge log_clk)
  if(rst)
    txio_tlast <= 0;
//  else if(d_valid && txio_tready)
//    txio_tlast <= fifoio2stream_out[64];
//  else
//  	txio_tlast <= 1'b0;

always@(posedge log_clk)
  if(rst)
    txio_tdata <= 0;
  else if(d_valid && txio_tready)
    txio_tdata <= fifoio2stream_out[127:0];

always@(posedge log_clk)
  if(rst)
    txio_tkeep <= 0;
  else if(d_valid && txio_tready)
    txio_tkeep <= 8'hff;

always@(posedge log_clk)
  if(rst)
    txio_tuser <= 0;
  else if(d_valid && txio_tready)
    txio_tuser <= {sorid,dstid};
    
endmodule
