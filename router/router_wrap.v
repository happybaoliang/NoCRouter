// $Id: router_wrap.v 5188 2012-08-30 00:31:31Z dub $

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
// wrapper around router component (configures router parameters based on
// selected network topology, etc.)
//==============================================================================

module router_wrap
  (clk, reset, router_address, channel_in_ip, flow_ctrl_out_ip, channel_out_op, 
   flow_ctrl_in_op, error);
   
`include "c_functions.v"   
`include "c_constants.v"
  
// select network topology
parameter topology = `TOPOLOGY_MESH;

// total buffer size per port in flits
parameter buffer_size = 16;

// number of message classes (e.g. request, reply)
parameter num_message_classes = 2;

// number of resource classes (e.g. minimal, adaptive)
parameter num_resource_classes = 1;

// number of VCs per class
parameter num_vcs_per_class = 1;

// total number of nodes
parameter num_nodes = 64;

// number of dimensions in network
parameter num_dimensions = 2;

// number of nodes per router (a.k.a. concentration factor)
parameter num_nodes_per_router = 1;

// select packet format
parameter packet_format = `PACKET_FORMAT_EXPLICIT_LENGTH;

// select type of flow control
parameter flow_ctrl_type = `FLOW_CTRL_TYPE_CREDIT;

// make incoming flow control signals bypass the output VC state tracking logic
parameter flow_ctrl_bypass = 0;

// maximum payload length (in flits)
parameter max_payload_length = 4;

// minimum payload length (in flits)
parameter min_payload_length = 0;

// select router implementation
parameter router_type = `ROUTER_TYPE_VC;

// enable link power management
parameter enable_link_pm = 1;

// width of flit payload data
parameter flit_data_width = 64;

// configure error checking logic
parameter error_capture_mode = `ERROR_CAPTURE_MODE_NO_HOLD;

// filter out illegal destination ports
// (the intent is to allow synthesis to optimize away the logic associated with 
// such turns)
parameter restrict_turns = 1;

// store lookahead routing info in pre-decoded form
// (only useful with dual-path routing enable)
parameter predecode_lar_info = 1;

// select routing function type
parameter routing_type = `ROUTING_TYPE_PHASED_DOR;

// select order of dimension traversal
parameter dim_order = `DIM_ORDER_ASCENDING;

// use input register as part of the flit buffer (wormhole router only)
parameter input_stage_can_hold = 0;

// select implementation variant for flit buffer register file
parameter fb_regfile_type = `REGFILE_TYPE_FF_2D;

// select flit buffer management scheme
parameter fb_mgmt_type = `FB_MGMT_TYPE_STATIC;

// improve timing for peek access
parameter fb_fast_peek = 1;

// EXPERIMENTAL:
// for dynamic buffer management, only reserve a buffer slot for a VC while it 
// is active (i.e., while a packet is partially transmitted)
// (NOTE: This is currently broken!)
parameter disable_static_reservations = 0;

// use explicit pipeline register between flit buffer and crossbar?
parameter explicit_pipeline_register = 1;

// gate flit buffer write port if bypass succeeds
// (requires explicit pipeline register; may increase cycle time)
parameter gate_buffer_write = 0;

// enable dual-path allocation
parameter dual_path_alloc = 0;

// resolve output conflicts when using dual-path allocation via arbitration
// (otherwise, kill if more than one fast-path request per output port)
parameter dual_path_allow_conflicts = 0;

// only mask fast-path requests if any slow path requests are ready
parameter dual_path_mask_on_ready = 1;

// precompute input-side arbitration decision one cycle ahead
parameter precomp_ivc_sel = 0;

// precompute output-side arbitration decision one cycle ahead
parameter precomp_ip_sel = 0;

// select whether to exclude full or non-empty VCs from VC allocation
parameter elig_mask = `ELIG_MASK_FULL;

// select implementation variant for VC allocator
parameter vc_alloc_type = `VC_ALLOC_TYPE_SEP_IF;

// select which arbiter type to use for VC allocator
parameter vc_alloc_arbiter_type = `ARBITER_TYPE_ROUND_ROBIN_BINARY;

// prefer empty VCs over non-empty ones in VC allocation
parameter vc_alloc_prefer_empty = 0;

// select implementation variant for switch allocator
parameter sw_alloc_type = `SW_ALLOC_TYPE_SEP_IF;

// select which arbiter type to use for switch allocator
parameter sw_alloc_arbiter_type = `ARBITER_TYPE_ROUND_ROBIN_BINARY;

// select speculation type for switch allocator
parameter sw_alloc_spec_type = `SW_ALLOC_SPEC_TYPE_PRIO;

// select implementation variant for crossbar
parameter crossbar_type = `CROSSBAR_TYPE_MUX;

parameter reset_type = `RESET_TYPE_ASYNC;
   
   // total number of packet classes
   localparam num_packet_classes = num_message_classes * num_resource_classes;
   
   // number of VCs
   localparam num_vcs = num_packet_classes * num_vcs_per_class;
   
   // width required to select individual VC
   localparam vc_idx_width = clogb(num_vcs);
   
   // total number of routers
   localparam num_routers
     = (num_nodes + num_nodes_per_router - 1) / num_nodes_per_router;
   
   // number of routers in each dimension
   localparam num_routers_per_dim = croot(num_routers, num_dimensions);
   
   // width required to select individual router in a dimension
   localparam dim_addr_width = clogb(num_routers_per_dim);
   
   // width required to select individual router in entire network
   localparam router_addr_width = num_dimensions * dim_addr_width;
   
   // connectivity within each dimension
   localparam connectivity
     = (topology == `TOPOLOGY_MESH) ?
       `CONNECTIVITY_LINE :
       (topology == `TOPOLOGY_TORUS) ?
       `CONNECTIVITY_RING :
       (topology == `TOPOLOGY_FBFLY) ?
       `CONNECTIVITY_FULL :
       -1;
   
   // number of adjacent routers in each dimension
   localparam num_neighbors_per_dim
     = ((connectivity == `CONNECTIVITY_LINE) ||
	(connectivity == `CONNECTIVITY_RING)) ?
       2 :
       (connectivity == `CONNECTIVITY_FULL) ?
       (num_routers_per_dim - 1) :
       -1;
   
   // number of input and output ports on router
   localparam num_ports
     = num_dimensions * num_neighbors_per_dim + num_nodes_per_router;
   
   // width of flow control signals
   localparam flow_ctrl_width
     = (flow_ctrl_type == `FLOW_CTRL_TYPE_CREDIT) ? (1 + vc_idx_width) :
       -1;
   
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
   
   // width of channel
   localparam channel_width
     = link_ctrl_width + flit_ctrl_width + flit_data_width;
   
   
   input clk;
   input reset;
   
   // current router's address
   input [0:router_addr_width-1] router_address;
   
   // incoming channels
   input [0:num_ports*channel_width-1] channel_in_ip;
   
   // outgoing flow control signals
   output [0:num_ports*flow_ctrl_width-1] flow_ctrl_out_ip;
   wire [0:num_ports*flow_ctrl_width-1]   flow_ctrl_out_ip;
   
   // outgoing channels
   output [0:num_ports*channel_width-1]   channel_out_op;
   wire [0:num_ports*channel_width-1] 	  channel_out_op;
   
   // incoming flow control signals
   input [0:num_ports*flow_ctrl_width-1]  flow_ctrl_in_op;
   
   // internal error condition detected
   output 				  error;
   wire 				  error;
   
   generate
      
      case(router_type)
	
	`ROUTER_TYPE_WORMHOLE:
	  begin
	     
	     whr_top
	       #(.buffer_size(buffer_size),
		 .num_routers_per_dim(num_routers_per_dim),
		 .num_dimensions(num_dimensions),
		 .num_nodes_per_router(num_nodes_per_router),
		 .connectivity(connectivity),
		 .packet_format(packet_format),
		 .flow_ctrl_type(flow_ctrl_type),
		 .flow_ctrl_bypass(flow_ctrl_bypass),
		 .max_payload_length(max_payload_length),
		 .min_payload_length(min_payload_length),
		 .enable_link_pm(enable_link_pm),
		 .flit_data_width(flit_data_width),
		 .error_capture_mode(error_capture_mode),
		 .restrict_turns(restrict_turns),
		 .routing_type(routing_type),
		 .dim_order(dim_order),
		 .input_stage_can_hold(input_stage_can_hold),
		 .fb_regfile_type(fb_regfile_type),
		 .fb_fast_peek(fb_fast_peek),
		 .explicit_pipeline_register(explicit_pipeline_register),
		 .gate_buffer_write(gate_buffer_write),
		 .precomp_ip_sel(precomp_ip_sel),
		 .arbiter_type(sw_alloc_arbiter_type),
		 .crossbar_type(crossbar_type),
		 .reset_type(reset_type))
	     whr
	       (.clk(clk),
		.reset(reset),
		.router_address(router_address),
		.channel_in_ip(channel_in_ip),
		.flow_ctrl_out_ip(flow_ctrl_out_ip),
		.channel_out_op(channel_out_op),
		.flow_ctrl_in_op(flow_ctrl_in_op),
		.error(error));
	     
	  end
	
	`ROUTER_TYPE_VC:
	  begin
	     
	     vcr_top
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
		 .flow_ctrl_bypass(flow_ctrl_bypass),
		 .max_payload_length(max_payload_length),
		 .min_payload_length(min_payload_length),
		 .enable_link_pm(enable_link_pm),
		 .flit_data_width(flit_data_width),
		 .error_capture_mode(error_capture_mode),
		 .restrict_turns(restrict_turns),
		 .routing_type(routing_type),
		 .dim_order(dim_order),
		 .fb_regfile_type(fb_regfile_type),
		 .fb_mgmt_type(fb_mgmt_type),
		 .fb_fast_peek(fb_fast_peek),
		 .disable_static_reservations(disable_static_reservations),
		 .explicit_pipeline_register(explicit_pipeline_register),
		 .gate_buffer_write(gate_buffer_write),
		 .elig_mask(elig_mask),
		 .vc_alloc_type(vc_alloc_type),
		 .vc_alloc_arbiter_type(vc_alloc_arbiter_type),
		 .sw_alloc_type(sw_alloc_type),
		 .sw_alloc_arbiter_type(sw_alloc_arbiter_type),
		 .sw_alloc_spec_type(sw_alloc_spec_type),
		 .crossbar_type(crossbar_type),
		 .reset_type(reset_type))
	     vcr
	       (.clk(clk),
		.reset(reset),
		.router_address(router_address),
		.channel_in_ip(channel_in_ip),
		.flow_ctrl_out_ip(flow_ctrl_out_ip),
		.channel_out_op(channel_out_op),
		.flow_ctrl_in_op(flow_ctrl_in_op),
		.error(error));
	     
	  end
	
	`ROUTER_TYPE_COMBINED:
	  begin
	     
	     rtr_top
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
		 .flow_ctrl_bypass(flow_ctrl_bypass),
		 .max_payload_length(max_payload_length),
		 .min_payload_length(min_payload_length),
		 .enable_link_pm(enable_link_pm),
		 .flit_data_width(flit_data_width),
		 .error_capture_mode(error_capture_mode),
		 .restrict_turns(restrict_turns),
		 .predecode_lar_info(predecode_lar_info),
		 .routing_type(routing_type),
		 .dim_order(dim_order),
		 .fb_regfile_type(fb_regfile_type),
		 .fb_mgmt_type(fb_mgmt_type),
		 .fb_fast_peek(fb_fast_peek),
		 .disable_static_reservations(disable_static_reservations),
		 .explicit_pipeline_register(explicit_pipeline_register),
		 .gate_buffer_write(gate_buffer_write),
		 .dual_path_alloc(dual_path_alloc),
		 .dual_path_allow_conflicts(dual_path_allow_conflicts),
		 .dual_path_mask_on_ready(dual_path_mask_on_ready),
		 .precomp_ivc_sel(precomp_ivc_sel),
		 .precomp_ip_sel(precomp_ip_sel),
		 .elig_mask(elig_mask),
		 .sw_alloc_arbiter_type(sw_alloc_arbiter_type),
		 .vc_alloc_arbiter_type(vc_alloc_arbiter_type),
		 .vc_alloc_prefer_empty(vc_alloc_prefer_empty),
		 .crossbar_type(crossbar_type),
		 .reset_type(reset_type))
	     rtr
	       (.clk(clk),
		.reset(reset),
		.router_address(router_address),
		.channel_in_ip(channel_in_ip),
		.flow_ctrl_out_ip(flow_ctrl_out_ip),
		.channel_out_op(channel_out_op),
		.flow_ctrl_in_op(flow_ctrl_in_op),
		.error(error));
	     
	  end
	
      endcase
      
   endgenerate
   
endmodule
