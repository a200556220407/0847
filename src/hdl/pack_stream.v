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
module pack_stream(/*autoarg*/
    //Inputs
    clk, rst, ss_axis_tvalid, ss_axis_tlast, ss_axis_tdata, 
    ss_axis_tkeep, tag_num, length, start_clear, s_axis_tready, 

    //Outputs
    ss_axis_tready, s_axis_tvalid, s_axis_tlast, 
    s_axis_tuser, s_axis_tdata, s_axis_tkeep);
//1K allign
parameter   C_DATA_W = 128;
parameter   C_ID_NUM = 0;
localparam  C_PACK_NUM = 1024 * 8/C_DATA_W;
localparam  C_KEEP_W = C_DATA_W/8;

input 	                    clk;
input 	                    rst;  
input 	                    ss_axis_tvalid;
output 	                    ss_axis_tready;
input 	                    ss_axis_tlast;
input [C_DATA_W - 1:0]      ss_axis_tdata;
input [C_KEEP_W - 1 : 0]    ss_axis_tkeep;
input[31:0]                 tag_num;
input[31:0]                 length;
input[31:0]                 start_clear;


output 	                    s_axis_tvalid;
input 	                    s_axis_tready;
output 	                    s_axis_tlast;
output [65:0]               s_axis_tuser;
output [C_DATA_W - 1:0]     s_axis_tdata;
output   [C_KEEP_W - 1 : 0] s_axis_tkeep;

reg                         s_axis_tlast;
reg                         soft_rst;

wire[31:0]                  tol_length;

reg[7:0]                    id;
wire[15:0]                  sec_cnt;
reg [31:0]                  pack_num_cnt;   
reg [33:0]                  offset_addr;
reg[33:0]                   pack_offset;
wire[31:0]                  id_offset;


assign                      s_axis_tkeep = ss_axis_tkeep;
assign                      ss_axis_tready = s_axis_tready;
assign                      s_axis_tvalid = ss_axis_tvalid;
assign                      s_axis_tdata = ss_axis_tdata;
assign                      s_axis_tuser = {sec_cnt,8'h0,id,pack_offset};

assign                      sec_cnt = 16'h400;
assign                      tol_length = tag_num * length;
assign                      id_offset = C_ID_NUM * tag_num;
//assign                      id_offset = C_ID_NUM << 4;
                     

always@(posedge clk)
	if(rst)
		soft_rst <= 0;
	else if(start_clear[0] == 1)
    soft_rst <= 1;
  else
    soft_rst <= 0;

always@(posedge clk)
	if(rst || soft_rst)
		pack_num_cnt <= 0;
	else if(s_axis_tvalid && s_axis_tready && s_axis_tlast)
    pack_num_cnt <= 0;
	else if(s_axis_tvalid && s_axis_tready)
		pack_num_cnt <= pack_num_cnt + 1;

always@(posedge clk)
	if(rst || soft_rst)
		s_axis_tlast <= 0;
	else if(s_axis_tvalid && s_axis_tready && (pack_num_cnt == (C_PACK_NUM - 2)))
    s_axis_tlast <= 1;
	else if(s_axis_tvalid && s_axis_tready && (pack_num_cnt == (C_PACK_NUM - 1)))
		s_axis_tlast <= 0;

always@(posedge clk)
	if(rst || soft_rst)
		offset_addr <= 0;
	else if(s_axis_tvalid && s_axis_tready && s_axis_tlast && (offset_addr == (tol_length - 16'h400)))
    offset_addr <= 0;
	else if(s_axis_tvalid && s_axis_tready && s_axis_tlast)
    offset_addr <= offset_addr + 16'h400;

always@(posedge clk)
	if(rst || soft_rst)
		pack_offset <= 0;
	else if(s_axis_tvalid && s_axis_tready && s_axis_tlast && (pack_offset == (length - 16'h400)))
    pack_offset <= 0;
	else if(s_axis_tvalid && s_axis_tready && s_axis_tlast)
    pack_offset <= pack_offset + 16'h400;

always@(posedge clk)
	if(rst || soft_rst)
		id <= id_offset;
	else if(s_axis_tvalid && s_axis_tready && s_axis_tlast && (pack_offset == (length - 16'h400)) && (offset_addr == (tol_length - 16'h400)) && ((id - id_offset) == (tag_num - 1)))
    id <= id_offset;
	else if(s_axis_tvalid && s_axis_tready && s_axis_tlast && (pack_offset == (length - 16'h400)))
    id <= id + 1;


endmodule



