
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
   rx_axis_tready, tag_tvalid, tag_tdata, tag_tlast, soft_rst,
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

 

endmodule
// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("")
// verilog-library-extensions:(".v" ".h")
// End:


