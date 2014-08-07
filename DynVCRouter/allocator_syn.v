module allocator_syn(clk, reset, route_ip_ivc_op, route_ip_shared_ivc_op, route_ip_ivc_orc, 
   route_ip_shared_ivc_orc, allocated_ip_ivc, allocated_ip_shared_ivc, flit_valid_ip_ivc, 
   flit_valid_ip_shared_ivc, flit_head_ip_ivc, flit_head_ip_shared_ivc, flit_tail_ip_ivc, 
   flit_tail_ip_shared_ivc, elig_op_ovc, elig_op_shared_ovc, free_nonspec_ip_shared_ivc, 
   free_nonspec_ip_ivc, vc_active_op, shared_vc_active_op, vc_gnt_ip_ivc, vc_gnt_ip_shared_ivc, 
   vc_gnt_op_ovc, vc_gnt_op_shared_ovc, vc_sel_ip_ivc_ovc, vc_sel_ip_ivc_shared_ovc, 
   vc_sel_ip_shared_ivc_ovc, vc_sel_ip_shared_ivc_shared_ovc, vc_sel_op_ovc_ip, vc_sel_op_shared_ovc_ip, 
   vc_sel_op_ovc_ivc, vc_sel_op_shared_ovc_ivc, sw_active_op, sw_gnt_ip, shared_sw_gnt_ip, 
   sw_sel_ip_ivc, sw_sel_ip_shared_ivc, sw_gnt_op, sw_sel_op_ip, sw_sel_op_ivc, shared_vc_out_op,
   vc_sel_op_ovc_shared_ivc, vc_sel_op_shared_ovc_shared_ivc, shared_ovc_ip_ivc, shared_ovc_ip_shared_ivc, 
   sw_sel_op_shared_ivc, flit_head_op, flit_tail_op, xbr_ctrl_op_ip);
   
`include "c_functions.v"
`include "c_constants.v"
`include "rtr_constants.v"
`include "vcr_constants.v"
   
   // number of message classes (e.g. request, reply)
   parameter num_message_classes = 1;
   
   // number of resource classes (e.g. minimal, adaptive)
   parameter num_resource_classes = 1;
   
   // total number of packet classes
   localparam num_packet_classes = num_message_classes * num_resource_classes;
   
   // number of VCs per class
   parameter num_vcs_per_class = 15;
   
   // number of VCs
   localparam num_vcs = num_packet_classes * num_vcs_per_class;   

   // number of routers in each dimension
   parameter num_routers_per_dim = 4;
   
   // number of dimensions in network
   parameter num_dimensions = 2;
   
   // number of nodes per router (a.k.a. concentration factor)
   parameter num_nodes_per_router = 1;
   
   // connectivity within each dimension
   parameter connectivity = `CONNECTIVITY_LINE;
   
   // number of adjacent routers in each dimension
   localparam num_neighbors_per_dim
     = ((connectivity == `CONNECTIVITY_LINE) ||
	(connectivity == `CONNECTIVITY_RING)) ?
       2 :
       (connectivity == `CONNECTIVITY_FULL) ?
       (num_routers_per_dim - 1) :
       -1;
   
   // number of input and output ports on router
   localparam num_ports = num_dimensions * num_neighbors_per_dim + num_nodes_per_router;
   
   // select implementation variant for VC allocator
   parameter vc_alloc_type = `VC_ALLOC_TYPE_SEP_IF;
   
   // select which arbiter type to use for VC allocator
   parameter vc_alloc_arbiter_type = `ARBITER_TYPE_ROUND_ROBIN_BINARY;
   
   // select implementation variant for switch allocator
   parameter sw_alloc_type = `SW_ALLOC_TYPE_SEP_IF;
   
   // select which arbiter type to use for switch allocator
   parameter sw_alloc_arbiter_type = `ARBITER_TYPE_ROUND_ROBIN_BINARY;
   
   // select speculation type for switch allocator
   parameter sw_alloc_spec_type = `SW_ALLOC_SPEC_TYPE_REQ;
   
   parameter reset_type = `RESET_TYPE_ASYNC;
   
   input clk;
   input reset;
   
   // destination port selects
   input [0:num_ports*num_vcs*num_ports-1] 				route_ip_ivc_op;
   
   input [0:num_ports*num_vcs*num_ports-1] 				route_ip_shared_ivc_op;

   // select next resource class
   input [0:num_ports*num_vcs*num_resource_classes-1] 	route_ip_ivc_orc;
   
   input [0:num_ports*num_vcs*num_resource_classes-1] 	route_ip_shared_ivc_orc;

   // VC has output VC allocated to it
   input [0:num_ports*num_vcs-1] 		      			allocated_ip_ivc;
   
   input [0:num_ports*num_vcs-1] 		      			allocated_ip_shared_ivc;

   // VC has flit available
   input [0:num_ports*num_vcs-1] 		      			flit_valid_ip_ivc;
   
   input [0:num_ports*num_vcs-1] 		      			flit_valid_ip_shared_ivc;

   // flit is head flit
   input [0:num_ports*num_vcs-1] 		      			flit_head_ip_ivc;
   
   input [0:num_ports*num_vcs-1] 		      			flit_head_ip_shared_ivc;

   // flit is tail flit
   input [0:num_ports*num_vcs-1] 		      			flit_tail_ip_ivc;
   
   input [0:num_ports*num_vcs-1] 		      			flit_tail_ip_shared_ivc;

   // output VC is eligible for allocation (i.e., not currently allocated)
   input [0:num_ports*num_vcs-1] 		      			elig_op_ovc;
   
   input [0:num_ports*num_vcs-1]              			elig_op_shared_ovc;

   // credit availability if output VC has been allocated
   input [0:num_ports*num_vcs-1] 		      			free_nonspec_ip_ivc;
   
   input [0:num_ports*num_vcs-1] 		      			free_nonspec_ip_shared_ivc;

   input [0:num_ports*num_vcs-1]						shared_ovc_ip_ivc;

   input [0:num_ports*num_vcs-1]						shared_ovc_ip_shared_ivc;

   // VC allocation activity (to output controller)
   output [0:num_ports-1] 			          			vc_active_op;
   wire [0:num_ports-1] 			          			vc_active_op;
   
   output [0:num_ports-1]					  			shared_vc_active_op;
   wire [0:num_ports-1]						  			shared_vc_active_op;

   // VC allocation successful (to input controller)
   output [0:num_ports*num_vcs-1] 		      			vc_gnt_ip_ivc;
   wire [0:num_ports*num_vcs-1] 		      			vc_gnt_ip_ivc;

   output [0:num_ports*num_vcs-1]			  			vc_gnt_ip_shared_ivc;
   wire [0:num_ports*num_vcs-1]				  			vc_gnt_ip_shared_ivc;

   // granted output VC (to input controller)
   output [0:num_ports*num_vcs*num_vcs-1] 	  			vc_sel_ip_ivc_ovc;
   wire [0:num_ports*num_vcs*num_vcs-1] 	  			vc_sel_ip_ivc_ovc;

   // used to generate the 'shared_vc_in' signal
   output [0:num_ports*num_vcs-1]						vc_sel_ip_ivc_shared_ovc;
   wire [0:num_ports*num_vcs-1]							vc_sel_ip_ivc_shared_ovc;
   
   // granted output VC (to input controller)
   output [0:num_ports*num_vcs*num_vcs-1] 	  			vc_sel_ip_shared_ivc_ovc;
   wire [0:num_ports*num_vcs*num_vcs-1] 	  			vc_sel_ip_shared_ivc_ovc;
 
   // used to generate the 'shared_vc_in' signal
   output [0:num_ports*num_vcs-1]						vc_sel_ip_shared_ivc_shared_ovc;
   wire [0:num_ports*num_vcs-1]							vc_sel_ip_shared_ivc_shared_ovc;
   
   // output VC was granted (to output controller)
   output [0:num_ports*num_vcs-1] 		      			vc_gnt_op_ovc;
   wire [0:num_ports*num_vcs-1] 		      			vc_gnt_op_ovc;
   
   output [0:num_ports*num_vcs-1]			  			vc_gnt_op_shared_ovc;
   wire [0:num_ports*num_vcs-1]				  			vc_gnt_op_shared_ovc;

   // input port that each output VC was granted to (to output controller)
   output [0:num_ports*num_vcs*num_ports-1]   			vc_sel_op_ovc_ip;
   wire [0:num_ports*num_vcs*num_ports-1] 	  			vc_sel_op_ovc_ip;
   
   output [0:num_ports*num_vcs*num_ports-1]				vc_sel_op_shared_ovc_ip;
   wire [0:num_ports*num_vcs*num_ports-1]				vc_sel_op_shared_ovc_ip; 

   // input VC that each output VC was granted to (to output controller)
   output [0:num_ports*num_vcs*num_vcs-1] 	  			vc_sel_op_ovc_ivc;
   wire [0:num_ports*num_vcs*num_vcs-1] 	  			vc_sel_op_ovc_ivc;
   
   // input VC that each output VC was granted to (to output controller)
   output [0:num_ports*num_vcs*num_vcs-1] 	  			vc_sel_op_shared_ovc_ivc;
   wire [0:num_ports*num_vcs*num_vcs-1] 	  			vc_sel_op_shared_ovc_ivc;
   
   // input VC that each output VC was granted to (to output controller)
   output [0:num_ports*num_vcs-1] 	  					vc_sel_op_ovc_shared_ivc;
   wire [0:num_ports*num_vcs-1] 	  					vc_sel_op_ovc_shared_ivc;
   
   // input VC that each output VC was granted to (to output controller)
   output [0:num_ports*num_vcs-1] 	  					vc_sel_op_shared_ovc_shared_ivc; 
   wire [0:num_ports*num_vcs-1] 	  					vc_sel_op_shared_ovc_shared_ivc;
   
   // switch allocation activity (to output controller)
   output [0:num_ports-1] 			      	  			sw_active_op;
   wire [0:num_ports-1] 			      	  			sw_active_op;
  
   // port grants (to input controller)
   output [0:num_ports-1] 			      	  			sw_gnt_ip;
   wire [0:num_ports-1] 			          			sw_gnt_ip;
  
   output [0:num_ports-1]								shared_sw_gnt_ip;
   wire [0:num_ports-1]									shared_sw_gnt_ip;

   // indicate which VC at a given port is granted (to input controller)
   output [0:num_ports*num_vcs-1] 		  				sw_sel_ip_ivc;
   wire [0:num_ports*num_vcs-1] 		  				sw_sel_ip_ivc;

   output [0:num_ports*num_vcs-1]		  				sw_sel_ip_shared_ivc;
   wire [0:num_ports*num_vcs-1]			  				sw_sel_ip_shared_ivc;

   // output port grants
   output [0:num_ports-1] 			      				sw_gnt_op;
   wire [0:num_ports-1] 			      				sw_gnt_op;
   
   // selected output ports for grants
   output [0:num_ports*num_ports-1] 	  				sw_sel_op_ip;
   wire [0:num_ports*num_ports-1] 		  				sw_sel_op_ip;
  
   // selected output VCs for grants
   output [0:num_ports*num_vcs-1] 		  				sw_sel_op_ivc;
   wire [0:num_ports*num_vcs-1] 		  				sw_sel_op_ivc;
 
   output [0:num_ports-1]								sw_sel_op_shared_ivc;
   wire [0:num_ports-1]									sw_sel_op_shared_ivc;

   output [0:num_ports-1]								shared_vc_out_op;
   wire [0:num_ports-1]									shared_vc_out_op;

   // which grants are for head flits
   output [0:num_ports-1] 			      				flit_head_op;
   wire [0:num_ports-1] 			      				flit_head_op;
   
   // which grants are for tail flits
   output [0:num_ports-1] 			      				flit_tail_op;
   wire [0:num_ports-1] 			     	 			flit_tail_op;
   
   // crossbar control signals
   output [0:num_ports*num_ports-1] 	  				xbr_ctrl_op_ip;
   wire [0:num_ports*num_ports-1] 		  				xbr_ctrl_op_ip;

   vcr_alloc_mac
     #(.num_message_classes(num_message_classes),
       .num_resource_classes(num_resource_classes),
       .num_vcs_per_class(num_vcs_per_class),
       .num_ports(num_ports),
       .vc_allocator_type(vc_alloc_type),
       .vc_arbiter_type(vc_alloc_arbiter_type),
       .sw_allocator_type(sw_alloc_type),
       .sw_arbiter_type(sw_alloc_arbiter_type),
       .spec_type(sw_alloc_spec_type),
       .reset_type(reset_type))
   alo
     (.clk(clk),
      .reset(reset),
      .route_ip_ivc_op(route_ip_ivc_op),
      .route_ip_shared_ivc_op(route_ip_shared_ivc_op),
      .route_ip_ivc_orc(route_ip_ivc_orc),
      .route_ip_shared_ivc_orc(route_ip_shared_ivc_orc),
      .allocated_ip_ivc(allocated_ip_ivc),
      .allocated_ip_shared_ivc(allocated_ip_shared_ivc),
      .flit_valid_ip_ivc(flit_valid_ip_ivc),
      .flit_valid_ip_shared_ivc(flit_valid_ip_shared_ivc),
      .flit_head_ip_ivc(flit_head_ip_ivc),
      .flit_head_ip_shared_ivc(flit_head_ip_shared_ivc),
      .flit_tail_ip_ivc(flit_tail_ip_ivc),
      .flit_tail_ip_shared_ivc(flit_tail_ip_shared_ivc),
	  .shared_ovc_ip_ivc(shared_ovc_ip_ivc),
	  .shared_ovc_ip_shared_ivc(shared_ovc_ip_shared_ivc),
      .elig_op_ovc(elig_op_ovc),
      .elig_op_shared_ovc(elig_op_shared_ovc),
      .free_nonspec_ip_ivc(free_nonspec_ip_ivc),
      .free_nonspec_ip_shared_ivc(free_nonspec_ip_shared_ivc),
      .vc_active_op(vc_active_op),
	  .shared_vc_active_op(shared_vc_active_op),
      .vc_gnt_ip_ivc(vc_gnt_ip_ivc),
	  .vc_gnt_ip_shared_ivc(vc_gnt_ip_shared_ivc),
	  .vc_sel_ip_ivc_ovc(vc_sel_ip_ivc_ovc),
      .vc_sel_ip_shared_ivc_ovc(vc_sel_ip_shared_ivc_ovc),
	  .vc_sel_ip_ivc_shared_ovc(vc_sel_ip_ivc_shared_ovc),
	  .vc_sel_ip_shared_ivc_shared_ovc(vc_sel_ip_shared_ivc_shared_ovc),
	  .vc_gnt_op_ovc(vc_gnt_op_ovc),
	  .vc_gnt_op_shared_ovc(vc_gnt_op_shared_ovc),
      .vc_sel_op_ovc_ip(vc_sel_op_ovc_ip),
      .vc_sel_op_shared_ovc_ip(vc_sel_op_shared_ovc_ip),
	  .vc_sel_op_ovc_ivc(vc_sel_op_ovc_ivc),
      .vc_sel_op_ovc_shared_ivc(vc_sel_op_ovc_shared_ivc),
	  .vc_sel_op_shared_ovc_ivc(vc_sel_op_shared_ovc_ivc),
	  .vc_sel_op_shared_ovc_shared_ivc(vc_sel_op_shared_ovc_shared_ivc),
	  .sw_active_op(sw_active_op),
      .sw_gnt_ip(sw_gnt_ip),
      .shared_sw_gnt_ip(shared_sw_gnt_ip),
	  .sw_sel_ip_ivc(sw_sel_ip_ivc),
      .sw_sel_ip_shared_ivc(sw_sel_ip_shared_ivc),
      .shared_vc_out_op(shared_vc_out_op),
	  .sw_gnt_op(sw_gnt_op),
	  .sw_sel_op_ip(sw_sel_op_ip),
	  .sw_sel_op_ivc(sw_sel_op_ivc),
	  .sw_sel_op_shared_ivc(sw_sel_op_shared_ivc),
	  .flit_head_op(flit_head_op),
	  .flit_tail_op(flit_tail_op),
	  .xbr_ctrl_op_ip(xbr_ctrl_op_ip));
 

endmodule
