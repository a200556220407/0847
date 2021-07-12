
`timescale 1ns/1ps
module rdata_ch
  (/*AUTOARG*/
   // Outputs
   tx_axis_tvalid, tx_axis_tdata, tx_axis_tkeep, tx_axis_tlast,
   tx_axis_tuser, tag_tvalid, tag_tdata, tag_tlast, rque_full,
   rque_empty, rcmd_q, rcmd_empty, txfifo_datacnt,
   // Inputs
   clk, s_axi_aclk, ext_clk, rst, tx_axis_tready, tag_tready,
   rque_wrreq, rque_din, rcmd_rdreq, txfifo_wrreq, txfifo_din, rdma_f
   );

   parameter C_M_AXI_BURST_LEN = 32;
   parameter C_M_AXI_DATA_WIDTH = 128;
   parameter C_DATA_WIDTH = 134;
   parameter C_HW_DB = 0;
   localparam C_SIZE = (C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8));

   localparam C_IDLE = 4'h1;
   localparam C_REQ  = 4'h2;
   localparam C_JUMP = 4'h4;
   localparam C_FILL = 4'h8;

   input clk;
   input s_axi_aclk;
   input ext_clk;
   input rst;


   input tx_axis_tready;
   output tx_axis_tvalid;
   output [C_M_AXI_DATA_WIDTH-1:0] tx_axis_tdata;
   output [C_M_AXI_DATA_WIDTH/8-1:0] tx_axis_tkeep;
   output 			     tx_axis_tlast; 
   output [65:0] 		     tx_axis_tuser;

   output 			     tag_tvalid;
   input 			     tag_tready;
   output [23:0] 		     tag_tdata;
   output 			     tag_tlast;

   input 			     rque_wrreq;
   input [127:0] 		     rque_din;
   output 			     rque_full;
   output 			     rque_empty;

   input 			     rcmd_rdreq;
   output [63:0] 		     rcmd_q;
   output 			     rcmd_empty;

   input 			     txfifo_wrreq;
   input [C_DATA_WIDTH-1:0] 	     txfifo_din;
   output [10:0] 		     txfifo_datacnt;

   input 			     rdma_f;

   integer 			     i;

   function [C_M_AXI_DATA_WIDTH/8-1:0] extend_keep;
      input [C_M_AXI_DATA_WIDTH/32-1:0] keep;
      begin
	 for(i=0;i<C_M_AXI_DATA_WIDTH/8;i=i+1)
	   extend_keep[i] = keep[i/4];
      end
   endfunction

   wire 			     txfifo_rdreq;
   wire 			     txfifo_empty;
   wire [C_DATA_WIDTH-1:0] 	     txfifo_q;
   reg 			             txfifo_rdvalid;

   wire 			     rque_rdreq;
   wire [127:0] 		     rque_q;
   wire 			     rque_empty;
   wire [31:0] 			     rcmd_addr;
   wire [31:0] 			     rcmd_len;
   wire [63:0] 			     rcmd_din;
   wire 			     rcmd_full;
   wire 			     rhead_wrreq;
   wire [63:0] 			     rhead_din;
   wire 			     rhead_full;
   wire 			     rhead_rdreq;
   wire [63:0] 			     rhead_q;
   wire 			     rhead_empty;
   wire [31:0] 			     target_addr;
   reg [33:0] 			     remote_addr;
   reg [31:0] 			     len_cnt;
   reg 				     rcmd_wrreq;
   wire 			     txfifo_full;
   reg 				     eof_flag;
   reg 				     head_valid;
   wire 			     data_eof;
   reg [63:0] 			     head_data;

   reg [15:0] 			     len;

   reg [3:0] 			     state;
   reg [3:0] 			     state_n;


   reg [15:0] 			     tag_id;
   wire [23:0] 			     id;
   
   wire [C_DATA_WIDTH-1:0] 	     tdata;

   wire 			     id_wrreq;
   wire 			     id_rdreq;
   wire [23:0] 			     id_q;
   wire 			     id_empty;

   reg 				     rdma_f_buf;
   reg [23:0] 			     tagfifo_din;
   reg 				     id_rdreq_buf;
   reg 				     tagfifo_wrreq;
   wire 			     tagfifo_rdreq;
   wire [23:0] 			     tagfifo_q;
   wire 			     tagfifo_full;
   wire 			     tagfifo_empty;

   assign rque_rdreq = (state == C_IDLE) && (~rque_empty) & (~rcmd_full) & (~rhead_full);
   assign rcmd_addr = rque_q[31:0];
   assign rcmd_len = rque_q[127:96];
   assign rcmd_int = rcmd_len[31];
   assign rcmd_din = {rcmd_addr,rcmd_len};

   assign id = rque_q[95:72];
   assign target_addr = rque_q[63:32];
   assign rhead_din = {len,tag_id,remote_addr[33:2]};
   assign rhead_wrreq = (state == C_FILL) && (~rhead_full) && (len_cnt != 0);
   assign rhead_rdreq = (~rhead_empty) && (data_eof || eof_flag);

   assign data_eof = txfifo_rdvalid & txfifo_q[C_DATA_WIDTH-2];

   assign id_wrreq = C_HW_DB ? (rcmd_wrreq & rcmd_int) : 1'h0;
   assign id_rdreq = C_HW_DB ? (rdma_f & (~rdma_f_buf)) : 1'h0;
   assign tag_tlast = 1'h1;

   always@(posedge clk)
     begin
	if(rst)
	  state <= #1 C_IDLE;
	else
	  state <= #1 state_n;
     end

   always@(*)
     case(state)
       C_IDLE : state_n = rque_rdreq ? C_REQ : C_IDLE;
       C_REQ  : state_n = C_JUMP;
       C_JUMP : state_n = C_FILL;
       C_FILL : state_n = (len_cnt == 0) ? C_IDLE : C_FILL;
       default : state_n = C_IDLE;
     endcase

   always@(posedge clk)
     begin
	if(rst)
	  rcmd_wrreq <= #1 1'h0;
	else
	  rcmd_wrreq <= #1 rque_rdreq;
     end
   
   always@(posedge clk)
     begin
	if(rst)
	  len_cnt <= #1 32'h0;
	else if(state == C_REQ)
	  len_cnt <= #1 rcmd_len[29:0];
	else if(rhead_wrreq)
	  len_cnt <= #1 len_cnt - C_SIZE;
     end

   always@(posedge clk)
     begin
	if(rst)
	  len <= #1 16'h0;
	else if(len_cnt > C_SIZE)
	  len <= #1 C_SIZE;
        else if(len > 0)
	  len <= #1 len_cnt[15:0];
     end

   always@(posedge clk)
     begin
	if(rst)
	  remote_addr <= #1 34'h0;
	else if(state == C_REQ)
	  remote_addr <= #1 {target_addr,2'h0};
	else if(rhead_wrreq)
	  remote_addr <= #1 remote_addr + C_SIZE;
     end

   always@(posedge clk)
     begin
	if(rst)
	  tag_id <= #1 16'h0;
	else if(state == C_REQ)
	  tag_id <= #1 id[23:8];
     end

   always@(posedge clk)
     begin
	if(rst)
	  rdma_f_buf <= #1 1'h0;
	else
	  rdma_f_buf <= #1 rdma_f;
     end

   always@(posedge clk)
     begin
	if(rst)
	  tagfifo_din <= #1 24'h0;
	else
	  tagfifo_din <= #1 id_q;
     end

   always@(posedge clk)
     begin
	if(rst)
	  id_rdreq_buf <= #1 1'h0;
	else
	  id_rdreq_buf <= #1 id_rdreq;
     end

   always@(posedge clk)
     begin
	if(rst)
	  tagfifo_wrreq <= #1 1'h0;
	else
	  tagfifo_wrreq <= #1 id_rdreq_buf;
     end

   // ext_clk domain
   always@(posedge ext_clk)
     begin
	if(rst)
	  eof_flag <= #1 1'h1;
	else if(rhead_rdreq)
	  eof_flag <= #1 1'h0;
	else if((~rhead_rdreq) && data_eof)
	  eof_flag <= #1 1'h1;
     end

   always@(posedge ext_clk)
     begin
	if(rst)
	  txfifo_rdvalid <= #1 1'h0;
	else
	  txfifo_rdvalid <= #1 txfifo_rdreq;
     end

   always@(posedge ext_clk)
     begin
	if(rst)
	  head_valid <= #1 1'h0;
	else if(rhead_rdreq)
	  head_valid <= #1 1'h1;
	else if(~txfifo_full)
	  head_valid <= #1 1'h0;
     end

   always@(posedge ext_clk)
     begin
	if(rst)
	  head_data <= #1 64'h0;
	else if(head_valid & (~txfifo_full))
	  head_data <= #1 rhead_q;
     end

   asyncfifo  #
     (
      .C_RAM_TYPE (1),
      .C_DATA_W   (128),
      .C_ADDR_W   (9))
   I_RQUE_FIFO
     (
      .wr_clk    (s_axi_aclk),
      .rd_clk    (clk),
      .rst       (rst),
      .din       (rque_din),
      .push_req  (rque_wrreq),
      .pop_req   (rque_rdreq),
      .dout      (rque_q),
      .full      (rque_full),
      .empty     (rque_empty),
      .al_full   (),
      .al_empty  ()
      );

   asyncfifo #
     (
      .C_RAM_TYPE (0),
      .C_DATA_W   (64),
      .C_ADDR_W   (5))
   I_HEAD_FIFO
     (
      .wr_clk    (clk),
      .rd_clk    (ext_clk),
      .rst       (rst),
      .din       (rhead_din),
      .push_req  (rhead_wrreq),
      .pop_req   (rhead_rdreq),
      .dout      (rhead_q),
      .full      (rhead_full),
      .empty     (rhead_empty),
      .al_full   (),
      .al_empty  ()
      );

   syncfifo #
     (
      .C_RAM_TYPE (0),
      .C_DATA_W   (64),
      .C_ADDR_W   (5))
   I_RCMD_FIFO
     (
      .clk       (clk),
      .rst       (rst),
      .din       (rcmd_din),
      .push_req  (rcmd_wrreq),
      .pop_req   (rcmd_rdreq),
      .dout      (rcmd_q),
      .full      (rcmd_full),
      .empty     (rcmd_empty),
      .al_full   (),
      .al_empty  ()
      );

   syncfifo #
     (
      .C_RAM_TYPE (0),
      .C_DATA_W   (24),
      .C_ADDR_W   (4))
   I_ID_FIFO
     (
      .clk       (clk),
      .rst       (rst),
      .din       (id),
      .push_req  (id_wrreq),
      .pop_req   (id_rdreq),
      .dout      (id_q),
      .full      (),
      .empty     (id_empty),
      .al_full   (),
      .al_empty  ()
      );

   asyncfifo #
     (
      .C_RAM_TYPE (1),
      .C_DATA_W   (24),
      .C_ADDR_W   (10))
   I_COMP_FIFO
     (
      .wr_clk    (clk),
      .rd_clk    (ext_clk),
      .rst       (rst),
      .din       (tagfifo_din),
      .push_req  (tagfifo_wrreq),
      .pop_req   (tagfifo_rdreq),
      .dout      (tagfifo_q),
      .full      (tagfifo_full),
      .empty     (tagfifo_empty)
      );

   asyncfifo  #
     (
      .C_RAM_TYPE (1),
      .C_DATA_W (C_DATA_WIDTH),
      .C_ADDR_W (10))
   I_TXFIFO
     (
      .wr_clk    (clk),
      .rd_clk    (ext_clk),
      .rst       (rst),
      .din       (txfifo_din),
      .push_req  (txfifo_wrreq),
      .pop_req   (txfifo_rdreq),
      .dout      (txfifo_q),
      .full      (txfifo_full),
      .empty     (txfifo_empty),
      .data_cnt_wclk (txfifo_datacnt),
      .al_full   (),
      .al_empty  ()
      );

   fifo2axis #
     (
      .C_DATA_W (24))
   I_FIFO2AXIS_TAG
     (
      .clk      (ext_clk),
      .rst      (rst),
      .rd_en    (tagfifo_rdreq),
      .fifo_q   (tagfifo_q),
      .empty    (tagfifo_empty),
      .tvalid   (tag_tvalid),
      .tready   (tag_tready),
      .tdata    (tag_tdata),
      .tvalid_pre (),
      .wr_en ()
      );

   fifo2axis #
     (
      .C_DATA_W (C_DATA_WIDTH))
   I_FIFO2AXIS
     (
      .clk      (ext_clk),
      .rst      (rst),
      .rd_en    (txfifo_rdreq),
      .fifo_q   (txfifo_q),
      .empty    (txfifo_empty),
      .tvalid   (tx_axis_tvalid),
      .tready   (tx_axis_tready),
      .tdata    (tdata),
      .tvalid_pre (),
      .wr_en ()
      );

   assign tx_axis_tdata = tdata[C_M_AXI_DATA_WIDTH-1:0];
   assign tx_axis_tkeep = extend_keep(tdata[C_M_AXI_DATA_WIDTH+C_M_AXI_DATA_WIDTH/32-1:C_M_AXI_DATA_WIDTH]);
   assign tx_axis_tlast = tdata[C_DATA_WIDTH-2];
   assign tx_axis_tuser = {head_data,2'h0};

endmodule


