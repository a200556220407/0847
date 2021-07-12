//
// Cmd packet
// Byte  /     3       |       2       |       2       |       0       |
//      /              |               |               |               |
//     |7 6 5 4 3 2 1 0|7 6 5 4 3 2 1 0|7 6 5 4 3 2 1 0|7 6 5 4 3 2 1 0|
//     +---------------+---------------+---------------+---------------+
//    0|             ID[15:0]          |Task Tag[7:0]  | Cmd Type| Sta |
//     +---------------+---------------+---------------+---------------+
//    4|                       Address[31:0]                           |
//     +---------------+---------------+---------------+---------------+
//    8|           LBA[15:0]           |Sector Count[15:0]/Data Len    |
//     +---------------+---------------+---------------+---------------+
//   12|                           LBA[47:16]                          |
//     +---------------+---------------+---------------+---------------+
//


`timescale 1ns/1ps
module cmd_deal
  (/*AUTOARG*/
   // Outputs
   req_full, resp_q, resp_empty, reqfifo_q, reqfifo_empty,
   respfifo_full,
   // Inputs
   s_axi_aclk, ext_clk, rst, req_wreq, req_din, resp_rdreq,
   reqfifo_rdreq, respfifo_wrreq, respfifo_din
   );

   localparam C_WCMD = 8'h11;
   localparam C_RCMD = 8'h12;
   localparam C_RESP_WCMD = 8'h15;
   localparam C_RESP_RCMD = 8'h16;

   input s_axi_aclk;
   input ext_clk;
   input rst;

   input req_wreq;
   input [127:0] req_din;
   output 	 req_full;
   input 	 resp_rdreq;
   output [127:0] resp_q;
   output 	  resp_empty;

   input 	  reqfifo_rdreq;
   output [31:0]  reqfifo_q;
   output 	  reqfifo_empty;
   input 	  respfifo_wrreq;
   input [31:0]   respfifo_din;
   output 	  respfifo_full;

   wire 	  clk;
   wire 	  reqfifo_wrreq;
   wire [31:0] 	  reqfifo_din;
   wire 	  reqfifo_full;


   reg 		  req_en;
   reg [127:0] 	  req_data;
   reg [2:0] 	  cnt_req_rdy;
   wire 	  shift_f;

   reg [2:0] 	  cnt_resp;
   reg 		  resp_wrreq;
   reg 		  resp_valid;
   reg 		  rdy;

   wire 	  reqfifo_al_full;
   wire 	  req_empty;
   wire [127:0]   req_q;
   wire 	  respfifo_empty;
   wire 	  resp_full;
   reg [127:0] 	  resp_din;
   wire [31:0] 	  respfifo_q;

   assign clk = s_axi_aclk;

   assign req_rdreq = rdy && (~reqfifo_al_full) & (~req_empty);
   assign shift_f = (cnt_req_rdy == 4);
   assign reqfifo_wrreq = (|cnt_req_rdy);
   assign reqfifo_din = req_data[31:0];

   always@(posedge clk)
     begin
	if(rst)
	  req_en <= #1 1'h0;
	else
	  req_en <= #1 req_rdreq;
     end

   always@(posedge clk)
     begin
	if(rst)
	  req_data <= #1 128'h0;
	else if(req_en)
	  req_data <= #1 req_q;
	else if(reqfifo_wrreq)
	  req_data <= #1 {32'h0,req_data[127:32]};
     end

   always@(posedge clk)
     begin
	if(rst)
	  rdy <= #1 1'h1;
        else if(shift_f)
	  rdy <= #1 1'h1;
	else if(req_rdreq)
	  rdy <= #1 1'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  cnt_req_rdy <= #1 3'h0;
	else if(req_rdreq || shift_f)
	  cnt_req_rdy <= #1 3'h0;
	else if(~rdy)
	  cnt_req_rdy <= #1 cnt_req_rdy + 1'h1;
     end

   assign respfifo_rdreq = (~respfifo_empty) && (~cnt_resp[2]);

   always@(posedge clk)
     begin
	if(rst)
	  cnt_resp <= #1 3'h0;
	else if(cnt_resp[2] && resp_wrreq && (~resp_full))
	  cnt_resp <= #1 3'h0;
	else if(respfifo_rdreq)
	  cnt_resp <= #1 cnt_resp + 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  resp_valid <= #1 1'h0;
	else
	  resp_valid <= #1 respfifo_rdreq;
     end

   always@(posedge clk)
     begin
	if(rst)
	  resp_wrreq <= #1 1'h0;
	else if(resp_wrreq && (~resp_full))
	  resp_wrreq <= #1 1'h0;
	else if(resp_valid && cnt_resp[2])
	  resp_wrreq <= #1 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  resp_din <= #1 128'h0;
	else if(resp_valid)
	  resp_din <= #1 {respfifo_q,resp_din[127:32]};
     end

   syncfifo #
     (
      .C_RAM_TYPE (1),
      .C_DATA_W   (32),
      .C_ADDR_W   (10))
   I_REQ_FIFO
     (
      .clk         (s_axi_aclk),
      .rst         (rst),
      .din         (reqfifo_din),
      .push_req    (reqfifo_wrreq),
      .pop_req     (reqfifo_rdreq),
      .dout        (reqfifo_q),
      .full        (reqfifo_full),
      .al_full     (reqfifo_al_full),
      .empty       (reqfifo_empty)
      );

   syncfifo #
     (
      .C_RAM_TYPE (1),
      .C_DATA_W   (32),
      .C_ADDR_W   (10))
   I_RESP_FIFO
     (
      .clk       (s_axi_aclk),
      .rst       (rst),
      .din       (respfifo_din),
      .push_req  (respfifo_wrreq),
      .pop_req   (respfifo_rdreq),
      .dout      (respfifo_q),
      .full      (respfifo_full),
      .empty     (respfifo_empty)
      );

   asyncfifo #
     (
      .C_RAM_TYPE (0),
      .C_DATA_W   (128),
      .C_ADDR_W   (4))
   I_REQ_FIFO2
     (
      .wr_clk    (ext_clk),
      .rd_clk    (s_axi_aclk),
      .rst       (rst),
      .din       (req_din),
      .push_req  (req_wreq),
      .pop_req   (req_rdreq),
      .dout      (req_q),
      .full      (req_full),
      .empty     (req_empty)
      );

   asyncfifo #
     (
      .C_RAM_TYPE (0),
      .C_DATA_W   (128),
      .C_ADDR_W   (4))
   I_RESP_FIFO2
     (
      .wr_clk    (s_axi_aclk),
      .rd_clk    (ext_clk),
      .rst       (rst),
      .din       (resp_din),
      .push_req  (resp_wrreq),
      .pop_req   (resp_rdreq),
      .dout      (resp_q),
      .full      (resp_full),
      .empty     (resp_empty)
      );



endmodule



