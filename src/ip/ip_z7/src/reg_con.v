
`timescale 1ns/1ps
module reg_con
  (/*AUTOARG*/
   // Outputs
   ready, rdata, irq, reqfifo_rdreq, respfifo_wrreq, respfifo_din,
   rque_wrreq, rque_din, compfifo_rdreq, soft_rst, wdma_en, rdma_en,
   rdma_f_ack, phy_loopback, tagram_wena, tagram_addra, tagram_dina,
   // Inputs
   clk, ext_clk, bus_rst, op, op_write, op_read, waddr, raddr, wdata,
   reqfifo_q, reqfifo_empty, respfifo_full, rque_full, compfifo_q,
   compfifo_empty, rdma_f, dev_id, phy_err, phy_link, head_err,
   compfifo_over, cmdfifo_over, err_tag, mwr_err_int, mrd_err_int,irq_wr,irq_rd,
   tagram_douta
   );

   parameter C_VERSION = 32'h0;
   parameter C_ADDR_W = 4;
   parameter C_TIME_LIMIT = 0;

   input clk;
   input ext_clk;
   input bus_rst;
   input op;
   input op_write;
   input op_read;
   input [C_ADDR_W-1:0] waddr;
   input [C_ADDR_W-1:0] raddr;
   input [31:0] 	wdata;
   output 		ready;
   output [31:0] 	rdata;

   output               irq;
	 output               irq_wr;
	 output               irq_rd;

   output 		reqfifo_rdreq;
   input [31:0] 	reqfifo_q;
   input 		reqfifo_empty;
   output 		respfifo_wrreq;
   output [31:0] 	respfifo_din;
   input 		respfifo_full;

   output 		rque_wrreq;
   output [127:0] 	rque_din;
   input 		rque_full;

   output 		compfifo_rdreq;
   input [7:0] 		compfifo_q;
   input 		compfifo_empty;

   output               soft_rst;
   output 		wdma_en;
   output 		rdma_en;
   output               rdma_f_ack;
   input 		rdma_f;
   input [15:0] 	dev_id;
   input [3:0] 		phy_err;
   input		phy_link;
   output               phy_loopback;

   input 		head_err;
   input 		compfifo_over;
   input 		cmdfifo_over;
   input 		err_tag;
   input 		mwr_err_int;
   input 		mrd_err_int;

   output 		tagram_wena;
   output [8:0] 	tagram_addra;
   output [31:0] 	tagram_dina;
   input [31:0] 	tagram_douta;

   localparam REG_OFFSET_0 = 4'h0;  // 0x00
   localparam REG_OFFSET_1 = 4'h1;  // 0x04
   localparam REG_OFFSET_2 = 4'h2;  // 0x08
   localparam REG_OFFSET_3 = 4'h3;  // 0x0C
   localparam REG_OFFSET_4 = 4'h4;  // 0x10
   localparam REG_OFFSET_5 = 4'h5;  // 0x14
   localparam REG_OFFSET_6 = 4'h6;  // 0x18
   localparam REG_OFFSET_7 = 4'h7;  // 0x1C
   localparam REG_OFFSET_8 = 4'h8;  // 0x20
   localparam REG_OFFSET_9 = 4'h9;  // 0x24
   localparam REG_OFFSET_10 = 4'ha; // 0x28
   localparam REG_OFFSET_11 = 4'hb; // 0x2C
   localparam REG_OFFSET_12 = 4'hc; // 0x30
   localparam REG_OFFSET_13 = 4'hd; // 0x34
   localparam REG_OFFSET_14 = 4'he; // 0x38
   localparam REG_OFFSET_15 = 4'hf; // 0x3C

   reg                  ready;
   reg [31:0] 		rdata;
   reg [31:0] 		rdata_n;
   reg [31:0] 		con;
   reg [31:0] 		status;
   reg [31:0] 		ie;
   reg [31:0] 		is;
   reg [31:0] 		dma_addr;
   reg [33:0] 		remote_addr;
   reg [31:0] 		dma_len;
   reg [31:0] 		tag_id;
   reg 			irq;
   reg 			irq_wr;	
   reg 			irq_rd;	 
   reg 			rque_wrreq;
   reg 			rdma_f_ack;

   reg 			rst_all;
   reg [4:0] 		cnt_rst;
   wire 		rst_en;
   wire 		rst;

   reg [31:0] 		respfifo_din;
   reg 			respfifo_wrreq;
   reg 			reqfiforeg_rdreq;
   reg [1:0] 		rdata_f_buf;
   wire 		reqfifo_rdreq;
   wire 		reqfiforeg_empty;

   wire 		rque_over;
   wire                 rque_empty_sync;
   wire 		rdma_f_sync;
   wire 		rdata_f;
   wire                 res_rdma_eq_0;
   wire [31:0] 		is_pre;
   wire [31:0] 		status_pre;
   wire 		resp_over;

   reg [15:0] 		res_rdma;
   reg [15:0] 		last_rdma;
   reg [15:0] 		rcv_rdma;
   reg [15:0] 		fin_rdma;
   reg                  last_rdata_f;
   reg 			ack_buf;
   wire                 load_rdma;
   wire                 rdma_int_flag;
   wire 		ack_inc;
   wire 		ack_dec;

   wire 		compfiforeg_empty;
   reg 			compfiforeg_rdreq;


   reg 			err_tag_buf;
   reg 			mwr_err_buf;
   reg 			mrd_err_buf;
   reg 			tag_err;
   reg 			mwr_err;
   reg 			mrd_err;
   reg  		phy_link_buf;
   reg 			link_up;
   reg 			link_down;
   wire 		head_err_sync;
   wire 		compfifo_over_sync;
   wire 		cmdfifo_over_sync;
   wire 		err_tag_sync;
   wire 		mwr_err_sync;
   wire 		mrd_err_sync;
   wire 		phy_link_sync;
   wire [15:0] 		dev_id_sync;
   wire [3:0] 		phy_err_sync;


   always@(posedge clk)
     begin
	if(rst)
	  con <= #1 32'h0;
	else if(op_write && waddr == REG_OFFSET_1)
          con <= #1 wdata;
	else
          con <= #1 {con[31:1],1'h0};
     end

   always@(posedge clk)
     begin
	if(rst)
	  status <= #1 32'h0;
	else
          status <= #1 status_pre;
     end

   assign status_pre = {8'h0,dev_id_sync,2'h0,phy_link_sync,1'h0,compfiforeg_empty,rque_full,
			reqfiforeg_empty,respfifo_full};

   always@(posedge clk)
     begin
	if(rst)
	  ie <= #1 32'h0;
	else if(op_write && waddr == REG_OFFSET_3)
          ie <= #1 wdata;
     end

   // write 1 to clean
   always@(posedge clk)
     begin
	if(rst)
	  is <= #1 32'h0;
	else if(op_write && waddr == REG_OFFSET_4)
          is <= #1 ((~wdata) & is);
	else
          is <= #1 {is[31:10],1'h0,is[8:3],1'h0,is[1:0]} | is_pre;
     end

   assign is_pre = {13'h0,cmdfifo_over_sync,phy_err_sync,link_down,link_up,
	            mrd_err,mwr_err, (~reqfiforeg_empty),1'h0,
		    resp_over,rque_over,tag_err,compfifo_over_sync,
		    head_err_sync,(~compfiforeg_empty),rdata_f,rdma_f_sync};

   always@(posedge clk)
     begin
	if(rst)
	  reqfiforeg_rdreq <= #1 1'h0;
	else if(op_read && ready && raddr == REG_OFFSET_5)
          reqfiforeg_rdreq <= #1 1'h1;
	else 
          reqfiforeg_rdreq <= #1 1'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  compfiforeg_rdreq <= #1 1'h0;
	else if(op_read && ready && raddr == REG_OFFSET_6)
          compfiforeg_rdreq <= #1 1'h1;
	else 
          compfiforeg_rdreq <= #1 1'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  respfifo_din <= #1 32'h0;
	else if(op_write && waddr == REG_OFFSET_7)
          respfifo_din <= #1 wdata;
     end

   always@(posedge clk)
     begin
	if(rst)
	  respfifo_wrreq <= #1 1'h0;
	else if(respfifo_wrreq && (~respfifo_full))
          respfifo_wrreq <= #1 1'h0;
	else if(op_write && waddr == REG_OFFSET_7)
          respfifo_wrreq <= #1 1'h1;
     end

   assign resp_over = respfifo_wrreq & respfifo_full;

   always@(posedge clk)
     begin
	if(rst)
	  dma_addr <= #1 32'h0;
	else if(op_write && waddr == REG_OFFSET_8)
          dma_addr <= #1 {wdata[31:8],8'h0}; // 256 bytes align
     end

   // srio remote addr, 34 bit, 16 bytes align
   always@(posedge clk)
     begin
	if(rst)
	  remote_addr <= #1 34'h0;
	else if(op_write && waddr == REG_OFFSET_9)
          remote_addr <= #1 {wdata[31:2],4'h0}; 
     end

   always@(posedge clk)
     begin
	if(rst)
	  tag_id <= #1 32'h0;
	else if(op_write && waddr == REG_OFFSET_10)
          tag_id <= #1 wdata;
     end

   //   [31]   : interrupt enable 
   //   [30]   : write fifo enable, auto clean
   //   [29:0] : data length
   always@(posedge clk)
     begin
	if(rst)
	  dma_len <= #1 32'h0;
	else if(op_write && waddr == REG_OFFSET_11)
          dma_len <= #1 wdata;
	else
          dma_len <= #1 {dma_len[31],1'h0,dma_len[29:0]};
     end

   always@(posedge clk)
     begin
	if(rst)
	  rque_wrreq <= #1 1'h0;
	else
          rque_wrreq <= #1 dma_len[30];
     end

   assign rdma_int_flag = dma_len[31]; 
   assign rque_over = rque_wrreq & rque_full;
   assign rque_din = {dma_len,tag_id,remote_addr[33:2],dma_addr};

   always@(posedge clk)
     begin
	if(rst)
	  res_rdma <= #1 16'h0;
	else if(ack_inc && (~ack_dec))
          res_rdma <= #1 res_rdma + 1'h1;
	else if((~ack_inc) & ack_dec)
          res_rdma <= #1 res_rdma - 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  last_rdma <= #1 16'h0;
	else if(load_rdma & ack_dec)
          last_rdma <= #1 16'h1;
	else if(load_rdma)
          last_rdma <= #1 16'h0;
	else if(ack_dec)
          last_rdma <= #1 last_rdma + 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  rcv_rdma <= #1 16'h0;
	else if(ack_inc)
          rcv_rdma <= #1 rcv_rdma + 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  fin_rdma <= #1 16'h0;
	else if(ack_dec)
          fin_rdma <= #1 fin_rdma + 1'h1;
     end

   assign load_rdma = (op_read && ready && raddr == REG_OFFSET_12);
   assign ack_inc = rque_wrreq & (~rque_full) & rdma_int_flag;
   assign ack_dec = (~ack_buf) & rdma_f_ack;
   assign res_rdma_eq_0 = (res_rdma == 0);
   assign rdata_f = {rdata_f_buf == 2'h1} | last_rdata_f;

   always@(posedge clk)
     begin
	if(rst)
	  last_rdata_f <= #1 1'h0;
	else
          last_rdata_f <= #1 (last_rdma != 0) && (res_rdma == 0);
     end

   always@(posedge clk)
     begin
	if(rst)
	  rdata_f_buf <= #1 2'h3;
	else
          rdata_f_buf <= #1 {rdata_f_buf[0],res_rdma_eq_0};
     end

   always@(posedge clk)
     begin
	if(bus_rst)
	  ready <= #1 1'h0;
	else if(op && (~ready))
	  ready <= #1 1'h1;
	else
	  ready <= #1 1'h0;
     end

   always@(posedge clk)
     begin
	if(bus_rst)
	  rdata <= #1 32'h0;
	else if(op_read & raddr[9])
	  rdata <= #1 tagram_douta;
	else if(op_read)
	  rdata <= #1 rdata_n;
     end

   always @(*)
     begin
	case(raddr)
	  REG_OFFSET_0: rdata_n = C_VERSION;
	  REG_OFFSET_1: rdata_n = con;
	  REG_OFFSET_2: rdata_n = status;
	  REG_OFFSET_3: rdata_n = ie;
	  REG_OFFSET_4: rdata_n = is;
	  REG_OFFSET_5: rdata_n = reqfifo_q;
	  REG_OFFSET_6: rdata_n = compfifo_q;
	  REG_OFFSET_7: rdata_n = respfifo_din;
	  REG_OFFSET_8: rdata_n = dma_addr;
	  REG_OFFSET_9: rdata_n = remote_addr[33:2];
	  REG_OFFSET_10: rdata_n = tag_id;
	  REG_OFFSET_11: rdata_n = dma_len;
	  REG_OFFSET_12: rdata_n = {last_rdma, res_rdma};
	  REG_OFFSET_13: rdata_n = {fin_rdma, rcv_rdma};
	  default: rdata_n = C_VERSION;
	endcase
     end

   assign tagram_addra = op_write ? waddr : raddr;
   assign tagram_wena = op_write & waddr[9];
   assign tagram_dina = wdata;

   always@(posedge clk)
     begin
	if(rst)
	  irq <= #1 1'h0;
	else if(ie & is)
	  irq <= #1 1'h1;
	else 
          irq <= #1 1'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  irq_wr <= #1 1'h0;
	else if(ie[2] & is[2])
	  irq_wr <= #1 1'h1;
	else 
          irq_wr <= #1 1'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  irq_rd <= #1 1'h0;
	else if(ie[1:0] & is[1:0])
	  irq_rd <= #1 1'h1;
	else 
          irq_rd <= #1 1'h0;
     end

   assign wdma_en = con[1];
   assign rdma_en = con[2];
   assign rst_en  = ~cnt_rst[4];
   assign rst     = soft_rst;
   assign phy_loopback = con[3];

   always@(posedge clk)
     begin
	if(bus_rst)
	  cnt_rst <= #1 5'h0;
	else if(con[0])
	  cnt_rst <= #1 5'h0;
	else if(rst_en)
          cnt_rst <= #1 cnt_rst + 1'h1;
     end

   always@(posedge clk)
     begin
	if(bus_rst)
	  rst_all <= #1 1'h1;
	else
	  rst_all <= #1 rst_en;
     end

   always@(posedge clk)
     begin
	if(rst)
	  rdma_f_ack <= #1 1'h0;
	else if(rdma_f_sync)
          rdma_f_ack <= #1 1'h1;
	else
          rdma_f_ack <= #1 1'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  ack_buf <= #1 1'h0;
	else
          ack_buf <= #1 rdma_f_ack;
     end

   always@(posedge clk)
     begin
	if(rst)
	  begin
	     mwr_err_buf <= #1 1'h0;
	     mrd_err_buf <= #1 1'h0;
	     err_tag_buf <= #1 1'h0;
	     phy_link_buf <= #1 4'h0;
	     mwr_err <= #1 1'h0;
	     mrd_err <= #1 1'h0;
	     tag_err <= #1 1'h0;
	     link_up <= #1 1'h0;
	     link_down <= #1 1'h0;
	  end
	else
	  begin
	     mwr_err_buf <= #1 mwr_err_sync;
	     mrd_err_buf <= #1 mrd_err_sync;
	     err_tag_buf <= #1 err_tag_sync;
	     phy_link_buf <= #1 phy_link_sync;
	     mwr_err <= #1 (~mwr_err_buf) & mwr_err_sync;
	     mrd_err <= #1 (~mrd_err_buf) & mrd_err_sync;
	     tag_err <= #1 (~err_tag_buf) & err_tag_sync;
	     link_up <= #1 (~phy_link_buf) & phy_link_sync;
	     link_down <= #1 phy_link_buf & (~phy_link_sync);
	  end
     end

   time_limit #
     (
      .C_TIME_LIMIT (C_TIME_LIMIT),
      .C_DW_CNT (37),
      .C_RSTIN_ACTIVE (1),
      .C_RSTOUT_ACTIVE (1))
   I_TIME_LIMIT
     (
      .clk   (clk),
      .rst   (rst_all),
      .rst_out (soft_rst)
      );

   fifo2reg
     I_COMP_FIFO2REG
       (
	.fifo_rdreq			(compfifo_rdreq),
	.fifo_empty			(compfifo_empty),
	.fiforeg_empty			(compfiforeg_empty),
	.fiforeg_rdreq			(compfiforeg_rdreq),
	/*AUTOINST*/
	// Inputs
	.clk				(clk),
	.rst				(rst)); 

   fifo2reg
     I_REQ_FIFO2REG
       (
	.fifo_rdreq			(reqfifo_rdreq),
	.fifo_empty			(reqfifo_empty),
	.fiforeg_empty			(reqfiforeg_empty),
	.fiforeg_rdreq			(reqfiforeg_rdreq),
	/*AUTOINST*/
	// Inputs
	.clk				(clk),
	.rst				(rst)); 

   sync_2ff #
     (
      .Width (7)) 
   I_SYNC
     (
      .clk_d    (clk),
      .rst_d    (rst),
      .data_s   ({mwr_err_int,mrd_err_int,err_tag,cmdfifo_over,compfifo_over,head_err,rdma_f}),
      .data_d   ({mwr_err_sync,mrd_err_sync,err_tag_sync,cmdfifo_over_sync,compfifo_over_sync,head_err_sync,rdma_f_sync})
      );

   sync_2ff #
     (
      .Width (21)) 
   I_SYNC2
     (
      .clk_d    (clk),
      .rst_d    (rst),
      .data_s   ({dev_id,phy_err,phy_link}),
      .data_d   ({dev_id_sync,phy_err_sync,phy_link_sync})
      );

endmodule


