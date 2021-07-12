
module syncfifo
  (
   /*AUTOARG*/
   // Outputs
   dout, full, empty, al_full, al_empty, data_cnt,
   // Inputs
   clk, rst, din, push_req, pop_req
   );

   parameter C_RAM_TYPE = 1;
   parameter C_DATA_W = 32;
   parameter C_ADDR_W = 10;
   parameter C_DEPTH  = (1 << C_ADDR_W);
   parameter C_AF_LEV = (C_DEPTH-1);
   parameter C_AE_LEV = 1;

   input clk;
   input rst;
   input [C_DATA_W-1 : 0] din;
   input 		  push_req;
   input 		  pop_req;
   output [C_DATA_W-1 : 0] dout;
   output 		   full;
   output 		   empty;
   output 		   al_full;
   output 		   al_empty;
   output [C_ADDR_W:0] 	   data_cnt;

   wire 		   wr_en;
   wire 		   rd_en;
   wire [C_ADDR_W-1:0] 	   wr_addr;
   wire [C_ADDR_W-1:0] 	   rd_addr;

   fifoctl_sync #
     (
      /*AUTOINSTPARAM*/
      // Parameters
      .C_ADDR_W				(C_ADDR_W),
      .C_DEPTH				(C_DEPTH),
      .C_AF_LEV				(C_AF_LEV),
      .C_AE_LEV				(C_AE_LEV))
   I_FIFOCTL_SYNC
     (
      /*AUTOINST*/
      // Outputs
      .wr_en				(wr_en),
      .wr_addr				(wr_addr[C_ADDR_W-1:0]),
      .rd_en				(rd_en),
      .rd_addr				(rd_addr[C_ADDR_W-1:0]),
      .data_cnt				(data_cnt[C_ADDR_W:0]),
      .full				(full),
      .empty				(empty),
      .al_full				(al_full),
      .al_empty				(al_empty),
      // Inputs
      .clk				(clk),
      .rst				(rst),
      .push_req				(push_req),
      .pop_req				(pop_req));

   ram #
     (
      .RAM_TYPE    (C_RAM_TYPE),
      .MEM_TYPE    (1),
      .DATA_W      (C_DATA_W),
      .ADDR_W      (C_ADDR_W),
      .DEPTH       (C_DEPTH),
      .REG_OUT_A   (0),
      .REG_OUT_B   (1))
   I_RAM
     (
      .clka   (clk),
      .cea    (1'h1),
      .wea    (wr_en),
      .addra  (wr_addr),
      .dina   (din),
      .douta  (),

      .clkb   (clk),
      .ceb    (rd_en),
      .web    (1'h0),
      .addrb  (rd_addr),
      .dinb   ({C_DATA_W{1'h0}}),
      .doutb  (dout)
      );

   
endmodule

