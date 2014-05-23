// $Id: testbench.v 5188 2012-08-30 00:31:31Z dub $

/*
 Copyright (c) 2007-2012, Trustees of The Leland Stanford Junior University
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 Redistributions of source code must retain the above copyright notice, this 
 list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

`default_nettype none

module testbench
  ();
   
`include "c_functions.v"
`include "c_constants.v"
   
   parameter num_buffers = 8;
   parameter data_width = 16;
   parameter regfile_type = `REGFILE_TYPE_FF_2D;
   parameter enable_bypass = 1;
   parameter reset_type = `RESET_TYPE_ASYNC;
   parameter Tclk = 2;
   parameter runtime = 1000;
   parameter rate_in = 50;
   parameter rate_out = 50; 
   parameter initial_seed = 0;
   
   localparam addr_width = clogb(num_buffers);
   localparam free_width = clogb(num_buffers + 1);
   
   reg clk;
   reg reset;
   
   wire push;
   wire pop;
   reg [0:data_width-1] push_data;
   wire [0:data_width-1] pop_data;
   wire 		 ff_almost_empty;
   wire 		 ff_empty;
   wire 		 ff_full;
   wire [0:1] 		 ff_errors;
   
   c_fifo
     #(.depth(num_buffers),
       .width(data_width),
       .regfile_type(regfile_type),
       .enable_bypass(enable_bypass),
       .reset_type(reset_type))
   ff
     (.clk(clk),
      .reset(reset),
      .push_active(1'b1),
      .pop_active(1'b1),
      .push(push),
      .pop(pop),
      .push_data(push_data),
      .pop_data(pop_data),
      .almost_empty(ff_almost_empty),
      .empty(ff_empty),
      .full(ff_full),
      .errors(ff_errors));
   
   wire 		 ft_almost_empty;
   wire 		 ft_empty;
   wire 		 ft_almost_full;
   wire 		 ft_full;
   wire [0:free_width-1] ft_free;
   wire [0:1] 		 ft_errors;
   
   c_fifo_tracker
     #(.depth(num_buffers),
       .enable_bypass(enable_bypass),
       .reset_type(reset_type))
   ft
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .push(push),
      .pop(pop),
      .almost_empty(ft_almost_empty),
      .empty(ft_empty),
      .almost_full(ft_almost_full),
      .full(ft_full),
      .two_free(ft_free),
      .errors(ft_errors));
   
   always
   begin
      clk <= 1'b1;
      #(Tclk/2);
      clk <= 1'b0;
      #(Tclk/2);
   end

   wire [0:data_width-1] push_data_next;
   
   assign push_data_next = reset ? {data_width{1'b0}} : (push_data + push);
   
   reg drain;
   reg flag_in, flag_out;

   assign push = ~reset & flag_in & ~ff_full;
   
   generate
      if(enable_bypass)
	assign pop = ~reset & flag_out & (~ff_empty | push);
      else
	assign pop = ~reset & flag_out & ~ff_empty;
   endgenerate
   
   integer seed = initial_seed;

   always @(posedge clk)
     begin
	flag_in <= ~drain && ($dist_uniform(seed, 0, 99) < rate_in);
	flag_out <= ($dist_uniform(seed, 0, 99) < rate_out);
	push_data <= push_data_next;
     end

   always @(negedge clk)
     begin
	if(push)
	  $display($time, " WRITE: %x.", push_data);
	if(pop)
	  $display($time, " READ:  %x.", pop_data);
	if(pop & (^pop_data === 1'bx))
	  begin
	     $display($time, " ERROR: read X value");
	     $stop;
	  end
	if((ff_almost_empty ^ ft_almost_empty) |
	   (ff_empty ^ ft_empty) |
	   (ff_full ^ ft_full))
	  begin
	     $display($time, " ERROR: c_fifo and c_fifo_tracker mismatch");
	     $stop;
	  end
     end
   
   initial
   begin
      reset = 1'b1;
      drain = 1'b0;

      #(Tclk);

      reset = 1'b0;

      #(runtime*Tclk);

      drain = 1'b1;

      while(!ff_empty)
	#(Tclk);
      
      $finish;
   end
      
endmodule
