// $Id: c_constants.v 5188 2012-08-30 00:31:31Z dub $

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
// global constant definitions
//==============================================================================
//------------------------------------------------------------------------------
// network topologies
//------------------------------------------------------------------------------

// mesh
`define TOPOLOGY_MESH  0

// torus
`define TOPOLOGY_TORUS 1

// flattened butterfly
`define TOPOLOGY_FBFLY 2

`define TOPOLOGY_LAST  `TOPOLOGY_FBFLY


//------------------------------------------------------------------------------
// what does connectivity look like within a dimension?
//------------------------------------------------------------------------------

// nodes are connected to their neighbors with no wraparound (e.g. mesh)
`define CONNECTIVITY_LINE 0

// nodes are connected to their neighbors with wraparound (e.g. torus)
`define CONNECTIVITY_RING 1

// nodes are fully connected (e.g. flattened butterfly)
`define CONNECTIVITY_FULL 2

`define CONNECTIVITY_LAST `CONNECTIVITY_FULL


//------------------------------------------------------------------------------
// router implementations
//------------------------------------------------------------------------------

// wormhole router
`define ROUTER_TYPE_WORMHOLE 0

// virtual channel router
`define ROUTER_TYPE_VC       1

// router with combined VC and switch allocation
`define ROUTER_TYPE_COMBINED 2

`define ROUTER_TYPE_LAST `ROUTER_TYPE_COMBINED


//------------------------------------------------------------------------------
// routing function types
//------------------------------------------------------------------------------

// dimension-order routing (using multiple phases if num_resource_classes > 1)
`define ROUTING_TYPE_PHASED_DOR 0

`define ROUTING_TYPE_LAST `ROUTING_TYPE_PHASED_DOR


//------------------------------------------------------------------------------
// dimension order
//------------------------------------------------------------------------------

// traverse dimensions in ascending order
`define DIM_ORDER_ASCENDING  0

// traverse dimensions in descending order
`define DIM_ORDER_DESCENDING 1

// order of dimension traversal depends on message class
`define DIM_ORDER_BY_CLASS   2

`define DIM_ORDER_LAST `DIM_ORDER_BY_CLASS


//------------------------------------------------------------------------------
// packet formats
//------------------------------------------------------------------------------

// packets are delimited by head and tail bits
`define PACKET_FORMAT_HEAD_TAIL       0

// the last flit in each packet is marked by having its tail bit set; head bits 
// are inferred by checking if the preceding flit was a tail flit
`define PACKET_FORMAT_TAIL_ONLY       1

// head flits are identified by header bit, and contain encoded packet length
`define PACKET_FORMAT_EXPLICIT_LENGTH 2

`define PACKET_FORMAT_LAST `PACKET_FORMAT_EXPLICIT_LENGTH


//------------------------------------------------------------------------------
// flow control types
//------------------------------------------------------------------------------

// credit-based flow control
`define FLOW_CTRL_TYPE_CREDIT 0

`define FLOW_CTRL_TYPE_LAST `FLOW_CTRL_TYPE_CREDIT


//------------------------------------------------------------------------------
// VC allocation masking
//------------------------------------------------------------------------------

// no masking
`define ELIG_MASK_NONE 0

// mask VCs that have no buffer space available
`define ELIG_MASK_FULL 1

// mask VCs that are not completely empty
`define ELIG_MASK_USED 2

`define ELIG_MASK_LAST `ELIG_MASK_USED


//------------------------------------------------------------------------------
// flit buffer management schemes
//------------------------------------------------------------------------------

// statically partitioned
`define FB_MGMT_TYPE_STATIC  0

// dynamically managed
`define FB_MGMT_TYPE_DYNAMIC 1

`define FB_MGMT_TYPE_LAST    `FB_MGMT_TYPE_DYNAMIC

//------------------------------------------------------------------------------
// reset handling
//------------------------------------------------------------------------------

// asynchronous reset
`define RESET_TYPE_ASYNC 0

// synchronous reset
`define RESET_TYPE_SYNC  1

`define RESET_TYPE_LAST `RESET_TYPE_SYNC


//------------------------------------------------------------------------------
// arbiter types
//------------------------------------------------------------------------------

// round-robin arbiter with binary-encoded state
`define ARBITER_TYPE_ROUND_ROBIN_BINARY  0

// round-robin arbiter with one-hot encoded state
`define ARBITER_TYPE_ROUND_ROBIN_ONE_HOT 1

// prefix arbiter with binary-encoded state
`define ARBITER_TYPE_PREFIX_BINARY       2

// prefix arbiter with one-hot encoded state
`define ARBITER_TYPE_PREFIX_ONE_HOT      3

// matrix arbiter
`define ARBITER_TYPE_MATRIX              4

`define ARBITER_TYPE_LAST `ARBITER_TYPE_MATRIX


//------------------------------------------------------------------------------
// error checker capture more
//------------------------------------------------------------------------------

// disable error reporting
`define ERROR_CAPTURE_MODE_NONE       0
// don't hold errors
`define ERROR_CAPTURE_MODE_NO_HOLD    1

// capture first error only (subsequent errors are blocked)
`define ERROR_CAPTURE_MODE_HOLD_FIRST 2

// capture all errors
`define ERROR_CAPTURE_MODE_HOLD_ALL   3

`define ERROR_CAPTURE_MODE_LAST `ERROR_CAPTURE_MODE_HOLD_ALL


//------------------------------------------------------------------------------
// crossbar implementation variants
//------------------------------------------------------------------------------

// tristate-based
`define CROSSBAR_TYPE_TRISTATE 0

// mux-based
`define CROSSBAR_TYPE_MUX      1

// distributed multiplexers
`define CROSSBAR_TYPE_DIST_MUX 2

`define CROSSBAR_TYPE_LAST `CROSSBAR_TYPE_DIST_MUX


//------------------------------------------------------------------------------
// register file implemetation variants
//------------------------------------------------------------------------------

// 2D array implemented using flipflops
`define REGFILE_TYPE_FF_2D     0

// 1D array of flipflops, read using a mux
`define REGFILE_TYPE_FF_1D_MUX 1

// 1D array of flipflops, read using a tristate mux
`define REGFILE_TYPE_FF_1D_SEL 2

`define REGFILE_TYPE_LAST `REGFILE_TYPE_FF_1D_SEL


//------------------------------------------------------------------------------
// directions of rotation
//------------------------------------------------------------------------------

`define ROTATE_DIR_LEFT  0
`define ROTATE_DIR_RIGHT 1


//------------------------------------------------------------------------------
// wavefront allocator implementation variants
//------------------------------------------------------------------------------

// variant which uses multiplexers to permute inputs and outputs based on 
// priority
`define WF_ALLOC_TYPE_MUX  0

// variant which replicates the entire allocation logic for the different 
// priorities and selects the result from the appropriate one
`define WF_ALLOC_TYPE_REP  1

// variant implementing a Diagonal Propagation Arbiter as described in Hurt et 
// al, "Design and Implementation of High-Speed Symmetric Crossbar Schedulers"
`define WF_ALLOC_TYPE_DPA  2

// variant which rotates inputs and outputs based on priority
`define WF_ALLOC_TYPE_ROT  3

// variant which uses wraparound (forming a false combinational loop) as 
// described in Dally et al, "Principles and Practices of Interconnection 
// Networks"
`define WF_ALLOC_TYPE_LOOP 4

// variant implementing a somewhat simplified Diagonal Propagation Arbiter
`define WF_ALLOC_TYPE_SDPA 5

`define WF_ALLOC_TYPE_LAST `WF_ALLOC_TYPE_SDPA


//------------------------------------------------------------------------------
// binary operators
//------------------------------------------------------------------------------

`define BINARY_OP_AND  0
`define BINARY_OP_NAND 1
`define BINARY_OP_OR   2
`define BINARY_OP_NOR  3
`define BINARY_OP_XOR  4
`define BINARY_OP_XNOR 5

`define BINARY_OP_LAST `BINARY_OP_XNOR

//------------------------------------------------------------------------------
// VC allocator implementation variants
//------------------------------------------------------------------------------

// separable, input-first
`define VC_ALLOC_TYPE_SEP_IF    0

// separable, output-first
`define VC_ALLOC_TYPE_SEP_OF    1

// wavefront-based
// (note: add WF_ALLOC_TYPE_* constant to select wavefront variant)
`define VC_ALLOC_TYPE_WF_BASE   2
`define VC_ALLOC_TYPE_WF_LIMIT  (`VC_ALLOC_TYPE_WF_BASE + `WF_ALLOC_TYPE_LAST)

`define VC_ALLOC_TYPE_LAST `VC_ALLOC_TYPE_WF_LIMIT


//------------------------------------------------------------------------------
// switch allocator implementation variants
//------------------------------------------------------------------------------

// separable, input-first
`define SW_ALLOC_TYPE_SEP_IF   0

// separable, output-first
`define SW_ALLOC_TYPE_SEP_OF   1

// wavefront-based
// (note: add WF_ALLOC_TYPE_* constant to select wavefront variant)
`define SW_ALLOC_TYPE_WF_BASE  2
`define SW_ALLOC_TYPE_WF_LIMIT (`SW_ALLOC_TYPE_WF_BASE + `WF_ALLOC_TYPE_LAST)

`define SW_ALLOC_TYPE_LAST `SW_ALLOC_TYPE_WF_LIMIT


//------------------------------------------------------------------------------
// speculation types for switch allocator
//------------------------------------------------------------------------------

// disable speculative switch allocation
`define SW_ALLOC_SPEC_TYPE_NONE 0

// use speculative grants when not conflicting with non-spec requests
`define SW_ALLOC_SPEC_TYPE_REQ  1

// use speculative grants when not conflicting with non-spec grants
`define SW_ALLOC_SPEC_TYPE_GNT  2

// use single allocator, but prioritize non-speculative requrests
`define SW_ALLOC_SPEC_TYPE_PRIO 3

`define SW_ALLOC_SPEC_TYPE_LAST `SW_ALLOC_SPEC_TYPE_PRIO

//------------------------------------------------------------------------------
// network pseudo-node register address declarations
//------------------------------------------------------------------------------

`define CFG_ADDR_NODE_CTRL            0
`define CFG_ADDR_NODE_STATUS          1
`define CFG_ADDR_NODE_FLIT_SIG        2
`define CFG_ADDR_NODE_LFSR_SEED       3
`define CFG_ADDR_NODE_NUM_PACKETS     4
`define CFG_ADDR_NODE_ARRIVAL_THRESH  5
`define CFG_ADDR_NODE_PLENGTH_THRESHS 6
`define CFG_ADDR_NODE_PLENGTH_VALS    7
`define CFG_ADDR_NODE_MC_THRESHS      8
`define CFG_ADDR_NODE_RC_THRESHS      9


//------------------------------------------------------------------------------
// network pseudo-node controller register address declarations
//------------------------------------------------------------------------------

`define CFG_ADDR_NCTL_CTRL   0
`define CFG_ADDR_NCTL_STATUS 1


//------------------------------------------------------------------------------
// network channel tester register address declarations
//------------------------------------------------------------------------------

`define CFG_ADDR_CTST_CTRL            0
`define CFG_ADDR_CTST_STATUS          1
`define CFG_ADDR_CTST_ERRORS          2
`define CFG_ADDR_CTST_TEST_DURATION   3
`define CFG_ADDR_CTST_WARMUP_DURATION 4
`define CFG_ADDR_CTST_CAL_INTERVAL    5
`define CFG_ADDR_CTST_CAL_DURATION    6
`define CFG_ADDR_CTST_PATTERN_ADDR    7
`define CFG_ADDR_CTST_PATTERN_DATA    8
