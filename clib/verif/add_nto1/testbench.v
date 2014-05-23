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
  #(parameter num_ports = 4,
    parameter width = 8,
    parameter Tclk = 2,
    parameter sim_cycles = 1000,
    parameter initial_seed = 0)
   ();

`include "c_functions.v"

   localparam out_width = clogb(num_ports) + width;

   wire [0:out_width-1] data_out;

   reg [0:num_ports*width-1] data_in;

   reg 			     clk;
   
   integer 		     seed = initial_seed;
   integer 		     i;
   
   always @(posedge clk)
     begin
	for(i = 0; i < num_ports; i = i + 1)
	  begin
	     data_in[i*width +: width]
	       = $dist_uniform(seed, 0, 2**width-1);
	  end
     end

   c_add_nto1
     #(.width(width),
       .num_ports(num_ports))
   dut
     (.data_in(data_in),
      .data_out(data_out));
   
   always
   begin
      clk <= 1'b1;
      #(Tclk/2);
      clk <= 1'b0;
      #(Tclk/2);
   end
   
   initial
   begin
      #(sim_cycles*Tclk);
      $finish;
   end
   
endmodule
