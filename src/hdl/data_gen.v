//+----------------------------------STAR_THEAD---------------------------------------
//--            ******************************************                      
//--            ** Copyright (C) 2017, ucas, Inc. **                      
//--            ** All Rights Reserved.                 **                      
//--            ******************************************                      
//------------------------------------------------------------------------------
//-- Module Name     :    fifo2tuser
//-- Description     :    Interface                                             
//-- Revision history:                                                          
//     Date               Author       Description                              
//     2017-11-04 10:49   shuangchao.lv   Initialize code
//-----------------------------------END_THEAD----------------------------------------
`timescale 1ns/100ps
module data_gen(/*autoarg*/
    //Inputs
    clk, rst, al_full, 

    //Outputs
    din, wr_en, wr_last);
//1K allign
parameter                   DATA_OFFSET = 0;
input 	                    clk;
input 	                    rst;  
input                       al_full;
output[127:0]                din;
output                      wr_en;
output                      wr_last;

reg[127:0]                din_buf;
reg                      wr_en;

reg[63:0]  cnt;
reg        wr_last;
always@(posedge clk)
	if(rst)
		cnt<= 0;
	else if((!al_full) && (cnt >= 150))
		cnt <= 0;
	else if(!al_full)
		cnt <= cnt + 1;

always@(posedge clk)
	if(rst)
		wr_en <= 0;
	else if((!al_full) && (cnt >= 1) && (cnt <= 128))
		wr_en <= 1;
	else 
	  wr_en <= 0;

always@(posedge clk)
	if(rst)
		wr_last <= 0;
	else if((!al_full) && (cnt == 128))
		wr_last <= 1;
	else 
	  wr_last <= 0;

always@(posedge clk)
	if(rst)
		din_buf <= {DATA_OFFSET,96'h0};
	else if(wr_en) 
		din_buf <= din_buf + 1;

//assign din = {din_buf[39:32],din_buf[47:40],din_buf[55:48],din_buf[63:56],din_buf[7:0],din_buf[15:8],din_buf[23:16],din_buf[31:24]};
//  assign din = {din_buf[31:24],din_buf[23:16],din_buf[15:8],din_buf[7:0],din_buf[63:56],din_buf[55:48],din_buf[47:40],din_buf[39:32]};
assign din = {din_buf};







endmodule





