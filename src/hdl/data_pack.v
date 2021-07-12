
`timescale 1ns/1ps
module data_pack(/*autoarg*/
    //Inputs
    wr_clk, rd_clk, rst, wrreq, din, din_last, s_axis_tready, 

    //Outputs
    al_full, s_axis_tvalid, s_axis_tlast, s_axis_tdata, s_axis_tkeep);

parameter C_DW = 64;
parameter C_DATA_W = 64;
parameter C_ADDR_W = 9;
parameter C_AF_LEV = ((1<<C_ADDR_W)-1);
parameter   C_TID    = 0;
parameter   C_TDEST  = 0;
parameter   C_ID_W   = 3;

input wr_clk;
input rd_clk;
input rst;
input wrreq;
input [C_DW-1:0] din;
input 	    din_last;
output 	    al_full;

output 	                    s_axis_tvalid;
input 	                    s_axis_tready;
output 	                    s_axis_tlast;
output [C_DATA_W - 1:0]     s_axis_tdata;
output         [7:0]        s_axis_tkeep;


wire 	                    pack_gnt;
wire	                    pack_req;
wire 	                    pack_rdreq;
wire [C_DATA_W - 1 : 0]   pack_q;
wire	                    pack_last;
wire	                    pack_empty;




pack_fifo #(
        .C_AF_LEV   (C_AF_LEV         ),
        .C_DW       (C_DW             ),
        .C_ADDR_W   (C_ADDR_W         ))
u_pack_fifo(
        //Inputs
        .din_last   (din_last         ),
        .rd_clk     (rd_clk           ),
        .rst        (rst              ),
        .pack_rdreq (pack_rdreq       ),
        .wr_clk     (wr_clk           ),
        .pack_gnt   (pack_gnt         ),
        .wrreq      (wrreq            ),
        .din        (din[C_DW-1:0]    ),
        //Outputs
        .overflow   (         ),
        .pack_empty (pack_empty       ),
        .pack_req   (pack_req         ),
        .full       (             ),
        .pack_last  (pack_last        ),
        .al_full    (al_full          ),
        .pack_q     (pack_q[C_DW-1:0] ));


packfifo_stream #(
        .C_DATA_W      (C_DATA_W                     ),
        .C_ID_W        (C_ID_W                       ),
        .C_TID         (C_TID                        ),
        .C_TDEST       (C_TDEST                      ))
u_packfifo_stream(
        //Inputs
        .pack_empty    (pack_empty                   ),
        .clk           (rd_clk                          ),
        .rst           (rst                          ),
        .pack_last     (pack_last                    ),
        .pack_q        (pack_q[C_DATA_W - 1 : 0]     ),
        .s_axis_tready (s_axis_tready                ),
        .pack_req      (pack_req                     ),
        //Outputs
        .s_axis_tuser  (            ),
        .s_axis_tvalid (s_axis_tvalid                ),
        .s_axis_tid    (   ),
        .dbg           (                  ),
        .s_axis_tstrb  (            ),
        .pack_rdreq    (pack_rdreq                   ),
        .s_axis_tkeep  (s_axis_tkeep[7:0]            ),
        .s_axis_tdata  (s_axis_tdata[C_DATA_W - 1:0] ),
        .s_axis_tlast  (s_axis_tlast                 ),
        .s_axis_tdest  ( ),
        .pack_gnt      (pack_gnt                     ));





endmodule
