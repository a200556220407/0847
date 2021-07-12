/*
 **
 ** File Name            :   dram.v
 **
 ** MEM_TYPE
 ** 0 - Single Port Memory
 ** 1 - Simple Dual Port Memory
 ** 2 - True Dual Port Memory
 ** 
 ** SP Interface  SDP Interface  TDP Interface
 ** clka          clka           clka
 ** wea           wea            wea
 ** addra         addra          addra
 ** dina          dina           dina
 ** cea                          cea
 ** douta                        douta
 **                                   
 **               clkb           clkb
 **               addrb          addrb
 **               ceb            ceb
 **               doutb          doutb
 */
`timescale 1ns/1ps

module dram
  (
   clka,
   cea,
   wea,
   addra,
   dina,
   douta,

   clkb,
   ceb,
   addrb,
   doutb
   );
   
   parameter  MEM_TYPE = 2;
   parameter  DATA_W = 32;
   parameter  ADDR_W  = 6;
   parameter  DEPTH = (1 << ADDR_W);
   parameter  REG_OUT_A = 1;
   parameter  REG_OUT_B = 1;
   
   input 		clka;
   input                cea;
   input 		wea;
   input [ADDR_W-1:0] 	addra;
   input [DATA_W-1:0] 	dina;
   output [DATA_W-1:0] 	douta;

   input 		clkb;
   input                ceb;
   input [ADDR_W-1:0] 	addrb;
   output [DATA_W-1:0] 	doutb;

   wire [DATA_W-1:0] 	mem_douta;
   wire [DATA_W-1:0] 	mem_doutb;
   reg [DATA_W-1:0] 	douta;
   reg [DATA_W-1:0] 	doutb;

   //synthesis attribute ram_style of mem is distributed 
   (* RAM_STYLE="{AUTO | DISTRIBUTED | PIPE_DISTRIBUTED}" *)
   reg [DATA_W-1:0] 	mem[0:DEPTH-1]/* synthesis syn_ramstyle = "select_ram" */;

   always@(posedge clka)
     begin
	if(cea)
	  begin
	     if(wea)
	       mem[addra] <= #1 dina;
	  end
     end

   assign mem_douta = mem[addra];
   assign mem_doutb = mem[addrb];
   
   generate
      if (MEM_TYPE == 0 || MEM_TYPE == 2) begin
	 if(REG_OUT_A == 0) begin
	    always@(*)
	    douta = mem_douta;
	 end
	 else begin
	    always@(posedge clka)
	      begin
		 if(cea)
		   douta <= #1 mem_douta;
	      end
	 end
      end
   endgenerate

   generate
      if (MEM_TYPE == 1 || MEM_TYPE == 2) begin
	 if(REG_OUT_B == 0) begin
	    always@(*)
		    doutb = mem_doutb;
	 end
	 else begin
	    always@(posedge clkb)
	      begin
		 if(ceb)
		   doutb <= #1 mem_doutb;
	      end
	 end
      end
   endgenerate

   // synopsys translate_off
   wire addra_is_over;
   wire addrb_is_over;
   wire error_write;
   assign addra_is_over = (addra > DEPTH-1);
   assign addrb_is_over = (addrb > DEPTH-1);
   assign error_write = wea && (((^addra) === 1'hx) || ((^dina) === 1'hx));

   always@(posedge clka)
     begin
	if ((addra_is_over === 1'h1) && (MEM_TYPE == 0 || MEM_TYPE == 2))
	  begin
	     $display("WARNING: in %m at time %4d ns adra > Max address", $time);
	  end
     end

   always@(posedge clkb)
     begin
	if ((addrb_is_over === 1'h1) && (MEM_TYPE == 1 || MEM_TYPE == 2))
	  begin
	     $display("WARNING: in %m at time %4d ns adrb > Max address", $time);
	  end
     end

   always@(posedge clka)
     begin
	if ((error_write === 1'h1) && (MEM_TYPE == 1 || MEM_TYPE == 2))
	  begin
	     $display("WARNING: in %m at time %4d ns write address or data has x", $time);
	  end
     end
   // synopsys translate_on

   // synopsys translate_off
   integer i;
   initial
     begin
	douta = 0;     
	doutb = 0;     
     end
   // synopsys translate_on

endmodule

