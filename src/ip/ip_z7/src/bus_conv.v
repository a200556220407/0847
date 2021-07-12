//---------------------------------------------------------
// File        : bus_conv.v
// Author      :
// Created     : 2013-12-01
// Company     :
//
//---------------------------------------------------------
// Description: 
// This is a bus convert module, the supportting 
// input interface is AXI-Lite, APB and DCR interface.
// Do not support write data mark or read data mark.
//---------------------------------------------------------
// parameter:
// C_BUS_PROTOCAL  0: AXI-Lite
//                 1: APB
//                 2: DCR
// 
//---------------------------------------------------------
// Output Timing 
// Note: 1 Ready signal must be arrive within 8 cycle after op start.
//       2 Read data must not be channged if no new read op occur.
// Write Timing: 
//              |--|  |--|  |--|  |--| 
// clk     -----|  |--|  |--|  |--|  |--
//              |-----------|
// op      -----|           |-----------
//              |-----------|
// op_write-----|           |-----------
//              |***********|
// waddr   -----|***********|-----------
//              |***********|
// wdata   -----|***********|-----------
//                    |-----|
// ready   -----------|     |-----------
// 
// Read Timing:
//              |--|  |--|  |--|  |--|  
// clk     -----|  |--|  |--|  |--|  |--
//              |-----------|
// op      -----|           |-----------
//              |-----------|
// op_read -----|           |-----------
//              |***********|
// raddr   -----|***********|-----------
//                    |*****|
// rdata   -----------|*****|
//                    |-----|
// ready   -----------|     |-----------
//
//---------------------------------------------------------

`timescale 1ns/1ps

module bus_conv
  (
   clk,
   rst,

   s_axi_awaddr,
   s_axi_awvalid,
   s_axi_awready,
   s_axi_wdata,
   s_axi_wstrb,
   s_axi_wvalid,
   s_axi_wready,
   s_axi_bresp,
   s_axi_bvalid,
   s_axi_bready,
   s_axi_araddr,
   s_axi_arvalid,
   s_axi_arready,
   s_axi_rdata,
   s_axi_rresp,
   s_axi_rvalid,
   s_axi_rready,

   apb_psel,
   apb_penable,
   apb_paddr,
   apb_pwrite,
   apb_pwdata,
   apb_pready,
   apb_prdata,

   dcr_read,
   dcr_write,
   dcr_abus,
   dcr_dbus,
   dcrdbus,
   dcrack,

   op,
   op_write,
   op_read,
   waddr,
   raddr,
   wdata,
   ready,
   rdata
   );
   parameter C_BUS_PROTOCAL = 0;
   parameter C_S_AXI_ADDR_WIDTH = 5;
   parameter C_S_AXI_DATA_WIDTH = 32;
   parameter C_APB_ADDR_WIDTH = 32;
   parameter C_APB_DATA_WIDTH = 32;
   parameter C_DCR_AWIDTH = 5;
   parameter C_DCR_DWIDTH = 32;
   parameter C_ADDR_W = 3;

   input clk;
   input rst;
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

   input 			    apb_psel;
   input 			    apb_penable;
   input [C_APB_ADDR_WIDTH-1:0]     apb_paddr;
   input 			    apb_pwrite;
   input [C_APB_DATA_WIDTH-1:0]     apb_pwdata;
   output 			    apb_pready;
   output [C_APB_DATA_WIDTH-1:0]    apb_prdata;

   input 			    dcr_read;
   input 			    dcr_write;
   input [C_DCR_AWIDTH-1:0] 	    dcr_abus;
   input [C_DCR_DWIDTH-1:0] 	    dcr_dbus;
   output [C_DCR_DWIDTH-1:0] 	    dcrdbus;
   output 			    dcrack;

   output 			    op;
   output 			    op_write;
   output 			    op_read;
   output [C_ADDR_W-1:0] 	    waddr;
   output [C_ADDR_W-1:0] 	    raddr;
   output [31:0] 		    wdata;
   input 			    ready;
   input [31:0] 		    rdata;

   reg 				    s_axi_bvalid;
   reg 				    s_axi_read;
   reg 				    s_axi_rvalid;
   reg [C_S_AXI_ADDR_WIDTH-1:0]     axi_waddr; 
   reg [C_S_AXI_ADDR_WIDTH-1:0]     axi_raddr; 
   wire 			    read_st;

   //----------------------------------
   // AXI-Lite interface
   //----------------------------------
   generate if(C_BUS_PROTOCAL == 0)
     begin // Note: do not support adddress pipeline
        assign op = s_axi_wvalid || op_read;
	assign op_write = s_axi_wvalid & s_axi_wready;
	assign op_read  = s_axi_read;
	assign waddr = axi_waddr[C_ADDR_W+2-1:2];
	assign raddr = axi_raddr[C_ADDR_W+2-1:2];
	assign wdata = s_axi_wdata;
	assign s_axi_rdata =  rdata;
	assign read_st = s_axi_arvalid & s_axi_arready;
	assign s_axi_awready = 1'h1;
	assign s_axi_wready = s_axi_wvalid & ready;
	assign s_axi_bresp = 2'h0;
	assign s_axi_arready = 1'h1;
	assign s_axi_rresp = 2'h0;

	always @ (posedge clk)
	  begin
             if (rst)
               s_axi_bvalid <= #1 1'h0;
             else if (op_write)
               s_axi_bvalid <= #1 1'h1;
             else if (s_axi_bready)
               s_axi_bvalid <= #1 1'h0;
	  end

	always @ (posedge clk)
	  begin
             if (rst)
               axi_waddr <= #1 0;
             else if (s_axi_awvalid & s_axi_awready)
               axi_waddr <= #1 s_axi_awaddr;
	  end

	always @ (posedge clk)
	  begin
             if (rst)
               axi_raddr <= #1 0;
             else if (read_st)
               axi_raddr <= #1 s_axi_araddr;
	  end

	always @ (posedge clk)
	  begin
             if (rst)
               s_axi_read <= #1 1'h0;
             else if (read_st)
               s_axi_read <= #1 1'h1;
             else if(ready)
               s_axi_read <= #1 1'h0;
	  end

	always @ (posedge clk)
	  begin
             if (rst)
               s_axi_rvalid <= #1 1'h0;
             else if(s_axi_rready && s_axi_rvalid)
               s_axi_rvalid <= #1 1'h0;
             else if (s_axi_read && ready)
               s_axi_rvalid <= #1 1'h1;
	  end

     end
   endgenerate

   //----------------------------------
   // APB interface
   //----------------------------------
   generate if(C_BUS_PROTOCAL == 1)
     begin
	assign op = apb_psel & apb_penable;
	assign op_write = op & apb_pwrite & ready;
	assign op_read = op & ~apb_pwrite;
	assign waddr = apb_paddr[C_ADDR_W+2-1:2];
	assign raddr = apb_paddr[C_ADDR_W+2-1:2];
	assign wdata = apb_pwdata;
	assign apb_pready = ready;
	assign apb_prdata = rdata;
     end
   endgenerate

   //----------------------------------
   // DCR interface
   //----------------------------------
   generate if(C_BUS_PROTOCAL == 2)
     begin
	assign op = dcr_write || dcr_read;
	assign op_write = dcr_write & ready;
	assign op_read = dcr_read;
	assign waddr = dcr_abus[C_ADDR_W-1:0];
	assign raddr = dcr_abus[C_ADDR_W-1:0];
	assign wdata = dcr_dbus;
	assign dcrack = ready;
	assign dcrdbus = rdata;
     end
   endgenerate

endmodule



