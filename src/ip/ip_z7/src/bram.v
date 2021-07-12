/*
 **
 ** File Name            :   bram.v
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
 **                              dinb
 **               ceb            ceb
 **               doutb          doutb
 */
`timescale 1ns/1ps

module bram
  (
   clka,
   cea,
   wea,
   addra,
   dina,
   douta,

   clkb,
   ceb,
   web,
   addrb,
   dinb,
   doutb
   );
   
   parameter  MEM_TYPE = 2;
   parameter  DATA_W = 32;
   parameter  ADDR_W  = 8;
   parameter  DEPTH = (1 << ADDR_W);
   
   input 		clka;
   input 		cea;
   input 		wea;
   input [ADDR_W-1:0] 	addra;
   input [DATA_W-1:0] 	dina;
   output [DATA_W-1:0] 	douta;

   input 		clkb;
   input                ceb;
   input                web;
   input [ADDR_W-1:0] 	addrb;
   input [DATA_W-1:0] 	dinb;
   output [DATA_W-1:0] 	doutb;

   reg [DATA_W-1:0] 	douta;
   reg [DATA_W-1:0] 	doutb;

   //synthesis attribute ram_style of mem is block 
   (* RAM_STYLE="{AUTO | BLOCK |  BLOCK_POWER1 | BLOCK_POWER2}" *)
   reg [DATA_W-1:0] 	mem[0:DEPTH-1]/* synthesis syn_ramstyle = "block_ram" */;

   always@(posedge clka)
     begin
	if(cea)
	  begin
             if (MEM_TYPE == 0 || MEM_TYPE == 2)
               douta <= #1 mem[addra];
	     if(wea)
	       mem[addra] <= #1 dina;
	  end
     end


   always@(posedge clkb)
     begin
	if(ceb)
	  begin
	     if (MEM_TYPE == 1 || MEM_TYPE == 2)
	       doutb <= #1 mem[addrb];
	     if(web)
	       mem[addrb] <= #1 dinb;
	  end
     end

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




