
`timescale 1ns/1ps
module axi_rd
  (/*AUTOARG*/
   // Outputs
   mrd_err_int, m_axi_arid, m_axi_arvalid, m_axi_araddr, m_axi_arlen,
   m_axi_arsize, m_axi_arburst, m_axi_arlock, m_axi_arcache,
   m_axi_arprot, m_axi_rready, rcmd_rdreq, rdma_f, txfifo_wrreq,
   txfifo_din,
   // Inputs
   clk, rst, m_axi_arready, m_axi_rid, m_axi_rdata, m_axi_rresp,
   m_axi_rlast, m_axi_rvalid, rcmd_empty, rcmd_q, rdma_en, rdma_f_ack,
   txfifo_datacnt
   );

   function integer log2;
      input integer depth;
      begin
	 log2=0;
	 while((1<<log2)<depth)
	   log2=log2+1;
      end
   endfunction

   parameter C_M_AXI_THREAD_ID_WIDTH = 1;
   parameter C_M_AXI_BURST_LEN = 32;
   parameter C_M_AXI_ADDR_WIDTH = 32;
   parameter C_M_AXI_DATA_WIDTH = 128;
   parameter C_DATA_WIDTH = 134;
   localparam C_BURST_SIZE = C_M_AXI_BURST_LEN * (C_M_AXI_DATA_WIDTH/8);
   localparam C_SIZE = log2(C_M_AXI_DATA_WIDTH/8);
   localparam C_BURST_CNT_W = log2(C_M_AXI_BURST_LEN);


   // System Signals
   input                             clk;
   input                             rst;
   output 			     mrd_err_int;
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

   output 				rcmd_rdreq;
   input 				rcmd_empty;
   input [63:0] 			rcmd_q;
   input 				rdma_en;
   output 				rdma_f;
   input 				rdma_f_ack;

   output 				txfifo_wrreq;
   output [C_DATA_WIDTH-1:0] 		txfifo_din;
   input [10:0] 			txfifo_datacnt;

   reg [C_M_AXI_ADDR_WIDTH-1:0] 	m_axi_araddr;
   reg [7:0] 				m_axi_arlen;
   reg 					m_axi_arvalid;
   reg 					txfifo_wrreq;
   reg [C_DATA_WIDTH-1:0] 		txfifo_din;
   reg                                  rready;
   reg 					mrd_err_int;

   reg [3:0] 				state;
   reg [3:0] 				state_n;
   reg [30:0] 				cnt_len;
   reg [10:0] 				data_cnt;
   reg                                  rdma_f;
   reg                                  cmd_valid;
   reg 					flag_valid;
   wire 				flagfifo_wrreq;
   wire 				dma_f;
   wire                                 flagfifo_full;

   wire 				cmd_f;
   wire 				addr_req_valid;
   wire 				data_valid;
   wire 				data_ack_f;
   wire 				req_valid;
   wire [31:0] 				cmd_addr;
   wire 				cmd_irq_en;
   wire [30:0] 				cmd_len;

   localparam C_IDLE = 4'h1;
   localparam C_CMD  = 4'h2;
   localparam C_REQ  = 4'h4;
   localparam C_NOP  = 4'h8;


   always@(posedge clk)
     begin
	if(rst)
	  state <= #1 C_IDLE;
	else
	  state <= #1 state_n;
     end

   always@(*)
     case(state)
       C_IDLE : state_n = rcmd_rdreq ? C_CMD : C_IDLE;
       C_CMD  : state_n = C_REQ;
       C_REQ  : state_n = addr_req_valid ? C_NOP : C_REQ;
       C_NOP  : begin
	  if(cmd_f && ~flagfifo_full) 
	    state_n = C_IDLE;
	  else if(~flagfifo_full)
	    state_n = C_REQ;
	  else
	    state_n = C_NOP;
       end
       default: state_n = C_IDLE;
     endcase

   assign rcmd_rdreq = (state == C_IDLE) && rdma_en && (~rcmd_empty) && (~flagfifo_full);
   assign addr_req_valid = m_axi_arready & m_axi_arvalid;
   assign data_valid = m_axi_rvalid & m_axi_rready;
   assign data_ack_f = data_valid & m_axi_rlast;
   assign cmd_f = cmd_irq_en & (cnt_len == 0);
   assign flagfifo_wrreq = (state == C_NOP) && (~flagfifo_full);
   assign req_valid = (data_cnt < 448); // 32 reqeset(1024 - 32*(16+1) - 32=448)
   assign cmd_addr = rcmd_q[63:32];
   assign cmd_irq_en = rcmd_q[31];
   assign cmd_len = rcmd_q[29:0];

   always@(posedge clk)
     begin
	if(rst)
	  data_cnt <= #1 10'h0;
	else
	  data_cnt <= #1 txfifo_datacnt;
     end

   always@(posedge clk)
     begin
	if(rst)
	  cmd_valid <= #1 31'h0;
	else
	  cmd_valid <= #1 rcmd_rdreq;
     end

   always@(posedge clk)
     begin
	if(rst)
	  cnt_len <= #1 31'h0;
	else if(cmd_valid)
	  cnt_len <= #1 cmd_len;
        else if(addr_req_valid && cnt_len >= C_BURST_SIZE)
	  cnt_len <= #1 cnt_len - C_BURST_SIZE;
        else if(addr_req_valid)
	  cnt_len <= #1 31'h0;
     end

   always@(posedge clk)
     begin
	if(rst)
	  m_axi_araddr <= #1 32'h0;
	else if(cmd_valid)
	  m_axi_araddr <= #1 cmd_addr;
        else if(addr_req_valid)
	  m_axi_araddr <= #1 m_axi_araddr + C_BURST_SIZE;
     end

   always@(posedge clk)
     begin
	if(rst)
	  m_axi_arlen <= #1 8'h0;
	else if(cnt_len >= C_BURST_SIZE)
	  m_axi_arlen <= #1 (C_M_AXI_BURST_LEN-1);
        else if(cnt_len > 0)
	  m_axi_arlen <= #1 cnt_len[C_SIZE+7:C_SIZE]-1;
     end

   // note: arvalid timing
   always@(posedge clk)
     begin
	if(rst)
	  m_axi_arvalid <= #1 1'h0;
	else if(addr_req_valid)
	  m_axi_arvalid <= #1 1'h0;
	else if((state == C_REQ) && req_valid)
	  m_axi_arvalid <= #1 1'h1;
     end

   always@(posedge clk)
     begin
	if(rst)
	  rready <= #1 1'h1;
	else
	  rready <= #1 (data_cnt < 1016);
     end

   assign m_axi_rready = rready;
   assign m_axi_arid = 0;
   assign m_axi_arsize = C_SIZE;
   assign m_axi_arburst = 2'h1;
   assign m_axi_arlock = 1'h0;
   assign m_axi_arcache = 4'h3;
   assign m_axi_arprot = 3'h0;

   // txfifo interface
   always@(posedge clk)
     begin
	if(rst)
	  txfifo_wrreq <= #1 1'h0;
	else
	  txfifo_wrreq <= #1 data_valid;
     end

   always@(posedge clk)
     begin
	if(rst)
	  txfifo_din <= #1 {C_DATA_WIDTH{1'h0}};
	else 
	  txfifo_din <= #1 {1'h0,m_axi_rlast,{(C_DATA_WIDTH/32){1'h1}},m_axi_rdata};
     end
   
   // error out
   always@(posedge clk)
     begin
	if(rst)
	  mrd_err_int <= #1 1'h0;
	else if(m_axi_rready && m_axi_rvalid)
	  mrd_err_int <= #1 (m_axi_rresp != 0);
     end

   // irq deal  
   always@(posedge clk)
     begin
	if(rst)
	  flag_valid <= #1 1'h0;
	else
	  flag_valid <= #1 data_ack_f;
     end

   always@(posedge clk)
     begin
	if(rst)
	  rdma_f <= #1 1'h0;
	else if(rdma_f_ack)
	  rdma_f <= #1 1'h0;
	else if(flag_valid && dma_f)
	  rdma_f <= #1 1'h1;
     end

   syncfifo #
     (
      .C_RAM_TYPE (0),
      .C_DATA_W   (1),
      .C_ADDR_W   (5))
   I_FLAG_FIFO
     (
      .clk       (clk),
      .rst       (rst),
      .din       (cmd_f),
      .push_req  (flagfifo_wrreq),
      .pop_req   (data_ack_f),
      .dout      (dma_f),
      .full      (flagfifo_full),
      .empty     ()
      );

endmodule


