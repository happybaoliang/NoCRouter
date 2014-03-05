// $Id: tc_node_mac.v 5188 2012-08-30 00:31:31Z dub $

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
// network pseudo-node (combined packet source / sink)
//==============================================================================

module tc_node_mac
  (clk, reset, address, channel_out, flow_ctrl_in, channel_in, flow_ctrl_out, 
   cfg_node_addrs, cfg_req, cfg_write, cfg_addr, cfg_write_data, cfg_read_data, 
   cfg_done, error);
   
`include "c_functions.v"
`include "c_constants.v"
   
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
   
   // width required to select individual packet class
   localparam pc_idx_width = clogb(num_packet_classes);
   
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
   
   // width of global addresses
   localparam addr_width = router_addr_width + node_addr_width;
   
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
   localparam num_ports
     = num_dimensions * num_neighbors_per_dim + num_nodes_per_router;
   
   // width required to select an individual port
   localparam port_idx_width = clogb(num_ports);
   
   // select packet format
   parameter packet_format = `PACKET_FORMAT_EXPLICIT_LENGTH;
   
   // select type of flow control
   parameter flow_ctrl_type = `FLOW_CTRL_TYPE_CREDIT;
   
   // make incoming flow control signals bypass the output VC state tracking 
   // logic
   parameter flow_ctrl_bypass = 1;
   
   // width of flow control signals
   localparam flow_ctrl_width
     = (flow_ctrl_type == `FLOW_CTRL_TYPE_CREDIT) ? (1 + vc_idx_width) :
       -1;
   
   // maximum payload length (in flits)
   // (note: only used if packet_format==`PACKET_FORMAT_EXPLICIT_LENGTH)
   parameter max_payload_length = 4;
   
   // minimum payload length (in flits)
   // (note: only used if packet_format==`PACKET_FORMAT_EXPLICIT_LENGTH)
   parameter min_payload_length = 1;
   
   // number of bits required to represent all possible payload sizes
   localparam payload_length_width
     = clogb(max_payload_length-min_payload_length+1);
   
   // maximum packet length (in flits)
   localparam max_packet_length = 1 + max_payload_length;
   
   // total number of bits required to represent maximum packet length
   localparam packet_length_width = clogb(max_packet_length);
   
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
   localparam channel_width
     = link_ctrl_width + flit_ctrl_width + flit_data_width;
   
   // include error checking logic
   parameter error_capture_mode = `ERROR_CAPTURE_MODE_NO_HOLD;
   
   // width required for lookahead routing information
   localparam lar_info_width = port_idx_width + resource_class_idx_width;
   
   // select routing function type
   parameter routing_type = `ROUTING_TYPE_PHASED_DOR;
   
   // total number of bits required for storing routing information
   localparam dest_info_width
     = (routing_type == `ROUTING_TYPE_PHASED_DOR) ? 
       (num_resource_classes * router_addr_width + node_addr_width) : 
       -1;
   
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
   
   // select order of dimension traversal
   parameter dim_order = `DIM_ORDER_ASCENDING;
   
   // select flit buffer management scheme
   parameter fb_mgmt_type = `FB_MGMT_TYPE_STATIC;
   
   // EXPERIMENTAL:
   // for dynamic buffer management, only reserve a buffer slot for a VC while 
   // it is active (i.e., while a packet is partially transmitted)
   // (NOTE: This is currently broken!)
   parameter disable_static_reservations = 0;
   
   // select whether to exclude full or non-empty VCs from VC allocation
   parameter elig_mask = `ELIG_MASK_NONE;
   
   // generate almost_empty signal early on in clock cycle
   localparam fast_almost_empty
     = flow_ctrl_bypass && (elig_mask == `ELIG_MASK_USED);
   
   // select set of feedback polynomials used for LFSRs
   parameter lfsr_index = 0;
   
   // number of bits in address that are considered base address
   parameter cfg_node_addr_width = 10;
   
   // width of register selector part of control register address
   parameter cfg_reg_addr_width = 6;
   
   // width of configuration bus addresses
   localparam cfg_addr_width = cfg_node_addr_width + cfg_reg_addr_width;
   
   // number of distinct base addresses to which this node replies
   parameter num_cfg_node_addrs = 2;
   
   // width of control register data
   parameter cfg_data_width = 32;
   
   // smallest multiple of cfg_data_width that is >= flit_data_width
   localparam flit_sig_exp_width
     = ((flit_data_width+cfg_data_width-1)/cfg_data_width)*cfg_data_width;
   
   // width of run cycle counter
   parameter num_packets_width = 20;
   
   // width of arrival rate LFSR
   parameter arrival_rv_width = 20;
   
   // width of message class selection LFSR
   parameter mc_idx_rv_width = 1;
   
   // width of message class threshold register
   localparam mc_threshs_width = (num_message_classes - 1) * mc_idx_rv_width;
   
   // width of resource class selection LFSR
   parameter rc_idx_rv_width = 1;
   
   // width of resource class threshold register
   localparam rc_threshs_width = (num_resource_classes - 1) * rc_idx_rv_width;
   
   // width of payload length selection LFSR
   parameter plength_idx_rv_width = 1;
   
   // number of selectable payload lengths
   parameter num_plength_vals = 2;
   
   // width of packet length threshold register
   localparam plength_threshs_width
     = (num_plength_vals - 1) * plength_idx_rv_width;
   
   // width of packet length value register
   localparam plength_vals_width = num_plength_vals * payload_length_width;
   
   // select width (and thus period) for LFSRs
   localparam packet_rvs_width
     = mc_idx_rv_width + rc_idx_rv_width + dest_info_width + 
       plength_idx_rv_width;
   
   // width of register that holds the number of outstanding packets
   parameter packet_count_width = 8;
   
   parameter reset_type = `RESET_TYPE_ASYNC;
   
   input clk;
   input reset;
   
   // current node's address
   input [0:addr_width-1] address;
   
   // outgoing channel
   output [0:channel_width-1] channel_out;
   wire [0:channel_width-1]   channel_out;
   
   // incoming flow control signals
   input [0:flow_ctrl_width-1] flow_ctrl_in;
   
   // incoming channel
   input [0:channel_width-1]   channel_in;
   
   // outgoing flow control signals
   output [0:flow_ctrl_width-1] flow_ctrl_out;
   wire [0:flow_ctrl_width-1] 	flow_ctrl_out;
   
   // node addresses assigned to this node
   input [0:num_cfg_node_addrs*cfg_node_addr_width-1] cfg_node_addrs;
   
   // config register access pending
   input 					      cfg_req;
   
   // config register access is write access
   input 					      cfg_write;
   
   // select config register to access
   input [0:cfg_addr_width-1] 			      cfg_addr;
   
   // data to be written to selected config register for write accesses
   input [0:cfg_data_width-1] 			      cfg_write_data;
   
   // contents of selected config register for read accesses
   output [0:cfg_data_width-1] 			      cfg_read_data;
   wire [0:cfg_data_width-1] 			      cfg_read_data;
   
   // config register access complete
   output 					      cfg_done;
   wire 					      cfg_done;
   
   // internal error condition detected
   output 					      error;
   wire 					      error;
   
   
   //---------------------------------------------------------------------------
   // configuration register interface
   //---------------------------------------------------------------------------
   
   wire 					      ifc_active;
   wire 					      ifc_req;
   wire 					      ifc_write;
   wire [0:num_cfg_node_addrs-1] 		      ifc_node_addr_match;
   wire [0:cfg_reg_addr_width-1] 		      ifc_reg_addr;
   wire [0:cfg_data_width-1] 			      ifc_write_data;
   wire [0:cfg_data_width-1] 			      ifc_read_data;
   wire 					      ifc_done;
   
   tc_cfg_bus_ifc
     #(.cfg_node_addr_width(cfg_node_addr_width),
       .cfg_reg_addr_width(cfg_reg_addr_width),
       .num_cfg_node_addrs(num_cfg_node_addrs),
       .cfg_data_width(cfg_data_width),
       .reset_type(reset_type))
   ifc
     (.clk(clk),
      .reset(reset),
      .cfg_node_addrs(cfg_node_addrs),
      .cfg_req(cfg_req),
      .cfg_write(cfg_write),
      .cfg_addr(cfg_addr),
      .cfg_write_data(cfg_write_data),
      .cfg_read_data(cfg_read_data),
      .cfg_done(cfg_done),
      .active(ifc_active),
      .req(ifc_req),
      .write(ifc_write),
      .node_addr_match(ifc_node_addr_match),
      .reg_addr(ifc_reg_addr),
      .write_data(ifc_write_data),
      .read_data(ifc_read_data),
      .done(ifc_done));
   
   wire 					      ifc_sel_node;
   assign ifc_sel_node = |ifc_node_addr_match;
   
   wire 					      do_write;
   assign do_write = ifc_req & ifc_write;
   
   // all registers in the pseudo-node are read immediately
   assign ifc_done = ifc_req & ifc_sel_node;
   
   wire 					      ifc_sel_ctrl;
   assign ifc_sel_ctrl
     =  ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_CTRL);
   
   wire 					      ifc_sel_status;
   assign ifc_sel_status
     = ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_STATUS);
   
   wire 					      ifc_sel_flit_sig;
   assign ifc_sel_flit_sig
     = ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_FLIT_SIG);
   
   wire 					      ifc_sel_lfsr_seed;
   assign ifc_sel_lfsr_seed
     = ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_LFSR_SEED);
   
   wire 					      ifc_sel_num_packets;
   assign ifc_sel_num_packets
     = ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_NUM_PACKETS);
   
   wire 					      ifc_sel_arrival_thresh;
   assign ifc_sel_arrival_thresh
     = ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_ARRIVAL_THRESH);
   
   wire 					      ifc_sel_plength_threshs;
   assign ifc_sel_plength_threshs
     = ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_PLENGTH_THRESHS);
   
   wire 					      ifc_sel_plength_vals;
   assign ifc_sel_plength_vals
     = ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_PLENGTH_VALS);
   
   wire 					      ifc_sel_mc_threshs;
   assign ifc_sel_mc_threshs
     = ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_MC_THRESHS);
   
   wire 					      ifc_sel_rc_threshs;
   assign ifc_sel_rc_threshs
     = ifc_sel_node && (ifc_reg_addr == `CFG_ADDR_NODE_RC_THRESHS);
   
   wire [0:cfg_data_width-1] 			      ifc_read_data_status;
   wire [0:cfg_data_width-1] 			      ifc_read_data_flit_sig;
   wire [0:cfg_data_width-1] 			      ifc_read_data_num_packets;
   
   c_select_1ofn
     #(.num_ports(3),
       .width(cfg_data_width))
   ifc_read_data_sel
     (.select({ifc_sel_status, 
	       ifc_sel_flit_sig, 
	       ifc_sel_num_packets}),
      .data_in({ifc_read_data_status, 
		ifc_read_data_flit_sig, 
		ifc_read_data_num_packets}),
      .data_out(ifc_read_data));
   
   
   //---------------------------------------------------------------------------
   // run control register
   // ====================
   // Setting bit 0 of this register to 1'b1 wakes up the terminal and starts 
   // the experiment; setting it to 1'b0 stops it and puts the terminal into 
   // idle mode.
   // If bit 1 of this register is set, the traffic generator is operated in
   // loopback mode; i.e., its outputs are fed back into its inputs.
   // If bit 2 of this register is set, packets from node ports whose 
   // destination address corresponds to that same port are discarded.
   //---------------------------------------------------------------------------
   
   wire 					      write_ctrl;
   assign write_ctrl = do_write & ifc_sel_ctrl;
   
   wire 					      active_s, active_q;
   assign active_s = write_ctrl ? ifc_write_data[0] : active_q;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   activeq
     (.clk(clk),
      .reset(reset),
      .active(ifc_active),
      .d(active_s),
      .q(active_q));
   
   wire 					      reg_active;
   assign reg_active = ifc_active | active_q;
   
   wire 					      loopback_s, loopback_q;
   assign loopback_s = write_ctrl ? ifc_write_data[1] : loopback_q;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   loopbackq
     (.clk(clk),
      .reset(reset),
      .active(ifc_active),
      .d(loopback_s),
      .q(loopback_q));
   
   wire 					      suppress_s, suppress_q;
   assign suppress_s = write_ctrl ? ifc_write_data[2] : suppress_q;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   suppressq
     (.clk(clk),
      .reset(reset),
      .active(ifc_active),
      .d(suppress_s),
      .q(suppress_q));
   
   wire [0:channel_width-1] 			      channel_muxed;
   assign channel_muxed = loopback_q ? channel_out : channel_in;
   
   wire [0:flow_ctrl_width-1] 			      flow_ctrl_muxed;
   assign flow_ctrl_muxed = loopback_q ? flow_ctrl_out : flow_ctrl_in;
   
   wire 					      start_s, start_q;
   assign start_s = write_ctrl & ifc_write_data[0];
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   startq
     (.clk(clk),
      .reset(reset),
      .active(ifc_active),
      .d(start_s),
      .q(start_q));
   
   
   //---------------------------------------------------------------------------
   // status register
   // ===============
   // Bit 0 of this register is non-zero for as long as there are packets 
   // and/or flits left to send.
   // Bit 1 of this register is the summary error bit, i.e., the output of the 
   // error reporting logic.
   //---------------------------------------------------------------------------
   
   wire 					      packet_count_zero;
   wire 					      gen_packets;
   wire 					      packet_valid_q;
   wire [0:num_vcs-1] 				      empty_ovc;
   
   wire 					      last_credit_received;
   assign last_credit_received
     = (~gen_packets & packet_count_zero & ~packet_valid_q & (&empty_ovc));
   
   wire 					      running_s, running_q;
   assign running_s = (running_q & ~last_credit_received) | start_q;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   runningq
     (.clk(clk),
      .reset(1'b0),
      .active(active_q),
      .d(running_s),
      .q(running_q));
   
   c_align
     #(.in_width(2),
       .out_width(cfg_data_width))
   ifc_read_data_status_alg
     (.data_in({running_q, error}),
      .dest_in({cfg_data_width{1'b0}}),
      .data_out(ifc_read_data_status));
   
   
   //---------------------------------------------------------------------------
   // packet count register
   // =====================
   // specify how many packets to generate during the experiment
   // (special value of -1 corresponds to an infinite number of packets)
   //---------------------------------------------------------------------------
   
   wire [0:num_packets_width-1] 		      num_packets_loadval;
   c_align
     #(.in_width(cfg_data_width),
       .out_width(num_packets_width))
   num_packets_loadval_alg
     (.data_in(ifc_write_data),
      .dest_in({num_packets_width{1'b0}}),
      .data_out(num_packets_loadval));
   
   wire 					      num_packets_zero;
   wire 					      num_packets_inf;
   wire [0:num_packets_width-1] 		      num_packets_q;
   wire 					      new_packet_rv;
   
   wire [0:num_packets_width-1] 		      num_packets_next;
   assign num_packets_next = (~active_q | num_packets_inf | num_packets_zero) ? 
			     num_packets_q : 
			     (num_packets_q - new_packet_rv);
   
   wire 					      write_num_packets;
   assign write_num_packets = do_write & ifc_sel_num_packets;
   
   wire [0:num_packets_width-1] 		      num_packets_s;
   assign num_packets_s
     = write_num_packets ? num_packets_loadval : num_packets_next;
   c_dff
     #(.width(num_packets_width),
       .reset_type(reset_type))
   num_packetsq
     (.clk(clk),
      .reset(1'b0),
      .active(reg_active),
      .d(num_packets_s),
      .q(num_packets_q));
   
   assign num_packets_zero = ~|num_packets_q;
   assign num_packets_inf = &num_packets_q;
   
   assign gen_packets = ~num_packets_zero;
   
   c_align
     #(.in_width(num_packets_width),
       .out_width(cfg_data_width))
   ifc_read_data_num_packets_alg
     (.data_in(num_packets_q),
      .dest_in({cfg_data_width{1'b0}}),
      .data_out(ifc_read_data_num_packets));
   
   
   //---------------------------------------------------------------------------
   // generate packet arrival times
   //---------------------------------------------------------------------------
   
   wire [0:arrival_rv_width-1] 			      arrival_rv_feedback;
   c_fbgen
     #(.width(arrival_rv_width),
       .index(4*lfsr_index+0))
   arrival_rv_feedback_fbgen
     (.feedback(arrival_rv_feedback));
   
   wire [0:arrival_rv_width-1] 			      arrival_rv_loadval;
   c_align
     #(.in_width(cfg_data_width),
       .out_width(arrival_rv_width))
   arrival_rv_loadval_alg
     (.data_in(ifc_write_data),
      .dest_in({arrival_rv_width{1'b0}}),
      .data_out(arrival_rv_loadval));
   
   wire 					      write_lfsr_seed;
   assign write_lfsr_seed = do_write & ifc_sel_lfsr_seed;
   
   wire 					      update_arrival_rv;
   assign update_arrival_rv = active_q & gen_packets;
   
   wire [0:arrival_rv_width-1] 			      arrival_rv_s, 
						      arrival_rv_q;
   assign arrival_rv_s
     = {arrival_rv_width{write_lfsr_seed}} & arrival_rv_loadval;
   c_lfsr
     #(.width(arrival_rv_width),
       .iterations(arrival_rv_width),
       .reset_type(reset_type))
   arrival_rv_lfsr
     (.clk(clk),
      .reset(1'b0),
      .active(reg_active),
      .load(write_lfsr_seed),
      .run(update_arrival_rv),
      .feedback(arrival_rv_feedback),
      .complete(1'b1),
      .d(arrival_rv_s),
      .q(arrival_rv_q));
   
   wire [0:arrival_rv_width-1] 			      arrival_thresh_loadval;
   c_align
     #(.in_width(cfg_data_width),
       .out_width(arrival_rv_width))
   arrival_thresh_loadval_alg
     (.data_in(ifc_write_data),
      .dest_in({arrival_rv_width{1'b0}}),
      .data_out(arrival_thresh_loadval));
   
   wire 					      write_arrival_thresh;
   assign write_arrival_thresh = do_write & ifc_sel_arrival_thresh;
   
   wire [0:arrival_rv_width-1] 			      arrival_thresh_s, 
						      arrival_thresh_q;
   assign arrival_thresh_s
     = write_arrival_thresh ? arrival_thresh_loadval : arrival_thresh_q;
   c_dff
     #(.width(arrival_rv_width),
       .reset_type(reset_type))
   arrival_threshq
     (.clk(clk),
      .reset(1'b0),
      .active(ifc_active),
      .d(arrival_thresh_s),
      .q(arrival_thresh_q));
   
   assign new_packet_rv = (arrival_rv_q <= arrival_thresh_q);
   
   
   //---------------------------------------------------------------------------
   // shared LFSR for per-packet random values
   //---------------------------------------------------------------------------
   
   wire [0:packet_rvs_width-1] 			      packet_rvs_feedback;
   c_fbgen
     #(.width(packet_rvs_width),
       .index(4*lfsr_index+1))
   packet_rvs_feedback_fbgen
     (.feedback(packet_rvs_feedback));
   
   wire [0:packet_rvs_width-1] 			      packet_rvs_loadval;
   c_align
     #(.in_width(cfg_data_width),
       .out_width(packet_rvs_width))
   packet_rvs_loadval_alg
     (.data_in(ifc_write_data),
      .dest_in({packet_rvs_width{1'b0}}),
      .data_out(packet_rvs_loadval));
   
   wire 					      packet_sent;
   
   wire 					      update_packet_rvs;
   assign update_packet_rvs = active_q & packet_sent;
   
   wire [0:packet_rvs_width-1] 			      packet_rvs_s, 
						      packet_rvs_q;
   assign packet_rvs_s
     = {packet_rvs_width{write_lfsr_seed}} & packet_rvs_loadval;
   c_lfsr
     #(.width(packet_rvs_width),
       .iterations(packet_rvs_width),
       .reset_type(reset_type))
   packet_rvs_lfsr
     (.clk(clk),
      .reset(1'b0),
      .active(reg_active),
      .load(write_lfsr_seed),
      .run(update_packet_rvs),
      .feedback(packet_rvs_feedback),
      .complete(1'b1),
      .d(packet_rvs_s),
      .q(packet_rvs_q));
   
   
   //---------------------------------------------------------------------------
   // determine random message and resource class
   //---------------------------------------------------------------------------
   
   wire [0:num_message_classes-1] 		      sel_mc_rv;
   wire [0:num_resource_classes-1] 		      sel_orc_rv;
   
   wire [0:num_packet_classes-1] 		      sel_opc_rv;
   c_mat_mult
     #(.dim1_width(num_message_classes),
       .dim2_width(1),
       .dim3_width(num_resource_classes),
       .prod_op(`BINARY_OP_AND),
       .sum_op(`BINARY_OP_OR))
   sel_opc_rv_mmult
     (.input_a(sel_mc_rv),
      .input_b(sel_orc_rv),
      .result(sel_opc_rv));
   
   wire 					      vc_alloc_q;
   wire [0:num_vcs_per_class-1] 		      vc_alloc_ocvc_q;
   wire [0:num_vcs_per_class-1] 		      next_elig_ocvc;
   
   wire [0:num_vcs_per_class-1] 		      sel_ocvc;
   assign sel_ocvc = vc_alloc_q ? vc_alloc_ocvc_q : next_elig_ocvc;
   
   wire [0:num_vcs-1] 				      sel_ovc;
   c_mat_mult
     #(.dim1_width(num_packet_classes),
       .dim2_width(1),
       .dim3_width(num_vcs_per_class),
       .prod_op(`BINARY_OP_AND),
       .sum_op(`BINARY_OP_OR))
   sel_ovc_mmult
     (.input_a(sel_opc_rv),
      .input_b(sel_ocvc),
      .result(sel_ovc));
   
   wire 					      flit_sent;
   wire 					      flit_head_out;
   
   wire [0:num_vcs-1] 				      elig_ovc;
   wire [0:num_packet_classes-1] 		      elig_opc;
   wire [0:num_resource_classes-1] 		      elig_orc;
   wire 					      elig;
   
   wire [0:num_vcs-1] 				      next_elig_ovc;
   wire [0:num_resource_classes*num_vcs_per_class-1]  next_elig_orc_ocvc;
   
   wire [0:num_vcs-1] 				      full_ovc;
   wire [0:num_resource_classes*num_vcs_per_class-1]  full_orc_ocvc;
   wire [0:num_vcs_per_class-1] 		      full_ocvc;
   wire 					      full;
   
   generate
      
      if(num_message_classes > 1)
	begin
	   
	   // synopsys translate_off
	   if(mc_threshs_width > cfg_data_width)
	     begin
		initial
		begin
		   $display({"ERROR: The value of the cfg_data_width ", 
			     "parameter (%d) in module %m is too small to ",
			     "accomodate %d message class selection ",
			     "thresholds of width %d."}, 
			    cfg_data_width, num_message_classes - 1, 
			    mc_idx_rv_width);
		   $stop;
		end
	     end
	   // synopsys translate_on
	   
	   wire [0:mc_threshs_width-1] mc_threshs_loadval;
	   c_align
	     #(.in_width(cfg_data_width),
	       .out_width(mc_threshs_width))
	   mc_threshs_loadval_alg
	     (.data_in(ifc_write_data),
	      .dest_in({mc_threshs_width{1'b0}}),
	      .data_out(mc_threshs_loadval));
	   
	   wire 		       write_mc_threshs;
	   assign write_mc_threshs = do_write & ifc_sel_mc_threshs;
	   
	   wire [0:mc_threshs_width-1] mc_threshs_s, mc_threshs_q;
	   assign mc_threshs_s
	     = write_mc_threshs ? mc_threshs_loadval : mc_threshs_q;
	   c_dff
	     #(.width(mc_threshs_width),
	       .reset_type(reset_type))
	   mc_threshsq
	     (.clk(clk),
	      .reset(1'b0),
	      .active(ifc_active),
	      .d(mc_threshs_s),
	      .q(mc_threshs_q));
	   
	   wire [0:mc_idx_rv_width-1]  mc_idx_rv;
	   assign mc_idx_rv = packet_rvs_q[0:mc_idx_rv_width-1];
	   
	   wire [0:num_message_classes-1] sel_mc_rv_unmasked;
	   
	   genvar 			  mc;
	   
	   for(mc = 0; mc < (num_message_classes - 1); mc = mc + 1)
	     begin:mcs
		
		assign sel_mc_rv_unmasked[mc]
			 = (mc_idx_rv <
			    mc_threshs_q[mc*mc_idx_rv_width:
					 (mc+1)*mc_idx_rv_width-1]);
		
	     end
	   
	   assign sel_mc_rv_unmasked[num_message_classes-1] = 1'b1;
	   
	   c_lod
	     #(.width(num_message_classes))
	   sel_mc_rv_lod
	     (.data_in_pr(sel_mc_rv_unmasked),
	      .data_out_pr(sel_mc_rv),
	      .data_out(),
	      .mask_out());
	   
	   c_select_1ofn
	     #(.num_ports(num_message_classes),
	       .width(num_resource_classes))
	   elig_orc_sel
	     (.select(sel_mc_rv),
	      .data_in(elig_opc),
	      .data_out(elig_orc));
	   
	   c_select_1ofn
	     #(.num_ports(num_message_classes),
	       .width(num_resource_classes*num_vcs_per_class))
	   next_elig_orc_ocvc_sel
	     (.select(sel_mc_rv),
	      .data_in(next_elig_ovc),
	      .data_out(next_elig_orc_ocvc));
	   
	   c_select_1ofn
	     #(.num_ports(num_message_classes),
	       .width(num_resource_classes*num_vcs_per_class))
	   full_orc_ocvc_sel
	     (.select(sel_mc_rv),
	      .data_in(full_ovc),
	      .data_out(full_orc_ocvc));
	   
	end
      else
	begin
	   assign sel_mc_rv = 1'b1;
	   assign elig_orc = elig_opc;
	   assign next_elig_orc_ocvc = next_elig_ovc;
	   assign full_orc_ocvc = full_ovc;
	end
      
      if(num_resource_classes > 1)
	begin
	   
	   // synopsys translate_off
	   if(rc_threshs_width > cfg_data_width)
	     begin
		initial
		begin
		   $display({"ERROR: The value of the cfg_data_width ", 
			     "parameter (%d) in module %m is too small to ",
			     "accomodate %d resource class selection ",
			     "thresholds of width %d."}, 
			    cfg_data_width, num_resource_classes - 1, 
			    rc_idx_rv_width);
		   $stop;
		end
	     end
	   // synopsys translate_on
	   
	   wire [0:rc_threshs_width-1] rc_threshs_loadval;
	   c_align
	     #(.in_width(cfg_data_width),
	       .out_width(rc_threshs_width))
	   rc_threshs_loadval_alg
	     (.data_in(ifc_write_data),
	      .dest_in({rc_threshs_width{1'b0}}),
	      .data_out(rc_threshs_loadval));
	   
	   wire 		       write_rc_threshs;
	   assign write_rc_threshs = do_write & ifc_sel_rc_threshs;
	   
	   wire [0:rc_threshs_width-1] rc_threshs_s, rc_threshs_q;
	   assign rc_threshs_s
	     = write_rc_threshs ? rc_threshs_loadval : rc_threshs_q;
	   c_dff
	     #(.width(rc_threshs_width),
	       .reset_type(reset_type))
	   rc_threshsq
	     (.clk(clk),
	      .reset(1'b0),
	      .active(ifc_active),
	      .d(rc_threshs_s),
	      .q(rc_threshs_q));
	   
	   wire [0:rc_idx_rv_width-1]  rc_idx_rv;
	   assign rc_idx_rv
	     = packet_rvs_q[mc_idx_rv_width:
			    (mc_idx_rv_width+rc_idx_rv_width)-1];
	   
	   wire [0:num_resource_classes-1] sel_orc_rv_unmasked;
	   
	   genvar 			   rc;
	   
	   for(rc = 0; rc < (num_resource_classes - 1); rc = rc + 1)
	     begin:rcs
		
		assign sel_orc_rv_unmasked[rc]
			 = (rc_idx_rv <
			    rc_threshs_q[rc*rc_idx_rv_width:
					 (rc+1)*rc_idx_rv_width-1]);
		
	     end
	   
	   assign sel_orc_rv_unmasked[num_resource_classes-1] = 1'b1;
	   
	   c_lod
	     #(.width(num_resource_classes),
	       .num_priorities(1))
	   sel_orc_rv_lod
	     (.data_in_pr(sel_orc_rv_unmasked),
	      .data_out_pr(sel_orc_rv),
	      .data_out(),
	      .mask_out());
	   
	   c_select_1ofn
	     #(.num_ports(num_resource_classes),
	       .width(1))
	   elig_sel
	     (.select(sel_orc_rv),
	      .data_in(elig_orc),
	      .data_out(elig));
	   
	   c_select_1ofn
	     #(.num_ports(num_resource_classes),
	       .width(num_vcs_per_class))
	   next_elig_ocvc_sel
	     (.select(sel_orc_rv),
	      .data_in(next_elig_orc_ocvc),
	      .data_out(next_elig_ocvc));
	   
	   c_select_1ofn
	     #(.num_ports(num_resource_classes),
	       .width(num_vcs_per_class))
	   full_ocvc_sel
	     (.select(sel_orc_rv),
	      .data_in(full_orc_ocvc),
	      .data_out(full_ocvc));
	   
	end
      else
	begin
	   assign sel_orc_rv = 1'b1;
	   assign elig = elig_orc;
	   assign next_elig_ocvc = next_elig_orc_ocvc;
	   assign full_ocvc = full_orc_ocvc;
	end
      
      if(num_vcs_per_class > 1)
	begin
	   
	   c_select_1ofn
	     #(.width(1),
	       .num_ports(num_vcs_per_class))
	   full_sel
	     (.select(sel_ocvc),
	      .data_in(full_ocvc),
	      .data_out(full));
	   
	   genvar opc;
	   
	   for(opc = 0; opc < num_packet_classes; opc = opc + 1)
	     begin:opcs
		
		wire [0:num_vcs_per_class-1] elig_ocvc;
		assign elig_ocvc = elig_ovc[opc*num_vcs_per_class:
					    (opc+1)*num_vcs_per_class-1];
		
		wire [0:num_vcs_per_class-1] full_ocvc;
		assign full_ocvc = full_ovc[opc*num_vcs_per_class:
					    (opc+1)*num_vcs_per_class-1];
		
		wire [0:num_vcs_per_class-1] empty_ocvc;
		assign empty_ocvc = empty_ovc[opc*num_vcs_per_class:
					      (opc+1)*num_vcs_per_class-1];
		
		assign elig_opc[opc] = |elig_ocvc;
		
		wire [0:num_vcs_per_class-1] req_hi_ocvc;
		assign req_hi_ocvc = elig_ocvc & empty_ocvc;
		
		wire [0:num_vcs_per_class-1] req_lo_ocvc;
		assign req_lo_ocvc = elig_ocvc & ~full_ocvc;
		
		wire 			     update;
		assign update = flit_sent & flit_head_out;
		
		wire [0:num_vcs_per_class-1] gnt_hi_ocvc, gnt_lo_ocvc, gnt_ocvc;
		c_arbiter
		  #(.num_ports(num_vcs_per_class),
		    .num_priorities(2),
		    .arbiter_type(`ARBITER_TYPE_ROUND_ROBIN_BINARY),
		    .reset_type(reset_type))
		gnt_ocvc_arb
		  (.clk(clk),
		   .reset(reset),
		   .active(active_q),
		   .update(update),
		   .req_pr({req_hi_ocvc, req_lo_ocvc}),
		   .gnt_pr({gnt_hi_ocvc, gnt_lo_ocvc}),
		   .gnt(gnt_ocvc));
		
		wire [0:num_vcs_per_class-1] next_elig_ocvc;
		assign next_elig_ocvc = gnt_ocvc;
		
		assign next_elig_ovc[opc*num_vcs_per_class:
				     (opc+1)*num_vcs_per_class-1]
		  = next_elig_ocvc;
		
	     end
	   
	end
      else
	begin
	   assign elig_opc = elig_ovc;
	   assign next_elig_ovc = elig_ovc & ~full_ovc;
	   assign full = full_ocvc;
	end
      
   endgenerate
   
   
   //---------------------------------------------------------------------------
   // channel interface
   //---------------------------------------------------------------------------
   
   wire flit_valid_in;
   wire flit_head_in;
   wire [0:num_vcs-1] flit_head_in_ivc;
   wire 	      flit_tail_in;
   wire [0:num_vcs-1] flit_tail_in_ivc;
   wire [0:flit_data_width-1] flit_data_in;
   wire [0:num_vcs-1] 	      flit_sel_in_ivc;
   rtr_channel_input
     #(.num_vcs(num_vcs),
       .packet_format(packet_format),
       .max_payload_length(max_payload_length),
       .min_payload_length(min_payload_length),
       .route_info_width(route_info_width),
       .enable_link_pm(enable_link_pm),
       .flit_data_width(flit_data_width),
       .reset_type(reset_type))
   chi
     (.clk(clk),
      .reset(reset),
      .active(active_q),
      .channel_in(channel_muxed),
      .flit_valid_out(flit_valid_in),
      .flit_head_out(flit_head_in),
      .flit_head_out_ivc(flit_head_in_ivc),
      .flit_tail_out(flit_tail_in),
      .flit_tail_out_ivc(flit_tail_in_ivc),
      .flit_data_out(flit_data_in),
      .flit_sel_out_ivc(flit_sel_in_ivc));
   
   wire 		      cho_active;
   assign cho_active = packet_valid_q;
   
   wire 		      flit_valid_out;
   wire 		      flit_tail_out;
   wire [0:flit_data_width-1] flit_data_out;
   rtr_channel_output
     #(.num_vcs(num_vcs),
       .packet_format(packet_format),
       .enable_link_pm(enable_link_pm),
       .flit_data_width(flit_data_width),
       .reset_type(reset_type))
   cho
     (.clk(clk),
      .reset(reset),
      .active(cho_active),
      .flit_valid_in(flit_valid_out),
      .flit_head_in(flit_head_out),
      .flit_tail_in(flit_tail_out),
      .flit_data_in(flit_data_out),
      .flit_sel_in_ovc(sel_ovc),
      .channel_out(channel_out));
   
   
   //---------------------------------------------------------------------------
   // flow control interface
   //---------------------------------------------------------------------------
   
   wire 		      fc_event_valid_in;
   wire [0:num_vcs-1] 	      fc_event_sel_in_ovc;
   rtr_flow_ctrl_input
     #(.num_vcs(num_vcs),
       .flow_ctrl_type(flow_ctrl_type),
       .reset_type(reset_type))
   fci
     (.clk(clk),
      .reset(reset),
      .active(active_q),
      .flow_ctrl_in(flow_ctrl_muxed),
      .fc_event_valid_out(fc_event_valid_in),
      .fc_event_sel_out_ovc(fc_event_sel_in_ovc));
   
   
   //---------------------------------------------------------------------------
   // VC state tracking
   //---------------------------------------------------------------------------
   
   wire 		      flit_valid_s, flit_valid_q;
   assign flit_valid_s = flit_valid_out;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_validq
     (.clk(clk),
      .reset(reset),
      .active(active_q),
      .d(flit_valid_s),
      .q(flit_valid_q));
   
   wire 		      flit_head_s, flit_head_q;
   assign flit_head_s = flit_head_out;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_headq
     (.clk(clk),
      .reset(1'b0),
      .active(active_q),
      .d(flit_head_s),
      .q(flit_head_q));
   
   wire 		      flit_tail_s, flit_tail_q;
   assign flit_tail_s = flit_tail_out;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_tailq
     (.clk(clk),
      .reset(1'b0),
      .active(active_q),
      .d(flit_tail_s),
      .q(flit_tail_q));
   
   wire [0:num_vcs-1] 	      flit_sel_ovc_s, flit_sel_ovc_q;
   assign flit_sel_ovc_s = sel_ovc;
   c_dff
     #(.width(num_vcs),
       .reset_type(reset_type))
   flit_sel_ovcq
     (.clk(clk),
      .reset(1'b0),
      .active(active_q),
      .d(flit_sel_ovc_s),
      .q(flit_sel_ovc_q));
   
   wire 		      fc_active;
   wire [0:num_vcs-1] 	      almost_full_ovc;
   wire [0:num_vcs-1] 	      full_prev_ovc;
   wire [0:num_vcs*2-1]       fcs_errors_ovc;
   rtr_fc_state
     #(.num_vcs(num_vcs),
       .buffer_size(buffer_size),
       .flow_ctrl_type(flow_ctrl_type),
       .flow_ctrl_bypass(flow_ctrl_bypass),
       .mgmt_type(fb_mgmt_type),
       .fast_almost_empty(fast_almost_empty),
       .disable_static_reservations(disable_static_reservations),
       .reset_type(reset_type))
   fcs
     (.clk(clk),
      .reset(reset),
      .active(active_q),
      .flit_valid(flit_valid_q),
      .flit_head(flit_head_q),
      .flit_tail(flit_tail_q),
      .flit_sel_ovc(flit_sel_ovc_q),
      .fc_event_valid(fc_event_valid_in),
      .fc_event_sel_ovc(fc_event_sel_in_ovc),
      .fc_active(fc_active),
      .empty_ovc(empty_ovc),
      .almost_full_ovc(almost_full_ovc),
      .full_ovc(full_ovc),
      .full_prev_ovc(full_prev_ovc),
      .errors_ovc(fcs_errors_ovc));
   
   genvar 		      ovc;
   
   generate
      
      for(ovc = 0; ovc < num_vcs; ovc = ovc + 1)
	begin:ovcs
	   
	   //-------------------------------------------------------------------
	   // track whether this output VC is currently in use
	   //-------------------------------------------------------------------
	   
	   // NOTE: For the reset condition, we don't have to worry about 
	   // whether or not sufficient buffer space is available: If the VC is 
	   // currently allocated, these checks would already have been 
	   // performed at the beginning of switch allocation; on the other 
	   // hand, if it is not currently allocated, 'allocated_q' is zero, 
	   // and thus the reset condition does not have any effect.
	   
	   wire allocated;
	   
	   wire allocated_s, allocated_q;
	   assign allocated_s = allocated;
	   c_dff
	     #(.width(1),
	       .reset_type(reset_type))
	   allocatedq
	     (.clk(clk),
	      .reset(reset),
	      .active(active_q),
	      .d(allocated_s),
	      .q(allocated_q));
	   
	   wire flit_sent;
	   assign flit_sent = flit_valid_q & flit_sel_ovc_q[ovc];
	   
	   assign allocated = flit_sent ? ~flit_tail_q : allocated_q;
	   
	   wire empty;
	   assign empty = empty_ovc[ovc];
	   
	   wire full;
	   assign full = full_ovc[ovc];
	   
	   wire elig;
	   
	   case(elig_mask)
	     
	     `ELIG_MASK_NONE:
	       assign elig = ~allocated;
	     
	     `ELIG_MASK_FULL:
	       assign elig = ~allocated & ~full;
	     
	     `ELIG_MASK_USED:
	       assign elig = ~allocated & empty;
	     
	   endcase
	   
	   assign elig_ovc[ovc] = elig;
	   
	end
      
   endgenerate   
   
   
   //---------------------------------------------------------------------------
   // generate random route info
   //---------------------------------------------------------------------------
   
   wire [0:addr_width-1] 	dest_addr_1_rv;
   
   wire 			first_addr_match;
   assign first_addr_match = (dest_addr_1_rv == address);
   
   wire 			packet_to_self;
   assign packet_to_self = first_addr_match & suppress_q;
   
   wire [0:addr_width-1] 	dest_addr_2_rv;
   
   wire [0:addr_width-1] 	dest_addr_rv;
   assign dest_addr_rv = first_addr_match ? dest_addr_2_rv : dest_addr_1_rv;
   
   wire [0:dest_info_width-1] 	dest_info_rv;
   assign dest_info_rv[(num_resource_classes-1)*router_addr_width:
			dest_info_width-1]
	    = dest_addr_rv;
   
   genvar 			dim;
   
   generate
      
      //------------------------------------------------------------------------
      // generate two (distinct) candidate random final destination addresses
      //------------------------------------------------------------------------
      
      for(dim = 0; dim < num_dimensions; dim = dim + 1)
	begin:dims
	   
	   assign dest_addr_1_rv[dim*dim_addr_width:(dim+1)*dim_addr_width-1]
		    = packet_rvs_q[mc_idx_rv_width+rc_idx_rv_width+
				   (num_resource_classes-1)*router_addr_width+
				   dim*dim_addr_width:
				   mc_idx_rv_width+rc_idx_rv_width+
				   (num_resource_classes-1)*router_addr_width+
				   (dim+1)*dim_addr_width-1] % 
		      num_routers_per_dim;
	   
	end
      
      if(num_nodes_per_router > 1)
	begin
	   
	   assign dest_addr_1_rv[router_addr_width:addr_width-1]
		    = packet_rvs_q[mc_idx_rv_width+rc_idx_rv_width+
				   num_resource_classes*router_addr_width:
				   mc_idx_rv_width+rc_idx_rv_width+
				   num_resource_classes*router_addr_width+
				   node_addr_width-1] % 
		      num_nodes_per_router;
	   
	   assign dest_addr_2_rv[0:router_addr_width-1]
		    = dest_addr_1_rv[0:router_addr_width-1];
	   
	   assign dest_addr_2_rv[router_addr_width:addr_width-1]
		    = (packet_rvs_q[mc_idx_rv_width+rc_idx_rv_width+
				    num_resource_classes*router_addr_width:
				    mc_idx_rv_width+rc_idx_rv_width+
				    num_resource_classes*router_addr_width+
				    node_addr_width-1] + 1) % 
		      num_nodes_per_router;
	   
	end
      else
	begin
	   
	   if(num_dimensions > 1)
	     assign dest_addr_2_rv[0:(num_dimensions-1)*dim_addr_width-1]
		      = dest_addr_1_rv[0:(num_dimensions-1)*dim_addr_width-1];
	   
	   assign dest_addr_2_rv[(num_dimensions-1)*dim_addr_width:
				 num_dimensions*dim_addr_width-1]
		    = (packet_rvs_q[mc_idx_rv_width+rc_idx_rv_width+
				    (num_resource_classes-1)*router_addr_width+
				    (num_dimensions-1)*dim_addr_width:
				    mc_idx_rv_width+rc_idx_rv_width+
				    (num_resource_classes-1)*router_addr_width+
				    num_dimensions*dim_addr_width-1] + 1) % 
		      num_routers_per_dim;
	   
	end
      
      
      //------------------------------------------------------------------------
      // generate random intermediate addresses
      //------------------------------------------------------------------------
      
      if(num_resource_classes > 1)
	begin:intm_addr_gen
	   
	   wire [0:num_resource_classes*router_addr_width-1] intm_addr_rvs;
	   assign intm_addr_rvs[(num_resource_classes-1)*router_addr_width:
				num_resource_classes*router_addr_width-1]
		    = dest_addr_rv[0:router_addr_width-1];
	   
	   genvar 					     orc;
	   
	   for(orc = 0; orc < (num_resource_classes - 1); orc = orc + 1)
	     begin:orcs
		
		wire orc_active;
		assign orc_active = sel_orc_rv[orc];
		
		// as with the final destination, we generate two candidates
		wire [0:router_addr_width-1] rand_addr_1_rv;
		wire [0:router_addr_width-1] rand_addr_2_rv;
		
		for(dim = 0; dim < num_dimensions; dim = dim + 1)
		  begin:dims
		     
		     assign rand_addr_1_rv[dim*dim_addr_width:
					   (dim+1)*dim_addr_width-1]
			      = packet_rvs_q[mc_idx_rv_width+rc_idx_rv_width+
					     orc*router_addr_width+
					     dim*dim_addr_width:
					     mc_idx_rv_width+rc_idx_rv_width+
					     orc*router_addr_width+
					     (dim+1)*dim_addr_width-1] %
				num_routers_per_dim;
		     
		  end
		
		if(num_dimensions > 1)
		  assign rand_addr_2_rv[0:(num_dimensions-1)*dim_addr_width-1]
		    = rand_addr_1_rv[0:(num_dimensions-1)*dim_addr_width-1];
		
		assign rand_addr_2_rv[(num_dimensions-1)*dim_addr_width:
				      num_dimensions*dim_addr_width-1]
			 = (packet_rvs_q[mc_idx_rv_width+rc_idx_rv_width+
					 orc*router_addr_width+
					 (num_dimensions-1)*dim_addr_width:
					 mc_idx_rv_width+rc_idx_rv_width+
					 orc*router_addr_width+
					 num_dimensions*dim_addr_width-1] + 1) %
			   num_routers_per_dim;
		
		// get the intermediate address for the next resource class
		wire [0:router_addr_width-1] next_addr_rv;
		assign next_addr_rv
		  = intm_addr_rvs[(orc+1)*router_addr_width:
				  (orc+2)*router_addr_width-1];
		
		//--------------------------------------------------------------
		// NOTE:
		//--------------------------------------------------------------
		// Packets transition from one resource class to the next at 
		// each intermediate address; in particular, the router logic
		// assumes that a packet's current resource class is incremented
		// by one at each intermediate address. Thus, the router cannot
		// currently handle the case where multiple successive 
		// intermediate addresses (or the last intermediate and the 
		// final address) are identical, as this would require the
		// resource class to be incremented by more than one or the 
		// packet to be moved between different VCs at a router's input 
		// port, neither of which the RTL currently supports. 
		// Consequently, we must make sure that no two successive 
		// intermediate addresses nor the last intermediate and the 
		// final destination addresses are pairwise identical. 
		//--------------------------------------------------------------
		
		// if the first candidate intermediate address for the current 
		// resource class matches that for the next one, ...
		wire 			     first_addr_match;
		assign first_addr_match = (rand_addr_1_rv == next_addr_rv);
		
		// ... we use the second candidate instead
		wire [0:router_addr_width-1] intm_addr_rv;
		assign intm_addr_rv
		  = first_addr_match ? rand_addr_2_rv : rand_addr_1_rv;
		
		assign intm_addr_rvs[orc*router_addr_width:
				     (orc+1)*router_addr_width-1]
			 = intm_addr_rv;
		
		assign dest_info_rv[orc*router_addr_width:
				     (orc+1)*router_addr_width-1]
			 = intm_addr_rv;
		
	     end
	   
	end
      
   endgenerate
   
   wire [0:route_info_width-1] 		     route_info_out;
   
   assign route_info_out[lar_info_width:lar_info_width+dest_info_width-1]
     = dest_info_rv;
   
   
   //---------------------------------------------------------------------------
   // generate random lookahead routing info
   //---------------------------------------------------------------------------
   
   wire [0:router_addr_width-1] 	     router_address;
   assign router_address = address[0:router_addr_width-1];
   
   wire [0:num_ports-1] 		     route_op_rv;
   wire [0:num_resource_classes-1] 	     route_orc_rv;
   rtr_routing_logic
     #(.num_message_classes(num_message_classes),
       .num_resource_classes(num_resource_classes),
       .num_routers_per_dim(num_routers_per_dim),
       .num_dimensions(num_dimensions),
       .num_nodes_per_router(num_nodes_per_router),
       .connectivity(connectivity),
       .routing_type(routing_type),
       .dim_order(dim_order))
   rtl
     (.router_address(router_address),
      .sel_mc(sel_mc_rv),
      .sel_irc(sel_orc_rv),
      .dest_info(dest_info_rv),
      .route_op(route_op_rv),
      .route_orc(route_orc_rv));
   
   wire [0:port_idx_width-1] 		     route_port_rv;
   c_encode
     #(.num_ports(num_ports))
   route_port_rv_enc
     (.data_in(route_op_rv),
      .data_out(route_port_rv));
   
   wire [0:lar_info_width-1] 	     lar_info_rv;
   assign lar_info_rv[0:port_idx_width-1] = route_port_rv;
   
   generate
      
      if(num_resource_classes > 1)
	begin
	   
	   wire [0:resource_class_idx_width-1] route_rcsel_rv;
	   c_encode
	     #(.num_ports(num_resource_classes))
	   route_rcsel_rv_enc
	     (.data_in(route_orc_rv),
	      .data_out(route_rcsel_rv));
	   
	   assign lar_info_rv[port_idx_width:
				   port_idx_width+resource_class_idx_width-1]
	     = route_rcsel_rv;
	   
	end
      
   endgenerate
   
   assign route_info_out[0:lar_info_width-1] = lar_info_rv;
   
   wire [0:header_info_width-1] 	       header_info_out;
   assign header_info_out[0:route_info_width-1] = route_info_out;
   
   
   //---------------------------------------------------------------------------
   // generate random packet length
   //---------------------------------------------------------------------------
   
   wire [0:packet_length_width-1] 	     flit_count_rv;
   
   generate
      
      if(max_payload_length > min_payload_length)
	begin
	   
	   // synopsys translate_off
	   if(plength_threshs_width > cfg_data_width)
	     begin
		initial
		begin
		   $display({"ERROR: The value of the cfg_data_width ", 
			     "parameter (%d) in module %m is too small to ",
			     "accomodate %d packet length selection ",
			     "thresholds of width %d."}, 
			    cfg_data_width, num_plength_vals - 1, 
			    plength_idx_rv_width);
		   $stop;
		end
	     end
	   if(plength_vals_width > cfg_data_width)
	     begin
		initial
		begin
		   $display({"ERROR: The value of the cfg_data_width ", 
			     "parameter (%d) in module %m is too small to ",
			     "accomodate %d packet length values of ", 
			     "width %d."},
			    cfg_data_width, num_plength_vals, 
			    payload_length_width);
		   $stop;
		end
	     end
	   // synopsys translate_on
	   
	   wire [0:plength_vals_width-1] plength_vals_loadval;
	   c_align
	     #(.in_width(cfg_data_width),
	       .out_width(plength_vals_width))
	   plength_vals_loadval_alg
	     (.data_in(ifc_write_data),
	      .dest_in({(plength_vals_width){1'b0}}),
	      .data_out(plength_vals_loadval));
	   
	   wire 			 write_plength_vals;
	   assign write_plength_vals = do_write & ifc_sel_plength_vals;
	   
	   wire [0:plength_vals_width-1] plength_vals_s, plength_vals_q;
	   assign plength_vals_s
	     = write_plength_vals ? plength_vals_loadval : plength_vals_q;
	   c_dff
	     #(.width(plength_vals_width),
	       .reset_type(reset_type))
	   plength_valsq
	     (.clk(clk),
	      .reset(1'b0),
	      .active(ifc_active),
	      .d(plength_vals_s),
	      .q(plength_vals_q));
	   
	   wire [0:payload_length_width-1] plength_rv;
	   
	   if(num_plength_vals > 1)
	     begin
		
		wire [0:plength_threshs_width-1] plength_threshs_loadval;
		c_align
		  #(.in_width(cfg_data_width),
		    .out_width(plength_threshs_width))
		plength_threshs_loadval_alg
		  (.data_in(ifc_write_data),
		   .dest_in({plength_threshs_width{1'b0}}),
		   .data_out(plength_threshs_loadval));
		
		wire 				 write_plength_threshs;
		assign write_plength_threshs
		  = do_write & ifc_sel_plength_threshs;
		
		wire [0:plength_threshs_width-1] plength_threshs_s, 
						 plength_threshs_q;
		assign plength_threshs_s = write_plength_threshs ? 
					   plength_threshs_loadval :
					   plength_threshs_q;
		c_dff
		  #(.width(plength_threshs_width),
		    .reset_type(reset_type))
		plength_threshsq
		  (.clk(clk),
		   .reset(1'b0),
		   .active(ifc_active),
		   .d(plength_threshs_s),
		   .q(plength_threshs_q));
		
		wire [0:plength_idx_rv_width-1]  plength_idx_rv;
		assign plength_idx_rv
		  = packet_rvs_q[mc_idx_rv_width+rc_idx_rv_width+
				 dest_info_width:
				 mc_idx_rv_width+rc_idx_rv_width+
				 dest_info_width+plength_idx_rv_width-1];
		
		wire [0:num_plength_vals-1] 	 plength_select_unmasked;
		
		genvar 				 val;
		
		for(val = 0; val < (num_plength_vals - 1); val = val + 1)
		  begin:vals
		     
		     assign plength_select_unmasked[val]
			      = (plength_idx_rv <
				 plength_threshs_q[val*
						   plength_idx_rv_width:
						   (val+1)*
						   plength_idx_rv_width-1]);
		     
		  end
		
		assign plength_select_unmasked[num_plength_vals-1] = 1'b1;
		
		wire [0:num_plength_vals-1] 	 plength_select;
		c_lod
		  #(.width(num_plength_vals))
		plength_select_lod
		  (.data_in_pr(plength_select_unmasked),
		   .data_out_pr(plength_select),
		   .data_out(),
		   .mask_out());
		
		c_select_1ofn
		  #(.num_ports(num_plength_vals),
		    .width(payload_length_width))
		plength_rv_sel
		  (.select(plength_select),
		   .data_in(plength_vals_q),
		   .data_out(plength_rv));
		
	     end
	   else
	     assign plength_rv = plength_vals_q;
	   
	   if(packet_format == `PACKET_FORMAT_EXPLICIT_LENGTH)
	     assign header_info_out[route_info_width:
				    route_info_width+
				    payload_length_width-1]
		      = plength_rv;
	   
	   assign flit_count_rv = min_payload_length + plength_rv;
	   
	end
      else
	assign flit_count_rv = min_payload_length;
      
   endgenerate
   
   
   //---------------------------------------------------------------------------
   // keep track of packets being processed
   //---------------------------------------------------------------------------
   
   wire 					 add_packet;
   assign add_packet = gen_packets & new_packet_rv;
   
   wire 					 packet_count_zero_b;
   
   wire 					 packet_count_decr;
   assign packet_count_decr
     = (~packet_valid_q | packet_sent) & (packet_count_zero_b | add_packet);
   
   wire 					 packet_count_max_b;
   
   wire 					 packet_count_incr;
   assign packet_count_incr
     = (packet_count_max_b | ~packet_valid_q | packet_sent) & add_packet;
   
   wire [0:packet_count_width-1] 		 packet_count_s, packet_count_q;
   assign packet_count_s
     = {packet_count_width{~start_q}} &
       (packet_count_q + packet_count_incr - packet_count_decr);
   c_dff
     #(.width(packet_count_width),
       .reset_type(reset_type))
   packet_countq
     (.clk(clk),
      .reset(1'b0),
      .active(active_q),
      .d(packet_count_s),
      .q(packet_count_q));
   
   assign packet_count_zero = ~|packet_count_q;
   assign packet_count_zero_b = |packet_count_q;
   assign packet_count_max_b = ~&packet_count_q;
   
   wire 					 packet_valid_s;
   assign packet_valid_s
     = ((packet_valid_q  & ~packet_sent) | packet_count_zero_b | add_packet) & 
       ~start_q;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   packet_validq
     (.clk(clk),
      .reset(reset),
      .active(active_q),
      .d(packet_valid_s),
      .q(packet_valid_q));
   
   assign flit_sent
     = packet_valid_q & ((vc_alloc_q | elig) & ~full) & ~packet_to_self;
   
   assign flit_valid_out = flit_sent;
   
   wire [0:packet_length_width-1] 		 flit_count;
   
   wire [0:packet_length_width-1] 		 flit_count_s, flit_count_q;
   assign flit_count_s = flit_count - flit_sent;
   c_dff
     #(.width(packet_length_width),
       .reset_type(reset_type))
   flit_countq
     (.clk(clk),
      .reset(1'b0),
      .active(active_q),
      .d(flit_count_s),
      .q(flit_count_q));
   
   assign flit_count = flit_head_out ? flit_count_rv : flit_count_q;
   
   wire 					 flit_count_zero;
   assign flit_count_zero = ~|flit_count;
   
   assign flit_tail_out = flit_count_zero;
   
   assign packet_sent
     = (flit_sent & flit_count_zero) | (packet_valid_q & packet_to_self);
   
   wire 					 vc_alloc_s;
   assign vc_alloc_s
     = (vc_alloc_q | (packet_valid_q & elig & ~full)) & ~start_q & ~packet_sent;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   vc_allocq
     (.clk(clk),
      .reset(reset),
      .active(active_q),
      .d(vc_alloc_s),
      .q(vc_alloc_q));
   
   generate
      
      if(num_vcs_per_class > 1)
	begin
	   
	   wire [0:num_vcs_per_class-1] vc_alloc_ocvc_s;
	   assign vc_alloc_ocvc_s
	     = vc_alloc_q ? vc_alloc_ocvc_q : next_elig_ocvc;
	   c_dff
	     #(.width(num_vcs_per_class),
	       .reset_type(reset_type))
	   vc_alloc_ocvcq
	     (.clk(clk),
	      .reset(1'b0),
	      .active(active_q),
	      .d(vc_alloc_ocvc_s),
	      .q(vc_alloc_ocvc_q));
	   
	end
      else
	assign vc_alloc_ocvc_q = 1'b1;
      
      if(max_payload_length > 0)
	begin
	   
	   wire head_s, head_q;
	   assign head_s
	     = (head_q & ~flit_sent) | start_q | packet_sent;
	   c_dff
	     #(.width(1),
	       .reset_type(reset_type))
	   headq
	     (.clk(clk),
	      .reset(1'b0),
	      .active(active_q),
	      .d(head_s),
	      .q(head_q));
	   
	   assign flit_head_out = head_q;
	   
	end
      else
	assign flit_head_out = 1'b1;
      
   endgenerate
   
   
   //---------------------------------------------------------------------------
   // generate pseudo-random payload data
   //---------------------------------------------------------------------------
   
   wire [0:flit_data_width-1] 	   flit_data_rv_feedback;
   c_fbgen
     #(.width(flit_data_width),
       .index(4*lfsr_index+2))
   flit_data_rv_feedback_fbgen
     (.feedback(flit_data_rv_feedback));
   
   wire [0:flit_data_width-1] 	   flit_data_rv_loadval;
   c_align
     #(.in_width(cfg_data_width),
       .out_width(flit_data_width))
   flit_data_rv_loadval_alg
     (.data_in(ifc_write_data),
      .dest_in({flit_data_width{1'b0}}),
      .data_out(flit_data_rv_loadval));
   
   wire 			   update_flit_data_rv;
   assign update_flit_data_rv = active_q & flit_sent;
   
   wire [0:flit_data_width-1] 	   flit_data_rv_s, flit_data_rv_q;
   assign flit_data_rv_s
     = {flit_data_width{write_lfsr_seed}} & flit_data_rv_loadval;
   c_lfsr
     #(.width(flit_data_width),
       .iterations(flit_data_width),
       .reset_type(reset_type))
   flit_data_rv_lfsr
     (.clk(clk),
      .reset(1'b0),
      .active(reg_active),
      .load(write_lfsr_seed),
      .run(update_flit_data_rv),
      .feedback(flit_data_rv_feedback),
      .complete(1'b1),
      .d(flit_data_rv_s),
      .q(flit_data_rv_q));
   
   assign flit_data_out[0:header_info_width-1]
     = flit_head_out ? header_info_out : flit_data_rv_q[0:header_info_width-1];
   assign flit_data_out[header_info_width:flit_data_width-1]
     = flit_data_rv_q[header_info_width:flit_data_width-1];
   
   
   //---------------------------------------------------------------------------
   // flit signature register
   // =======================
   // This is a MISR that computes a signature over all flit data received
   // during the experiment.
   //---------------------------------------------------------------------------
   
   wire [0:flit_data_width-1] 	   flit_sig_feedback;
   c_fbgen
     #(.width(flit_data_width),
       .index(4*lfsr_index+3))
   flit_sig_feedback_fbgen
     (.feedback(flit_sig_feedback));
   
   wire [0:flit_data_width-1] 	   flit_sig_loadval;
   assign flit_sig_loadval = {{(flit_data_width-1){1'b0}}, 1'b1};
   
   wire 			   update_flit_sig;
   assign update_flit_sig = active_q & flit_valid_in;
   
   wire [0:flit_data_width-1] 	   flit_sig_s, flit_sig_q;
   assign flit_sig_s = start_q ? flit_sig_loadval : flit_data_in;
   c_lfsr
     #(.width(flit_data_width),
       .iterations(1),
       .reset_type(reset_type))
   flit_sig_lfsr
     (.clk(clk),
      .reset(1'b0),
      .active(active_q),
      .load(start_q),
      .run(update_flit_sig),
      .feedback(flit_sig_feedback),
      .complete(1'b0),
      .d(flit_sig_s),
      .q(flit_sig_q));

   // expand the signature to a multiple of cfg_data_width, ...
   wire [0:flit_sig_exp_width-1]   flit_sig_expanded;
   c_align
     #(.in_width(flit_data_width),
       .out_width(flit_sig_exp_width))
   flit_sig_expanded_alg
     (.data_in(flit_sig_q),
      .dest_in({flit_sig_exp_width{1'b0}}),
      .data_out(flit_sig_expanded));
   
   // ... and reduce it down to a single signature of width cfg_data_width
   c_binary_op
     #(.num_ports(flit_sig_exp_width / cfg_data_width),
       .width(cfg_data_width),
       .op(`BINARY_OP_XOR))
   ifc_read_data_flit_sig_xor
     (.data_in(flit_sig_expanded),
      .data_out(ifc_read_data_flit_sig));
   
   
   //---------------------------------------------------------------------------
   // credit return path
   //---------------------------------------------------------------------------
   
   rtr_flow_ctrl_output
     #(.num_vcs(num_vcs),
       .flow_ctrl_type(flow_ctrl_type),
       .reset_type(reset_type))
   fco
     (.clk(clk),
      .reset(reset),
      .active(active_q),
      .fc_event_valid_in(flit_valid_in),
      .fc_event_sel_in_ivc(flit_sel_in_ivc),
      .flow_ctrl_out(flow_ctrl_out));
   
   
   //---------------------------------------------------------------------------
   // error checking
   //---------------------------------------------------------------------------
   
   // synopsys translate_off
   
   integer 			   i;
   
   always @(posedge clk)
     begin
	
	for(i = 0; i < num_vcs; i = i + 1)
	  begin
	     
	     if(fcs_errors_ovc[i*2])
	       $display("ERROR: Credit tracker underflow in module %m.");
	     
	     if(fcs_errors_ovc[i*2+1])
	       $display("ERROR: Credit tracker overflow in module %m.");
	     
	  end
	
     end
   
   // synopsys translate_on
   
   generate
      
      if(error_capture_mode != `ERROR_CAPTURE_MODE_NONE)
	begin
	   
	   wire [0:num_vcs*2-1] errors_s, errors_q;
	   assign errors_s = fcs_errors_ovc;
	   c_err_rpt
	     #(.num_errors(num_vcs*2),
	       .capture_mode(error_capture_mode),
	       .reset_type(reset_type))
	   chk
	     (.clk(clk),
	      .reset(reset),
	      .active(active_q),
	      .errors_in(errors_s),
	      .errors_out(errors_q));
	   
	   assign error = |errors_q;
	   
	end
      else
	assign error = 1'bx;
      
   endgenerate
   
endmodule
