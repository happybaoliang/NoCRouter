// $Id: testbench.v 5188 2012-08-30 00:31:31Z dub $

/*
 Copyright (c) 2007-2012, Trustees of The Leland Stanford Junior University
 All rights reserved.

 Copyright (c) 2007-2012, Trustees of The Leland Stanford Junior University
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

module testbench();
   
`include "c_functions.v"
`include "c_constants.v"
`include "rtr_constants.v"
`include "vcr_constants.v"
`include "parameters.v"
   
   parameter Tclk = 2;
   
   parameter initial_seed = 0;
   
   // maximum number of packets to generate (-1 = no limit)
   parameter max_packet_count = -1;
   
   // packet injection rate (per 10k cycles)
   parameter packet_rate = 1000;
   
   // flit consumption rate (per 10k cycles)
   parameter consume_rate = 10000;
   
   // width of packet count register
   parameter packet_count_reg_width = 32;
   
   // channel latency in cycles
   parameter channel_latency = 1;
   
   // only inject traffic at the node ports
   parameter inject_node_ports_only = 1;
   
   // warmup time in cycles
   parameter warmup_time = 100000;
   
   // measurement interval in cycles
   parameter measure_time = 100000;
   
   // select packet length mode (0: uniform random, 1: bimodal)
   parameter packet_length_mode = 0;
   
   // width required to select individual resource class
   localparam resource_class_idx_width = clogb(num_resource_classes);
   
   // total number of packet classes
   localparam num_packet_classes = num_message_classes * num_resource_classes;
   
   // number of VCs
   localparam num_vcs = num_packet_classes * num_vcs_per_class;
   
   // width required to select individual VC
   localparam vc_idx_width = clogb(num_vcs);
   
   // total number of routers
   localparam num_routers = (num_nodes + num_nodes_per_router - 1) / num_nodes_per_router;
   
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
   localparam num_ports = num_dimensions * num_neighbors_per_dim + num_nodes_per_router;
   
   // width required to select individual port
   localparam port_idx_width = clogb(num_ports);
   
   // width required to select individual node at current router
   localparam node_addr_width = clogb(num_nodes_per_router);
   
   // width required for lookahead routing information
   localparam lar_info_width = port_idx_width + resource_class_idx_width;
   
   // total number of bits required for storing routing information
   localparam dest_info_width = (routing_type == `ROUTING_TYPE_PHASED_DOR) 
				? (num_resource_classes * router_addr_width + node_addr_width) 
				: -1;
   
   // total number of bits required for routing-related information
   localparam route_info_width = lar_info_width + dest_info_width;
   
   // width of flow control signals
   localparam flow_ctrl_width = (flow_ctrl_type == `FLOW_CTRL_TYPE_CREDIT) ? (1 + vc_idx_width) : -1;
   
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
   localparam channel_width = link_ctrl_width + flit_ctrl_width + flit_data_width;
   
   // use atomic VC allocation
   localparam atomic_vc_allocation = (elig_mask == `ELIG_MASK_USED);
   
   // number of pipeline stages in the channels
   localparam num_channel_stages = channel_latency - 1;
   
   reg clk;
   reg run;
   reg reset;
  
// port 0: West
// port 1: East
// port 2: South
// port 3: North
// port 4: Local

   wire [0:num_routers-1]							rtr_error;
   wire [0:num_routers-1] 							ps_error_ip;
   wire [0:num_routers-1]							fs_error_op;
   wire [0:num_routers-1] 							flit_valid_in_ip;
   wire [0:num_routers-1] 							cred_valid_in_op;
   wire [0:num_routers-1] 							cred_valid_out_ip;
   wire [0:num_routers-1] 							flit_valid_out_op;
   wire [0:num_routers*num_ports-1]					rtr_shared_vc_out;
   wire [0:num_routers*num_ports*channel_width-1]	rtr_channel_out_op;
   wire [0:num_routers*num_ports*flow_ctrl_width-1]	rtr_flow_ctrl_out_ip;
   wire [0:num_routers*num_ports-1]					rtr_ready_for_allocation;
   wire [0:num_routers*num_ports*num_ports-1]		rtr_memory_bank_grant_out;
   wire [0:num_routers*num_ports-1]					rtr_credit_for_shared_out;
   wire [0:num_routers*num_ports*num_vcs-1]			rtr_ip_shared_ivc_allocated;

	genvar x_dim, y_dim;
	generate      
		for(x_dim = 0; x_dim < num_routers_per_dim; x_dim = x_dim + 1)
		begin:xdims
			for (y_dim = 0; y_dim <num_routers_per_dim; y_dim = y_dim +1)
			begin:ydims
				wire [31:0] xdim_addr;
				assign xdim_addr = x_dim;
				
				wire [31:0] ydim_addr;
				assign ydim_addr = y_dim;

				wire [0:router_addr_width-1] router_address;
				assign router_address = {xdim_addr[dim_addr_width-1:0],ydim_addr[dim_addr_width-1:0]};

				wire [0:flow_ctrl_width-1] flow_ctrl_to_ps;
				assign flow_ctrl_to_ps = rtr_flow_ctrl_out_ip[(x_dim*num_routers_per_dim+y_dim)*num_ports*flow_ctrl_width
						+4*flow_ctrl_width+:flow_ctrl_width];
		
				assign cred_valid_out_ip[x_dim*num_routers_per_dim+y_dim] = flow_ctrl_to_ps[0];
		
				wire [0:flow_ctrl_width-1] flow_ctrl_to_ps_dly;
				c_shift_reg
		  		#(.width(flow_ctrl_width),
		    	  .depth(num_channel_stages),
		    	  .reset_type(reset_type))
				flow_ctrl_from_ps_dly_sr
		  		 (.clk(clk),
		   		  .reset(reset),
		   		  .active(1'b1),
		   		  .data_in(flow_ctrl_to_ps),
		   		  .data_out(flow_ctrl_to_ps_dly));

				wire shared_credit_from_rtr;
				assign shared_credit_from_rtr = rtr_credit_for_shared_out[(x_dim*num_routers_per_dim+y_dim)*num_ports+4+:1];
				
				wire credit_shared_in;
				c_shift_reg
		  		#(.width(1),
				  .depth(num_channel_stages),
				  .reset_type(reset_type))
				credit_for_shared_dly_sr
		   		 (.clk(clk),
				  .reset(reset),
				  .active(1'b1),
				  .data_in(shared_credit_from_rtr),
				  .data_out(credit_shared_in));

				wire [0:num_ports-1]		memory_bank_grant_to_ps;
				assign memory_bank_grant_to_ps = rtr_memory_bank_grant_out[(x_dim*num_routers_per_dim+y_dim)*num_ports+4+:1];

				wire 			   			ps_error;
				wire 			   			flit_valid;
				wire [0:channel_width-1]	channel_from_ps;
				wire						shared_vc_from_ps;

				packet_source
		  		#(.initial_seed(initial_seed+x_dim*num_routers_per_dim+y_dim),
		    	  .max_packet_count(max_packet_count),
		    	  .packet_rate(packet_rate),
		    	  .packet_count_reg_width(packet_count_reg_width),
		    	  .packet_length_mode(packet_length_mode),
		    	  .topology(topology),
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
		    	  .enable_link_pm(enable_link_pm),
		    	  .flit_data_width(flit_data_width),
		    	  .routing_type(routing_type),
		    	  .dim_order(dim_order),
		    	  .fb_mgmt_type(fb_mgmt_type),
		    	  .disable_static_reservations(disable_static_reservations),
		    	  .elig_mask(elig_mask),
		    	  .port_id(4), //hardcoded to the injection port, port 4
		    	  .reset_type(reset_type))
				ps
		  		 (.clk(clk),
		   		  .reset(reset),
		   		  .router_address(router_address),
		   		  .channel(channel_from_ps),
		   		  .memory_bank_grant(memory_bank_grant_to_ps),
		   		  .shared_vc(shared_vc_from_ps),
		   		  .flit_valid(flit_valid),
		   		  .credit_for_shared(credit_shared_in),
		   		  .flow_ctrl(flow_ctrl_to_ps_dly),
		   		  .run(run),
		   		  .error(ps_error));

				assign ps_error_ip[x_dim*num_routers_per_dim+y_dim] = ps_error;

				wire [0:channel_width-1] channel_from_ps_dly;
				c_shift_reg
		  		#(.width(channel_width),
		    	  .depth(num_channel_stages),
		    	  .reset_type(reset_type))
				channel_from_ps_dly_sr
		  		 (.clk(clk),
		   		  .reset(reset),
		   		  .active(1'b1),
		   		  .data_in(channel_from_ps),
		   		  .data_out(channel_from_ps_dly));

				wire shared_vc_from_ps_dly;
				c_shift_reg
		  		#(.width(1),
				  .depth(num_channel_stages),
				  .reset_type(reset_type))
				vc_shared_from_ps_dly_sr
		   		 (.clk(clk),
				  .reset(reset),
				  .active(1'b1),
				  .data_in(shared_vc_from_ps),
				  .data_out(shared_vc_from_ps_dly));

				wire flit_valid_dly;
				c_shift_reg
		  		#(.width(1),
		    	  .depth(num_channel_stages),
		    	  .reset_type(reset_type))
				flit_valid_dly_sr
		  		 (.clk(clk),
		   		  .reset(reset),
		   		  .active(1'b1),
		   		  .data_in(flit_valid),
		   		  .data_out(flit_valid_dly));
		
				assign flit_valid_in_ip[x_dim*num_routers_per_dim+y_dim] = flit_valid_dly;

	   			wire [0:flow_ctrl_width-1] 	flow_ctrl_from_fs_dly;
	   			wire 						shared_credit_from_fs_dly;
				wire [0:num_ports-1]		memory_bank_grant_from_fs;

   				// port 0: West
   				// port 1: East
   				// port 2: South
   				// port 3: North
   				// port 4: Local
				wire [0:num_ports-1]					shared_vc_in;
				wire [0:num_ports*channel_width-1] 		channel_in_ip;
				wire [0:num_ports*flow_ctrl_width-1] 	flow_ctrl_in_op;
				wire [0:num_ports-1]					credit_for_shared_in;
				wire [0:num_ports*num_ports-1]			memory_bank_grant_in;
				wire [0:num_ports-1]					ready_for_allocation_in;
				wire [0:num_ports*num_vcs-1]			ip_shared_ivc_allocated_in;

				if (x_dim==0)
				begin
					assign shared_vc_in[0] = 1'b0;
					assign credit_for_shared_in[0] = 1'b0;
					assign ready_for_allocation_in[0] = 1'b1;
					assign memory_bank_grant_in[0:num_ports-1] = {num_ports{1'b0}};
					assign channel_in_ip[0:channel_width-1] = {channel_width{1'b0}};
					assign ip_shared_ivc_allocated_in[0:num_vcs-1] = {num_vcs{1'b0}};
					assign flow_ctrl_in_op[0:flow_ctrl_width-1] = {flow_ctrl_width{1'b0}};
				end
				else
				begin
					assign shared_vc_in[0] = rtr_shared_vc_out[((x_dim-1)*num_routers_per_dim+y_dim)*num_ports+1+:1];
					assign credit_for_shared_in[0] = 
						rtr_credit_for_shared_out[((x_dim-1)*num_routers_per_dim+y_dim)*num_ports+1+:1];
					assign memory_bank_grant_in[0:num_ports-1] =
						rtr_memory_bank_grant_out[((x_dim-1)*num_routers_per_dim+y_dim)*num_ports*num_ports
							+num_ports+:num_ports];
					assign channel_in_ip[0:channel_width-1] =
						rtr_channel_out_op[((x_dim-1)*num_routers_per_dim+y_dim)*num_ports*channel_width
							+channel_width+:channel_width];
					assign flow_ctrl_in_op[0:flow_ctrl_width-1] = 
						rtr_flow_ctrl_out_ip[((x_dim-1)*num_routers_per_dim+y_dim)*num_ports*flow_ctrl_width
							+flow_ctrl_width+:flow_ctrl_width];
					assign ready_for_allocation_in[0] = 
						rtr_ready_for_allocation[((x_dim-1)*num_routers_per_dim+y_dim)*num_ports];
					assign ip_shared_ivc_allocated_in[0:num_vcs-1] =
						rtr_ip_shared_ivc_allocated[((x_dim-1)*num_routers_per_dim+y_dim)*num_ports*num_vcs+:num_vcs];
				end

				if (x_dim==num_routers_per_dim-1)
				begin
					assign shared_vc_in[1] = 1'b0;
					assign credit_for_shared_in[1] = 1'b0;
					assign memory_bank_grant_in[num_ports:2*num_ports-1] = {num_ports{1'b0}};
					assign channel_in_ip[channel_width:2*channel_width-1] = {channel_width{1'b0}};
					assign flow_ctrl_in_op[flow_ctrl_width:2*flow_ctrl_width-1] = {flow_ctrl_width{1'b0}};
					assign ready_for_allocation_in[1] = 1'b1;
					assign ip_shared_ivc_allocated_in[num_vcs:2*num_vcs-1] = {num_vcs{1'b0}};
				end
				else
				begin
					assign shared_vc_in[1] = rtr_shared_vc_out[((x_dim+1)*num_routers_per_dim+y_dim)*num_ports+:1];
					assign credit_for_shared_in[1] = 
						rtr_credit_for_shared_out[((x_dim+1)*num_routers_per_dim+y_dim)*num_ports+:1];
					assign memory_bank_grant_in[num_ports:2*num_ports-1] =
						rtr_memory_bank_grant_out[((x_dim+1)*num_routers_per_dim+y_dim)*num_ports*num_ports+:num_ports];
					assign channel_in_ip[channel_width:2*channel_width-1] =
						rtr_channel_out_op[((x_dim+1)*num_routers_per_dim+y_dim)*num_ports*channel_width+:channel_width];
					assign flow_ctrl_in_op[flow_ctrl_width:2*flow_ctrl_width-1] = 
						rtr_flow_ctrl_out_ip[((x_dim+1)*num_routers_per_dim+y_dim)*num_ports*flow_ctrl_width+:flow_ctrl_width];
					assign ready_for_allocation_in[1] = 
						rtr_ready_for_allocation[((x_dim+1)*num_routers_per_dim+y_dim)*num_ports];
					assign ip_shared_ivc_allocated_in[num_vcs:2*num_vcs-1] =
						rtr_ip_shared_ivc_allocated[((x_dim+1)*num_routers_per_dim+y_dim)*num_ports*num_vcs+:num_vcs];
				end

				if (y_dim==0)
				begin
					assign shared_vc_in[2] = 1'b0;
					assign credit_for_shared_in[2] = 1'b0;
					assign memory_bank_grant_in[2*num_ports:3*num_ports-1] = {num_ports{1'b0}};
					assign channel_in_ip[2*channel_width:3*channel_width-1] = {channel_width{1'b0}};
					assign flow_ctrl_in_op[2*flow_ctrl_width:3*flow_ctrl_width-1] = {flow_ctrl_width{1'b0}};
					assign ready_for_allocation_in[2] = 1'b1;
					assign ip_shared_ivc_allocated_in[2*num_vcs:3*num_vcs-1] = {num_vcs{1'b0}};
				end
				else
				begin
					assign shared_vc_in[2] = rtr_shared_vc_out[(x_dim*num_routers_per_dim+y_dim-1)*num_ports+3+:1];
					assign credit_for_shared_in[2] = 
						rtr_credit_for_shared_out[(x_dim*num_routers_per_dim+y_dim-1)*num_ports+3+:1];
					assign memory_bank_grant_in[2*num_ports:3*num_ports-1] =
						rtr_memory_bank_grant_out[(x_dim*num_routers_per_dim+y_dim-1)*num_ports*num_ports
							+3*num_ports+:num_ports];
					assign channel_in_ip[2*channel_width:3*channel_width-1] =
						rtr_channel_out_op[(x_dim*num_routers_per_dim+y_dim-1)*num_ports*channel_width
							+3*channel_width+:channel_width];
					assign flow_ctrl_in_op[2*flow_ctrl_width:3*flow_ctrl_width-1] = 
						rtr_flow_ctrl_out_ip[(x_dim*num_routers_per_dim+y_dim-1)*num_ports*flow_ctrl_width
							+3*flow_ctrl_width+:flow_ctrl_width];
					assign ready_for_allocation_in[2] = 
						rtr_ready_for_allocation[(x_dim*num_routers_per_dim+y_dim-1)*num_ports];
					assign ip_shared_ivc_allocated_in[2*num_vcs:3*num_vcs-1] =
						rtr_ip_shared_ivc_allocated[(x_dim*num_routers_per_dim+y_dim-1)*num_ports*num_vcs+:num_vcs];
				end

				if (y_dim==num_routers_per_dim-1)
				begin
					assign shared_vc_in[3] = 1'b0;
					assign credit_for_shared_in[3] =1'b0;
					assign memory_bank_grant_in[3*num_ports:4*num_ports-1] = {num_ports{1'b0}};
					assign channel_in_ip[3*channel_width:4*channel_width-1] = {channel_width{1'b0}};
					assign flow_ctrl_in_op[3*flow_ctrl_width:4*flow_ctrl_width-1] = {flow_ctrl_width{1'b0}};
					assign ready_for_allocation_in[3] = 1'b1;
					assign ip_shared_ivc_allocated_in[3*num_vcs:4*num_vcs-1] = {num_vcs{1'b0}};
				end
				else
				begin
					assign shared_vc_in[3] = rtr_shared_vc_out[(x_dim*num_routers_per_dim+y_dim+1)*num_ports+2+:1];
					assign credit_for_shared_in[3] = 
						rtr_credit_for_shared_out[(x_dim*num_routers_per_dim+y_dim+1)*num_ports+2+:1];
					assign memory_bank_grant_in[3*num_ports:4*num_ports-1] =
						rtr_memory_bank_grant_out[(x_dim*num_routers_per_dim+y_dim+1)*num_ports*num_ports
							+2*num_ports+:num_ports];
					assign channel_in_ip[3*channel_width:4*channel_width-1] =
						rtr_channel_out_op[(x_dim*num_routers_per_dim+y_dim+1)*num_ports*channel_width
							+2*channel_width+:channel_width];
					assign flow_ctrl_in_op[3*flow_ctrl_width:4*flow_ctrl_width-1] = 
						rtr_flow_ctrl_out_ip[(x_dim*num_routers_per_dim+y_dim+1)*num_ports*flow_ctrl_width
							+2*flow_ctrl_width+:flow_ctrl_width];
					assign ready_for_allocation_in[3] = 
						rtr_ready_for_allocation[(x_dim*num_routers_per_dim+y_dim+1)*num_ports];
					assign ip_shared_ivc_allocated_in[3*num_vcs:4*num_vcs-1] =
						rtr_ip_shared_ivc_allocated[(x_dim*num_routers_per_dim+y_dim+1)*num_ports*num_vcs+:num_vcs];
				end

				assign ready_for_allocation_in[4] = 1'b1;
				assign shared_vc_in[4] = shared_vc_from_ps_dly;
				assign credit_for_shared_in[4] = shared_credit_from_fs_dly;
				assign ip_shared_ivc_allocated_in[4*num_vcs:5*num_vcs-1] = {num_vcs{1'b0}};
				assign channel_in_ip[4*channel_width:5*channel_width-1] = channel_from_ps_dly;
				assign memory_bank_grant_in[4*num_ports:5*num_ports-1] = memory_bank_grant_from_fs;
				assign flow_ctrl_in_op[4*flow_ctrl_width:5*flow_ctrl_width-1] = flow_ctrl_from_fs_dly;


				wire 									router_error;
				wire [0:num_ports-1]					shared_vc_out;
				wire [0:num_ports*channel_width-1] 		channel_out_op;
				wire [0:num_ports*flow_ctrl_width-1] 	flow_ctrl_out_ip;
				wire [0:num_ports-1]					credit_for_shared_out;
				wire [0:num_ports*num_ports-1] 			memory_bank_grant_out;
				wire [0:num_ports-1]					ready_for_allocation_out;
				wire [0:num_ports*num_vcs-1]			ip_shared_ivc_allocated_out;

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
       			  .explicit_pipeline_register(explicit_pipeline_register),
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
				 (.clk(clk),
      			  .reset(reset),
      			  .router_address(router_address),
      			  .shared_vc_in(shared_vc_in),
      			  .shared_vc_out(shared_vc_out),
      			  .credit_for_shared_in(credit_for_shared_in), 
      			  .credit_for_shared_out(credit_for_shared_out),
      			  .memory_bank_grant_in(memory_bank_grant_in),
      			  .memory_bank_grant_out(memory_bank_grant_out),
      			  .channel_in_ip(channel_in_ip),
      			  .flow_ctrl_out_ip(flow_ctrl_out_ip),
      			  .channel_out_op(channel_out_op),
      			  .flow_ctrl_in_op(flow_ctrl_in_op),
				  .ready_for_allocation_in(ready_for_allocation_in),
				  .ready_for_allocation_out(ready_for_allocation_out),
				  .ip_shared_ivc_allocated_in(ip_shared_ivc_allocated_in),
				  .ip_shared_ivc_allocated_out(ip_shared_ivc_allocated_out),
      			  .error(router_error));

				assign rtr_ready_for_allocation[(x_dim*num_routers_per_dim+y_dim)*num_ports+:num_ports]
						= ready_for_allocation_out;

				assign rtr_ip_shared_ivc_allocated[(x_dim*num_routers_per_dim+y_dim)*num_ports*num_vcs+:num_ports*num_vcs]
						= ip_shared_ivc_allocated_out;

				assign rtr_channel_out_op[(x_dim*num_routers_per_dim+y_dim)*num_ports*channel_width+:num_ports*channel_width]
						= channel_out_op;

				assign rtr_flow_ctrl_out_ip[(x_dim*num_routers_per_dim+y_dim)*num_ports*flow_ctrl_width
						+:num_ports*flow_ctrl_width] = flow_ctrl_out_ip;

				assign rtr_memory_bank_grant_out[(x_dim*num_routers_per_dim+y_dim)*num_ports*num_ports+:num_ports*num_ports]
						= memory_bank_grant_out;

				assign rtr_credit_for_shared_out[(x_dim*num_routers_per_dim+y_dim)*num_ports+:num_ports] = credit_for_shared_out;
				
				assign rtr_shared_vc_out[(x_dim*num_routers_per_dim+y_dim)*num_ports+:num_ports] = shared_vc_out;

				assign rtr_error[x_dim*num_routers_per_dim+y_dim] = router_error;

	   
	   			wire shared_vc_to_fs;
				assign shared_vc_to_fs = rtr_shared_vc_out[(x_dim*num_routers_per_dim+y_dim)*num_ports+4+:1];

				wire shared_vc_to_fs_dly;
	   			c_shift_reg
	     		#(.width(1),
	       		  .depth(num_channel_stages),
	       		  .reset_type(reset_type))
	   			vc_shared_from_fs_dly_sr
	     		 (.clk(clk),
	      		  .reset(reset),
	      		  .active(1'b1),
	      		  .data_in(shared_vc_to_fs),
	      		  .data_out(shared_vc_to_fs_dly));


	   			wire [0:channel_width-1] channel_to_fs;
				assign channel_to_fs = rtr_channel_out_op[(x_dim*num_routers_per_dim+y_dim)*num_ports*channel_width
							+4*channel_width+:channel_width];
	   
	   			wire [0:flit_ctrl_width-1] flit_ctrl_to_fs;
	   			assign flit_ctrl_to_fs = channel_to_fs[link_ctrl_width:link_ctrl_width+flit_ctrl_width-1];
	   
	   			assign flit_valid_out_op[x_dim*num_routers_per_dim+y_dim] = flit_ctrl_to_fs[0];
				
	   			wire [0:channel_width-1] channel_to_fs_dly;
	   			c_shift_reg
	     		#(.width(channel_width),
	       		  .depth(num_channel_stages),
	       		  .reset_type(reset_type))
	   			channel_to_fs_dly_sr
	     		 (.clk(clk),
	      		  .reset(reset),
	      		  .active(1'b1),
	      		  .data_in(channel_to_fs),
	      		  .data_out(channel_to_fs_dly));

	   			wire shared_credit_from_fs;
	   			c_shift_reg
	     		#(.width(1),
	       		  .depth(num_channel_stages),
	       		  .reset_type(reset_type))
	   			shared_credit_dly_sr
	     		 (.clk(clk),
	      		  .reset(reset),
	      		  .active(1'b1),
	      		  .data_in(shared_credit_from_fs),
	      		  .data_out(shared_credit_from_fs_dly));
	   
				wire						fs_error;
	   			wire [0:flow_ctrl_width-1]  flow_ctrl_from_fs;

	   			flit_sink
	     		#(.initial_seed(initial_seed + 2*num_routers + x_dim*num_routers_per_dim + y_dim),
	       		  .consume_rate(consume_rate),
				  .buffer_size(buffer_size),
	       		  .num_ports(num_ports),
	       		  .num_vcs(num_vcs),
	       		  .num_routers(num_routers),
				  .num_dimensions(num_dimensions),
				  .packet_count_reg_width(packet_count_reg_width),
				  .packet_format(packet_format),
	       		  .flow_ctrl_type(flow_ctrl_type),
	       		  .max_payload_length(max_payload_length),
	       		  .min_payload_length(min_payload_length),
	       		  .route_info_width(route_info_width),
	       		  .enable_link_pm(enable_link_pm),
	       		  .flit_data_width(flit_data_width),
	       		  .fb_regfile_type(fb_regfile_type),
	       		  .fb_mgmt_type(fb_mgmt_type),
	       		  .atomic_vc_allocation(atomic_vc_allocation),
	       		  .reset_type(reset_type))
	   			fs
	     		 (.clk(clk),
	      		  .reset(reset),
	       		  .router_address(router_address),
	      		  .channel(channel_to_fs_dly),
	      		  .shared_vc(shared_vc_to_fs_dly),
	      		  .memory_bank_grant(memory_bank_grant_from_fs),
	      		  .credit_for_shared(shared_credit_from_fs),
	      		  .flow_ctrl(flow_ctrl_from_fs),
	      		  .error(fs_error));

	   			c_shift_reg
	     		#(.width(flow_ctrl_width),
	       		  .depth(num_channel_stages),
	       		  .reset_type(reset_type))
	   			flow_ctrl_from_fs_sr
	     		 (.clk(clk),
	      		  .reset(reset),
	      		  .active(1'b1),
	      		  .data_in(flow_ctrl_from_fs),
	      		  .data_out(flow_ctrl_from_fs_dly));
	   
	   			assign cred_valid_in_op[x_dim*num_routers_per_dim+y_dim] = flow_ctrl_from_fs_dly[0];

	   			assign fs_error_op[x_dim*num_routers_per_dim+y_dim] = fs_error;
			end
		end
	endgenerate

	   
   wire [0:2] tb_errors;
   assign tb_errors = {|ps_error_ip, |fs_error_op, 1'b0};
   
   wire       tb_error;
   assign tb_error = |tb_errors;
   
   wire [0:31] in_flits_s, in_flits_q;
   assign in_flits_s = in_flits_q + pop_count(flit_valid_in_ip);
   c_dff
     #(.width(32),
       .reset_type(reset_type))
   in_flitsq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(in_flits_s),
      .q(in_flits_q));
   
   wire [0:31] in_flits;
   assign in_flits = in_flits_s;
   
   wire [0:31] in_creds_s, in_creds_q;
   assign in_creds_s = in_creds_q + pop_count(cred_valid_out_ip);
   c_dff
     #(.width(32),
       .reset_type(reset_type))
   in_credsq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(in_creds_s),
      .q(in_creds_q));
   
   wire [0:31] in_creds;
   assign in_creds = in_creds_q;
   
   wire [0:31] out_flits_s, out_flits_q;
   assign out_flits_s = out_flits_q + pop_count(flit_valid_out_op);
   c_dff
     #(.width(32),
       .reset_type(reset_type))
   out_flitsq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(out_flits_s),
      .q(out_flits_q));
   
   wire [0:31] out_flits;
   assign out_flits = out_flits_s;
   
   wire [0:31] out_creds_s, out_creds_q;
   assign out_creds_s = out_creds_q + pop_count(cred_valid_in_op);
   c_dff
     #(.width(32),
       .reset_type(reset_type))
   out_credsq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(out_creds_s),
      .q(out_creds_q));
   
   wire [0:31] out_creds;
   assign out_creds = out_creds_q;
   
   reg 	       count_en;
   
   wire [0:31] count_in_flits_s, count_in_flits_q;
   assign count_in_flits_s
     = count_en ?
       count_in_flits_q + pop_count(flit_valid_in_ip) :
       count_in_flits_q;
   c_dff
     #(.width(32),
       .reset_type(reset_type))
   count_in_flitsq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(count_in_flits_s),
      .q(count_in_flits_q));
   
   wire [0:31] count_in_flits;
   assign count_in_flits = count_in_flits_s;
   
   wire [0:31] count_out_flits_s, count_out_flits_q;
   assign count_out_flits_s
     = count_en ?
       count_out_flits_q + pop_count(flit_valid_out_op) :
       count_out_flits_q;
   c_dff
     #(.width(32),
       .reset_type(reset_type))
   count_out_flitsq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(count_out_flits_s),
      .q(count_out_flits_q));
   
   wire [0:31] count_out_flits;
   assign count_out_flits = count_out_flits_s;
   
   reg 	       clk_en;
   
   always
   begin
      clk <= clk_en;
      #(Tclk/2);
      clk <= 1'b0;
      #(Tclk/2);
   end
   
   always @(posedge clk)
    begin
	if(|rtr_error)
	  begin
	     $display("internal error detected, cyc=%d", $time);
	     $stop;
	  end
	if(tb_error)
	  begin
	     $display("external error detected, cyc=%d", $time);
	     $stop;
	  end
     end
   
   integer cycles;
   integer d;
   
   initial
   begin  
      reset = 1'b0;
      clk_en = 1'b0;
      run = 1'b0;
      count_en = 1'b0;
      cycles = 0;
      
      #(Tclk);
      
      #(Tclk/2);
      
      reset = 1'b1;
      
      #(Tclk);
      
      reset = 1'b0;
      
      #(Tclk);
      
      clk_en = 1'b1;
      
      #(Tclk/2);
      
      $display("warming up...");
      
      run = 1'b1;

      while(cycles < warmup_time)
	  begin
	   cycles = cycles + 1;
	   #(Tclk);
	  end
      
      $display("measuring...");
      
      count_en = 1'b1;
      
      while(cycles < warmup_time + measure_time)
	  begin
	   cycles = cycles + 1;
	   #(Tclk);
	  end
      
      count_en = 1'b0;
      
      $display("measured %d cycles", measure_time);
      
      $display("%d flits in, %d flits out", count_in_flits, count_out_flits);
      
      $display("cooling down...");
    
      run = 1'b0;
      
      while((in_flits > out_flits) || (in_flits > in_creds))
	  begin
	   cycles = cycles + 1;
	   #(Tclk);
	  end
	 
      #(Tclk*10);
      
      $display("simulation ended after %d cycles", cycles);
      
      $display("%d flits received, %d flits sent", in_flits, out_flits);

      $finish;
   end

/*
   initial
   begin
   	$dumpfile("router.db");
	$dumpvars(0,testbench);
   end
*/

endmodule

