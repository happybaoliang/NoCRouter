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
   
   parameter width = 4;
   
   parameter index = 0;
   
   parameter Tclk = 2;
   
   wire [0:width-1] feedback;
   c_fbgen
     #(.width(width),
       .index(index))
   fbgen
     (.feedback(feedback));
   
   reg 		    clk;
   reg 		    reset;
   reg 		    complete;
   reg 		    load;
   reg 		    run;
   reg [0:width-1]  d;
   
   wire [0:width-1] lfsr_q;
   c_lfsr
     #(.width(width))
   lfsr
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .load(load),
      .run(run),
      .feedback(feedback),
      .complete(complete),
      .d(d),
      .q(lfsr_q));
   
   wire [0:width-1] ulfsr_q;
   c_lfsr
     #(.width(width),
       .iterations(width))
   ulfsr
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .load(load),
      .run(run),
      .feedback(feedback),
      .complete(complete),
      .d(d),
      .q(ulfsr_q));
   
   always
   begin
      clk <= 1'b1;
      #(Tclk/2);
      clk <= 1'b0;
      #(Tclk/2);
   end
   
   integer i;
   
   initial
   begin
      reset = 1'b1;
      
      #(Tclk);
      
      #(Tclk/2);
      
      reset = 1'b0;
      
      complete = 1'b0;
      load = 1'b1;
      run = 1'b0;
      d = {width{1'b1}};
      
      #(Tclk);
      
      load = 1'b0;
      run = 1'b1;
      d = {width{1'b0}};
      
      $display("feedback=%x, complete=%b:", feedback, complete);
      
      for(i = 0; i < (1 << width); i = i + 1)
	begin
	   $display("%8d | %b (%x) | %b (%x)", 
		    i, lfsr_q, lfsr_q, ulfsr_q, ulfsr_q);
	   #(Tclk);
	end
      
      complete = 1'b1;
      load = 1'b1;
      run = 1'b0;
      d = {width{1'b1}};
      
      #(Tclk);
      
      load = 1'b0;
      run = 1'b1;
      d = {width{1'b0}};
      
      $display("feedback=%x, complete=%b:", feedback, complete);
      
      for(i = 0; i < ((1 << width) + 1); i = i + 1)
	begin
	   $display("%8d | %b (%x) | %b (%x)", 
		    i, lfsr_q, lfsr_q, ulfsr_q, ulfsr_q);
	   #(Tclk);
	end
      
      $finish;
   end
   
endmodule
