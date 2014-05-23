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
   
`include "c_constants.v"
`include "c_functions.v"
   
   parameter num_ports = 5;
   
   parameter arbiter_type = `ARBITER_TYPE_ROUND_ROBIN_BINARY;
   
   parameter reset_type = `RESET_TYPE_ASYNC;
   
   parameter Tclk = 2;
   
   parameter num_patterns = 1000;
   
   parameter initial_seed = 0;
   
   reg clk;
   reg reset;
   
   reg [0:num_ports-1] req;
   
   wire [0:num_ports-1] gnt;
   
   wire 		update;
   assign update = |req;
   
   c_arbiter
     #(.num_ports(num_ports),
       .num_priorities(1),
       .arbiter_type(arbiter_type),
       .reset_type(reset_type))
   dut
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .req_pr(req),
      .gnt_pr(gnt),
      .gnt(),
      .update(update));
   
   wire 		multi_hot_error;
   c_multi_hot_det
     #(.width(num_ports))
   mhd
     (.data(gnt),
      .multi_hot(multi_hot_error));
   
   wire [0:num_ports-1] stray_gnt_error;
   assign stray_gnt_error = gnt & ~req;
   
   always
   begin
      clk <= 1'b1;
      #(Tclk/2);
      clk <= 1'b0;
      #(Tclk/2);
   end

   integer i;
   integer seed;
   integer elapsed, total_elapsed;
   
   initial
   begin
      @(posedge clk);
      seed = initial_seed;
      total_elapsed = 0;
      req = {num_ports*num_ports{1'b0}};
      reset = 1'b1;
      @(posedge clk);
      reset = 1'b0;
      @(posedge clk);
      for(i = 0; i < num_patterns; i = i + 1)
	begin
	   req = $dist_uniform(seed, 0, 1 << num_ports - 1);
	   elapsed = 0;
	   while(|req)
	     begin
		@(posedge clk);
		elapsed = elapsed + 1;
		req = req & ~gnt;
	     end
	   total_elapsed = total_elapsed + elapsed;
	end
      $display("Granted %d request patterns in %d cycles.", 
	       num_patterns, total_elapsed);
      $finish;
   end
   
   always @(negedge clk)
     begin
	if(multi_hot_error)
	  begin
	     $display("Multiple grants detected!");
	     $display("Requests:");
	     $display(" %b", req);
	     $display("Grants:");
	     $display(" %b", gnt);
	     $stop;
	  end
	if(|stray_gnt_error)
	  begin
	     $display("Stray grant detected!");
	     $display("Requests:");
	     $display(" %b", req);
	     $display("Grants:");
	     $display(" %b", gnt);
	     $display("Stray grants:");
	     $display(" %b", stray_gnt_error);
	     $stop;
	  end
     end
   
endmodule
