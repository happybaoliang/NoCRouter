// $Id: parameters.v 3175 2011-01-13 02:54:33Z dub $

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
// router configuration options
//==============================================================================

// select network topology
parameter topology = `TOPOLOGY_MESH;

// flit buffer entries per VC
parameter num_flits_per_vc = 8;

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
parameter max_payload_length = 9;

// minimum payload length (in flits)
parameter min_payload_length = 1;

// select router implementation
parameter router_type = `ROUTER_TYPE_VC;

// width of flit payload data
parameter flit_data_width = 64;

// configure error checking logic
parameter error_capture_mode = `ERROR_CAPTURE_MODE_NONE;

// filter out illegal destination ports
// (the intent is to allow synthesis to optimize away the logic associated with 
// such turns)
parameter restrict_turns = 0;

// select routing function type
parameter routing_type = `ROUTING_TYPE_PHASED_DOR;

// select order of dimension traversal
parameter dim_order = `DIM_ORDER_ASCENDING;

// use input register as part of the flit buffer (wormhole router only)
parameter input_stage_can_hold = 0;

// select implementation variant for flit buffer register file
parameter fb_regfile_type = `REGFILE_TYPE_FF_2D;

// use explicit pipeline register between flit buffer and crossbar?
parameter explicit_pipeline_register = 0;

// enable dual-path allocation
parameter dual_path_alloc = 0;

// precompute input-side arbitration decision one cycle ahead
parameter precomp_ivc_sel = 0;

// precompute output-side arbitration decision one cycle ahead
parameter precomp_ip_sel = 0;

// select implementation variant for VC allocator
parameter vc_alloc_type = `VC_ALLOC_TYPE_SEP_IF;

// select which arbiter type to use for VC allocator
parameter vc_alloc_arbiter_type = `ARBITER_TYPE_ROUND_ROBIN;

// select whether VCs must have credits available in order to be considered for
// VC allocation
parameter vc_alloc_requires_credit = 0;

// select implementation variant for switch allocator
parameter sw_alloc_type = `SW_ALLOC_TYPE_SEP_IF;

// select which arbiter type to use for switch allocator
parameter sw_alloc_arbiter_type = `ARBITER_TYPE_ROUND_ROBIN;

// select speculation type for switch allocator
parameter sw_alloc_spec_type = `SW_ALLOC_SPEC_TYPE_NONE;

// select implementation variant for crossbar
parameter crossbar_type = `CROSSBAR_TYPE_TRISTATE;

parameter reset_type = `RESET_TYPE_ASYNC;  
