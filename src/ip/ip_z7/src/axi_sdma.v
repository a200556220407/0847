
//======================================================================================
// Logic tree:
//     axi_sdma.v
//      |- bus_conv.v
//      |- reg_con.v
//      |   |- asyncfifo.v
//      |   |- fifo2reg.v
//      |   |- fifo2reg.v
//      |- cmd_deal.v
//      |   |- syncfifo.v
//      |   |- syncfifo.v
//      |   |- asyncfifo.v
//      |   |- asyncfifo.v
//      |- wdata_ch.v
//      |   |- asyncfifo.v
//      |   |- ram.v
//      |   |- ram.v
//      |   |- asyncfifo.v
//      |   |- axis2fifo.v
//      |   |- syncfifo.v
//      |- axi_wr.v
//      |   |- fifo2axis.v
//      |- rdata_ch.v
//      |   |- asyncfifo.v
//      |   |- asyncfifo.v
//      |   |- syncfifo.v
//      |   |- syncfifo.v
//      |   |- asyncfifo.v
//      |   |- asyncfifo.v
//      |   |- fifo2axis.v
//      |- axi_rd.v
//      |- fifo2axis.v

`timescale 1ns/1ps
module axi_sdma
  (/*AUTOARG*/
   // Outputs
   s_axi_awready, s_axi_wready, s_axi_bresp, s_axi_bvalid,
   s_axi_arready, s_axi_rdata, s_axi_rresp, s_axi_rvalid, irq,
   m_axi_awid, m_axi_awvalid, m_axi_awaddr, m_axi_awlen, m_axi_awsize,
   m_axi_awburst, m_axi_awlock, m_axi_awcache, m_axi_awprot,
   m_axi_wvalid, m_axi_wdata, m_axi_wstrb, m_axi_wlast, m_axi_bready,
   m_axi_arid, m_axi_arvalid, m_axi_araddr, m_axi_arlen, m_axi_arsize,
   m_axi_arburst, m_axi_arlock, m_axi_arcache, m_axi_arprot,
   m_axi_rready, req_full, resp_q, resp_empty, tx_axis_tvalid,
   tx_axis_tdata, tx_axis_tkeep, tx_axis_tlast, tx_axis_tuser,
   rx_axis_tready, tag_tvalid, tag_tdata, tag_tlast, soft_rst,irq_wr,irq_rd,
   phy_loopback,
   // Inputs
   aresetn, s_axi_aclk, m_axi_aclk, ext_clk, s_axi_awaddr,
   s_axi_awvalid, s_axi_wdata, s_axi_wstrb, s_axi_wvalid,
   s_axi_bready, s_axi_araddr, s_axi_arvalid, s_axi_rready,
   m_axi_awready, m_axi_wready, m_axi_bid, m_axi_bresp, m_axi_bvalid,
   m_axi_arready, m_axi_rid, m_axi_rdata, m_axi_rresp, m_axi_rlast,
   m_axi_rvalid, req_wreq, req_din, resp_rdreq, tx_axis_tready,
   rx_axis_tvalid, rx_axis_tdata, rx_axis_tkeep, rx_axis_tlast,
   rx_axis_tuser, tag_tready, dev_id, phy_err, phy_link
   );

   parameter C_M_AXI_THREAD_ID_WIDTH       = 1;
   parameter C_M_AXI_ADDR_WIDTH            = 32;
   parameter C_M_AXI_DATA_WIDTH            = 128;
   parameter C_M_AXI_BURST_LEN             = 32;
   parameter C_S_AXI_ADDR_WIDTH = 32;
   parameter C_S_AXI_DATA_WIDTH = 32;
   parameter C_TIME_LIMIT = 0;
   parameter C_CMD = 0;
   parameter C_HW_DB = 0;

   localparam C_VERSION = 32'haba069d3;
   localparam C_DATA_WIDTH = (C_M_AXI_DATA_WIDTH + C_M_AXI_DATA_WIDTH/32 + 2);
   localparam C_ADDR_W = 10;

   // System Signals
   input aresetn;
   input s_axi_aclk;
   input m_axi_aclk;
   input ext_clk;

   // Axi-Lite Slave Signals
   input [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr;
   input 			  s_axi_awvalid;
   output 			  s_axi_awready;
   input [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata;
   input [C_S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb;
   input 			    s_axi_wvalid;
   output 			    s_axi_wready;
   output [1:0] 		    s_axi_bresp;
   output 			    s_axi_bvalid;
   input 			    s_axi_bready;
   input [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr;
   input 			    s_axi_arvalid;
   output 			    s_axi_arready;
   output [C_S_AXI_DATA_WIDTH-1:0]  s_axi_rdata;
   output [1:0] 		    s_axi_rresp;
   output 			    s_axi_rvalid;
   input 			    s_axi_rready;
   output 			    irq;
	 output               irq_wr;
	 output               irq_rd;
   // Master Interface Write Address
   output [C_M_AXI_THREAD_ID_WIDTH-1:0] m_axi_awid;
   input 				m_axi_awready;
   output 				m_axi_awvalid;
   output [C_M_AXI_ADDR_WIDTH-1:0] 	m_axi_awaddr;
   output [7:0] 			m_axi_awlen;
   output [2:0] 			m_axi_awsize;
   output [1:0] 			m_axi_awburst;
   output 				m_axi_awlock;
   output [3:0] 			m_axi_awcache;
   output [2:0] 			m_axi_awprot;

   // Master Interface Write Data
   input 				m_axi_wready;
   output 				m_axi_wvalid;
   output [C_M_AXI_DATA_WIDTH-1:0] 	m_axi_wdata;
   output [C_M_AXI_DATA_WIDTH/8-1:0] 	m_axi_wstrb;
   output 				m_axi_wlast;

   // Master Interface Write Response
   input [C_M_AXI_THREAD_ID_WIDTH-1:0] 	m_axi_bid;
   input [2-1:0] 			m_axi_bresp;
   input 				m_axi_bvalid;
   output 				m_axi_bready;

   // Master Interface Read Address
   output [C_M_AXI_THREAD_ID_WIDTH-1:0] m_axi_arid;
   input 				m_axi_arready;
   output 				m_axi_arvalid;
   output [C_M_AXI_ADDR_WIDTH-1:0] 	m_axi_araddr;
   output [7:0] 			m_axi_arlen;
   output [2:0] 			m_axi_arsize;
   output [1:0] 			m_axi_arburst;
   output [1:0] 			m_axi_arlock;
   output [3:0] 			m_axi_arcache;
   output [2:0] 			m_axi_arprot;

   // Master Interface Read Data
   input [C_M_AXI_THREAD_ID_WIDTH-1:0] 	m_axi_rid;
   input [C_M_AXI_DATA_WIDTH-1:0] 	m_axi_rdata;
   input [1:0] 				m_axi_rresp;
   input 				m_axi_rlast;
   input 				m_axi_rvalid;
   output 				m_axi_rready;

   // Cmd inf
   input 				req_wreq;
   input [127:0] 			req_din;
   output 				req_full;
   input 				resp_rdreq;
   output [127:0] 			resp_q;
   output 				resp_empty;

   // Data inf
   input 				tx_axis_tready;
   output 				tx_axis_tvalid;
   output [C_M_AXI_DATA_WIDTH-1:0] 	tx_axis_tdata;
   output [C_M_AXI_DATA_WIDTH/8-1:0] 	tx_axis_tkeep;
   output 				tx_axis_tlast; 
   output [65:0] 			tx_axis_tuser; 

   output 				rx_axis_tready; 
   input 				rx_axis_tvalid; 
   input [C_M_AXI_DATA_WIDTH-1:0] 	rx_axis_tdata;
   input [C_M_AXI_DATA_WIDTH/8-1:0] 	rx_axis_tkeep;
   input 				rx_axis_tlast; 
   input [65:0] 			rx_axis_tuser; 

   // Comp Tag inf
   input 				tag_tready;
   output 				tag_tvalid;
   output [23:0] 			tag_tdata;
   output 				tag_tlast;

   // ext reset and error
   output 				soft_rst;
   input [15:0] 			dev_id;
   input [3:0] 				phy_err;
   input 				phy_link;
   output 				phy_loopback;

   wire 				rst;
   wire 				bus_rst;
   reg 					m_rst_0;
   reg 					m_rst;
   wire 				req_wreq_mid;
   wire [127:0] 			req_din_mid;
   wire 				resp_rdreq_mid;

   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			cmdfifo_over;		// From I_WDATA_CH of wdata_ch.v
   wire			compfifo_empty;		// From I_WDATA_CH of wdata_ch.v
   wire			compfifo_over;		// From I_WDATA_CH of wdata_ch.v
   wire [7:0]		compfifo_q;		// From I_WDATA_CH of wdata_ch.v
   wire			compfifo_rdreq;		// From I_REG_CON of reg_con.v
   wire			err_tag;		// From I_WDATA_CH of wdata_ch.v
   wire			head_err;		// From I_WDATA_CH of wdata_ch.v
   wire			mrd_err_int;		// From I_AXI_RD of axi_rd.v
   wire			mwr_err_int;		// From I_AXI_WR of axi_wr.v
   wire			op;			// From I_BUS_CONV of bus_conv.v
   wire			op_read;		// From I_BUS_CONV of bus_conv.v
   wire			op_write;		// From I_BUS_CONV of bus_conv.v
   wire [C_ADDR_W-1:0]	raddr;			// From I_BUS_CONV of bus_conv.v
   wire			rcmd_empty;		// From I_RDATA_CH of rdata_ch.v
   wire [63:0]		rcmd_q;			// From I_RDATA_CH of rdata_ch.v
   wire			rcmd_rdreq;		// From I_AXI_RD of axi_rd.v
   wire [31:0]		rdata;			// From I_REG_CON of reg_con.v
   wire			rdma_en;		// From I_REG_CON of reg_con.v
   wire			rdma_f;			// From I_AXI_RD of axi_rd.v
   wire			rdma_f_ack;		// From I_REG_CON of reg_con.v
   wire			ready;			// From I_REG_CON of reg_con.v
   wire			reqfifo_empty;		// From I_CMD_DEAL of cmd_deal.v
   wire [31:0]		reqfifo_q;		// From I_CMD_DEAL of cmd_deal.v
   wire			reqfifo_rdreq;		// From I_REG_CON of reg_con.v
   wire [31:0]		respfifo_din;		// From I_REG_CON of reg_con.v
   wire			respfifo_full;		// From I_CMD_DEAL of cmd_deal.v
   wire			respfifo_wrreq;		// From I_REG_CON of reg_con.v
   wire [127:0]		rque_din;		// From I_REG_CON of reg_con.v
   wire			rque_empty;		// From I_RDATA_CH of rdata_ch.v
   wire			rque_full;		// From I_RDATA_CH of rdata_ch.v
   wire			rque_wrreq;		// From I_REG_CON of reg_con.v
   wire			rxfifo_empty;		// From I_WDATA_CH of wdata_ch.v
   wire [C_DATA_WIDTH-1:0] rxfifo_q;		// From I_WDATA_CH of wdata_ch.v
   wire			rxfifo_rdreq;		// From I_AXI_WR of axi_wr.v
   wire [8:0]		tagram_addra;		// From I_REG_CON of reg_con.v
   wire [31:0]		tagram_dina;		// From I_REG_CON of reg_con.v
   wire [31:0]		tagram_douta;		// From I_WDATA_CH of wdata_ch.v
   wire			tagram_wena;		// From I_REG_CON of reg_con.v
   wire [10:0]		txfifo_datacnt;		// From I_RDATA_CH of rdata_ch.v
   wire [C_DATA_WIDTH-1:0] txfifo_din;		// From I_AXI_RD of axi_rd.v
   wire			txfifo_wrreq;		// From I_AXI_RD of axi_rd.v
   wire [C_ADDR_W-1:0]	waddr;			// From I_BUS_CONV of bus_conv.v
   wire			wcmd_fifo_empty;	// From I_WDATA_CH of wdata_ch.v
   wire [63:0]		wcmd_q;			// From I_WDATA_CH of wdata_ch.v
   wire			wcmd_rdreq;		// From I_AXI_WR of axi_wr.v
   wire [31:0]		wdata;			// From I_BUS_CONV of bus_conv.v
   wire			wdma_en;		// From I_REG_CON of reg_con.v
   // End of automatics

   assign bus_rst = (~aresetn);
   assign rst = soft_rst;

   always@(posedge m_axi_aclk)
     begin
	m_rst_0 <= #1 rst;
	m_rst   <= #1 m_rst_0;
     end


   bus_conv #
     (
      .C_BUS_PROTOCAL  (0),
      .C_APB_ADDR_WIDTH (32),
      .C_APB_DATA_WIDTH (32),
      .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH),
      .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
      .C_DCR_AWIDTH (C_ADDR_W),
      .C_DCR_DWIDTH (32),
      .C_ADDR_W     (C_ADDR_W)
      )
   I_BUS_CONV
     (
      .apb_psel				(0),
      .apb_penable			(0),
      .apb_paddr			(0),
      .apb_pwrite			(0),
      .apb_pwdata			(0),
      .apb_pready			(),
      .apb_prdata			(),
      .dcr_read				(0),
      .dcr_write			(0),
      .dcr_abus				(0),
      .dcr_dbus				(0),
      .dcrdbus				(),
      .dcrack				(),
      .clk				(s_axi_aclk),
      .rst				(bus_rst),
      /*AUTOINST*/
      // Outputs
      .s_axi_awready			(s_axi_awready),
      .s_axi_wready			(s_axi_wready),
      .s_axi_bresp			(s_axi_bresp[1:0]),
      .s_axi_bvalid			(s_axi_bvalid),
      .s_axi_arready			(s_axi_arready),
      .s_axi_rdata			(s_axi_rdata[C_S_AXI_DATA_WIDTH-1:0]),
      .s_axi_rresp			(s_axi_rresp[1:0]),
      .s_axi_rvalid			(s_axi_rvalid),
      .op				(op),
      .op_write				(op_write),
      .op_read				(op_read),
      .waddr				(waddr[C_ADDR_W-1:0]),
      .raddr				(raddr[C_ADDR_W-1:0]),
      .wdata				(wdata[31:0]),
      // Inputs
      .s_axi_awaddr			(s_axi_awaddr[C_S_AXI_ADDR_WIDTH-1:0]),
      .s_axi_awvalid			(s_axi_awvalid),
      .s_axi_wdata			(s_axi_wdata[C_S_AXI_DATA_WIDTH-1:0]),
      .s_axi_wstrb			(s_axi_wstrb[C_S_AXI_DATA_WIDTH/8-1:0]),
      .s_axi_wvalid			(s_axi_wvalid),
      .s_axi_bready			(s_axi_bready),
      .s_axi_araddr			(s_axi_araddr[C_S_AXI_ADDR_WIDTH-1:0]),
      .s_axi_arvalid			(s_axi_arvalid),
      .s_axi_rready			(s_axi_rready),
      .ready				(ready),
      .rdata				(rdata[31:0]));

   reg_con #
     (/*AUTOINSTPARAM*/
      // Parameters
      .C_VERSION			(C_VERSION),
      .C_ADDR_W				(C_ADDR_W),
      .C_TIME_LIMIT			(C_TIME_LIMIT))
   I_REG_CON
     (
      .clk				(s_axi_aclk),
      .bus_rst				(bus_rst),
      /*AUTOINST*/
      // Outputs
      .ready				(ready),
      .rdata				(rdata[31:0]),
      .irq				(irq),
      .irq_wr				(irq_wr),
      .irq_rd				(irq_rd),			
      .reqfifo_rdreq			(reqfifo_rdreq),
      .respfifo_wrreq			(respfifo_wrreq),
      .respfifo_din			(respfifo_din[31:0]),
      .rque_wrreq			(rque_wrreq),
      .rque_din				(rque_din[127:0]),
      .compfifo_rdreq			(compfifo_rdreq),
      .soft_rst				(soft_rst),
      .wdma_en				(wdma_en),
      .rdma_en				(rdma_en),
      .rdma_f_ack			(rdma_f_ack),
      .phy_loopback			(phy_loopback),
      .tagram_wena			(tagram_wena),
      .tagram_addra			(tagram_addra[8:0]),
      .tagram_dina			(tagram_dina[31:0]),
      // Inputs
      .ext_clk				(ext_clk),
      .op				(op),
      .op_write				(op_write),
      .op_read				(op_read),
      .waddr				(waddr[C_ADDR_W-1:0]),
      .raddr				(raddr[C_ADDR_W-1:0]),
      .wdata				(wdata[31:0]),
      .reqfifo_q			(reqfifo_q[31:0]),
      .reqfifo_empty			(reqfifo_empty),
      .respfifo_full			(respfifo_full),
      .rque_full			(rque_full),
      .compfifo_q			(compfifo_q[7:0]),
      .compfifo_empty			(compfifo_empty),
      .rdma_f				(rdma_f),
      .dev_id				(dev_id[15:0]),
      .phy_err				(phy_err[3:0]),
      .phy_link				(phy_link),
      .head_err				(head_err),
      .compfifo_over			(compfifo_over),
      .cmdfifo_over			(cmdfifo_over),
      .err_tag				(err_tag),
      .mwr_err_int			(mwr_err_int),
      .mrd_err_int			(mrd_err_int),
      .tagram_douta			(tagram_douta[31:0]));

   cmd_deal
     I_CMD_DEAL
       (
	.req_wreq			(req_wreq_mid),
	.req_din			(req_din_mid),
	.resp_rdreq			(resp_rdreq_mid),
	/*AUTOINST*/
	// Outputs
	.req_full			(req_full),
	.resp_q				(resp_q[127:0]),
	.resp_empty			(resp_empty),
	.reqfifo_q			(reqfifo_q[31:0]),
	.reqfifo_empty			(reqfifo_empty),
	.respfifo_full			(respfifo_full),
	// Inputs
	.s_axi_aclk			(s_axi_aclk),
	.ext_clk			(ext_clk),
	.rst				(rst),
	.reqfifo_rdreq			(reqfifo_rdreq),
	.respfifo_wrreq			(respfifo_wrreq),
	.respfifo_din			(respfifo_din[31:0]));

   wdata_ch #
     (/*AUTOINSTPARAM*/
      // Parameters
      .C_M_AXI_DATA_WIDTH		(C_M_AXI_DATA_WIDTH))
   I_WDATA_CH
     (
      .rst           (m_rst),
      /*AUTOINST*/
      // Outputs
      .head_err				(head_err),
      .compfifo_over			(compfifo_over),
      .cmdfifo_over			(cmdfifo_over),
      .err_tag				(err_tag),
      .rx_axis_tready			(rx_axis_tready),
      .compfifo_q			(compfifo_q[7:0]),
      .compfifo_empty			(compfifo_empty),
      .tagram_douta			(tagram_douta[31:0]),
      .wcmd_fifo_empty			(wcmd_fifo_empty),
      .wcmd_q				(wcmd_q[63:0]),
      .rxfifo_empty			(rxfifo_empty),
      .rxfifo_q				(rxfifo_q[C_DATA_WIDTH-1:0]),
      // Inputs
      .m_axi_aclk			(m_axi_aclk),
      .s_axi_aclk			(s_axi_aclk),
      .ext_clk				(ext_clk),
      .rx_axis_tvalid			(rx_axis_tvalid),
      .rx_axis_tdata			(rx_axis_tdata[C_M_AXI_DATA_WIDTH-1:0]),
      .rx_axis_tkeep			(rx_axis_tkeep[C_M_AXI_DATA_WIDTH/8-1:0]),
      .rx_axis_tlast			(rx_axis_tlast),
      .rx_axis_tuser			(rx_axis_tuser[65:0]),
      .compfifo_rdreq			(compfifo_rdreq),
      .tagram_wena			(tagram_wena),
      .tagram_addra			(tagram_addra[8:0]),
      .tagram_dina			(tagram_dina[31:0]),
      .wcmd_rdreq			(wcmd_rdreq),
      .rxfifo_rdreq			(rxfifo_rdreq));

   axi_wr #
     (/*AUTOINSTPARAM*/
      // Parameters
      .C_M_AXI_THREAD_ID_WIDTH		(C_M_AXI_THREAD_ID_WIDTH),
      .C_M_AXI_BURST_LEN		(C_M_AXI_BURST_LEN),
      .C_M_AXI_ADDR_WIDTH		(C_M_AXI_ADDR_WIDTH),
      .C_M_AXI_DATA_WIDTH		(C_M_AXI_DATA_WIDTH),
      .C_DATA_WIDTH			(C_DATA_WIDTH))
   I_AXI_WR
     (
      .clk				(m_axi_aclk),
      .rst				(m_rst),
      /*AUTOINST*/
      // Outputs
      .mwr_err_int			(mwr_err_int),
      .m_axi_awid			(m_axi_awid[C_M_AXI_THREAD_ID_WIDTH-1:0]),
      .m_axi_awvalid			(m_axi_awvalid),
      .m_axi_awaddr			(m_axi_awaddr[C_M_AXI_ADDR_WIDTH-1:0]),
      .m_axi_awlen			(m_axi_awlen[7:0]),
      .m_axi_awsize			(m_axi_awsize[2:0]),
      .m_axi_awburst			(m_axi_awburst[1:0]),
      .m_axi_awlock			(m_axi_awlock),
      .m_axi_awcache			(m_axi_awcache[3:0]),
      .m_axi_awprot			(m_axi_awprot[2:0]),
      .m_axi_wvalid			(m_axi_wvalid),
      .m_axi_wdata			(m_axi_wdata[C_M_AXI_DATA_WIDTH-1:0]),
      .m_axi_wstrb			(m_axi_wstrb[C_M_AXI_DATA_WIDTH/8-1:0]),
      .m_axi_wlast			(m_axi_wlast),
      .m_axi_bready			(m_axi_bready),
      .wcmd_rdreq			(wcmd_rdreq),
      .rxfifo_rdreq			(rxfifo_rdreq),
      // Inputs
      .m_axi_awready			(m_axi_awready),
      .m_axi_wready			(m_axi_wready),
      .m_axi_bid			(m_axi_bid[C_M_AXI_THREAD_ID_WIDTH-1:0]),
      .m_axi_bresp			(m_axi_bresp[2-1:0]),
      .m_axi_bvalid			(m_axi_bvalid),
      .wcmd_fifo_empty			(wcmd_fifo_empty),
      .wcmd_q				(wcmd_q[63:0]),
      .wdma_en				(wdma_en),
      .rxfifo_empty			(rxfifo_empty),
      .rxfifo_q				(rxfifo_q[C_DATA_WIDTH-1:0]));

   rdata_ch#
     (/*AUTOINSTPARAM*/
      // Parameters
      .C_M_AXI_BURST_LEN		(C_M_AXI_BURST_LEN),
      .C_M_AXI_DATA_WIDTH		(C_M_AXI_DATA_WIDTH),
      .C_DATA_WIDTH			(C_DATA_WIDTH),
      .C_HW_DB				(C_HW_DB))
   I_RDATA_CH
     (
      .clk				(m_axi_aclk),
      .rst				(m_rst),
      /*AUTOINST*/
      // Outputs
      .tx_axis_tvalid			(tx_axis_tvalid),
      .tx_axis_tdata			(tx_axis_tdata[C_M_AXI_DATA_WIDTH-1:0]),
      .tx_axis_tkeep			(tx_axis_tkeep[C_M_AXI_DATA_WIDTH/8-1:0]),
      .tx_axis_tlast			(tx_axis_tlast),
      .tx_axis_tuser			(tx_axis_tuser[65:0]),
      .tag_tvalid			(tag_tvalid),
      .tag_tdata			(tag_tdata[23:0]),
      .tag_tlast			(tag_tlast),
      .rque_full			(rque_full),
      .rque_empty			(rque_empty),
      .rcmd_q				(rcmd_q[63:0]),
      .rcmd_empty			(rcmd_empty),
      .txfifo_datacnt			(txfifo_datacnt[10:0]),
      // Inputs
      .s_axi_aclk			(s_axi_aclk),
      .ext_clk				(ext_clk),
      .tx_axis_tready			(tx_axis_tready),
      .tag_tready			(tag_tready),
      .rque_wrreq			(rque_wrreq),
      .rque_din				(rque_din[127:0]),
      .rcmd_rdreq			(rcmd_rdreq),
      .txfifo_wrreq			(txfifo_wrreq),
      .txfifo_din			(txfifo_din[C_DATA_WIDTH-1:0]),
      .rdma_f				(rdma_f));

   axi_rd #
     (/*AUTOINSTPARAM*/
      // Parameters
      .C_M_AXI_THREAD_ID_WIDTH		(C_M_AXI_THREAD_ID_WIDTH),
      .C_M_AXI_BURST_LEN		(C_M_AXI_BURST_LEN),
      .C_M_AXI_ADDR_WIDTH		(C_M_AXI_ADDR_WIDTH),
      .C_M_AXI_DATA_WIDTH		(C_M_AXI_DATA_WIDTH),
      .C_DATA_WIDTH			(C_DATA_WIDTH))
   I_AXI_RD
     (
      .clk				(m_axi_aclk),
      .rst				(m_rst),
      /*AUTOINST*/
      // Outputs
      .mrd_err_int			(mrd_err_int),
      .m_axi_arid			(m_axi_arid[C_M_AXI_THREAD_ID_WIDTH-1:0]),
      .m_axi_arvalid			(m_axi_arvalid),
      .m_axi_araddr			(m_axi_araddr[C_M_AXI_ADDR_WIDTH-1:0]),
      .m_axi_arlen			(m_axi_arlen[7:0]),
      .m_axi_arsize			(m_axi_arsize[2:0]),
      .m_axi_arburst			(m_axi_arburst[1:0]),
      .m_axi_arlock			(m_axi_arlock[1:0]),
      .m_axi_arcache			(m_axi_arcache[3:0]),
      .m_axi_arprot			(m_axi_arprot[2:0]),
      .m_axi_rready			(m_axi_rready),
      .rcmd_rdreq			(rcmd_rdreq),
      .rdma_f				(rdma_f),
      .txfifo_wrreq			(txfifo_wrreq),
      .txfifo_din			(txfifo_din[C_DATA_WIDTH-1:0]),
      // Inputs
      .m_axi_arready			(m_axi_arready),
      .m_axi_rid			(m_axi_rid[C_M_AXI_THREAD_ID_WIDTH-1:0]),
      .m_axi_rdata			(m_axi_rdata[C_M_AXI_DATA_WIDTH-1:0]),
      .m_axi_rresp			(m_axi_rresp[1:0]),
      .m_axi_rlast			(m_axi_rlast),
      .m_axi_rvalid			(m_axi_rvalid),
      .rcmd_empty			(rcmd_empty),
      .rcmd_q				(rcmd_q[63:0]),
      .rdma_en				(rdma_en),
      .rdma_f_ack			(rdma_f_ack),
      .txfifo_datacnt			(txfifo_datacnt[10:0]));

   // disable cmd
   generate if(C_CMD == 0) begin
      assign req_wreq_mid = 1'h0;
      assign req_din_mid  = 128'h0;
      assign resp_rdreq_mid = 1'h0;
   end
   endgenerate
   // cmd loopback mode
   generate if(C_CMD == 1) begin
      fifo2axis #
	(
         .C_DATA_W       (128))
      I_CMD_LOOP
	(
         .clk        (ext_clk),
         .rst        (rst),
         .rd_en      (resp_rdreq_mid),
         .fifo_q     (resp_q),
         .empty      (resp_empty),
         .tvalid     (),
         .tready     (~req_full),
         .tdata      (req_din_mid),
         .tvalid_pre (),
         .wr_en      (req_wreq_mid));
   end
   endgenerate
   // cmd normal mode
   generate if(C_CMD == 2) begin
      assign req_wreq_mid = req_wreq;
      assign req_din_mid  = req_din;
      assign resp_rdreq_mid = resp_rdreq;
   end
   endgenerate

endmodule
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:


