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
   
   parameter num_ports = 4;
   parameter num_priorities = 4;
   parameter arbiter_type = `ARBITER_TYPE_ROUND_ROBIN_BINARY;
   parameter reset_type = `RESET_TYPE_ASYNC;
   
   parameter Tclk = 2;
   parameter runtime = 1000;
   parameter rate = 50;
   parameter initial_seed = 0;
   
   localparam prio_width = clogb(num_priorities);
   
   reg clk;
   
   always
     begin
	clk <= 1'b1;
	#(Tclk/2);
	clk <= 1'b0;
	#(Tclk/2);
     end
   
   reg reset;
   
   initial
     begin
	
	reset = 1'b1;
	
	#(Tclk);
	
	reset = 1'b0;
	
	#(Tclk);
	
	#(runtime*Tclk);
	
	$finish;
	
     end
   
   reg [0:num_ports-1] enable;
   reg [0:num_ports*prio_width-1] priorities;
   
   integer 			  i;
   integer 			  seed = initial_seed;
   
   always @(posedge clk, posedge reset)
     begin
	
	for(i = 0; i < num_ports; i = i + 1)
	  begin
	     
	     enable[i] <= ($dist_uniform(seed, 0, 99) < rate);
	     priorities[i*prio_width +: prio_width]
	       <= $dist_uniform(seed, 0, num_priorities - 1);
	     
	  end
	
     end
   
   wire [0:num_ports-1] sel;
   c_prio_sel
     #(.num_ports(num_ports),
       .num_priorities(num_priorities))
   psel
     (.priorities(priorities),
      .enable(enable),
      .select(sel));
   
   reg [0:num_priorities*num_ports-1] req;
   
   integer 			      j;
   
   always @(enable, priorities)
     begin
	
	for(i = 0; i < num_priorities; i = i + 1)
	  for(j = 0; j < num_ports; j = j + 1)
	    req[i*num_ports+j] = enable[j] && 
		  (priorities[j*prio_width +: prio_width] == 
		   (num_priorities - 1 - i));
	
     end
   
   wire update;
   assign update = |req;
   
   wire [0:num_priorities*num_ports-1] gnt;
   wire [0:num_ports-1] 	       granted;
   c_arbiter
     #(.num_ports(num_ports),
       .num_priorities(num_priorities),
       .arbiter_type(arbiter_type),
       .reset_type(reset_type))
   parb
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .update(update),
      .req_pr(req),
      .gnt_pr(gnt),
      .gnt(granted));
   
   wire [0:num_ports-1] 	  error;
   assign error = granted & ~sel;
   
   always @(negedge clk)
     begin
	
	if(|error)
	  begin
	     
	     $display($time, " ERROR:");
	     $display($time, "  sel=%b", sel);
	     $display($time, "  req=%b", req);
	     $display($time, "  gnt=%b", gnt);
	     $display($time, "  err=%b", error);
	     
	     for(i = 0; i < num_ports; i = i + 1)
	       begin
		  $display($time, " %d = %b %b", i, enable[i], 
			   priorities[i*prio_width +: prio_width]);
	       end
	     
	     $stop;
	     
	  end
	
     end
   
endmodule
