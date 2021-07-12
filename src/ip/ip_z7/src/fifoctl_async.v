
`timescale 1ns/1ps
module fifoctl_async
  (/*autoarg*/
   // Outputs
   wr_en, wr_addr, rd_en, rd_addr, data_cnt_wclk, data_cnt_rclk, full,
   empty, al_full, al_empty,
   // Inputs
   wr_clk, wr_rst, push_req, rd_clk, rd_rst, pop_req
   );

   parameter  C_ADDR_W = 8;
   parameter  C_DEPTH = (1 << C_ADDR_W);
   parameter  C_AF_LEV = (C_DEPTH -1);
   parameter  C_AE_LEV = 1;
   parameter  FastGray = 1;

   localparam Is2Power = ((1 << C_ADDR_W) == C_DEPTH) ? 1 : 0;
   localparam CntC_ADDR_W = Is2Power ? C_ADDR_W+1 : C_ADDR_W;
   localparam CntC_ADDR_W2Power = (1 << CntC_ADDR_W);
   
   input               wr_clk;
   input               wr_rst;
   input               push_req;
   input               rd_clk;
   input               rd_rst;
   input               pop_req;

   output 	       wr_en;	// mem write strobe
   output [C_ADDR_W-1:0] wr_addr;	// mem write address
   output 		 rd_en;	// mem read strobe
   output [C_ADDR_W-1:0] rd_addr;	// mem read address
   output [CntC_ADDR_W-1:0] data_cnt_wclk;
   output [CntC_ADDR_W-1:0] data_cnt_rclk;
   output 		    full;
   output 		    empty;
   output 		    al_full;
   output 		    al_empty;
   
   //-------------------------------------------------------------------//
   reg [C_ADDR_W-1:0] 	    R_wram_addr; // write address for ram access
   reg [C_ADDR_W-1:0] 	    R_rram_addr; // read address for ram access
   
   assign wr_addr = R_wram_addr;
   assign rd_addr = R_rram_addr;
   
   wire [CntC_ADDR_W-1:0]   wr_pointer; // for counter calculation
   wire [CntC_ADDR_W-1:0]   rd_pointer; // for counter calculation
   wire [CntC_ADDR_W-1:0]   wr_pointer_rclk; // binary write address sync to rclk
   wire [CntC_ADDR_W-1:0]   rd_pointer_wclk; // binary read address sync to wclk
   wire [CntC_ADDR_W-1:0]   next_wr_pointer;
   wire [CntC_ADDR_W-1:0]   next_rd_pointer;
   reg [CntC_ADDR_W:0] 	    R_data_cnt_wclk; // data counter in wclk domain
   reg [CntC_ADDR_W:0] 	    R_data_cnt_rclk; // data counter in rclk domain
   
   assign al_full = (data_cnt_wclk >= C_AF_LEV);
   assign al_empty = (data_cnt_wclk <= C_AE_LEV);
   assign data_cnt_wclk  =  R_data_cnt_wclk[CntC_ADDR_W-1:0];
   assign data_cnt_rclk  =  R_data_cnt_rclk[CntC_ADDR_W-1:0];

   wire 		    pop_req_masked = pop_req & ~empty;
   wire 		    push_req_masked = push_req & ~full;
   assign rd_en = pop_req_masked;
   assign wr_en = push_req_masked;

   //-------------------------------------------------------------------//

   sync_gray #
     (CntC_ADDR_W, CntC_ADDR_W2Power, FastGray) 
   wr_addr_sync 
     (
      .clk_s		(wr_clk), 
      .rst_s		(wr_rst),
      .en_s		(push_req_masked),
      .clk_d		(rd_clk),
      .rst_d		(rd_rst), 
      .cnt_s		(wr_pointer),
      .cnt_d		(wr_pointer_rclk)
      );
   

   sync_gray #
     (CntC_ADDR_W, CntC_ADDR_W2Power, FastGray) 
   rd_addr_sync 
     (
      .clk_s		(rd_clk),
      .rst_s		(rd_rst),
      .en_s		(pop_req_masked),
      .clk_d		(wr_clk),
      .rst_d		(wr_rst), 
      .cnt_s		(rd_pointer),
      .cnt_d		(rd_pointer_wclk)
      );
   
   //-------------------------------------------------------------------//

   generate
      if (Is2Power) begin // don't use hard reg if depth is 2's power
	 always @(*)
	   R_wram_addr = wr_pointer[C_ADDR_W-1:0];
      end
      else begin // !Is2Power
	 always @(posedge wr_clk or posedge wr_rst) begin
	    if (wr_rst)
	      R_wram_addr <= #1 {C_ADDR_W{1'b0}};
	    else if (push_req_masked) begin
	       if (R_wram_addr == (C_DEPTH - 1))
		 R_wram_addr <= #1 {C_ADDR_W{1'b0}};
	       else
		 R_wram_addr <= #1 R_wram_addr + 1;
	    end
	 end // always @ (posedge wr_clk)
      end // else: !if(Is2Power)
   endgenerate

   assign next_wr_pointer = push_req_masked ? wr_pointer+1 : wr_pointer;
   
   always @(posedge wr_clk or posedge wr_rst) begin
      if(wr_rst)
        R_data_cnt_wclk <= #1 {CntC_ADDR_W{1'b0}};
      else if ( next_wr_pointer < rd_pointer_wclk )
        R_data_cnt_wclk <= #1 next_wr_pointer - rd_pointer_wclk + CntC_ADDR_W2Power;
      else
	R_data_cnt_wclk <= #1 next_wr_pointer - rd_pointer_wclk;
   end
   
   assign full = (R_data_cnt_wclk == C_DEPTH) ? 1'b1 : 1'b0;

   //-------------------------------------------------------------------//

   generate
      if (Is2Power) begin // don't use hard reg if depth is 2's power
	 always @(*)
			 R_rram_addr = rd_pointer[C_ADDR_W-1:0];
      end
      else begin // !Is2Power
	 always @(posedge rd_clk or posedge rd_rst) begin
	    if (rd_rst)
	      R_rram_addr <= #1 {C_ADDR_W{1'b0}};
	    else if (pop_req_masked) begin
	       if (R_rram_addr == (C_DEPTH - 1))
		 R_rram_addr <= #1 {C_ADDR_W{1'b0}};
	       else
		 R_rram_addr <= #1 R_rram_addr + 1;
	    end
	 end // always @ (posedge rd_clk)
      end // else: !if(Is2Power)
   endgenerate

   assign next_rd_pointer = pop_req_masked ? rd_pointer+1 : rd_pointer;

   always @(posedge rd_clk or posedge rd_rst) begin
      if(rd_rst)
        R_data_cnt_rclk <= #1 {CntC_ADDR_W{1'b0}};
      else if (wr_pointer_rclk < next_rd_pointer)
        R_data_cnt_rclk <= #1 wr_pointer_rclk - next_rd_pointer + CntC_ADDR_W2Power;
      else
	R_data_cnt_rclk <= #1 wr_pointer_rclk - next_rd_pointer;
   end

   assign empty = (R_data_cnt_rclk == 0) ? 1'b1 : 1'b0;
   
endmodule

