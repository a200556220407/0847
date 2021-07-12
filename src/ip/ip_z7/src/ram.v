/*
 **
 ** File Name            :   bram.v
 ** RAM_TYPE
 ** 0 - dram
 ** 1 - bram
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

module ram
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

   parameter RAM_TYPE = 0;
   parameter MEM_TYPE = 2;
   parameter DATA_W = 32;
   parameter ADDR_W  = 8;
   parameter DEPTH = (1 << ADDR_W);
   parameter REG_OUT_A = 1;
   parameter REG_OUT_B = 1;

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


   generate
      if (RAM_TYPE == 0) begin
	 dram #
	   (
	    /*AUTOINSTPARAM*/
	    // Parameters
	    .MEM_TYPE			(MEM_TYPE),
	    .DATA_W			(DATA_W),
	    .ADDR_W			(ADDR_W),
	    .DEPTH			(DEPTH),
	    .REG_OUT_A			(REG_OUT_A),
	    .REG_OUT_B			(REG_OUT_B))
	 I_DRAM
	   (
	    /*AUTOINST*/
	    // Outputs
	    .douta			(douta[DATA_W-1:0]),
	    .doutb			(doutb[DATA_W-1:0]),
	    // Inputs
	    .clka			(clka),
	    .cea			(cea),
	    .wea			(wea),
	    .addra			(addra[ADDR_W-1:0]),
	    .dina			(dina[DATA_W-1:0]),
	    .clkb			(clkb),
	    .ceb			(ceb),
	    .addrb			(addrb[ADDR_W-1:0]));

      end
   endgenerate

   generate
      if (RAM_TYPE == 1) begin
	 bram #
	   (
	    /*AUTOINSTPARAM*/
	    // Parameters
	    .MEM_TYPE			(MEM_TYPE),
	    .DATA_W			(DATA_W),
	    .ADDR_W			(ADDR_W),
	    .DEPTH			(DEPTH))
	 I_BRAM
	   (
	    /*AUTOINST*/
	    // Outputs
	    .douta			(douta[DATA_W-1:0]),
	    .doutb			(doutb[DATA_W-1:0]),
	    // Inputs
	    .clka			(clka),
	    .cea			(cea),
	    .wea			(wea),
	    .addra			(addra[ADDR_W-1:0]),
	    .dina			(dina[DATA_W-1:0]),
	    .clkb			(clkb),
	    .ceb			(ceb),
	    .web			(web),
	    .addrb			(addrb[ADDR_W-1:0]),
	    .dinb			(dinb[DATA_W-1:0]));

      end
   endgenerate

endmodule


