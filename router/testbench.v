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

module testbench ();

`include "c_functions.v"
`include "c_constants.v"
   
parameter Tclk = 4;
   
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
   
   // width required to select individual resource class
   localparam resource_class_idx_width = clogb(num_resource_classes);
   
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
   
   // width required to select individual port
   localparam port_idx_width = clogb(num_ports);
   
   // width required for lookahead routing information
   localparam lar_info_width = port_idx_width + resource_class_idx_width;
   
   // total number of bits required for storing routing information
   localparam dest_info_width
     = num_resource_classes * router_addr_width + node_addr_width;
   
   // total number of bits required for routing-related information
   localparam route_info_width = lar_info_width + dest_info_width;
   
   // number of bits required to represent all possible payload sizes
   localparam payload_length_width
     = clogb(max_payload_length-min_payload_length+1);
   
   // total number of bits required for storing header information
   localparam header_info_width
     = (packet_format == `PACKET_FORMAT_HEAD_TAIL) ? 
       route_info_width : 
       (packet_format == `PACKET_FORMAT_TAIL_ONLY) ? 
       route_info_width : 
       (packet_format == `PACKET_FORMAT_EXPLICIT_LENGTH) ? 
       (route_info_width + payload_length_width) : 
       -1;
   
   // width of counter for remaining flits
   localparam flit_ctr_width = clogb(max_payload_length);
   
   // width of flow control signals
   localparam flow_ctrl_width
     = (flow_ctrl_type == `FLOW_CTRL_TYPE_CREDIT) ? (1 + vc_idx_width) :
       -1;
   
   // width of flit control signals
   localparam flit_ctrl_width
     = (packet_format == `PACKET_FORMAT_HEAD_TAIL) ? 
       (1 + vc_idx_width + 1 + 1) : 
       (packet_format == `PACKET_FORMAT_TAIL_ONLY) ? 
       (1 + vc_idx_width + 1) : 
       (packet_format == `PACKET_FORMAT_EXPLICIT_LENGTH) ? 
       (1 + vc_idx_width + 1) : 
       -1;
   
   // select set of feedback polynomials used for LFSRs
   parameter lfsr_index = 0;
   
   // number of bits in address that are considered base address
   parameter cfg_node_addr_width = 10;
   
   // width of register selector part of control register address
   parameter cfg_reg_addr_width = 6;
   
   // width of configuration bus addresses
   localparam cfg_addr_width = cfg_node_addr_width + cfg_reg_addr_width;
   
   // width of control register data
   parameter cfg_data_width = 32;
   
   // base address width for interface bus
   localparam io_node_addr_width = cfg_node_addr_width;
   
   // register index width for interface bus
   localparam io_reg_addr_width = cfg_reg_addr_width;
   
   // width of interface bus addresses
   localparam io_addr_width = cfg_addr_width;
   
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
   parameter done_delay_width = 4;
   
   // number of node control signals to generate
   parameter node_ctrl_width = 2;
   
   // number of node status signals to accept
   parameter node_status_width = 1;
   
   // RNG seed value
   parameter initial_seed = 0;
   
   reg 		    reset;
   reg 		    clk;
   
   reg [0:io_node_addr_width-1] io_node_addr_base;
   
   reg 				io_write;
   reg 				io_read;
   reg [0:cfg_addr_width-1] 	io_addr;
   reg [0:cfg_data_width-1] 	io_write_data;
   wire [0:cfg_data_width-1] 	io_read_data;
   wire 			io_done;
   
   wire 			error;
   
   tc_router_wrap
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
       .flit_data_width(flit_data_width),
       .error_capture_mode(error_capture_mode),
       .restrict_turns(restrict_turns),
       .predecode_lar_info(predecode_lar_info),
       .routing_type(routing_type),
       .dim_order(dim_order),
       .input_stage_can_hold(input_stage_can_hold),
       .fb_regfile_type(fb_regfile_type),
       .fb_mgmt_type(fb_mgmt_type),
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
       .reset_type(reset_type),
       .lfsr_index(lfsr_index),
       .cfg_node_addr_width(cfg_node_addr_width),
       .cfg_reg_addr_width(cfg_reg_addr_width),
       .cfg_data_width(cfg_data_width),
       .num_packets_width(num_packets_width),
       .arrival_rv_width(arrival_rv_width),
       .mc_idx_rv_width(mc_idx_rv_width),
       .rc_idx_rv_width(rc_idx_rv_width),
       .plength_idx_rv_width(plength_idx_rv_width),
       .num_plength_vals(num_plength_vals),
       .packet_count_width(packet_count_width),
       .done_delay_width(done_delay_width))
   dut
     (.clk(clk),
      .reset(reset),
      .io_node_addr_base(io_node_addr_base),
      .io_write(io_write),
      .io_read(io_read),
      .io_addr(io_addr),
      .io_write_data(io_write_data),
      .io_read_data(io_read_data),
      .io_done(io_done),
      .error(error));
   
   reg 				clk_en;
   
   always
   begin
      clk <= clk_en;
      #(Tclk/2);
      clk <= 1'b0;
      #(Tclk/2);
   end
   
   always @(posedge clk)
     begin
	if(error)
	  begin
	     $display("error detected, cyc=%d", $time);
	     $stop;
	  end
     end
   
   reg done;
   integer i, j;
   integer seed = initial_seed;
   
   initial
   begin
      
      reset = 1'b0;
      clk_en = 1'b0;
      io_node_addr_base = 'd0;
      
      #(Tclk);
      
      #(Tclk/4);
      
      reset = 1'b1;
      io_write = 1'b0;
      io_read = 1'b0;
      io_addr = 'b0;
      io_write_data = 'b0;
      done = 1'b0;
      
      #(Tclk);
      
      reset = 1'b0;
      
      #(Tclk);
      
      clk_en = 1'b1;
      
      #(Tclk);
      
      
      // disable reset (i.e., enable reset_b)
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 'd0;
      io_addr[cfg_node_addr_width:cfg_addr_width-1] = `CFG_ADDR_NCTL_CTRL;
      io_write_data = 'd0;
      io_write_data[0] = 1'b1;
      io_write_data[2] = 1'b1;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(Tclk);
      
      // enable clocks
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 'd0;
      io_addr[cfg_node_addr_width:cfg_addr_width-1] = `CFG_ADDR_NCTL_CTRL;
      io_write_data = 'd0;
      io_write_data[0] = 1'b1;
      io_write_data[1] = 1'b1;
      io_write_data[2] = 1'b1;
      io_write_data[3] = 1'b1;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(Tclk);
      
      // set LFSR seeds
      
      for(j = (num_ports - num_nodes_per_router); j < num_ports; j = j + 1)
	begin
	   io_write = 1'b1;
	   io_addr[0:cfg_node_addr_width-1] = 1 + j;
	   io_addr[cfg_node_addr_width:cfg_addr_width-1]
	     = `CFG_ADDR_NODE_LFSR_SEED;
	   for(i = 0; i < cfg_data_width; i = i + 1)
	     io_write_data[i] = $dist_uniform(seed, 0, 1);
	   while(!io_done)
	     #(Tclk);
	   #(Tclk);
	   io_write = 1'b0;
	   while(io_done)
	     #(Tclk);
	   
	   #(Tclk);
	   
	end
      
      // set number of packets
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1]
	= `CFG_ADDR_NODE_NUM_PACKETS;
      io_write_data = 'd0;
      io_write_data[0:num_packets_width-1] = 'd1024;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(Tclk);
      
      
      // set arrival rate threshold
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1]
	= `CFG_ADDR_NODE_ARRIVAL_THRESH;
      io_write_data = 'd0;
      io_write_data[0:arrival_rv_width-1] = 'd4096;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(Tclk);
      
      
      // set packet length selection threshold
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1]
	= `CFG_ADDR_NODE_PLENGTH_THRESHS;
      io_write_data = 'd0;
      io_write_data[0:plength_idx_rv_width-1] = 'd8;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(Tclk);
      
      
      // set packet length values
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1]
	= `CFG_ADDR_NODE_PLENGTH_VALS;
      io_write_data = 'd0;
      io_write_data[0:payload_length_width-1] = 'd0;
      io_write_data[payload_length_width:2*payload_length_width-1] = 'd4;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(Tclk);
      
      
      // set message class selection thresholds
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1] = `CFG_ADDR_NODE_MC_THRESHS;
      io_write_data = 'd0;
      io_write_data[0:mc_idx_rv_width-1] = 'd10;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(Tclk);
      
      
      // set resource class selection thresholds
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1] = `CFG_ADDR_NODE_RC_THRESHS;
      io_write_data = 'd0;
      io_write_data[0:rc_idx_rv_width-1] = 'd12;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(10*Tclk);
      
      
      // start experiment
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1] = `CFG_ADDR_NODE_CTRL;
      io_write_data = 'd0;
      io_write_data[0] = 'd1;
      io_write_data[1] = 'd0;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      
      // wait for experiment to finish
      
      while(!done)
	begin
	   
	   #(10*Tclk);
	   
	   io_read = 1'b1;
	   io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
	   io_addr[cfg_node_addr_width:cfg_addr_width-1]
	     = `CFG_ADDR_NODE_STATUS;
	   io_write_data = 'd0;
	   while(!io_done)
	     #(Tclk);
	   done = ~io_read_data[0];
	   #(Tclk);
	   io_read = 1'b0;
	   while(io_done)
	     #(Tclk);
	   
	end
      done = 1'b0;
      
      #(Tclk);
      
      
      // disable nodes
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1] = `CFG_ADDR_NODE_CTRL;
      io_write_data = 'd0;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(Tclk);
      
      
      // disable router clocks
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 'd0;
      io_addr[cfg_node_addr_width:cfg_addr_width-1] = `CFG_ADDR_NCTL_CTRL;
      io_write_data = 'd0;
      io_write_data[0] = 1'b1;
      io_write_data[1] = 1'b1;
      io_write_data[2] = 1'b1;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(Tclk);
      
      
      // reset number of packets
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1]
	= `CFG_ADDR_NODE_NUM_PACKETS;
      io_write_data = 'd0;
      io_write_data[0:num_packets_width-1] = 'd1024;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(10*Tclk);
      
      
      // restart experiment in loopback mode
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1] = `CFG_ADDR_NODE_CTRL;
      io_write_data = 'd0;
      io_write_data[0] = 'd1;
      io_write_data[1] = 'd1;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      
      // wait for experiment to finish
      
      while(!done)
	begin
	   
	   #(10*Tclk);
	   
	   io_read = 1'b1;
	   io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
	   io_addr[cfg_node_addr_width:cfg_addr_width-1]
	     = `CFG_ADDR_NODE_STATUS;
	   io_write_data = 'd0;
	   while(!io_done)
	     #(Tclk);
	   done = ~io_read_data[0];
	   #(Tclk);
	   io_read = 1'b0;
	   while(io_done)
	     #(Tclk);
	   
	end
      done = 1'b0;
      
      #(Tclk);
      
      
      // disable nodes
      
      io_write = 1'b1;
      io_addr[0:cfg_node_addr_width-1] = 1 + num_ports;
      io_addr[cfg_node_addr_width:cfg_addr_width-1] = `CFG_ADDR_NODE_CTRL;
      io_write_data = 'd0;
      while(!io_done)
	#(Tclk);
      #(Tclk);
      io_write = 1'b0;
      while(io_done)
	#(Tclk);
      
      #(3*Tclk/4);
      
      #(Tclk);
      
      $finish;
      
   end
   
endmodule
