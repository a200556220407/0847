
`timescale 1ns/1ps
module wdata_ch
  (/*AUTOARG*/
   // Outputs
   head_err, compfifo_over, cmdfifo_over, err_tag, rx_axis_tready,
   compfifo_q, compfifo_empty, tagram_douta, wcmd_fifo_empty, wcmd_q,
   rxfifo_empty, rxfifo_q,
   // Inputs
   m_axi_aclk, s_axi_aclk, ext_clk, rst, rx_axis_tvalid,
   rx_axis_tdata, rx_axis_tkeep, rx_axis_tlast, rx_axis_tuser,
   compfifo_rdreq, tagram_wena, tagram_addra, tagram_dina, wcmd_rdreq,
   rxfifo_rdreq
   );

   parameter C_M_AXI_DATA_WIDTH = 128;
   localparam C_DATA_WIDTH = (C_M_AXI_DATA_WIDTH + C_M_AXI_DATA_WIDTH/32 + 2);
	 localparam C_STREAM_FULL = 4;


   input m_axi_aclk;
   input s_axi_aclk; 
   input ext_clk; 
   input rst;

   output head_err;
   output compfifo_over;
   output cmdfifo_over;
   output err_tag;

   output rx_axis_tready; 
   input  rx_axis_tvalid; 
   input [C_M_AXI_DATA_WIDTH-1:0] rx_axis_tdata;
   input [C_M_AXI_DATA_WIDTH/8-1:0] rx_axis_tkeep;
   input 			    rx_axis_tlast; 
   input [65:0] 		    rx_axis_tuser;

   input 			    compfifo_rdreq;
   output [7:0] 		    compfifo_q;
   output 			    compfifo_empty;

   input 			    tagram_wena;
   input [8:0] 			    tagram_addra;
   input [31:0] 		    tagram_dina;
   output [31:0] 		    tagram_douta;

   input 			    wcmd_rdreq;
   output 			    wcmd_fifo_empty;
   output [63:0] 		    wcmd_q;

   input 			    rxfifo_rdreq;
   output 			    rxfifo_empty;
   output [C_DATA_WIDTH-1:0] 	    rxfifo_q;

	 wire           stream_full;
	 wire           rx_axis_tready_buf;
	 wire[5:0]      data_cnt_wclk;
	 wire[5:0]      data_cnt_rclk;
   wire 			    clk;
   reg 				    head_err;
   wire [31:0] 			    tagram_douta;
   wire [31:0] 			    tagram_b_douta;
   wire [30:0] 			    tagram_a_douta;
   wire 			    tagram_wenb;
   wire [7:0] 			    tagram_addrb;
   wire [30:0] 			    tagram_dinb;
   wire [31:0] 			    tagram_b_doutb;
   wire [30:0] 			    tagram_a_doutb;
   wire [31:0] 			    win_addr;
   wire 			    rxfifo_wrreq;
   wire 			    rxfifo_full;
   wire [C_DATA_WIDTH-1:0] 	    rxfifo_din;
   wire [4:0] 			    cmd_type;
   wire [7:0] 			    task_tag;
   wire [15:0] 			    sec_cnt;
   reg 				    eof_flag;
   reg 				    err_tag;
   reg [3:0] 			    valid_buf;
   reg [1:0] 			    last_buf;
   wire 			    tlast_flag;
   wire 			    head_flag;
   wire [63:0] 			    wcmd_din;
   wire 			    wcmd_wrreq;
   wire 			    wcmd_fifo_full;
   reg  			    last_pkg;
   wire [31:0] 			    wcmd_len;
   reg [31:0] 			    wcmd_addr;
   wire 			    compfifo_wrreq;
   wire 			    compfifo_full;
   wire [7:0] 			    compfifo_din;
   wire 			    data_int;

   reg [65:0] 			    rx_cmd;
   reg [31:0] 			    next_addr;
   wire [31:0] 			    max_addr;

   wire [C_M_AXI_DATA_WIDTH/32-1:0] keep;
   wire [C_M_AXI_DATA_WIDTH+C_M_AXI_DATA_WIDTH/32+1:0] tdata;

   integer 					       i;


   function [C_M_AXI_DATA_WIDTH/32-1:0] reduce_keep;
      input [C_M_AXI_DATA_WIDTH/8-1:0] 		       tkeep;
      begin
	 for(i=0;i<C_M_AXI_DATA_WIDTH/32;i=i+1)
	   reduce_keep[i] = tkeep[i*4];
      end
   endfunction

   assign stream_full = (data_cnt_wclk == (C_STREAM_FULL - 2));
	 assign rx_axis_tready = rx_axis_tready_buf && (!stream_full);
   assign clk = m_axi_aclk;
   assign tlast_flag = rx_axis_tready && rx_axis_tvalid && rx_axis_tlast;
   assign head_flag = rx_axis_tready && rx_axis_tvalid && eof_flag;
   assign data_int = last_pkg & rx_axis_tlast;

   assign sec_cnt  = rx_cmd[65:50];
   assign cmd_type = rx_cmd[49:42];
   assign task_tag = rx_cmd[41:34];
   assign win_addr = rx_cmd[33:0];

   assign tagram_addrb = task_tag;
   assign tagram_douta = tagram_addra[0] ? tagram_b_douta : {1'h0,tagram_a_douta};

   assign cmdfifo_over = wcmd_wrreq & wcmd_fifo_full;
   assign wcmd_wrreq = valid_buf[3];
   assign max_addr = tagram_a_doutb;
   assign wcmd_len = {16'h0,sec_cnt};
   assign wcmd_din = {wcmd_addr,wcmd_len};

   assign compfifo_over = compfifo_wrreq & compfifo_full;
   assign compfifo_wrreq = rxfifo_wrreq & rxfifo_din[C_DATA_WIDTH-1];
   assign compfifo_din = tagram_addrb;

   assign keep = reduce_keep(rx_axis_tkeep);
   assign tdata = {data_int,rx_axis_tlast,keep,rx_axis_tdata};

   always@(posedge ext_clk)
     begin
	if(rst)
	  eof_flag <= #1 1'h1;
	else if(eof_flag && rx_axis_tvalid && rx_axis_tready && (~rx_axis_tlast))
	  eof_flag <= #1 1'h0;
	else if(tlast_flag)
	  eof_flag <= #1 1'h1;
     end

   always@(posedge ext_clk)
     begin
	if(rst)
	  rx_cmd <= #1 66'h0;
	else if(head_flag)
	  rx_cmd <= #1 rx_axis_tuser;
     end

   always@(posedge ext_clk)
     begin
	if(rst)
	  valid_buf <= #1 4'h0;
	else
	  valid_buf <= #1 {valid_buf[2:0],head_flag};
     end
   
   always@(posedge ext_clk)
     begin
	if(rst)
	  last_buf <= #1 2'h0;
	else
	  last_buf <= #1 {last_buf[0],tlast_flag};
     end

   always@(posedge ext_clk)
     begin
	if(rst)
	  head_err <= #1 1'h0;
	else
	  head_err <= #1 (last_buf == 2'h3);
     end

   always@(posedge ext_clk)
     begin
	if(rst)
	  wcmd_addr <= #1 32'h0;
	else if(valid_buf[1])
	  wcmd_addr <= #1 tagram_b_doutb + win_addr;
	else if(valid_buf[2] & err_tag)
	  wcmd_addr <= #1 tagram_b_doutb;
     end

   always@(posedge ext_clk)
     begin
	if(rst)
          next_addr <= #1 32'h0;
	else if(valid_buf[0])
          next_addr <= #1 win_addr + sec_cnt;
     end

   always@(posedge ext_clk)
     begin
	if(rst)
	  begin
	     err_tag <= #1 1'h0;
	     last_pkg <= #1 1'h0;
	  end
	else if(valid_buf[1])
	  begin
	     err_tag <= #1 (next_addr > max_addr);
	     last_pkg <= #1 (next_addr == max_addr);
	  end
     end

   asyncfifo #
     (
      .C_RAM_TYPE (0),
      .C_DATA_W   (8),
      .C_ADDR_W   (5))
   I_COMP_FIFO
     (
      .wr_clk    (ext_clk),
      .rd_clk    (s_axi_aclk),
      .rst       (rst),
      .din       (compfifo_din),
      .push_req  (compfifo_wrreq),
      .pop_req   (compfifo_rdreq),
      .dout      (compfifo_q),
      .full      (compfifo_full),
			.data_cnt_wclk(data_cnt_wclk),
      .data_cnt_rclk(data_cnt_rclk),
      .empty     (compfifo_empty)
      );

   ram #
     (
      .RAM_TYPE  (1),
      .MEM_TYPE  (2),
      .DATA_W    (31),
      .ADDR_W    (8)
      )
   I_TAGRAM
     (
      .clka  (s_axi_aclk),
      .cea   (1'h1),
      .wea   (tagram_wena & (~tagram_addra[0])),
      .addra (tagram_addra[8:1]),
      .dina  (tagram_dina[30:0]),
      .douta (tagram_a_douta),
      .clkb  (ext_clk),
      .ceb   (1'h1),
      .web   (1'h0),
      .addrb (tagram_addrb),
      .dinb  (31'h0),
      .doutb (tagram_a_doutb)
      );

   ram #
     (
      .RAM_TYPE  (1),
      .MEM_TYPE  (2),
      .DATA_W    (32),
      .ADDR_W    (8)
      )
   I_TAGRAM_B
     (
      .clka  (s_axi_aclk),
      .cea   (1'h1),
      .wea   (tagram_wena & tagram_addra[0]),
      .addra (tagram_addra[8:1]),
      .dina  (tagram_dina),
      .douta (tagram_b_douta),
      .clkb  (ext_clk),
      .ceb   (1'h1),
      .web   (1'h0),
      .addrb (tagram_addrb),
      .dinb  (32'h0),
      .doutb (tagram_b_doutb)
      );

   asyncfifo #
     (
      .C_RAM_TYPE (0),
      .C_DATA_W   (64),
      .C_ADDR_W   (6))
   I_WCMD_FIFO
     (
      .wr_clk    (ext_clk),
      .rd_clk    (clk),
      .rst       (rst),
      .din       (wcmd_din),
      .push_req  (wcmd_wrreq),
      .pop_req   (wcmd_rdreq),
      .dout      (wcmd_q),
      .full      (wcmd_fifo_full),
      .empty     (wcmd_fifo_empty)
      );

   axis2fifo #
     (
      .C_DATA_W (C_DATA_WIDTH))
   I_AXIS2FIFO
     (
      .clk      (ext_clk),
      .rst      (rst),
      .wr_en    (rxfifo_wrreq),
      .m_tvalid (),
      .m_tdata  (rxfifo_din),
      .m_tready (~rxfifo_full),
      .s_tvalid (rx_axis_tvalid),
      .s_tready (rx_axis_tready_buf),
      .s_tdata  (tdata)
      );

   asyncfifo #
     (
      .C_RAM_TYPE (1),
      .C_DATA_W   (C_DATA_WIDTH),
      .C_ADDR_W   (10))
   I_RXFIFO
     (
      .wr_clk    (ext_clk),
      .rd_clk    (clk),
      .rst       (rst),
      .din       (rxfifo_din),
      .push_req  (rxfifo_wrreq),
      .pop_req   (rxfifo_rdreq),
      .dout      (rxfifo_q),
      .full      (rxfifo_full),
      .empty     (rxfifo_empty)
      );

endmodule

