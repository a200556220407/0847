
`timescale 1ns/10ps
module fifoctl_sync
  (/*AUTOARRG*/
   // Outputs
   wr_en, wr_addr, rd_en, rd_addr, data_cnt, full, empty, al_full,
   al_empty,
   // Inputs
   clk, rst, push_req, pop_req
   );

   parameter  C_ADDR_W = 8;
   parameter  C_DEPTH = (1 << C_ADDR_W);
   parameter  C_AF_LEV = (C_DEPTH - 1);
   parameter  C_AE_LEV = 1;
   
   input               clk;
   input               rst;
   input               push_req;
   input               pop_req;

   output              wr_en;
   output [C_ADDR_W-1:0] wr_addr;
   output 		 rd_en;
   output [C_ADDR_W-1:0] rd_addr;
   output [C_ADDR_W:0] 	 data_cnt;
   output 		 full;
   output 		 empty;
   output 		 al_full;
   output 		 al_empty;
   
   //-------------------------------------------------------------------//
   
   reg [C_ADDR_W-1:0] 	 R_wr_addr;
   reg [C_ADDR_W-1:0] 	 R_rd_addr;
   reg [C_ADDR_W:0] 	 R_data_cnt;

   
   assign wr_addr   =  R_wr_addr;
   assign rd_addr   =  R_rd_addr;
   assign data_cnt  =  R_data_cnt;

   always @(posedge clk) begin
      if (rst)
	R_wr_addr <= #1 {C_ADDR_W{1'b0}};
      else if (push_req && !full) begin
	 if (R_wr_addr == (C_DEPTH-1))
	   R_wr_addr <= #1 {C_ADDR_W{1'b0}};
	 else
	   R_wr_addr <= #1 R_wr_addr + 1'b1;
      end
   end
   
   always @(posedge clk) begin
      if (rst)
	R_rd_addr <= #1 {C_ADDR_W{1'b0}};
      else if (pop_req && !empty) begin
	 if (R_rd_addr == (C_DEPTH-1))
	   R_rd_addr <= #1 {C_ADDR_W{1'b0}};
	 else
	   R_rd_addr <= #1 R_rd_addr + 1'b1;
      end
   end
   
   assign full  = (R_data_cnt == C_DEPTH);
   assign empty = (R_data_cnt == {(C_ADDR_W+1){1'b0}});

   assign wr_en = ~full  & push_req;
   assign rd_en = ~empty & pop_req;

   assign al_full  = R_data_cnt >= C_AF_LEV;
   assign al_empty = R_data_cnt <= C_AE_LEV;
   
   always @ (posedge clk) begin
      if (rst)
	R_data_cnt <= #1 {(C_ADDR_W+1){1'b0}};
      else begin
	 case ({push_req, pop_req})
	   2'b00:
	     R_data_cnt   <= #1 R_data_cnt;
	   2'b10:
	     if (!full)
	       R_data_cnt <= #1 R_data_cnt + 1'b1;
	   2'b01:
	     if (!empty)
	       R_data_cnt <= #1 R_data_cnt - 1'b1;
	   2'b11: begin
	      if (full)
		R_data_cnt   <= #1 R_data_cnt - 1'b1;
	      else if (empty)
		R_data_cnt   <= #1 R_data_cnt + 1'b1;
	      else
		R_data_cnt   <= #1 R_data_cnt;
	   end
	 endcase
      end
   end 
   
   
endmodule 

