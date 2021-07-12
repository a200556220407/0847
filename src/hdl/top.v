`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/30 13:21:54
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(/*autoarg*/
    //Inputs
    clk_100, pcie_rxn, pcie_rxp, pcie_refclk_clk_n, 
    pcie_refclk_clk_p, pcie_rst, 

    //Outputs
    DDR3_0_addr, DDR3_0_ba, DDR3_0_cas_n, DDR3_0_ck_n, 
    DDR3_0_ck_p, DDR3_0_cke, DDR3_0_cs_n, DDR3_0_dm, 
    DDR3_0_dq, DDR3_0_dqs_n, DDR3_0_dqs_p, DDR3_0_odt, 
    DDR3_0_ras_n, DDR3_0_reset_n, DDR3_0_we_n, 
    pcie_txn, pcie_txp);
  output [14:0]DDR3_0_addr;
  output [2:0]DDR3_0_ba;
  output DDR3_0_cas_n;
  output [0:0]DDR3_0_ck_n;
  output [0:0]DDR3_0_ck_p;
  output [0:0]DDR3_0_cke;
  output [0:0]DDR3_0_cs_n;
  output [7:0]DDR3_0_dm;
  inout [63:0]DDR3_0_dq;
  inout [7:0]DDR3_0_dqs_n;
  inout [7:0]DDR3_0_dqs_p;
  output [0:0]DDR3_0_odt;
  output DDR3_0_ras_n;
  output DDR3_0_reset_n;
  output DDR3_0_we_n;

  input clk_100;
  input [7:0]pcie_rxn;
  input [7:0]pcie_rxp;
  output [7:0]pcie_txn;
  output [7:0]pcie_txp;
  input [0:0]pcie_refclk_clk_n;
  input [0:0]pcie_refclk_clk_p;
  input pcie_rst;
   parameter C_M_AXI_THREAD_ID_WIDTH       = 1;
   parameter C_M_AXI_ADDR_WIDTH            = 32;
   parameter C_M_AXI_DATA_WIDTH            = 128;
   parameter C_M_AXI_BURST_LEN             = 32;
   parameter C_S_AXI_ADDR_WIDTH = 32;
   parameter C_S_AXI_DATA_WIDTH = 32;
   parameter C_TIME_LIMIT = 0;
   parameter C_CMD = 0;
   parameter C_HW_DB = 0;
   parameter   C_DATA_W = 128;
   localparam  C_KEEP_W = C_DATA_W/8;

  wire  irq_rd;
  wire  irq_wr;
  wire  [31:0]length;
  wire  [31:0]reg_irq_ctr;
  wire [127:0]req_din;
  wire  req_full;
  wire  [31:0]req_irq_ctr_rd;
  wire req_wreq;
  wire  resp_empty;
  wire  [127:0]resp_q;
  wire resp_rdreq;
  wire [127:0]rx_axis_tdata;
  wire [15:0]rx_axis_tkeep;
  wire rx_axis_tlast;
  wire  rx_axis_tready;
  wire [65:0]rx_axis_tuser;
  wire rx_axis_tvalid;
  wire  [31:0]slv_reg;
  wire [31:0]srio_mon_status;
  wire [31:0]srio_speed;
  wire  [31:0]start_clear;
  wire  [31:0]tag_num;
  wire  [127:0]tx_axis_tdata;
  wire  [15:0]tx_axis_tkeep;
  wire  tx_axis_tlast;
  wire tx_axis_tready = 1;
  wire  [65:0]tx_axis_tuser;
  wire  tx_axis_tvalid;
  reg [2:0]usr_irq_req;
	wire  pcie_user_clk;

  reg[31:0]cnt_rst;
	reg      rst;
	wire     clk;
(* keep="true" *)	reg      irq_flag;
(* keep="true" *)	wire     irq_rd;
(* keep="true" *)	reg      reg_irq_flag;
(* keep="true" *)  wire     reg_irq;
(* keep="true" *)  reg      req_irq_flag_rd;

   // Comp Tag inf
   wire				tag_tready = 1;
   wire 			tag_tvalid;
   wire [23:0]tag_tdata;
   wire 			tag_tlast;
   // ext reset and error
   wire 				soft_rst;
   wire[15:0] 	dev_id = 1;
   wire[3:0] 		phy_err = 0;
   wire				  phy_link = 1;
   wire 				phy_loopback;

(* keep="true" *)  wire   	                    ss_axis_tvalid;
                   wire  	                      ss_axis_tready;
(* keep="true" *)  wire   	                    ss_axis_tlast;
                   wire  [C_DATA_W - 1:0]       ss_axis_tdata;
                   wire  [C_KEEP_W - 1 : 0]     ss_axis_tkeep = 16'hffff;

(*keep = "true"*)wire 	                    s_axis_tvalid;
(*keep = "true"*)wire 	                    s_axis_tready;
(*keep = "true"*)wire 	                    s_axis_tlast;
(*keep = "true"*)wire [65:0]                s_axis_tuser;
(*keep = "true"*)wire [C_DATA_W - 1:0]      s_axis_tdata;
(*keep = "true"*)wire   [C_KEEP_W - 1 : 0]  s_axis_tkeep;




assign                    rx_axis_tvalid    =  s_axis_tvalid;
assign                    rx_axis_tlast     =  s_axis_tlast;
assign                    rx_axis_tdata     =  s_axis_tdata;
assign                    rx_axis_tuser     =  s_axis_tuser;
assign                    rx_axis_tkeep[15:0]  =  s_axis_tkeep;                    
assign                    s_axis_tready           =  rx_axis_tready;

assign                    clk = pcie_user_clk;

wire[97:0]probe0_ila;
ila_2 u_ila_2 (
	.clk(pcie_user_clk), // input wire clk
	.probe0(probe0_ila) // input wire [95:0] probe0
);
assign probe0_ila[0] = req_irq_flag_rd;
assign probe0_ila[3:1] = usr_irq_req;
assign probe0_ila[4] = irq_rd;
assign probe0_ila[30:5] = req_irq_ctr_rd[25:0];
assign probe0_ila[31] = 0;
assign probe0_ila[63:32] = tag_num;
assign probe0_ila[90:64] = length[26:0];
assign probe0_ila[92:91] = reg_irq_ctr[1:0];
assign probe0_ila[93] = irq_flag;
assign probe0_ila[95:94] = 0;
assign probe0_ila[96] = reg_irq;
assign probe0_ila[97] = reg_irq_flag;




always@(posedge pcie_user_clk)
	if(irq_wr)
    irq_flag <= 1;
	else 	if(slv_reg == 1)
    irq_flag <= 0;

always@(posedge pcie_user_clk)
	if(reg_irq)
    reg_irq_flag <= 1;
	else 	if(reg_irq_ctr == 1)
    reg_irq_flag <= 0;

always@(posedge pcie_user_clk)
	if(irq_rd)
    req_irq_flag_rd <= 1;
	else 	if(req_irq_ctr_rd == 1)
    req_irq_flag_rd <= 0;


always@(posedge pcie_user_clk)
	if(slv_reg == 1)
    usr_irq_req[0] <= 1'b0;
	else 	if(slv_reg == 2)
    usr_irq_req[0] <= irq_flag;

always@(posedge pcie_user_clk)
	if(reg_irq_ctr == 1)
    usr_irq_req[1] <= 1'b0;
	else 	if(reg_irq_ctr == 2)
    usr_irq_req[1] <= reg_irq_flag;

always@(posedge pcie_user_clk)
	if(req_irq_ctr_rd == 1)
    usr_irq_req[2] <= 1'b0;
	else 	if(req_irq_ctr_rd == 2)
    usr_irq_req[2] <= req_irq_flag_rd;


always@(posedge pcie_user_clk)
	if(cnt_rst == 100000000)
		rst = 1'b0;
	else
    rst = 1'b1;
    
always@(posedge pcie_user_clk)
	if(start_clear[1])begin
		if(cnt_rst >= 100000000)	
		  cnt_rst <= cnt_rst;
		else
      cnt_rst <= cnt_rst + 1;
	end
	else 
		  cnt_rst <= 0;
		
wire   wr_en;
wire[127:0]din;
wire   al_full;
wire   empty;
wire[127:0]dout;
wire   rd_en;

data_gen #(.DATA_OFFSET(0)) 
u_srio_data_gen(
    //Inputs
    .clk(clk), 
		.rst(rst),//rst 
		.al_full(al_full), 

    //Outputs
    .din(din),
		.wr_last(),	
		.wr_en(wr_en));

fifo_generator_0 u_srio_data_fifo (
  .rst(rst),                  // input wire rst
  .wr_clk(clk),            // input wire wr_clk
  .rd_clk(clk),            // input wire rd_clk
  .din(din),                  // input wire [63 : 0] din
  .wr_en(wr_en),              // input wire wr_en
  .rd_en(rd_en),              // input wire rd_en
  .dout(dout),                // output wire [127 : 0] dout
  .full(),                // output wire full
  .almost_full(al_full),  // output wire almost_full
  .empty(empty),              // output wire empty
  .wr_rst_busy(),  // output wire wr_rst_busy
  .rd_rst_busy()  // output wire rd_rst_busy
);

//fifo_axis #(
//        .C_DATA_W   (C_DATA_W             ))
//u_srio_fifo_axis(
//        //Inputs
//        .clk        (clk                  ),
//        .rst        (rst                  ),
//        .fifo_q     (dout[C_DATA_W-1:0] ),
//        .empty      (empty                ),
//        .tready     (ss_axis_tready               ),
//        //Outputs
//        .rd_en      (rd_en                ),
//        .tvalid_pre (           ),
//        .tdata      (ss_axis_tdata[C_DATA_W-1:0]  ),
//        .tvalid     (ss_axis_tvalid               ),
//        .wr_en      (                ));

fifoio2stream(
    .log_clk(clk), 
		.rst(rst),  
		.dstid(0),  
		.sorid(0),  
		.txio_tready(ss_axis_tready),  
		.fifoio2stream_out(dout),  
    .fifoio2stream_empty(empty),  

    //Outputs
    .txio_tuser(),  
		.txio_tvalid(ss_axis_tvalid),  
		.txio_tlast(),  
		.txio_tdata(ss_axis_tdata),  
    .txio_tkeep(),  
		.fifoio2stream_reqrd(rd_en));

//Instance:pack_stream.v
pack_stream #(
        .C_DATA_W       (C_DATA_W                        ),
        .C_ID_NUM       (0                        ))
u_srio_pack_stream(
        //Inputs
        .ss_axis_tvalid (ss_axis_tvalid                  ),
        .clk            (clk                             ),
        .s_axis_tready  (s_axis_tready                   ),
        .rst            (rst                             ),
        .tag_num        (tag_num[31:0]                   ),
        .length         (length[31:0]                    ),
        .ss_axis_tdata  (ss_axis_tdata[C_DATA_W - 1:0]   ),
        .start_clear    (start_clear[31:0]               ),
        .ss_axis_tkeep  (ss_axis_tkeep[C_KEEP_W - 1 : 0] ),
        .ss_axis_tlast  (ss_axis_tlast                   ),
        //Outputs
        .s_axis_tuser   (s_axis_tuser[65:0]              ),
        .s_axis_tvalid  (s_axis_tvalid                   ),
        .ss_axis_tready (ss_axis_tready                  ),
        .s_axis_tdata   (s_axis_tdata[C_DATA_W - 1:0]    ),
        .s_axis_tlast   (s_axis_tlast                    ),
        .s_axis_tkeep   (s_axis_tkeep[C_KEEP_W - 1 : 0]  ));


//Instance:../bd/design_1/hdl/design_1_wrapper.v
design_1
u_design_1(/*autoinst*/
        //Inputs
        .phy_link          (phy_link               ),
        .tag_tready        (tag_tready             ),
        .srio_mon_status   (srio_mon_status[31:0]  ),
        .pcie_rxn          (pcie_rxn[7:0]          ),
        .pcie_rxp          (pcie_rxp[7:0]          ),
        .req_din           (req_din[127:0]         ),
        .rx_axis_tvalid    (rx_axis_tvalid         ),
        .rx_axis_tkeep     (rx_axis_tkeep[15:0]    ),
        .rx_axis_tuser     (rx_axis_tuser[65:0]    ),
        .rx_axis_tlast     (rx_axis_tlast          ),
        .pcie_refclk_clk_n (pcie_refclk_clk_n[0:0] ),
        .pcie_refclk_clk_p (pcie_refclk_clk_p[0:0] ),
        .resp_rdreq        (resp_rdreq             ),
        .srio_speed        (srio_speed[31:0]       ),
        .pcie_rst          (pcie_rst               ),
        .usr_irq_req       (usr_irq_req[2:0]       ),
        .phy_err           (phy_err[3:0]           ),
        .req_wreq          (req_wreq               ),
        .tx_axis_tready    (tx_axis_tready         ),
        .dev_id            (dev_id[15:0]           ),
        .clk_100           (clk_100                ),
        .rx_axis_tdata     (rx_axis_tdata[127:0]   ),
        //Outputs
        .tag_tvalid        (tag_tvalid             ),
        .resp_empty        (resp_empty             ),
        .reg_irq_ctr       (reg_irq_ctr[31:0]      ),
        .DDR3_0_ras_n      (DDR3_0_ras_n           ),
        .tag_tlast         (tag_tlast              ),
        .soft_rst          (soft_rst               ),
        .pcie_user_clk     (pcie_user_clk          ),
        .DDR3_0_odt        (DDR3_0_odt[0:0]        ),
        .tag_num           (tag_num[31:0]          ),
        .start_clear       (start_clear[31:0]      ),
        .slv_reg           (slv_reg[31:0]          ),
        .req_full          (req_full               ),
        .DDR3_0_dm         (DDR3_0_dm[7:0]         ),
        .req_irq_ctr_rd    (req_irq_ctr_rd[31:0]   ),
        .DDR3_0_cke        (DDR3_0_cke[0:0]        ),
        .DDR3_0_dq         (DDR3_0_dq[63:0]        ),
        .tx_axis_tdata     (tx_axis_tdata[127:0]   ),
        .DDR3_0_reset_n    (DDR3_0_reset_n         ),
        .DDR3_0_we_n       (DDR3_0_we_n            ),
        .tag_tdata         (tag_tdata[23:0]        ),
        .pcie_txn          (pcie_txn[7:0]          ),
        .irq_rd            (irq_rd                 ),
        .length            (length[31:0]           ),
        .DDR3_0_cas_n      (DDR3_0_cas_n           ),
        .DDR3_0_dqs_n      (DDR3_0_dqs_n[7:0]      ),
        .DDR3_0_ck_n       (DDR3_0_ck_n[0:0]       ),
        .DDR3_0_ck_p       (DDR3_0_ck_p[0:0]       ),
        .resp_q            (resp_q[127:0]          ),
        .phy_loopback      (phy_loopback           ),
        .rx_axis_tready    (rx_axis_tready         ),
        .irq_wr            (irq_wr                 ),
        .DDR3_0_cs_n       (DDR3_0_cs_n[0:0]       ),
        .tx_axis_tkeep     (tx_axis_tkeep[15:0]    ),
        .tx_axis_tuser     (tx_axis_tuser[65:0]    ),
        .tx_axis_tlast     (tx_axis_tlast          ),
        .DDR3_0_ba         (DDR3_0_ba[2:0]         ),
        .tx_axis_tvalid    (tx_axis_tvalid         ),
        .pcie_txp          (pcie_txp[7:0]          ),
        .DDR3_0_dqs_p      (DDR3_0_dqs_p[7:0]      ),
        .DDR3_0_addr       (DDR3_0_addr[14:0]      ));


endmodule
