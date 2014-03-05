// $Id: tc_router_wrap.v 5188 2012-08-30 00:31:31Z dub $

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
// wrapper around router component, pseudo-nodes and controller
//==============================================================================

module tc_router_wrap
  (clk, reset, io_node_addr_base, io_write, io_read, io_addr, io_write_data, 
   io_read_data, io_done, error);
   
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
   
   // width required to select individual node at current router
   localparam node_addr_width = clogb(num_nodes_per_router);
   
   // width of global addresses
   localparam addr_width = router_addr_width + node_addr_width;
   
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
   
   // channel width
   localparam channel_width
     = link_ctrl_width + flit_ctrl_width + flit_data_width;
   
   // select set of feedback polynomials used for LFSRs
   parameter lfsr_index = 0;
   
   // number of bits in address that are considered base address
   parameter cfg_node_addr_width = 10;
   
   // width of register selector part of control register address
   parameter cfg_reg_addr_width = 6;
   
   // width of configuration bus addresses
   localparam cfg_addr_width = cfg_node_addr_width + cfg_reg_addr_width;
   
   // width of configuration bus datapath
   parameter cfg_data_width = 32;
   
   // base address width for interface bus
   localparam io_node_addr_width = cfg_node_addr_width;
   
   // register index width for interface bus
   localparam io_reg_addr_width = cfg_reg_addr_width;
   
   // width of interface bus addresses
   localparam io_addr_width = io_node_addr_width + io_reg_addr_width;
   
   // width of interface bus datapath
   localparam io_data_width = cfg_data_width;
   
   // width of run cycle counter
   parameter num_packets_width = 16;
   
   // width of arrival rate LFSR
   parameter arrival_rv_width = 16;
   
   // width of message class selection LFSR
   parameter mc_idx_rv_width = 4;
   
   // width of resource class selection LFSR
   parameter rc_idx_rv_width = 4;
   
   // width of payload length selection LFSR
   parameter plength_idx_rv_width = 4;
   
   // number of selectable payload lengths
   parameter num_plength_vals = 2;
   
   // width of register that holds the number of outstanding packets
   parameter packet_count_width = 8;
   
   // number of bits in delay counter for acknowledgement (i.e., log2 of 
   // interval before acknowledgement is sent)
   parameter done_delay_width = 6;
   
   // number of node control signals to generate
   localparam node_ctrl_width = 2 + 2;
   
   // number of node status signals to accept
   localparam node_status_width = 1 + num_ports;
   
   input clk;
   input reset;
   
   // base address for this router
   input [0:io_node_addr_width-1] io_node_addr_base;
   
   // write request indicator from chip controller
   input 			  io_write;
   
   // read request indicator from chip controller
   input 			  io_read;
   
   // register address
   input [0:io_addr_width-1] 	  io_addr;
   
   // input data
   input [0:io_data_width-1] 	  io_write_data;
   
   // result data to chip controller
   output [0:io_data_width-1] 	  io_read_data;
   wire [0:io_data_width-1] 	  io_read_data;
   
   // completion indicator to chip controller
   output 			  io_done;
   wire 			  io_done;
   
   // summary error indicator
   output 			  error;
   wire 			  error;
   
   wire [0:router_addr_width-1]   router_address;
   
   genvar 			  dim;
   
   generate
      
      for(dim = 0; dim < num_dimensions; dim = dim + 1)
	begin:dims
	   assign router_address[dim*dim_addr_width:(dim+1)*dim_addr_width-1]
	     = num_routers_per_dim / 2;
	end
      
   endgenerate
   
   wire [0:cfg_node_addr_width-1] nctl_cfg_node_addrs;
   assign nctl_cfg_node_addrs = io_node_addr_base;
   
   wire 			  cfg_req;
   wire 			  cfg_write;
   wire [0:cfg_addr_width-1] 	  cfg_addr;
   wire [0:cfg_data_width-1] 	  cfg_write_data;
   wire [0:cfg_data_width-1] 	  cfg_read_data;
   wire 			  cfg_done;
   
   wire [0:node_ctrl_width-1] 	  node_ctrl;
   wire [0:node_status_width-1]   node_status;
   
   tc_node_ctrl_mac
     #(.cfg_node_addr_width(cfg_node_addr_width),
       .cfg_reg_addr_width(cfg_reg_addr_width),
       .num_cfg_node_addrs(1),
       .cfg_data_width(cfg_data_width),
       .done_delay_width(done_delay_width),
       .node_ctrl_width(node_ctrl_width),
       .node_status_width(node_status_width),
       .reset_type(reset_type))
   nctl
     (.clk(clk),
      .reset(reset),
      .io_write(io_write),
      .io_read(io_read),
      .io_addr(io_addr),
      .io_write_data(io_write_data),
      .io_read_data(io_read_data),
      .io_done(io_done),
      .cfg_node_addrs(nctl_cfg_node_addrs),
      .cfg_req(cfg_req),
      .cfg_write(cfg_write),
      .cfg_addr(cfg_addr),
      .cfg_write_data(cfg_write_data),
      .cfg_read_data(cfg_read_data),
      .cfg_done(cfg_done),
      .node_ctrl(node_ctrl),
      .node_status(node_status));
   
   wire 			  force_node_reset_b;
   assign force_node_reset_b = node_ctrl[0];
   
   wire 			  node_reset;
   assign node_reset = reset | ~force_node_reset_b;
   
   wire 			  node_clk_en;
   assign node_clk_en = node_ctrl[1];
   
   wire 			  node_clk;
   assign node_clk = clk & node_clk_en;
   
   wire 			  force_rtr_reset_b;
   assign force_rtr_reset_b = node_ctrl[2];
   
   wire 			  rtr_reset;
   assign rtr_reset = reset | ~force_rtr_reset_b;
   
   wire 			  rtr_clk_en;
   assign rtr_clk_en = node_ctrl[3];
   
   wire 			  rtr_clk;
   assign rtr_clk = clk & rtr_clk_en;
   
   wire [0:num_ports*channel_width-1] node_rtr_channel_p;
   wire [0:num_ports*flow_ctrl_width-1] node_rtr_flow_ctrl_p;
   
   wire [0:num_ports*channel_width-1] 	rtr_node_channel_p;
   wire [0:num_ports*flow_ctrl_width-1] rtr_node_flow_ctrl_p;
   
   wire [0:num_ports*cfg_data_width-1] 	cfg_read_data_p;
   wire [0:num_ports-1] 		cfg_done_p;
   
   wire [0:num_ports-1] 		node_error_p;
   
   genvar 				port;
   
   generate
      
      for(port = 0; port < num_ports; port = port + 1)
	begin:ports
	   
	   wire [0:channel_width-1] channel_in;
	   assign channel_in
	     = rtr_node_channel_p[port*channel_width:(port+1)*channel_width-1];
	   
	   wire [0:flow_ctrl_width-1] flow_ctrl_in;
	   assign flow_ctrl_in
	     = rtr_node_flow_ctrl_p[port*flow_ctrl_width:
				    (port+1)*flow_ctrl_width-1];
	   
	   wire [0:2*cfg_node_addr_width-1] node_cfg_node_addrs;
	   assign node_cfg_node_addrs[0:cfg_node_addr_width-1]
		    = io_node_addr_base + port + 1;
	   assign node_cfg_node_addrs[cfg_node_addr_width:
				      2*cfg_node_addr_width-1]
		    = io_node_addr_base + num_ports + 1;
	   
	   wire [0:channel_width-1] 	    channel_out;
	   wire [0:flow_ctrl_width-1] 	    flow_ctrl_out;
	   
	   wire [0:cfg_data_width-1] 	    cfg_read_data;
	   wire 			    cfg_done;
	   
	   wire 			    node_error;
	   
	   if(port >= (num_ports - num_nodes_per_router))
	     begin
		
		wire [0:addr_width-1] address;
		assign address[0:router_addr_width-1] = router_address;
		
		if(num_nodes_per_router > 1)
		  assign address[router_addr_width:addr_width-1]
			   = (port - (num_ports - num_nodes_per_router));
		
		tc_node_mac
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
		    .routing_type(routing_type),
		    .dim_order(dim_order),
		    .fb_mgmt_type(fb_mgmt_type),
		    .disable_static_reservations(disable_static_reservations),
		    .elig_mask(elig_mask),
		    .lfsr_index(/*num_ports * */ lfsr_index /*+ port*/),
		    .cfg_node_addr_width(cfg_node_addr_width),
		    .cfg_reg_addr_width(cfg_reg_addr_width),
		    .num_cfg_node_addrs(2),
		    .cfg_data_width(cfg_data_width),
		    .num_packets_width(num_packets_width),
		    .arrival_rv_width(arrival_rv_width),
		    .mc_idx_rv_width(mc_idx_rv_width),
		    .rc_idx_rv_width(rc_idx_rv_width),
		    .plength_idx_rv_width(plength_idx_rv_width),
		    .num_plength_vals(num_plength_vals),
		    .packet_count_width(packet_count_width),
		    .reset_type(reset_type))
		node
		  (.clk(node_clk),
		   .reset(node_reset),
		   .address(address),
		   .channel_out(channel_out),
		   .flow_ctrl_in(flow_ctrl_in),
		   .channel_in(channel_in),
		   .flow_ctrl_out(flow_ctrl_out),
		   .cfg_node_addrs(node_cfg_node_addrs),
		   .cfg_req(cfg_req),
		   .cfg_write(cfg_write),
		   .cfg_addr(cfg_addr),
		   .cfg_write_data(cfg_write_data),
		   .cfg_read_data(cfg_read_data),
		   .cfg_done(cfg_done),
		   .error(node_error));
		
	     end
	   else
	     begin
		
		assign channel_out = {channel_width{1'b0}};
		
		wire [0:flit_ctrl_width-1] flit_ctrl_in;
		assign flit_ctrl_in
		  = channel_in[link_ctrl_width:
			       link_ctrl_width+flit_ctrl_width-1];
		
		assign flow_ctrl_out = flit_ctrl_in[0:flow_ctrl_width-1];
		
		assign cfg_read_data = {cfg_data_width{1'b0}};
		assign cfg_done = 1'b0;
		
		assign node_error = 1'b0;
		
	     end
	   
	   assign node_rtr_channel_p[port*channel_width:
				     (port+1)*channel_width-1]
		    = channel_out;
	   assign node_rtr_flow_ctrl_p[port*flow_ctrl_width:
				       (port+1)*flow_ctrl_width-1]
		    = flow_ctrl_out;
	   
	   assign cfg_read_data_p[port*cfg_data_width:(port+1)*cfg_data_width-1]
		    = cfg_read_data;
	   assign cfg_done_p[port] = cfg_done;
	   
	   assign node_error_p[port] = node_error;
	   
	end
      
   endgenerate
   
   wire 				    rtr_error;
   
   router_wrap
     #(.topology(topology),
       .buffer_size(buffer_size),
       .num_message_classes(num_message_classes),
       .num_resource_classes(num_resource_classes),
       .num_vcs_per_class(num_vcs_per_class),
       .num_nodes(num_nodes),
       .num_dimensions(num_dimensions),
       .num_nodes_per_router(num_nodes_per_router),
       .packet_format(packet_format),
       .flow_ctrl_type(flow_ctrl_type),
       .flow_ctrl_bypass(flow_ctrl_bypass),
       .max_payload_length(max_payload_length),
       .min_payload_length(min_payload_length),
       .router_type(router_type),
       .enable_link_pm(enable_link_pm),
       .flit_data_width(flit_data_width),
       .error_capture_mode(error_capture_mode),
       .restrict_turns(restrict_turns),
       .predecode_lar_info(predecode_lar_info),
       .routing_type(routing_type),
       .dim_order(dim_order),
       .input_stage_can_hold(input_stage_can_hold),
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
       .vc_alloc_type(vc_alloc_type),
       .vc_alloc_arbiter_type(vc_alloc_arbiter_type),
       .vc_alloc_prefer_empty(vc_alloc_prefer_empty),
       .sw_alloc_type(sw_alloc_type),
       .sw_alloc_arbiter_type(sw_alloc_arbiter_type),
       .sw_alloc_spec_type(sw_alloc_spec_type),
       .crossbar_type(crossbar_type),
       .reset_type(reset_type))
   rtr
     (.clk(rtr_clk),
      .reset(rtr_reset),
      .router_address(router_address),
      .channel_in_ip(node_rtr_channel_p),
      .flow_ctrl_out_ip(rtr_node_flow_ctrl_p),
      .channel_out_op(rtr_node_channel_p),
      .flow_ctrl_in_op(node_rtr_flow_ctrl_p),
      .error(rtr_error));
   
   c_select_1ofn
     #(.num_ports(num_ports),
       .width(cfg_data_width))
   cfg_read_data_sel
     (.select(cfg_done_p),
      .data_in(cfg_read_data_p),
      .data_out(cfg_read_data));
   
   assign cfg_done = |cfg_done_p;
   
   wire [0:num_ports] 			    errors;
   assign errors = {rtr_error, node_error_p};
   
   assign error = |errors;
   
   assign node_status = errors;
   
endmodule