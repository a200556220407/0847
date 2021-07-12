// fifo data bit define
// [C_M_AXI_DATA_WIDTH-1:0] data
// [C_M_AXI_DATA_WIDTH+C_M_AXI_DATA_WIDTH/32-1:C_M_AXI_DATA_WIDTH] dword byte enable
// [C_M_AXI_DATA_WIDTH+C_M_AXI_DATA_WIDTH/32] data eof flag
// [C_M_AXI_DATA_WIDTH+C_M_AXI_DATA_WIDTH/32+1] data interrupt flag


`timescale 1ns/1ps
module axi_wr
  (/*AUTOARG*/
   // Outputs
   mwr_err_int, m_axi_awid, m_axi_awvalid, m_axi_awaddr, m_axi_awlen,
   m_axi_awsize, m_axi_awburst, m_axi_awlock, m_axi_awcache,
   m_axi_awprot, m_axi_wvalid, m_axi_wdata, m_axi_wstrb, m_axi_wlast,
   m_axi_bready, wcmd_rdreq, rxfifo_rdreq,
   // Inputs
   clk, rst, m_axi_awready, m_axi_wready, m_axi_bid, m_axi_bresp,
   m_axi_bvalid, wcmd_fifo_empty, wcmd_q, wdma_en, rxfifo_empty,
   rxfifo_q
   );

   function integer log2;
      input integer depth;
      begin
	 log2=0;
	 while((1<<log2)<depth)
	   log2=log2+1;
      end
   endfunction

   parameter C_M_AXI_THREAD_ID_WIDTH       = 1;
   parameter C_M_AXI_BURST_LEN = 32;
   parameter C_M_AXI_ADDR_WIDTH            = 32;
   parameter C_M_AXI_DATA_WIDTH            = 128;
   parameter C_DATA_WIDTH                  = 134;
   localparam C_BURST_SIZE = C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8);
   localparam C_SIZE = log2(C_M_AXI_DATA_WIDTH/8);

   function [C_M_AXI_DATA_WIDTH/8-1:0] calc_be;
      input [C_M_AXI_DATA_WIDTH/32-1:0] dw_be;
      integer 				i;
      begin
	 for(i=0;i<C_M_AXI_DATA_WIDTH/8;i=i+1)
           calc_be[i] = dw_be[i/4];
      end
   endfunction

   // System Signals
   input                               clk;
   input                               rst;
   output 			       mwr_err_int;

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


   output 				wcmd_rdreq;
   input 				wcmd_fifo_empty;
   input [63:0] 			wcmd_q;
   input 				wdma_en;

   output 				rxfifo_rdreq;
   input 				rxfifo_empty;
   input [C_DATA_WIDTH-1:0] 		rxfifo_q;
   
   localparam C_IDLE = 4'h1;
   localparam C_CMD  = 4'h2;
   localparam C_CALC = 4'h4;
   localparam C_REQ  = 4'h8;
   localparam C_DATA = 2'h2;


   reg [30:0] 				cnt_len;
   reg [C_M_AXI_ADDR_WIDTH-1:0] 	m_axi_awaddr;
   reg [7:0] 				m_axi_awlen;
   reg 					m_axi_awvalid;
   reg [C_M_AXI_DATA_WIDTH-1:0] 	m_axi_wdata;
   reg [C_M_AXI_DATA_WIDTH/8-1:0] 	m_axi_wstrb;
   reg 					m_axi_wlast;


   reg [3:0] 				state;
   reg [3:0] 				state_n;
   reg [1:0] 				dstate;
   reg [1:0] 				dstate_n;
   wire 				dma_f;
   wire 				addr_req_valid;
   wire 				data_valid;
   wire 				data_ack_f;
   wire [31:0] 				cmd_addr;
   wire [30:0] 				cmd_len;
   wire [C_M_AXI_DATA_WIDTH/8-1:0] 	data_be;
   reg [8:0] 				cnt_data;
   reg 					mwr_err_int;

   reg [7:0] 				cnt_pre_req;
   wire 				data_eof;
   wire 				empty;
   wire 				wr_en_pre;
   wire                                 wvalid;
   wire                                 wready;

   always@(posedge clk)
     begin
	if(rst)
	  state <= #1 C_IDLE;
	else
	  state <= #1 state_n;
     end

   always@(*)
     case(state)
       C_IDLE : state_n = (wdma_en & ~wcmd_fifo_empty) ? C_CMD : C_IDLE;
       C_CMD  : state_n = C_CALC;
       C_CALC : state_n = cnt_len ? C_REQ : C_IDLE;
       C_REQ  : state_n = addr_req_valid ? C_CALC : C_REQ;
       default: state_n = C_IDLE;
     endcase

   always@(posedge clk)
     begin
	if(rst)
	  dstate <= #1 C_IDLE;
	else
	  dstate <= #1 dstate_n;
     end

   always@(*)
     case(dstate)
       C_IDLE : dstate_n = (cnt_pre_req) ? C_DATA : C_IDLE;
       C_DATA : dstate_n = (data_ack_f && (cnt_pre_req == 0)) ? C_IDLE : C_DATA;
       default: dstate_n = C_IDLE;
     endcase

   assign cmd_addr = wcmd_q[63:32];
   assign cmd_len = wcmd_q[28:C_SIZE];
   assign data_eof = rxfifo_q[C_DATA_WIDTH-2] || (cnt_data == C_M_AXI_BURST_LEN);
   assign data_be = calc_be(rxfifo_q[(C_M_AXI_DATA_WIDTH+C_M_AXI_DATA_WIDTH/32-1):C_M_AXI_DATA_WIDTH]);
   assign data_int = rxfifo_q[C_DATA_WIDTH-1];

   assign wcmd_rdreq = (state == C_IDLE) && wdma_en && (~wcmd_fifo_empty);
   assign addr_req_valid = m_axi_awready & m_axi_awvalid;
   assign data_valid = m_axi_wvalid & m_axi_wready;
   assign data_ack_f = data_valid & m_axi_wlast;
   assign wready = (cnt_pre_req != 0) && m_axi_wready;
   assign m_axi_wvalid = (cnt_pre_req != 0) && wvalid;
   assign dma_f = data_int & data_ack_f;

   always@(posedge clk)
     begin
	if(rst)
	  cnt_len <= #1 31'h0;
	else if(state == C_CMD)
	  cnt_len <= #1 cmd_len;
	else if(state == C_CALC && cnt_len >= C_M_AXI_BURST_LEN)
	  cnt_len <= #1 cnt_len - C_M_AXI_BURST_LEN;
	else if(state == C_CALC)
	  cnt_len <= #1 31'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  m_axi_awaddr <= #1 32'h0;
	else if(state == C_CMD)
	  m_axi_awaddr <= #1 cmd_addr;
	else if(addr_req_valid)
	  m_axi_awaddr <= #1 m_axi_awaddr + C_BURST_SIZE;
     end

   always@(posedge clk)
     begin
	if(rst)
	  m_axi_awlen <= #1 8'h0;
	else if(state == C_CALC && cnt_len >= C_M_AXI_BURST_LEN)
	  m_axi_awlen <= #1 (C_M_AXI_BURST_LEN-1);
	else if(state == C_CALC)
	  m_axi_awlen <= #1 cnt_len[7:0] - 1'h1;
     end
   
   always@(posedge clk)
     begin
	if(rst)
	  m_axi_awvalid <= #1 1'h0;
	else if(addr_req_valid)
	  m_axi_awvalid <= #1 1'h0;
	else if(state == C_REQ)
	  m_axi_awvalid <= #1 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  cnt_pre_req <= #1 8'h0;
	else if(addr_req_valid && (~data_ack_f))
	  cnt_pre_req <= #1 cnt_pre_req + 1'h1;
        else if((~addr_req_valid) && data_ack_f)
	  cnt_pre_req <= #1 cnt_pre_req - 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  cnt_data <= #1 9'h0;
        else if(data_eof && rxfifo_rdreq)
	  cnt_data <= #1 9'h1;
        else if(data_eof && m_axi_wready)
	  cnt_data <= #1 9'h0;
	else if(rxfifo_rdreq)
	  cnt_data <= #1 cnt_data + 1'h1;
     end

   fifo2axis #
     (
      .C_DATA_W	 (1))
   I_FIFO2AXIS
     (
      .clk        (clk),
      .rst        (rst),
      .rd_en      (rxfifo_rdreq), 
      .fifo_q     (1'h0),
      .empty      (rxfifo_empty),
      .tvalid     (wvalid),
      .tready     (wready),
      .tdata      (),
      .tvalid_pre (wr_en_pre),
      .wr_en      ());

   always@(posedge clk)
     begin
	if(rst)
	  begin
	     m_axi_wdata <= #1 {C_M_AXI_DATA_WIDTH{1'h0}};
             m_axi_wstrb <= #1 {(C_M_AXI_DATA_WIDTH/8){1'h1}};
          end
	else if(wr_en_pre)
	  begin
	     m_axi_wdata <= #1 rxfifo_q[C_M_AXI_DATA_WIDTH-1:0];
             m_axi_wstrb <= #1 data_be;
          end
     end

   always@(posedge clk)
     begin
	if(rst)
	  m_axi_wlast <= #1 1'h0;
	else if(wr_en_pre)
	  m_axi_wlast <= #1 data_eof;
     end

   // error out
   always@(posedge clk)
     begin
	if(rst)
	  mwr_err_int <= #1 1'h0;
	else if(m_axi_bvalid && m_axi_bready)
	  mwr_err_int <= #1 (m_axi_bresp != 0);
     end

   assign m_axi_awid = 0;
   assign m_axi_awsize = C_SIZE;
   assign m_axi_awburst = 2'h1;
   assign m_axi_awlock = 1'h0;
   assign m_axi_awcache = 4'h3;
   assign m_axi_awprot = 3'h0;
   assign m_axi_bready = 1'h1;

endmodule


