// $Id: vcr_top.v 5188 2012-08-30 00:31:31Z dub $

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

//==============================================================================
// top-level module for virtual channel router
//==============================================================================

module vcr_top (clk, reset, router_address, channel_in_ip, memory_bank_grant_in,
	memory_bank_grant_out, shared_vc_in, shared_vc_out, flow_ctrl_out_ip, error,
	credit_for_shared_in, credit_for_shared_out, channel_out_op, flow_ctrl_in_op,
	ready_for_allocation_in, ready_for_allocation_out, ip_shared_ivc_allocated_in,
	ip_shared_ivc_allocated_out);
   
`include "c_functions.v"
`include "c_constants.v"
`include "rtr_constants.v"
`include "vcr_constants.v"
   
   // total buffer size per port in flits
   parameter buffer_size = 32;
   
   // number of message classes (e.g. request, reply)
   parameter num_message_classes = 2;
   
   // number of resource classes (e.g. minimal, adaptive)
   parameter num_resource_classes = 2;
   
   // width required to select individual resource class
   localparam resource_class_idx_width = clogb(num_resource_classes);
   
   // total number of packet classes
   localparam num_packet_classes = num_message_classes * num_resource_classes;
   
   // number of VCs per class
   parameter num_vcs_per_class = 1;
   
   // number of VCs
   localparam num_vcs = num_packet_classes * num_vcs_per_class;   

   // width required to select individual VC
   localparam vc_idx_width = clogb(num_vcs);
   
   // number of routers in each dimension
   parameter num_routers_per_dim = 4;
   
   // width required to select individual router in a dimension
   localparam dim_addr_width = clogb(num_routers_per_dim);
   
   // number of dimensions in network
   parameter num_dimensions = 2;
   
   // width required to select individual router in entire network
   localparam router_addr_width = num_dimensions * dim_addr_width;
   
   // number of nodes per router (a.k.a. concentration factor)
   parameter num_nodes_per_router = 1;
   
   // width required to select individual node at current router
   localparam node_addr_width = clogb(num_nodes_per_router);
   
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
   
   localparam memory_bank_size = buffer_size / num_ports;

   localparam num_vcs_per_bank = num_vcs / num_ports;

   // select packet format
   parameter packet_format = `PACKET_FORMAT_EXPLICIT_LENGTH;
   
   // select type of flow control
   parameter flow_ctrl_type = `FLOW_CTRL_TYPE_CREDIT;
   
   // make incoming flow control signals bypass the output VC state tracking logic
   parameter flow_ctrl_bypass = 1;
   
   // width of flow control signals
   localparam flow_ctrl_width = (flow_ctrl_type == `FLOW_CTRL_TYPE_CREDIT) ? (1 + vc_idx_width) : -1;
   
   // maximum payload length (in flits)
   // (note: only used if packet_format==`PACKET_FORMAT_EXPLICIT_LENGTH)
   parameter max_payload_length = 4;
   
   // minimum payload length (in flits)
   // (note: only used if packet_format==`PACKET_FORMAT_EXPLICIT_LENGTH)
   parameter min_payload_length = 1;
   
   // number of bits required to represent all possible payload sizes
   localparam payload_length_width = clogb(max_payload_length-min_payload_length+1);

   // enable link power management
   parameter enable_link_pm = 1;
   
   // width of link management signals
   localparam link_ctrl_width = enable_link_pm ? 1 : 0;
   
   // width of flit control signals
   localparam flit_ctrl_width
     = (packet_format == `PACKET_FORMAT_HEAD_TAIL) ? 
       (1 + vc_idx_width + 1 + 1) : 
       (packet_format == `PACKET_FORMAT_TAIL_ONLY) ? 
       (1 + vc_idx_width + 1) : 
       (packet_format == `PACKET_FORMAT_EXPLICIT_LENGTH) ? 
       (1 + vc_idx_width + 1) : 
       -1;
   
   // width of flit payload data
   parameter flit_data_width = 64;
   
   // channel width
   localparam channel_width = link_ctrl_width + flit_ctrl_width + flit_data_width;
   
   // configure error checking logic
   parameter error_capture_mode = `ERROR_CAPTURE_MODE_NO_HOLD;
   
   // filter out illegal destination ports (the intent is to allow synthesis to 
   // optimize away the logic associated with such turns)
   parameter restrict_turns = 1;
   
   // select routing function type
   parameter routing_type = `ROUTING_TYPE_PHASED_DOR;
   
   // select order of dimension traversal
   parameter dim_order = `DIM_ORDER_ASCENDING;
   
   // total number of bits required for storing routing information
   localparam dest_info_width
     = (routing_type == `ROUTING_TYPE_PHASED_DOR) ? 
       (num_resource_classes * router_addr_width + node_addr_width) : 
       -1;
   
   // width required to select an individual port
   localparam port_idx_width = clogb(num_ports);
   
   // width required for lookahead routing information
   localparam lar_info_width = port_idx_width + resource_class_idx_width;
   
   // total number of bits required for routing-related information
   localparam route_info_width = lar_info_width + dest_info_width;
   
   // total number of bits of header information encoded in header flit payload
   localparam header_info_width
     = (packet_format == `PACKET_FORMAT_HEAD_TAIL) ? 
       route_info_width : 
       (packet_format == `PACKET_FORMAT_TAIL_ONLY) ? 
       route_info_width : 
       (packet_format == `PACKET_FORMAT_EXPLICIT_LENGTH) ? 
       (route_info_width + payload_length_width) : 
       -1;
   
   // select implementation variant for flit buffer register file
   parameter fb_regfile_type = `REGFILE_TYPE_FF_2D;
   
   // select flit buffer management scheme
   parameter fb_mgmt_type = `FB_MGMT_TYPE_STATIC;
   
   // improve timing for peek access
   parameter fb_fast_peek = 1;
   
   // EXPERIMENTAL:
   // for dynamic buffer management, only reserve a buffer slot for a VC while 
   // it is active (i.e., while a packet is partially transmitted)
   // (NOTE: This is currently broken!)
   parameter disable_static_reservations = 0;
   
   // use explicit pipeline register between flit buffer and crossbar?
   parameter explicit_pipeline_register = 0;
   
   // gate flit buffer write port if bypass succeeds
   // (requires explicit pipeline register; may increase cycle time)
   parameter gate_buffer_write = 0;
   
   // select whether to exclude full or non-empty VCs from VC allocation
   parameter elig_mask = `ELIG_MASK_NONE;
   
   // generate almost_empty signal early on in clock cycle
   localparam fast_almost_empty = flow_ctrl_bypass && (elig_mask == `ELIG_MASK_USED);

   // VC allocation is atomic
   localparam atomic_vc_allocation = (elig_mask == `ELIG_MASK_USED);
   
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
   
   // select implementation variant for crossbar
   parameter crossbar_type = `CROSSBAR_TYPE_MUX;
   
   parameter reset_type = `RESET_TYPE_ASYNC;
   
   input clk;
   input reset;
   
   // current router's address
   input [0:router_addr_width-1] 	        router_address;
   
   // incoming channels
   input [0:num_ports*channel_width-1]      channel_in_ip;
   
   input [0:num_ports*num_ports-1]	        memory_bank_grant_in;

   output [0:num_ports*num_ports-1]	        memory_bank_grant_out;
   wire [0:num_ports*num_ports-1]	        memory_bank_grant_out;

   input [0:num_ports-1]		            shared_vc_in;

   output [0:num_ports-1]		            shared_vc_out;
   wire [0:num_ports-1]			            shared_vc_out; 
   
   // outgoing flow control signals
   output [0:num_ports*flow_ctrl_width-1]   flow_ctrl_out_ip;
   wire [0:num_ports*flow_ctrl_width-1]     flow_ctrl_out_ip;
   
   output [0:num_ports-1]		            credit_for_shared_out;
   wire [0:num_ports-1]			            credit_for_shared_out;

   // outgoing channels
   output [0:num_ports*channel_width-1]     channel_out_op;
   wire [0:num_ports*channel_width-1] 	    channel_out_op;
   
   // incoming flow control signals
   input [0:num_ports*flow_ctrl_width-1]    flow_ctrl_in_op;

   input [0:num_ports-1]		            credit_for_shared_in;
   
   input [0:num_ports-1]					ready_for_allocation_in;

   output [0:num_ports-1]					ready_for_allocation_out;
   wire [0:num_ports-1]						ready_for_allocation_out;

   input [0:num_ports*num_vcs-1]			ip_shared_ivc_allocated_in;

   output [0:num_ports*num_vcs-1]			ip_shared_ivc_allocated_out;
   wire [0:num_ports*num_vcs-1]				ip_shared_ivc_allocated_out;

   // internal error condition detected
   output 				                    error;
   wire 				                    error;
   
   
   //---------------------------------------------------------------------------
   // input ports
   //---------------------------------------------------------------------------
   wire [0:num_ports-1] 			                    sw_gnt_ip;
   wire [0:num_ports-1] 			                    sw_gnt_op;
   wire [0:num_ports*num_vcs-1] 		                full_op_ovc;
   wire [0:num_ports-1] 			                    ipc_error_ip;
   wire [0:num_ports*num_vcs-1] 		                sw_sel_ip_ivc;
   wire [0:num_ports*num_vcs-1] 		                vc_gnt_ip_ivc;
   wire [0:num_ports*flit_data_width-1] 	            xbr_data_in_ip;
   wire [0:num_ports*num_vcs*num_ports-1] 	            route_ip_ivc_op;
   wire [0:num_ports*num_vcs*num_resource_classes-1]    route_ip_ivc_orc;
   wire [0:num_ports*num_vcs-1] 		                allocated_ip_ivc;
   wire [0:num_ports*num_vcs-1] 		                flit_head_ip_ivc;
   wire [0:num_ports*num_vcs-1] 		                flit_tail_ip_ivc;
   wire [0:num_ports*num_vcs-1] 		                flit_valid_ip_ivc;
   wire [0:num_ports*num_vcs*num_vcs-1] 	            vc_sel_ip_ivc_ovc;
   wire [0:num_ports*num_vcs-1]							shared_ovc_ip_ivc;
   wire [0:num_ports*num_vcs-1] 		                almost_full_op_ovc;
   wire [0:num_ports*num_vcs-1] 		                free_nonspec_ip_ivc;
   wire [0:num_vcs-1] 		             				shared_allocated_ivc;
   wire [0:num_ports*num_vcs-1]							vc_sel_ip_ivc_shared_ovc;

   wire [0:num_ports-1]			     	    			shared_fb_full;
   wire [0:num_ports-1]		    						shared_sw_gnt_ip; 
   wire [0:num_ports-1]				                    shared_fb_push_head;
   wire [0:num_ports-1]	     	     		            shared_fb_push_tail;
   wire [0:num_ports*flit_data_width-1] 	            shared_fb_push_data;
   wire [0:num_ports-1]	     	     		            shared_fb_push_valid;
   wire [0:num_ports*num_vcs-1]	     		            shared_fb_push_sel_ivc;
   wire [0:num_ports*num_vcs-1] 	     	            shared_fb_push_head_ivc;
   wire [0:num_ports*num_vcs-1] 	     	            shared_fb_push_tail_ivc;

   // connecting sharing memory bank
   wire [0:num_ports*flit_data_width-1]     			shared_fb_flit_data;
   wire [0:num_vcs-1]	     			    			shared_fb_empty_ivc;
   wire [0:num_ports*num_vcs-1]		        			vc_gnt_ip_shared_ivc;
   wire [0:num_ports*num_vcs-1]							sw_sel_ip_shared_ivc;
   wire [0:num_vcs*2-1]	     			    			shared_fb_errors_ivc;
   wire [0:num_vcs_per_bank*num_ports-1]    			shared_fb_pop_tail_ivc;
   wire [0:num_ports*flow_ctrl_width-1]					shared_fb_flow_ctrl_out;
   wire [0:num_vcs-1]	     			    			shared_fb_almost_empty_ivc;
   wire [0:num_ports*header_info_width-1]   			shared_fb_pop_next_header_info;  


   // mapping 'memory_bank_grant' to 'memory_bank_grant_out'
   wire [0:num_ports*num_ports-1] memory_bank_grant;
   //assign memory_bank_grant = 25'b10000_01000_00100_00010_00001;//pass


   genvar gnt1,gnt2;
   generate
   	wire [0:num_ports*num_ports-1] memory_bank_grant_out_sel;
	
	for (gnt1=0;gnt1<num_ports;gnt1=gnt1+1)
	begin:gnts1
		wire [0:num_ports-1] grant_out;
		for (gnt2=0;gnt2<num_ports;gnt2=gnt2+1)
		begin:gnts2
			assign grant_out[gnt2] =  memory_bank_grant[gnt2*num_ports+gnt1];
		end
		assign memory_bank_grant_out_sel[gnt1*num_ports:(gnt1+1)*num_ports-1] = grant_out;
	end
   
	assign memory_bank_grant_out = memory_bank_grant_out_sel;
   endgenerate


   generate
      genvar 					     ip;
      for (ip = 0; ip < num_ports; ip = ip + 1)
	begin:ips
	   //-------------------------------------------------------------------
	   // input controller
	   //-------------------------------------------------------------------
	   wire 		      sw_gnt;
	   assign sw_gnt = sw_gnt_ip[ip];
	   
	   wire [0:num_vcs-1] 	    vc_gnt_ivc;
	   assign vc_gnt_ivc = vc_gnt_ip_ivc[ip*num_vcs:(ip+1)*num_vcs-1];
	   
	   wire [0:num_vcs-1] 	      sw_sel_ivc;
	   assign sw_sel_ivc = sw_sel_ip_ivc[ip*num_vcs:(ip+1)*num_vcs-1];

       wire	shared_full_fb;
       assign shared_full_fb = &(shared_fb_full & memory_bank_grant_out);
	   
	   wire [0:channel_width-1] channel_in;
	   assign channel_in = channel_in_ip[ip*channel_width:(ip+1)*channel_width-1];
	   
	   wire [0:num_vcs-1] vc_sel_ivc_shared_ovc;
	   assign vc_sel_ivc_shared_ovc = vc_sel_ip_ivc_shared_ovc[ip*num_vcs:(ip+1)*num_vcs-1];
	   
	   wire [0:num_vcs*num_vcs-1] vc_sel_ivc_ovc;
	   assign vc_sel_ivc_ovc = vc_sel_ip_ivc_ovc[ip*num_vcs*num_vcs:(ip+1)*num_vcs*num_vcs-1];

	   wire 				                    ipc_error;
	   wire [0:flit_data_width-1] 		        flit_data;
	   wire [0:num_vcs*num_ports-1] 	        route_ivc_op;
	   wire [0:num_vcs*num_resource_classes-1]  route_ivc_orc;
	   wire [0:num_vcs-1] 			            allocated_ivc;
	   wire [0:num_vcs-1] 			            flit_head_ivc;
	   wire [0:num_vcs-1] 			            flit_tail_ivc;
	   wire [0:flow_ctrl_width-1] 		        flow_ctrl_out;
	   wire [0:num_vcs-1] 			            flit_valid_ivc;
	   wire [0:num_vcs-1]						shared_ovc_ivc;
	   wire [0:num_vcs-1] 			            free_nonspec_ivc;

	   wire					                    shared_push_head;
	   wire					                    shared_push_tail;
	   wire [0:flit_data_width-1]		        shared_push_data;
	   wire					                    shared_push_valid;
	   wire					                    shared_push_active;
	   wire [0:num_vcs-1]			            shared_push_sel_ivc;
	   wire [0:num_vcs-1]			            shared_push_head_ivc;
	   wire [0:num_vcs-1]			            shared_push_tail_ivc;

	   vcr_ip_ctrl_mac
	     #(.buffer_size(buffer_size),
	       .num_message_classes(num_message_classes),
	       .num_resource_classes(num_resource_classes),
	       .num_vcs_per_class(num_vcs_per_class),
	       .num_routers_per_dim(num_routers_per_dim),
	       .num_dimensions(num_dimensions),
	       .num_nodes_per_router(num_nodes_per_router),
	       .connectivity(connectivity),
	       .packet_format(packet_format),
	       .flow_ctrl_type(flow_ctrl_type),
	       .max_payload_length(max_payload_length),
	       .min_payload_length(min_payload_length),
	       .enable_link_pm(enable_link_pm),
	       .flit_data_width(flit_data_width),
	       .restrict_turns(restrict_turns),
	       .routing_type(routing_type),
	       .dim_order(dim_order),
	       .fb_regfile_type(fb_regfile_type),
	       .fb_mgmt_type(fb_mgmt_type),
	       .fb_fast_peek(fb_fast_peek),
	       .explicit_pipeline_register(explicit_pipeline_register),
	       .gate_buffer_write(gate_buffer_write),
	       .elig_mask(elig_mask),
	       .sw_alloc_spec(sw_alloc_spec_type != `SW_ALLOC_SPEC_TYPE_NONE),
	       .error_capture_mode(error_capture_mode),
	       .port_id(ip),
	       .reset_type(reset_type))
	   ipc
	     (.clk(clk),
	      .reset(reset),
	      .router_address(router_address),
	      .channel_in(channel_in),
	      .route_ivc_op(route_ivc_op),
	      .route_ivc_orc(route_ivc_orc),
	      .allocated_ivc(allocated_ivc),
	      .flit_valid_ivc(flit_valid_ivc),
	      .flit_head_ivc(flit_head_ivc),
	      .flit_tail_ivc(flit_tail_ivc),
	      .free_nonspec_ivc(free_nonspec_ivc),
	      .vc_gnt_ivc(vc_gnt_ivc),
	      .vc_sel_ivc_ovc(vc_sel_ivc_ovc),
		  .vc_sel_ivc_shared_ovc(vc_sel_ivc_shared_ovc),
	      .sw_gnt(sw_gnt),
	      .sw_sel_ivc(sw_sel_ivc),
	      .sw_gnt_op(sw_gnt_op),
	      .almost_full_op_ovc(almost_full_op_ovc),
	      .full_op_ovc(full_op_ovc),
	      .flit_data(flit_data),
	      .flow_ctrl_out(flow_ctrl_out),
		  .shared_full(shared_full_fb),
		  .shared_ovc_ivc(shared_ovc_ivc),
		  .shared_vc_in(shared_vc_in[ip]),
	      .shared_fb_push_head_ivc(shared_push_head_ivc),
	      .shared_fb_push_tail_ivc(shared_push_tail_ivc),
	      .shared_fb_push_valid(shared_push_valid),
	      .shared_fb_push_head(shared_push_head),
	      .shared_fb_push_tail(shared_push_tail),
	      .shared_fb_push_sel_ivc(shared_push_sel_ivc),
	      .shared_fb_push_data(shared_push_data),
	      .error(ipc_error));

	   assign shared_fb_push_data[ip*flit_data_width:(ip+1)*flit_data_width-1] = shared_push_data;
	   assign shared_fb_push_head_ivc[ip*num_vcs:(ip+1)*num_vcs-1] = shared_push_head_ivc;
	   assign shared_fb_push_tail_ivc[ip*num_vcs:(ip+1)*num_vcs-1] = shared_push_tail_ivc;
	   assign shared_fb_push_sel_ivc[ip*num_vcs:(ip+1)*num_vcs-1] = shared_push_sel_ivc;
	   assign shared_fb_push_valid[ip] = shared_push_valid;
	   assign shared_fb_push_head[ip] = shared_push_head;
	   assign shared_fb_push_tail[ip] = shared_push_tail;

	   assign route_ip_ivc_op[ip*num_vcs*num_ports:(ip+1)*num_vcs*num_ports-1] = route_ivc_op;
	   assign route_ip_ivc_orc[ip*num_vcs*num_resource_classes:(ip+1)*num_vcs*num_resource_classes-1] = route_ivc_orc;
	   assign allocated_ip_ivc[ip*num_vcs:(ip+1)*num_vcs-1] = allocated_ivc;
	   assign flit_valid_ip_ivc[ip*num_vcs:(ip+1)*num_vcs-1] = flit_valid_ivc;
	   assign flit_head_ip_ivc[ip*num_vcs:(ip+1)*num_vcs-1] = flit_head_ivc;
	   assign flit_tail_ip_ivc[ip*num_vcs:(ip+1)*num_vcs-1] = flit_tail_ivc;
	   assign free_nonspec_ip_ivc[ip*num_vcs:(ip+1)*num_vcs-1] = free_nonspec_ivc;
	   assign shared_ovc_ip_ivc[ip*num_vcs:(ip+1)*num_vcs-1] = shared_ovc_ivc;
	   assign ipc_error_ip[ip] = ipc_error;
	
	   wire [0:num_vcs-1]	shared_sw_sel_ivc;	
	   assign shared_sw_sel_ivc = sw_sel_ip_shared_ivc[ip*num_vcs:(ip+1)*num_vcs-1];

	   wire [0:num_ports-1]   shared_fb_sel;
	   c_reduce_bits
	     #(.op(`BINARY_OP_OR),
		   .num_ports(num_ports),
		   .width(num_vcs_per_bank))
	   shared_reduce_sw_sel
	      (.data_in(shared_sw_sel_ivc),
		   .data_out(shared_fb_sel));

	   reg [0:num_ports-1]	shared_sel_fb;
	   always @(posedge clk, posedge reset)
	   if (reset)
			shared_sel_fb <= {num_ports{1'b0}};
	   else
	   		shared_sel_fb <= shared_fb_sel;

	   wire [0:flit_data_width-1] shared_data_sel;
	   c_select_1ofn
	     #(.num_ports(num_ports),
		   .width(flit_data_width))
	   shared_sel_data
	      (.select(shared_sel_fb),
		   .data_in(shared_fb_flit_data),
		   .data_out(shared_data_sel));

	   wire [0:flow_ctrl_width-1] shared_flow_ctrl_out;
	   c_select_1ofn
	     #(.num_ports(num_ports),
		   .width(flow_ctrl_width))
	   shared_flow_ctrl_o
	      (.select(shared_sel_fb),
		   .data_in(shared_fb_flow_ctrl_out),
		   .data_out(shared_flow_ctrl_out));

	   reg shared_sw_ip_sel;
	   always @(posedge clk, posedge reset)
	   if (reset)
			shared_sw_ip_sel <= 1'b0;
	   else
	   		shared_sw_ip_sel <= shared_sw_gnt_ip[ip];

	   assign credit_for_shared_out[ip] = shared_sw_ip_sel ? 1'b1 : 1'b0;
	   
	   assign flow_ctrl_out_ip[ip*flow_ctrl_width:(ip+1)*flow_ctrl_width-1] 
	   				= shared_sw_ip_sel 
					? shared_flow_ctrl_out
					: flow_ctrl_out;
	   
	   assign xbr_data_in_ip[ip*flit_data_width:(ip+1)*flit_data_width-1] 
	   				= shared_sw_ip_sel 
					? shared_data_sel 
					: flit_data;
	 end
   endgenerate

   wire [0:num_vcs-1]						shared_ovc_ivc;
   wire [0:num_vcs*num_ports-1] 	     	shared_route_ivc_op;
   wire [0:num_ports*num_vcs-1]				vc_gnt_op_shared_ovc;
   wire [0:num_vcs*num_resource_classes-1]  shared_route_ivc_orc;
   wire [0:num_vcs-1] 		             	shared_flit_head_ivc;
   wire [0:num_vcs-1] 		             	shared_flit_tail_ivc;
   wire [0:num_vcs-1]			     	    shared_free_spec_ivc;
   wire [0:num_vcs-1] 		             	shared_flit_valid_ivc;
   wire [0:num_vcs-1]						shared_ovc_shared_ivc;
   wire [0:num_vcs*3-1]			     	    shared_ivcc_errors_ivc;
   wire [0:num_vcs-1] 		             	shared_free_nonspec_ivc;
   wire [0:num_ports*num_vcs*num_ports-1]   vc_sel_op_shared_ovc_ip;
   wire [0:num_vcs*lar_info_width-1]	    shared_next_lar_info_ivc;
   wire [0:num_ports*num_vcs-1]				vc_sel_op_ovc_shared_ivc;

   wire [0:num_ports*num_vcs*num_vcs-1]		vc_sel_ip_shared_ivc_ovc;
   wire [0:num_ports*num_vcs-1]				vc_sel_ip_shared_ivc_shared_ovc;

   genvar 	fb;
   generate
	for (fb = 0; fb < num_ports; fb = fb + 1)
	begin:fbs
	   wire								shared_full;
	   wire [0:flit_data_width-1] 		shared_pop_data;
	   wire [0:num_vcs_per_bank-1]		shared_empty_ivc;
	   wire [0:2*num_vcs_per_bank-1] 	shared_errors_ivc;
	   wire [0:num_vcs_per_bank-1]		shared_pop_tail_ivc;
	   wire [0:num_vcs_per_bank-1]		shared_almost_empty_ivc;
	   wire [0:header_info_width-1]		shared_pop_next_header_info;
	   
	   wire [0:num_ports-1]     memory_bank_grant_sel;
	   assign memory_bank_grant_sel = memory_bank_grant[fb*num_ports:(fb+1)*num_ports-1];

	   wire				shared_push_active;
	   c_select_1ofn
	      #(.width(1),
			.num_ports(num_ports))
	   push_active_sel
	   	   (.select(memory_bank_grant_sel),
			.data_in(shared_fb_push_valid),
			.data_out(shared_push_active));

	   wire			    shared_push_valid;	   
	   c_select_1ofn
	      #(.width(1),
			.num_ports(num_ports))
	   push_valid_sel
	       (.select(memory_bank_grant_sel),
			.data_in(shared_fb_push_valid),
			.data_out(shared_push_valid));

	   wire			    shared_push_head;
	   c_select_1ofn
	      #(.width(1),
			.num_ports(num_ports))
	   push_head_sel
	       (.select(memory_bank_grant_sel),
			.data_in(shared_fb_push_head),
			.data_out(shared_push_head));

	   wire			    shared_push_tail;
	   c_select_1ofn
	      #(.width(1),
			.num_ports(num_ports))
	   push_tail_sel
	       (.select(memory_bank_grant_sel),
			.data_in(shared_fb_push_tail),
			.data_out(shared_push_tail));


	   wire [0:flit_data_width-1] 	shared_push_data;
	   c_select_1ofn
	      #(.width(flit_data_width),
		.num_ports(num_ports))
	   push_data_sel
	       (.select(memory_bank_grant_sel),
			.data_in(shared_fb_push_data),
			.data_out(shared_push_data));

	   wire [0:num_vcs-1]	shared_ivc_push;
	   c_select_1ofn
	      #(.width(num_vcs),
			.num_ports(num_ports))
	   shared_push_ivc_sel
		   (.select(memory_bank_grant_sel),
			.data_in(shared_fb_push_sel_ivc),
			.data_out(shared_ivc_push));

	   wire [0:num_vcs_per_bank-1]	shared_push_ivc;
	   assign shared_push_ivc = shared_ivc_push[fb*num_vcs_per_bank:(fb+1)*num_vcs_per_bank-1];

	   wire	shared_alloc_active;
	   assign shared_alloc_active = shared_push_valid | ~& shared_empty_ivc;

	   wire	shared_pop_active;
	   assign shared_pop_active = shared_alloc_active;

	   wire	shared_flit_sent;
	   wire	shared_pop_valid;
	   assign shared_pop_valid = shared_flit_sent;

   	   wire [0:num_vcs-1] shared_fb_sw_sel_ivc;
	   c_select_1ofn
	      #(.width(num_vcs),
			.num_ports(num_ports))
	   shared_sw_ivc_sel
	       (.select(memory_bank_grant_sel),
			.data_in(sw_sel_ip_shared_ivc),
			.data_out(shared_fb_sw_sel_ivc));

	   wire [0:num_vcs_per_bank-1] shared_pop_sel_ivc;
	   assign shared_pop_sel_ivc = shared_fb_sw_sel_ivc[fb*num_vcs_per_bank:(fb+1)*num_vcs_per_bank-1];

	   rtr_flit_buffer
	     #(.num_vcs(num_vcs_per_bank),
	       .buffer_size(memory_bank_size),
	       .flit_data_width(flit_data_width),
	       .header_info_width(header_info_width),
	       .regfile_type(fb_regfile_type),
	       .mgmt_type(fb_mgmt_type),
	       .fast_peek(fb_fast_peek),
	       .explicit_pipeline_register(explicit_pipeline_register),
	       .gate_buffer_write(gate_buffer_write),
	       .atomic_vc_allocation(atomic_vc_allocation),
	       .enable_bypass(1),
	       .reset_type(reset_type))
	   flb(.clk(clk),
			.reset(reset),
			.push_active(shared_push_active & (|shared_push_ivc)),
			.push_valid(shared_push_valid & (|shared_push_ivc)),
			.push_head(shared_push_head),
			.push_tail(shared_push_tail),
			.push_sel_ivc(shared_push_ivc),
			.push_data(shared_push_data),
			.pop_active(shared_pop_active),
			.pop_valid(shared_pop_valid),
			.pop_sel_ivc(shared_pop_sel_ivc),
			.pop_data(shared_pop_data),
			.pop_tail_ivc(shared_pop_tail_ivc),
			.pop_next_header_info(shared_pop_next_header_info),
			.almost_empty_ivc(shared_almost_empty_ivc),
			.empty_ivc(shared_empty_ivc),
			.full(shared_full),
			.errors_ivc(shared_errors_ivc));

	   assign shared_fb_full[fb] = shared_full;
	   assign shared_fb_errors_ivc[fb*2*num_vcs_per_bank:(fb+1)*2*num_vcs_per_bank-1] = shared_errors_ivc;
	   assign shared_fb_empty_ivc[fb*num_vcs_per_bank:(fb+1)*num_vcs_per_bank-1] = shared_empty_ivc;
	   assign shared_fb_almost_empty_ivc[fb*num_vcs_per_bank:(fb+1)*num_vcs_per_bank-1] = shared_almost_empty_ivc;
	   assign shared_fb_pop_tail_ivc[fb*num_vcs_per_bank:(fb+1)*num_vcs_per_bank-1] = shared_pop_tail_ivc;
	   assign shared_fb_pop_next_header_info[fb*header_info_width:(fb+1)*header_info_width-1] = shared_pop_next_header_info;

	   wire ready_for_allocation;

	   memory_bank_allocator
		#(.bank_id(fb),
		  .num_vcs(num_vcs),
		  .counter_width(3),
		  .num_ports(num_ports),
		  .dim_addr_width(dim_addr_width),
		  .num_vcs_per_bank(num_vcs_per_bank),
		  .router_addr_width(router_addr_width),
		  .num_routers_per_dim(num_routers_per_dim))
   	   allocator
   	 	 (.clk(clk),
		  .reset(reset),
		  .router_address(router_address),
		  .shared_ivc_empty(shared_empty_ivc),
		  .allocated_ip_ivc(allocated_ip_ivc),
		  .ready_for_allocation(ready_for_allocation),
		  .allocated_ip_shared_ivc(ip_shared_ivc_allocated_in),
		  .memory_bank_grant_out(memory_bank_grant[fb*num_ports:(fb+1)*num_ports-1]));

	   assign ready_for_allocation_out[fb] = ready_for_allocation;

	   wire [0:header_info_width-1] shared_header_info_in;
	   assign shared_header_info_in = shared_push_data[0:header_info_width-1];

   	   wire [0:num_vcs-1]	 	  shared_fb_vc_gnt_ivc;
	   c_select_1ofn
	      #(.width(num_vcs),
			.num_ports(num_ports))
	   shared_vc_gnt_input_vc_sel
	   	   (.select(memory_bank_grant_sel),
			.data_in(vc_gnt_ip_shared_ivc),
			.data_out(shared_fb_vc_gnt_ivc));

	   wire [0:num_vcs*num_vcs-1]	vc_sel_shared_ivc_ovc;
	   c_select_1ofn
  		#(.width(num_vcs*num_vcs),
		  .num_ports(num_ports))
   	   shared_vc_sel_output_vc
	     (.select(memory_bank_grant_sel),
	      .data_in(vc_sel_ip_shared_ivc_ovc),
		  .data_out(vc_sel_shared_ivc_ovc));

	   wire [0:num_vcs-1]	vc_sel_shared_ivc_shared_ovc;
	   c_select_1ofn
  		#(.width(num_vcs),
		  .num_ports(num_ports))
   	   vc_sel_shared_output_vc
	     (.select(memory_bank_grant_sel),
	      .data_in(vc_sel_ip_shared_ivc_shared_ovc),
		  .data_out(vc_sel_shared_ivc_shared_ovc));

	   wire	shared_sw_gnt;
	   c_select_1ofn
	   	 #(.width(1),
		   .num_ports(num_ports))
	   shared_sw_gnt_sel
	      (.select(memory_bank_grant_sel),
		   .data_in(shared_sw_gnt_ip),
		   .data_out(shared_sw_gnt));

	wire [0:num_ports-1]	port_sel;
	assign port_sel = memory_bank_grant[fb*num_ports:(fb+1)*num_ports-1];

    // generate the shared ivc control singals. 
   	genvar ivc_ctrl;
	for (ivc_ctrl=fb*num_vcs_per_bank; ivc_ctrl<(fb+1)*num_vcs_per_bank;ivc_ctrl=ivc_ctrl+1)
  	begin:ivc_ctrls
  	   //-------------------------------------------------------------------
  	   // connect inputs
  	   //-------------------------------------------------------------------
	   wire								shared_ovc;
	   wire [0:num_ports-1] 		    shared_route_op;
	   wire 				            shared_flit_head;
	   wire 				            shared_flit_tail;
	   wire 				            shared_allocated;
	   wire 				            shared_free_spec;
	   wire [0:num_resource_classes-1] 	shared_route_orc;
	   wire 				            shared_flit_valid;
	   wire [0:2] 				        shared_ivcc_errors;
	   wire 				            shared_free_nonspec;
	   wire [0:lar_info_width-1] 		shared_next_lar_info;

	   wire	shared_flit_sel_in;
	   assign shared_flit_sel_in = shared_ivc_push[ivc_ctrl];

	   wire	shared_vc_gnt;
	   assign shared_vc_gnt = shared_fb_vc_gnt_ivc[ivc_ctrl];

	   wire	shared_sw_sel;
	   assign shared_sw_sel = shared_fb_sw_sel_ivc[ivc_ctrl];

	   wire shared_pop_tail;
	   assign shared_pop_tail = shared_fb_pop_tail_ivc[ivc_ctrl];

	   wire vc_sel_shared_ovc;
	   assign vc_sel_shared_ovc = vc_sel_shared_ivc_shared_ovc[ivc_ctrl]; 

	   wire [0:num_vcs-1]	shared_vc_sel_ovc;
	   assign shared_vc_sel_ovc = vc_sel_shared_ivc_ovc[ivc_ctrl*num_vcs:(ivc_ctrl+1)*num_vcs-1];

  	   vcr_ivc_ctrl
  	       #(.num_message_classes(num_message_classes),
  	         .num_resource_classes(num_resource_classes),
  	         .num_vcs_per_class(num_vcs),
  	         .num_routers_per_dim(num_routers_per_dim),
  	         .num_dimensions(num_dimensions),
  	         .num_nodes_per_router(num_nodes_per_router),
  	         .connectivity(connectivity),
  	         .packet_format(packet_format),
  	         .max_payload_length(max_payload_length),
  	         .min_payload_length(min_payload_length),
  	         .restrict_turns(restrict_turns),
  	         .routing_type(routing_type),
  	         .dim_order(dim_order),
  	         .elig_mask(elig_mask),
	         .sw_alloc_spec(sw_alloc_spec_type != `SW_ALLOC_SPEC_TYPE_NONE),
  	         .fb_mgmt_type(fb_mgmt_type),
  	         .explicit_pipeline_register(explicit_pipeline_register),
  	         .vc_id(ivc_ctrl),
  	         .shared_ivc(1),
			 .port_id(0),
  	         .reset_type(reset_type))
  	   ivcc
  	       (.clk(clk),
  	        .reset(reset),
			.port_sel(port_sel),
			.router_address(router_address),
  	        .flit_valid_in(shared_push_valid),
  	        .flit_head_in(shared_push_head),
  	        .flit_tail_in(shared_push_tail),
  	        .flit_sel_in(shared_flit_sel_in),
  	        .header_info_in(shared_header_info_in),
  	        .fb_pop_tail(shared_pop_tail),
  	        .fb_pop_next_header_info(shared_pop_next_header_info),
  	        .almost_full_op_ovc(almost_full_op_ovc),
  	        .full_op_ovc(full_op_ovc),
  	        .route_op(shared_route_op),
  	        .route_orc(shared_route_orc),
  	        .vc_gnt(shared_vc_gnt),
  	        .vc_sel_ovc(shared_vc_sel_ovc),
  	        .vc_sel_shared_ovc(vc_sel_shared_ovc),
			.sw_gnt(shared_sw_gnt),
  	        .sw_sel(shared_sw_sel),
  	        .sw_gnt_op(sw_gnt_op),
  	        .flit_valid(shared_flit_valid),
  	        .flit_head(shared_flit_head),
  	        .flit_tail(shared_flit_tail),
  	        .shared_ovc_out(shared_ovc),
			.next_lar_info(shared_next_lar_info),
  	        .fb_almost_empty(shared_fb_almost_empty_ivc[ivc_ctrl]),
  	        .fb_empty(shared_fb_empty_ivc[ivc_ctrl]),
  	        .allocated(shared_allocated),
  	        .free_nonspec(shared_free_nonspec),
  	        .free_spec(shared_free_spec),
  	        .errors(shared_ivcc_errors));

       	 //-------------------------------------------------------------------
   	     // connect outputs
   	     //-------------------------------------------------------------------
 	     assign shared_ovc_shared_ivc[ivc_ctrl] = shared_ovc;
 	     assign shared_allocated_ivc[ivc_ctrl] = shared_allocated;
 	     assign shared_free_spec_ivc[ivc_ctrl] = shared_free_spec;
 	     assign shared_flit_head_ivc[ivc_ctrl] = shared_flit_head;
 	     assign shared_flit_tail_ivc[ivc_ctrl] = shared_flit_tail;
 	     assign shared_flit_valid_ivc[ivc_ctrl] = shared_flit_valid;
 	     assign shared_free_nonspec_ivc[ivc_ctrl] = shared_free_nonspec;
 	     assign shared_ivcc_errors_ivc[ivc_ctrl*3:(ivc_ctrl+1)*3-1] = shared_ivcc_errors;
		 assign shared_route_ivc_op[ivc_ctrl*num_ports:(ivc_ctrl+1)*num_ports-1] = shared_route_op;
 	     assign shared_next_lar_info_ivc[ivc_ctrl*lar_info_width:(ivc_ctrl+1)*lar_info_width-1] = shared_next_lar_info;
 	     assign shared_route_ivc_orc[ivc_ctrl*num_resource_classes:(ivc_ctrl+1)*num_resource_classes-1] = shared_route_orc;
   	    end


	   wire [0:num_vcs_per_bank-1] shared_allocate;
	   assign shared_allocate = shared_allocated_ivc[fb*num_vcs_per_bank:(fb+1)*num_vcs_per_bank-1];

	   wire [0:num_vcs_per_bank-1] shared_freespec_ivc;
	   assign shared_freespec_ivc = shared_free_spec_ivc[fb*num_vcs_per_bank:(fb+1)*num_vcs_per_bank-1];

	   wire [0:num_vcs_per_bank-1] share_fb_vc_gnt_ivc;
	   assign share_fb_vc_gnt_ivc = shared_fb_vc_gnt_ivc[fb*num_vcs_per_bank:(fb+1)*num_vcs_per_bank-1];

   	   if(sw_alloc_spec_type!=`SW_ALLOC_SPEC_TYPE_NONE)
   	    begin
   	       wire [0:num_vcs_per_bank-1] shared_spec_mask_ivc;
   	       if(elig_mask == `ELIG_MASK_NONE)
   	         assign shared_spec_mask_ivc = shared_allocate | (share_fb_vc_gnt_ivc & shared_freespec_ivc);
   	       else
   	         assign shared_spec_mask_ivc = shared_allocate | share_fb_vc_gnt_ivc;
   	       
   	       wire    shared_spec_mask;
   	       c_select_1ofn
   	         #(.width(1),
	           .num_ports(num_vcs_per_bank))
   	       spec_mask_sel
   	         (.select(shared_pop_sel_ivc),
   	          .data_in(shared_spec_mask_ivc),
   	          .data_out(shared_spec_mask));
   	       
   	       assign shared_flit_sent = shared_sw_gnt & (|shared_pop_sel_ivc) & shared_spec_mask;
   	    end
   	   else
   	    assign shared_flit_sent = shared_sw_gnt & (|shared_pop_sel_ivc);

  	   wire		flit_head;
   	   c_select_1ofn
   	    #(.width(1),
	      .num_ports(num_vcs))
   	   flit_head_sel
   	     (.select(shared_fb_sw_sel_ivc),
   	      .data_in(shared_flit_head_ivc),
   	      .data_out(flit_head));

	   wire [0:lar_info_width-1] share_next_lar_info;
	   c_select_1ofn
	     #(.width(lar_info_width),
		   .num_ports(num_vcs))
	   share_sel_ivc_pop
		  (.select(shared_fb_sw_sel_ivc),
		   .data_in(shared_next_lar_info_ivc),
		   .data_out(share_next_lar_info));

	   wire [0:lar_info_width-1]  	lar_info_q;
  	   wire [0:lar_info_width-1]	lar_info_s;
  	   assign lar_info_s = flit_head ? share_next_lar_info : lar_info_q;

  	   c_dff
  	     #(.width(lar_info_width),
  	       .reset_type(reset_type))
  	   lar_infoq
  	     (.clk(clk),
  	      .reset(1'b0),
  	      .active(shared_alloc_active),
  	      .d(lar_info_s),
  	      .q(lar_info_q));
  	   
   	   wire         flit_sent_prev;

   	   wire         flit_valid_active;
           assign flit_valid_active = shared_alloc_active | flit_sent_prev;
   		
   	   wire         flit_valid_s, flit_valid_q;
   	   assign flit_valid_s = shared_flit_sent;

   	   c_dff
   	    #(.width(1),
   	      .reset_type(reset_type))
   	   flit_validq
   	     (.clk(clk),
   	      .reset(reset),
   	      .active(flit_valid_active),
   	      .d(flit_valid_s),
   	      .q(flit_valid_q));
   		
   	   assign flit_sent_prev = flit_valid_q;
   		
   	   wire flit_head_s, flit_head_q;
   	   assign flit_head_s = flit_head;

   	   c_dff
   	    #(.width(1),
   	      .reset_type(reset_type))
   	   flit_headq
   	     (.clk(clk),
   	      .reset(1'b0),
   	      .active(shared_alloc_active),
   	      .d(flit_head_s),
   	      .q(flit_head_q));
   
	   wire 	flit_head_prev;
   	   assign flit_head_prev = flit_head_q;

       wire [0:flow_ctrl_width-1]	shared_flow_ctrl_out;
	   rtr_flow_ctrl_output
         #(.num_vcs(num_vcs),
           .flow_ctrl_type(flow_ctrl_type),
           .reset_type(reset_type))
       shared_fco
          (.clk(clk),
           .reset(reset),
           .active(shared_alloc_active),
           .fc_event_valid_in(shared_flit_sent),
           .fc_event_sel_in_ivc(shared_fb_sw_sel_ivc),
           .flow_ctrl_out(shared_flow_ctrl_out));

	   assign shared_fb_flow_ctrl_out[fb*flow_ctrl_width:(fb+1)*flow_ctrl_width-1] = shared_flow_ctrl_out;

  	   assign shared_fb_flit_data[fb*flit_data_width:fb*flit_data_width+lar_info_width-1] 
			= flit_head_prev ? lar_info_q : shared_pop_data[0:lar_info_width-1];

  	   assign shared_fb_flit_data[fb*flit_data_width+lar_info_width:(fb+1)*flit_data_width-1] 
			= shared_pop_data[lar_info_width:flit_data_width-1];
	end
   endgenerate


   // generate the necessary input signals for 'vcr_alloc_mac.v' module.
   wire [0:num_ports*num_vcs-1]                         elig_op_shared_ovc;  
   wire [0:num_ports*num_vcs*num_ports-1] 	            route_ip_shared_ivc_op;
   wire [0:num_ports*num_vcs*num_resource_classes-1]    route_ip_shared_ivc_orc;
   wire [0:num_ports*num_vcs-1] 		                allocated_ip_shared_ivc;
   wire [0:num_ports*num_vcs-1] 		                flit_head_ip_shared_ivc;
   wire [0:num_ports*num_vcs-1] 		                flit_tail_ip_shared_ivc;
   wire [0:num_ports*num_vcs-1] 		                flit_valid_ip_shared_ivc;
   wire [0:num_ports*num_vcs-1]							shared_ovc_ip_shared_ivc;
   wire [0:num_ports*num_vcs-1] 		                free_nonspec_ip_shared_ivc;

   genvar sip, sop;
   generate
    for (sip=0; sip<num_ports; sip=sip+1)
    begin:sips
        for (sop=0;sop<num_ports;sop=sop+1)// sop means the index of shared memory bank.
        begin:sops
            assign route_ip_shared_ivc_op[sip*num_vcs*num_ports+sop*num_vcs_per_bank*num_ports:
				sip*num_vcs*num_ports+(sop+1)*num_vcs_per_bank*num_ports-1]
                    = memory_bank_grant_out[sip*num_ports+sop] 
                    ? shared_route_ivc_op[sop*num_vcs_per_bank*num_ports:(sop+1)*num_vcs_per_bank*num_ports-1]
                    : {num_vcs_per_bank*num_ports{1'b0}};

            assign route_ip_shared_ivc_orc[sip*num_vcs*num_resource_classes+sop*num_vcs_per_bank*num_resource_classes:
                        sip*num_vcs*num_resource_classes+(sop+1)*num_vcs_per_bank*num_resource_classes-1]
                    = memory_bank_grant_out[sip*num_ports+sop]
                    ? shared_route_ivc_orc[sop*num_vcs_per_bank*num_resource_classes
						:(sop+1)*num_vcs_per_bank*num_resource_classes-1]
                    : {num_vcs_per_bank*num_resource_classes{1'b0}};
            
            assign flit_valid_ip_shared_ivc[sip*num_vcs+sop*num_vcs_per_bank:sip*num_vcs+(sop+1)*num_vcs_per_bank-1]
                    = memory_bank_grant_out[sip*num_ports+sop]
                    ? shared_flit_valid_ivc[sop*num_vcs_per_bank:(sop+1)*num_vcs_per_bank-1]
                    : {num_vcs_per_bank{1'b0}};
            
            assign flit_head_ip_shared_ivc[sip*num_vcs+sop*num_vcs_per_bank:sip*num_vcs+(sop+1)*num_vcs_per_bank-1]
                    = memory_bank_grant_out[sip*num_ports+sop]
                    ? shared_flit_head_ivc[sop*num_vcs_per_bank:(sop+1)*num_vcs_per_bank-1]
                    : {num_vcs_per_bank{1'b0}};

            assign flit_tail_ip_shared_ivc[sip*num_vcs+sop*num_vcs_per_bank:sip*num_vcs+(sop+1)*num_vcs_per_bank-1]
                    = memory_bank_grant_out[sip*num_ports+sop]
                    ? shared_flit_tail_ivc[sop*num_vcs_per_bank:(sop+1)*num_vcs_per_bank-1]
                    : {num_vcs_per_bank{1'b0}};

            assign allocated_ip_shared_ivc[sip*num_vcs+sop*num_vcs_per_bank:sip*num_vcs+(sop+1)*num_vcs_per_bank-1]
                    = memory_bank_grant_out[sip*num_ports+sop]
                    ? shared_allocated_ivc[sop*num_vcs_per_bank:(sop+1)*num_vcs_per_bank-1]
                    : {num_vcs_per_bank{1'b0}};

            assign free_nonspec_ip_shared_ivc[sip*num_vcs+sop*num_vcs_per_bank:sip*num_vcs+(sop+1)*num_vcs_per_bank-1]
                    = memory_bank_grant_out[sip*num_ports+sop]
                    ? shared_free_nonspec_ivc[sop*num_vcs_per_bank:(sop+1)*num_vcs_per_bank-1]
                    : {num_vcs_per_bank{1'b0}};

			assign shared_ovc_ip_shared_ivc[sip*num_vcs+sop*num_vcs_per_bank:sip*num_vcs+(sop+1)*num_vcs_per_bank-1]
					= memory_bank_grant_out[sip*num_ports+sop]
					? shared_ovc_shared_ivc[sop*num_vcs_per_bank:(sop+1)*num_vcs_per_bank-1]
					: {num_vcs_per_bank{1'b0}};
        end
    end
   endgenerate
 

   //---------------------------------------------------------------------------
   // VC and switch allocator
   //---------------------------------------------------------------------------
   wire [0:num_ports*num_vcs-1] 		    elig_op_ovc; // generated by the 'vcr_output_ctrl_mac'.
   wire [0:num_ports-1] 			        vc_active_op; // used for the 'vcr_output_ctrl_mac'.
   wire [0:num_ports-1] 			        sw_active_op; // used for the cxb
   wire [0:num_ports*num_ports-1] 		    sw_sel_op_ip; // used for the 'vcr_output_ctrl_mac'.
   wire [0:num_ports-1] 			        flit_head_op; // indicator for the output to generate the flit_head signals.
   wire [0:num_ports-1] 			        flit_tail_op; // indicator for the output to generate the flit_tail signals.
   wire [0:num_ports*num_vcs-1] 		    vc_gnt_op_ovc; // used for the 'vcr_output_ctrl_mac'.
   wire [0:num_ports*num_vcs-1] 		    sw_sel_op_ivc; // used for the 'vcr_output_ctrl_mac'.
   wire [0:num_ports*num_ports-1] 		    xbr_ctrl_op_ip; // used for the cxb to ctrl switch.
   wire [0:num_ports*num_vcs*num_ports-1] 	vc_sel_op_ovc_ip;  // used for the 'vcr_output_ctrl_mac'.
   wire [0:num_ports*num_vcs*num_vcs-1] 	vc_sel_op_ovc_ivc; // used for the 'vcr_output_ctrl_mac'.
   wire [0:num_ports-1]						shared_vc_from_alo;
   wire [0:num_ports-1] 			        shared_vc_active_op; // used for the 'vcr_output_ctrl_mac'.
   wire [0:num_ports-1]						sw_sel_op_shared_ivc;
   wire [0:num_ports*num_vcs*num_vcs-1]		vc_sel_op_shared_ovc_ivc;
   wire [0:num_ports*num_vcs-1]				vc_sel_op_shared_ovc_shared_ivc;

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
      .shared_vc_out_op(shared_vc_from_alo),
	  .sw_gnt_op(sw_gnt_op),
	  .sw_sel_op_ip(sw_sel_op_ip),
	  .sw_sel_op_ivc(sw_sel_op_ivc),
	  .sw_sel_op_shared_ivc(sw_sel_op_shared_ivc),
	  .flit_head_op(flit_head_op),
	  .flit_tail_op(flit_tail_op),
	  .xbr_ctrl_op_ip(xbr_ctrl_op_ip));
 

   //---------------------------------------------------------------------------
   // crossbars
   //---------------------------------------------------------------------------
   
   wire [0:num_ports*flit_data_width-1]     xbr_data_out_op;
   rtr_crossbar_mac
     #(.num_ports(num_ports),
       .width(flit_data_width),
       .crossbar_type(crossbar_type))
   xbr
     (.ctrl_in_op_ip(xbr_ctrl_op_ip),
      .data_in_ip(xbr_data_in_ip),
      .data_out_op(xbr_data_out_op));
   

   //---------------------------------------------------------------------------
   // output ports
   //---------------------------------------------------------------------------
   
   wire [0:num_ports-1]		opc_error_op;

   generate
      genvar ovc_ctrl, sb, op;
      for(op = 0; op < num_ports; op = op + 1)
	  begin:ops
	   //-------------------------------------------------------------------
	   // output controller
	   //-------------------------------------------------------------------
	   wire sw_gnt;
	   assign sw_gnt = sw_gnt_op[op];

	   wire sw_active;
	   assign sw_active = sw_active_op[op];

	   wire flit_head;
	   assign flit_head = flit_head_op[op];
	   
	   wire flit_tail;
	   assign flit_tail = flit_tail_op[op];
	   
	   wire	shared_vc;
	   assign shared_vc = shared_vc_from_alo[op];

	   wire vc_active;
	   assign vc_active = vc_active_op[op];

	   wire	shared_vc_active;
	   assign shared_vc_active = shared_vc_active_op[op];

	   wire	credit_for_shared;
	   assign credit_for_shared = credit_for_shared_in[op];

	   wire [0:num_vcs-1] vc_gnt_ovc;
	   assign vc_gnt_ovc = vc_gnt_op_ovc[op*num_vcs:(op+1)*num_vcs-1];
	  
	   wire [0:num_vcs-1] sw_sel_ivc;
	   assign sw_sel_ivc = sw_sel_op_ivc[op*num_vcs:(op+1)*num_vcs-1];
		
	   wire	sw_sel_shared_ivc;
	   assign sw_sel_shared_ivc = sw_sel_op_shared_ivc[op];

	   wire [0:num_ports-1]	sw_sel_ip;
	   assign sw_sel_ip = sw_sel_op_ip[op*num_ports:(op+1)*num_ports-1];

	   wire [0:num_vcs-1] shared_vc_gnt_ovc;
	   assign shared_vc_gnt_ovc = vc_gnt_op_shared_ovc[op*num_vcs:(op+1)*num_vcs-1];

	   wire [0:flit_data_width-1] flit_data;
	   assign flit_data = xbr_data_out_op[op*flit_data_width:(op+1)*flit_data_width-1];

	   wire [0:flow_ctrl_width-1] flow_ctrl_in;
	   assign flow_ctrl_in = flow_ctrl_in_op[op*flow_ctrl_width:(op+1)*flow_ctrl_width-1];

	   wire [0:num_vcs*num_vcs-1] vc_sel_ovc_ivc;
	   assign vc_sel_ovc_ivc = vc_sel_op_ovc_ivc[op*num_vcs*num_vcs:(op+1)*num_vcs*num_vcs-1];

	   wire [0:num_vcs-1]	vc_sel_ovc_shared_ivc;
	   assign vc_sel_ovc_shared_ivc = vc_sel_op_ovc_shared_ivc[op*num_vcs:(op+1)*num_vcs-1];

	   wire [0:num_vcs*num_ports-1] vc_sel_ovc_ip;
	   assign vc_sel_ovc_ip = vc_sel_op_ovc_ip[op*num_vcs*num_ports:(op+1)*num_vcs*num_ports-1];

	   wire [0:num_vcs*num_vcs-1] vc_sel_shared_ovc_ivc;
	   assign vc_sel_shared_ovc_ivc = vc_sel_op_shared_ovc_ivc[op*num_vcs*num_vcs:(op+1)*num_vcs*num_vcs-1];
	   
	   wire [0:num_vcs-1]	vc_sel_shared_ovc_shared_ivc;
	   assign vc_sel_shared_ovc_shared_ivc = vc_sel_op_shared_ovc_shared_ivc[op*num_vcs:(op+1)*num_vcs-1];

	   wire [0:num_vcs*num_ports-1] vc_sel_shared_ovc_ip;
	   assign vc_sel_shared_ovc_ip = vc_sel_op_shared_ovc_ip[op*num_vcs*num_ports:(op+1)*num_vcs*num_ports-1];

	   wire [0:num_vcs-1] 		full_ovc;
	   wire [0:num_vcs-1] 		elig_ovc;
	   wire 			        opc_error;
	   wire [0:channel_width-1] channel_out;
	   wire [0:num_vcs-1] 		shared_full_ovc;
	   wire [0:num_vcs-1] 		shared_elig_ovc;
	   wire [0:num_vcs-1] 		almost_full_ovc;
	   wire [0:num_vcs-1]		shared_ovc_allocated;
	   wire [0:num_vcs-1] 		shared_almost_full_ovc;

	   vcr_op_ctrl_mac
	     #(.buffer_size(buffer_size),
	       .num_message_classes(num_message_classes),
	       .num_resource_classes(num_resource_classes),
	       .num_vcs_per_class(num_vcs_per_class),
	       .num_ports(num_ports),
	       .packet_format(packet_format),
	       .flow_ctrl_type(flow_ctrl_type),
	       .flow_ctrl_bypass(flow_ctrl_bypass),
	       .enable_link_pm(enable_link_pm),
	       .flit_data_width(flit_data_width),
	       .error_capture_mode(error_capture_mode),
	       .fb_mgmt_type(fb_mgmt_type),
	       .disable_static_reservations(disable_static_reservations),
	       .elig_mask(elig_mask),
	       .sw_alloc_spec(sw_alloc_spec_type != `SW_ALLOC_SPEC_TYPE_NONE),
	       .reset_type(reset_type))
	   opc
	     (.clk(clk),
	      .reset(reset),
	      .flow_ctrl_in(flow_ctrl_in),
		  .credit_for_shared(credit_for_shared),
	      .vc_active(vc_active),
	      .shared_vc_active(shared_vc_active),
		  .vc_gnt_ovc(vc_gnt_ovc),
	      .vc_gnt_shared_ovc(shared_vc_gnt_ovc),
		  .vc_sel_ovc_ip(vc_sel_ovc_ip),
	      .vc_sel_shared_ovc_ip(vc_sel_shared_ovc_ip),
		  .vc_sel_ovc_ivc(vc_sel_ovc_ivc),
		  .vc_sel_ovc_shared_ivc(vc_sel_ovc_shared_ivc),
		  .vc_sel_shared_ovc_ivc(vc_sel_shared_ovc_ivc),
	      .vc_sel_shared_ovc_shared_ivc(vc_sel_shared_ovc_shared_ivc),
		  .shared_vc_in(shared_vc),
	      .shared_vc_out(shared_vc_out[op]),
		  .sw_active(sw_active),
		  .sw_gnt(sw_gnt),
	      .sw_sel_ip(sw_sel_ip),
	      .sw_sel_ivc(sw_sel_ivc),
	      .sw_sel_shared_ivc(sw_sel_shared_ivc),
		  .flit_head(flit_head),
	      .flit_tail(flit_tail),
	      .flit_data(flit_data),
	      .channel_out(channel_out),
	      .almost_full_ovc(almost_full_ovc),
		  .shared_almost_full_ovc(shared_almost_full_ovc),
	      .full_ovc(full_ovc),
		  .shared_full_ovc(shared_full_ovc),
	      .elig_ovc(elig_ovc),
		  .shared_elig_ovc(shared_elig_ovc),
		  .shared_ovc_allocated(shared_ovc_allocated),
	      .error(opc_error));
	  
	   assign ip_shared_ivc_allocated_out[op*num_vcs:(op+1)*num_vcs-1] = shared_ovc_allocated;
	   assign channel_out_op[op*channel_width:(op+1)*channel_width-1] = channel_out;
	   assign elig_op_ovc[op*num_vcs:(op+1)*num_vcs-1] = elig_ovc;

	   for (sb=0; sb<num_ports; sb=sb+1)
	   begin:sbs
	   	assign elig_op_shared_ovc[op*num_vcs+sb*num_vcs_per_bank:op*num_vcs+(sb+1)*num_vcs_per_bank-1] 
	   						   = memory_bank_grant_in[op*num_ports+sb]
							   ? (shared_elig_ovc[sb*num_vcs_per_bank:(sb+1)*num_vcs_per_bank-1] 
											   & {num_vcs_per_bank{ready_for_allocation_in[sb]}})
							   : {num_vcs_per_bank{1'b0}};

		assign almost_full_op_ovc[op*num_vcs+sb*num_vcs_per_bank:op*num_vcs+(sb+1)*num_vcs_per_bank-1]
								= memory_bank_grant_in[op*num_ports+sb]
								? shared_almost_full_ovc[sb*num_vcs_per_bank:(sb+1)*num_vcs_per_bank-1]
									& almost_full_ovc[sb*num_vcs_per_bank:(sb+1)*num_vcs_per_bank-1]
								: almost_full_ovc[sb*num_vcs_per_bank:(sb+1)*num_vcs_per_bank-1];

		assign full_op_ovc[op*num_vcs+sb*num_vcs_per_bank:op*num_vcs+(sb+1)*num_vcs_per_bank-1]
								= memory_bank_grant_in[op*num_ports+sb]
								? shared_full_ovc[sb*num_vcs_per_bank:(sb+1)*num_vcs_per_bank-1]
									& full_ovc[sb*num_vcs_per_bank:(sb+1)*num_vcs_per_bank-1]
								: full_ovc[sb*num_vcs_per_bank:(sb+1)*num_vcs_per_bank-1];
	   end

	   assign opc_error_op[op] = opc_error;
	end
   endgenerate
   
   //---------------------------------------------------------------------------
   // error reporting
   //---------------------------------------------------------------------------
   generate
    if(error_capture_mode != `ERROR_CAPTURE_MODE_NONE)
	begin
	   wire [0:num_ports+num_ports-1] errors_s, errors_q;
	   assign errors_s = {ipc_error_ip, opc_error_op};
	   c_err_rpt
	     #(.num_errors(num_ports+num_ports),
	       .capture_mode(error_capture_mode),
	       .reset_type(reset_type))
	   chk
	     (.clk(clk),
	      .reset(reset),
	      .active(1'b1),
	      .errors_in(errors_s),
	      .errors_out(errors_q));
	   
	   assign error = |errors_q;
	end
    else
		assign error = 1'bx;
   endgenerate

endmodule
