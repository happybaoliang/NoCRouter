//==============================================================================
// generic arbiter
//==============================================================================

module c_arbiter(clk, reset, active, req_pr, gnt_pr, gnt, update);
   
`include "c_functions.v"
`include "c_constants.v"
   
   // number of input ports
   parameter num_ports = 32;
   
   // number of priority levels
   parameter num_priorities = 1;
   
   // number fo bits required to select a port
   localparam port_idx_width = clogb(num_ports);
   
   // select type of arbiter to use
   parameter arbiter_type = `ARBITER_TYPE_ROUND_ROBIN_BINARY;
   
   // for round-robin style arbiters, should state be stored in encoded form?
   localparam encode_state = (arbiter_type==`ARBITER_TYPE_ROUND_ROBIN_BINARY) || (arbiter_type==`ARBITER_TYPE_PREFIX_BINARY);
   
   parameter reset_type = `RESET_TYPE_ASYNC;
   
   input clk;
   input reset;
   input active;
   
   // request vector
   input [0:num_priorities*num_ports-1] req_pr;
   
   // grant vector
   output [0:num_priorities*num_ports-1] gnt_pr;
   wire [0:num_priorities*num_ports-1] 	 gnt_pr;
   
   // merged grant vector
   output [0:num_ports-1] 		 gnt;
   wire [0:num_ports-1] 		 gnt;
   
   // update port priorities
   input 				 update;
   
   generate
      if(num_ports == 1)
	begin
	   c_lod
	     #(.width(num_priorities))
	   gnt_lod
	     (.data_in(req_pr),
	      .data_out(gnt_pr));
	   assign gnt = |req_pr;
	end
      else if(num_ports > 1)
	begin
	   case(arbiter_type)
	     `ARBITER_TYPE_ROUND_ROBIN_BINARY,
	     `ARBITER_TYPE_ROUND_ROBIN_ONE_HOT:
	       begin
		  c_rr_arbiter
		    #(.num_ports(num_ports),
		      .num_priorities(num_priorities),
		      .encode_state(encode_state),
		      .reset_type(reset_type))
		  rr_arb
		    (.clk(clk),
		     .reset(reset),
		     .active(active),
		     .req_pr(req_pr),
		     .gnt_pr(gnt_pr),
		     .gnt(gnt),
		     .update(update));
	       end
	     `ARBITER_TYPE_PREFIX_BINARY, `ARBITER_TYPE_PREFIX_ONE_HOT:
	       begin
		  c_prefix_arbiter
		    #(.num_ports(num_ports),
		      .num_priorities(num_priorities),
		      .encode_state(encode_state),
		      .reset_type(reset_type))
		  prefix_arb
		    (.clk(clk),
		     .reset(reset),
		     .active(active),
		     .req_pr(req_pr),
		     .gnt_pr(gnt_pr),
		     .gnt(gnt),
		     .update(update));
	       end
	     `ARBITER_TYPE_MATRIX:
	       begin
		  c_matrix_arbiter
		    #(.num_ports(num_ports),
		      .num_priorities(num_priorities),
		      .reset_type(reset_type))
		  matrix_arb
		    (.clk(clk),
		     .reset(reset),
		     .active(active),
		     .req_pr(req_pr),
		     .gnt_pr(gnt_pr),
		     .gnt(gnt),
		     .update(update));
	       end
	   endcase
	end
   endgenerate
endmodule
