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
   
   parameter num_ports = 8;

   parameter num_priorities = 2;
   
   parameter skip_empty_diags = 1;
   
   parameter wf_alloc_type = `WF_ALLOC_TYPE_DPA;
   
   parameter reset_type = `RESET_TYPE_ASYNC;
   
   parameter Tclk = 2;
   
   parameter num_patterns = 1000;
   
   parameter initial_seed = 0;
   
   reg clk;
   reg reset;
   
   reg [0:num_priorities*num_ports*num_ports-1] req_pr;
   
   wire [0:num_priorities*num_ports*num_ports-1] gnt_pr;
   wire [0:num_ports*num_ports-1] 		 gnt;
   
   wire 			  update;
   assign update = |req_pr;
   
   c_wf_alloc
     #(.num_ports(num_ports),
       .num_priorities(num_priorities),
	.skip_empty_diags(skip_empty_diags),
       .wf_alloc_type(wf_alloc_type),
       .reset_type(reset_type))
   dut
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .req_pr(req_pr),
      .gnt_pr(gnt_pr),
      .gnt(gnt),
      .update(update));
   
   wire [0:num_ports*num_ports-1] gnt_xp;
   c_interleave
     #(.width(num_ports*num_ports),
       .num_blocks(num_ports))
   gnt_xp_intl
     (.data_in(gnt),
      .data_out(gnt_xp));
   
   wire [0:num_ports*num_ports*num_priorities-1] gnt_pr_xp;
   c_interleave
     #(.width(num_priorities*num_ports*num_ports),
       .num_blocks(num_priorities))
   gnt_pr_xp_intl
     (.data_in(gnt_pr),
      .data_out(gnt_pr_xp));
   
   wire [0:num_ports-1] 	  row_multi_hot_error;
   wire [0:num_ports-1] 	  col_multi_hot_error;
   
   wire [0:num_ports*num_ports-1] pr_row_multi_hot_error;
   wire [0:num_ports*num_ports-1] pr_col_multi_hot_error;
   
   generate
      
      genvar 			  idx;
   
      for(idx = 0; idx < num_ports; idx = idx + 1)
	begin:idxs
	   
	   c_multi_hot_det
	     #(.width(num_ports))
	   row_mhd
	     (.data(gnt[idx*num_ports:(idx+1)*num_ports-1]),
	      .multi_hot(row_multi_hot_error[idx]));
	   
	   c_multi_hot_det
	     #(.width(num_ports))
	   col_mhd
	     (.data(gnt_xp[idx*num_ports:(idx+1)*num_ports-1]),
	      .multi_hot(col_multi_hot_error[idx]));
	   
	   genvar 			  idx2;
	   
	   for(idx2 = 0; idx2 < num_ports; idx2 = idx2 + 1)
	     begin:idx2s
		
		c_multi_hot_det
		  #(.width(num_priorities))
		pr_row_mhd
		  (.data(gnt_pr_xp[(idx*num_ports+idx2)*num_priorities:
				   (idx*num_ports+idx2+1)*num_priorities-1]),
		   .multi_hot(pr_row_multi_hot_error[idx*num_ports+idx2]));
		
		c_multi_hot_det
		  #(.width(num_priorities))
		pr_col_mhd
		  (.data(gnt_pr_xp[(idx*num_ports+idx2)*num_priorities:
				   (idx*num_ports+idx2+1)*num_priorities-1]),
		   .multi_hot(pr_col_multi_hot_error[idx*num_ports+idx2]));
		
	     end
	   
	end
      
   endgenerate
   
   wire [0:num_priorities*num_ports*num_ports-1] stray_gnt_error;
   assign stray_gnt_error = gnt_pr & ~req_pr;
   
   wire [0:num_priorities*num_ports*num_ports-1] inconsistent_gnt_error;
   assign inconsistent_gnt_error = gnt_pr & ~{num_priorities{gnt}};
   
   always
   begin
      clk <= 1'b1;
      #(Tclk/2);
      clk <= 1'b0;
      #(Tclk/2);
   end

   integer i, j, k;
   integer seed;
   integer elapsed, total_elapsed;
   
   initial
   begin
      @(posedge clk);
      seed = initial_seed;
      total_elapsed = 0;
      req_pr = {num_priorities*num_ports*num_ports{1'b0}};
      reset = 1'b1;
      @(posedge clk);
      reset = 1'b0;
      @(posedge clk);
      for(i = 0; i < num_patterns; i = i + 1)
	begin
	   for(j = 0; j < num_priorities; j = j + 1)
	     for(k = 0; k < num_ports; k = k + 1)
	       req_pr[(j*num_ports+k)*num_ports +: num_ports]
	         = $dist_uniform(seed, 0, 1 << num_ports - 1);
	   elapsed = 0;
	   while(|req_pr)
	     begin
		@(posedge clk);
		elapsed = elapsed + 1;
		req_pr = req_pr & ~gnt_pr;
	     end
	   total_elapsed = total_elapsed + elapsed;
	end
      $display("Generated %d matchings in %d cycles.", 
	       num_patterns, total_elapsed);
      $finish;
   end
   
   always @(negedge clk)
     begin
	if(|row_multi_hot_error)
	  begin
	     $display("Multiple grants per input detected!");
	     $display("Request matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", req_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $display("Grant matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", gnt_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $stop;
	  end
	if(|col_multi_hot_error)
	  begin
	     $display("Multiple grants per output detected!");
	     $display("Request matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", req_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $display("Grant matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", gnt_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $stop;
	  end
	if(|pr_row_multi_hot_error)
	  begin
	     $display("Multiple priority grants per input detected!");
	     $display("Request matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", req_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $display("Grant matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", gnt_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $stop;
	  end
	if(|pr_col_multi_hot_error)
	  begin
	     $display("Multiple priority grants per output detected!");
	     $display("Request matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", req_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $display("Grant matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", gnt_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $stop;
	  end
	if(|stray_gnt_error)
	  begin
	     $display("Stray grant detected!");
	     $display("Request matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", req_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $display("Grant matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", gnt_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $display("Stray grant matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
	       $display(" %b", stray_gnt_error[(i*num_ports+j)*num_ports +: num_ports]);
	     $stop;
	  end
	if(|inconsistent_gnt_error)
	  begin
	     $display("Inconsistent grant detected!");
	     $display("Request matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", req_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $display("Grant matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
		 $display(" %b", gnt_pr[(i*num_ports+j)*num_ports +: num_ports]);
	     $display("Stray grant matrix:");
	     for(i = 0; i < num_priorities; i = i + 1)
	       for(j = 0; j < num_ports; j = j + 1)
	       $display(" %b", stray_gnt_error[(i*num_ports+j)*num_ports +: num_ports]);
	     $stop;
	  end
     end
   
endmodule
