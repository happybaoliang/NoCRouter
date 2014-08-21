// $Id: vcr_op_ctrl_mac.v 5188 2012-08-30 00:31:31Z dub $

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
// output port controller (tracks state of buffers in downstream router)
//==============================================================================

module vcr_op_ctrl_mac (clk, reset, flow_ctrl_in, vc_active, shared_vc_active, vc_gnt_ovc, 
	vc_sel_ovc_ip, vc_sel_shared_ovc_ip, vc_sel_ovc_ivc, vc_sel_shared_ovc_ivc, sw_active, 
	sw_gnt, sw_sel_ip, sw_sel_ivc, flit_head, flit_tail, flit_data, channel_out, shared_vc_in,
	shared_almost_full_ovc, almost_full_ovc, shared_full_ovc, full_ovc, elig_ovc, error, 
	shared_elig_ovc, vc_gnt_shared_ovc, shared_vc_out, credit_for_shared, vc_sel_ovc_shared_ivc,
	vc_sel_shared_ovc_shared_ivc, sw_sel_shared_ivc, shared_ovc_allocated);
   
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
   
   // total number of packet classes
   localparam num_packet_classes = num_message_classes * num_resource_classes;
   
   // number of VCs available for each class
   parameter num_vcs_per_class = 1;
   
   // number of VCs
   localparam num_vcs = num_packet_classes * num_vcs_per_class;
   
   // width required to select individual VC
   localparam vc_idx_width = clogb(num_vcs);
   
   // number of input and output ports on router
   parameter num_ports = 5;
   
   localparam num_vcs_per_bank = num_vcs / num_ports;

   localparam memory_bank_size = buffer_size / num_ports;
   
   // select packet format
   parameter packet_format = `PACKET_FORMAT_EXPLICIT_LENGTH;
   
   // select type of flow control
   parameter flow_ctrl_type = `FLOW_CTRL_TYPE_CREDIT;
   
   // make incoming flow control signals bypass the output VC state tracking 
   // logic
   parameter flow_ctrl_bypass = 1;
   
   // width of flow control signals
   localparam flow_ctrl_width = (flow_ctrl_type == `FLOW_CTRL_TYPE_CREDIT) ? (1 + vc_idx_width) : -1;
   
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
   localparam fast_almost_empty = flow_ctrl_bypass && (elig_mask == `ELIG_MASK_USED);
   
   // enable speculative switch allocation
   parameter sw_alloc_spec = 1;
   
   parameter reset_type = `RESET_TYPE_ASYNC;
   
   input clk;
   input reset;
   
   // incoming flow control signals
   input [0:flow_ctrl_width-1]      flow_ctrl_in;
   
   // VC allocation activity indicator
   input 		                    vc_active;
   
   input 							shared_vc_active;
   
   // output VC was granted to an input VC
   input [0:num_vcs-1] 	            vc_gnt_ovc;
  
   input [0:num_vcs-1]				vc_gnt_shared_ovc;

   // input port that each output VC was granted to
   input [0:num_vcs*num_ports-1]    vc_sel_ovc_ip;
   
   // input port that each output VC was granted to
   input [0:num_vcs*num_ports-1]    vc_sel_shared_ovc_ip;
   
   // input VC that each output VC was granted to
   input [0:num_vcs*num_vcs-1] 	    vc_sel_ovc_ivc;
  
   input [0:num_vcs-1]				vc_sel_ovc_shared_ivc;

   // input VC that each output VC was granted to
   input [0:num_vcs*num_vcs-1] 	    vc_sel_shared_ovc_ivc;
   
   input [0:num_vcs-1]				vc_sel_shared_ovc_shared_ivc;

   // switch allocation activity indicator
   input 			                sw_active;
   
   // was this output granted to an input port?
   input 			                sw_gnt;
   
   // which input port was this output granted to?
   input [0:num_ports-1] 	        sw_sel_ip;
   
   // which input VC was the grant for?
   input [0:num_vcs-1] 		        sw_sel_ivc;

   input							sw_sel_shared_ivc;

   input							credit_for_shared;

   input							shared_vc_in;

   // incoming flit is a head flit
   input 			                flit_head;

   // incoming flit is a tail flit
   input 			                flit_tail;

   // incoming flit data
   input [0:flit_data_width-1] 	    flit_data;

   output							shared_vc_out;
   wire								shared_vc_out;

   // outgoing flit control signals
   output [0:channel_width-1] 	    channel_out;
   wire [0:channel_width-1] 	    channel_out;
   
   // which output VC have only a single credit left?
   output [0:num_vcs-1] 	        almost_full_ovc;
   wire [0:num_vcs-1] 		        almost_full_ovc;
 
   // which output VC have only a single credit left?
   output [0:num_vcs-1] 	        shared_almost_full_ovc;
   wire [0:num_vcs-1] 		        shared_almost_full_ovc;
  
   // which output VC have no credit left?
   output [0:num_vcs-1] 	        full_ovc;
   wire [0:num_vcs-1] 		        full_ovc;

   // which output VC have no credit left?
   output [0:num_vcs-1] 	        shared_full_ovc;
   wire [0:num_vcs-1] 		        shared_full_ovc;
   
   // output VC is eligible for allocation (i.e., not currently allocated)
   output [0:num_vcs-1] 	        elig_ovc;
   wire [0:num_vcs-1] 		        elig_ovc;
  
   // output VC is eligible for allocation (i.e., not currently allocated)
   output [0:num_vcs-1] 	        shared_elig_ovc;
   wire [0:num_vcs-1] 		        shared_elig_ovc;

   output [0:num_vcs-1]				shared_ovc_allocated;
   wire [0:num_vcs-1]				shared_ovc_allocated;

   // internal error condition detected
   output 			                error;
   wire 			                error;


   wire [0:flow_ctrl_width-1] shared_flow_ctrl_in;
   assign shared_flow_ctrl_in = credit_for_shared  ? flow_ctrl_in  : {flow_ctrl_width{1'b0}};

   wire [0:flow_ctrl_width-1] private_flow_ctrl_in;
   assign private_flow_ctrl_in = credit_for_shared  ? {flow_ctrl_width{1'b0}}  : flow_ctrl_in;

   //---------------------------------------------------------------------------
   // input staging
   //---------------------------------------------------------------------------
   wire    fc_active;
   wire    flow_ctrl_active;
   assign flow_ctrl_active = fc_active;
   
   wire	[0:num_ports-1] shared_fb_fc_active;

   wire	shared_flow_ctrl_active;
   assign 	shared_flow_ctrl_active = |shared_fb_fc_active;
   
   wire    fc_event_valid;
   wire [0:num_vcs-1]   fc_event_sel_ovc;
   rtr_flow_ctrl_input
     #(.num_vcs(num_vcs),
       .flow_ctrl_type(flow_ctrl_type),
       .reset_type(reset_type))
   fci
     (.clk(clk),
      .reset(reset),
      .active(flow_ctrl_active),
      .flow_ctrl_in(private_flow_ctrl_in),
      .fc_event_valid_out(fc_event_valid),
      .fc_event_sel_out_ovc(fc_event_sel_ovc));
   		
   wire			shared_fc_event_valid;
   wire [0:num_vcs-1]	shared_fc_event_sel_ovc;
   rtr_flow_ctrl_input
      #(.num_vcs(num_vcs),
        .flow_ctrl_type(flow_ctrl_type),
        .reset_type(reset_type))
   shared_fci
       (.clk(clk),
        .reset(reset),
        .active(shared_flow_ctrl_active),
        .flow_ctrl_in(shared_flow_ctrl_in),
        .fc_event_valid_out(shared_fc_event_valid),
        .fc_event_sel_out_ovc(shared_fc_event_sel_ovc));

   //---------------------------------------------------------------------------
   // output VC control logic
   //---------------------------------------------------------------------------
   wire	 gnt_active;
   
   wire	 flit_valid_s, flit_valid_q;
   assign flit_valid_s = sw_gnt;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_validq
     (.clk(clk),
      .reset(reset),
      .active(gnt_active),
      .d(flit_valid_s),
      .q(flit_valid_q));
   
   assign gnt_active = sw_active | flit_valid_q;
  
   wire shared_vc_s, shared_vc_q;
   wire shared_active = sw_active | shared_vc_q;
   assign shared_vc_s = sw_gnt ? shared_vc_in : shared_vc_q;
   c_dff
     #(.width(1),
	   .reset_type(reset_type))
   shared_vcq
      (.clk(clk),
	   .reset(reset),
	   .active(shared_active),
	   .d(shared_vc_s),
	   .q(shared_vc_q));

   wire	 flit_head_s, flit_head_q;
   assign flit_head_s = sw_gnt ? flit_head : flit_head_q;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_headq
     (.clk(clk),
      .reset(1'b0),
      .active(sw_active),
      .d(flit_head_s),
      .q(flit_head_q));
   
   wire	 flit_tail_s, flit_tail_q;
   assign flit_tail_s = sw_gnt ? flit_tail : flit_tail_q;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_tailq
     (.clk(clk),
      .reset(1'b0),
      .active(sw_active),
      .d(flit_tail_s),
      .q(flit_tail_q));
   
   wire 	        	flit_sent;
   wire [0:num_vcs-1]   flit_sel_ovc;
   wire [0:num_vcs-1] 	shared_flit_sel_ovc;
   
   generate
   	if(sw_alloc_spec)
		assign flit_sent = flit_valid_q & (|(flit_sel_ovc|shared_flit_sel_ovc));
    else
		assign flit_sent = flit_valid_q; 
   endgenerate
   
   wire  fcs_active;
   assign fcs_active = flit_valid_q | fc_event_valid;
   
   wire [0:num_vcs-1] 	 empty_ovc;
   wire [0:num_vcs-1] 	 full_prev_ovc;
   wire [0:num_vcs*2-1]	 fcs_errors_ovc;

   wire					 fc_flit_valid;
   assign fc_flit_valid = ~shared_vc_q & flit_sent;

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
      .active(fcs_active),
      .flit_valid(fc_flit_valid),
      .flit_head(flit_head_q),
      .flit_tail(flit_tail_q),
      .flit_sel_ovc(flit_sel_ovc),
      .fc_event_valid(fc_event_valid),
      .fc_event_sel_ovc(fc_event_sel_ovc),
      .fc_active(fc_active),
      .empty_ovc(empty_ovc),
      .almost_full_ovc(almost_full_ovc),
      .full_ovc(full_ovc),
      .full_prev_ovc(full_prev_ovc),
      .errors_ovc(fcs_errors_ovc));

   	wire [0:num_vcs-1]		shared_empty_ovc;
   	wire [0:num_vcs-1]		shared_full_prev_ovc;
	wire [0:num_vcs*2-1]	shared_fcs_errors_ovc;

	wire					shared_fcs_flit_valid;
	assign shared_fcs_flit_valid = shared_vc_q & flit_sent;

    genvar fc;
    generate
	for (fc=0; fc<num_ports; fc=fc+1)
    begin:fcss
        wire shared_fb_fcs_flit_valid;
        assign shared_fb_fcs_flit_valid = shared_fcs_flit_valid & (|shared_flit_sel_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]);

        wire shared_fb_fc_event_valid;
        assign shared_fb_fc_event_valid = shared_fc_event_valid & (|shared_fc_event_sel_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]);

        wire	shared_fb_fcs_active;
        assign shared_fb_fcs_active = shared_fb_fcs_flit_valid | shared_fb_fc_event_valid;

        rtr_fc_state
	        #(.num_vcs(num_vcs_per_bank),
	          .buffer_size(memory_bank_size),
	          .flow_ctrl_type(flow_ctrl_type),
	          .flow_ctrl_bypass(flow_ctrl_bypass),
              .mgmt_type(fb_mgmt_type),
              .fast_almost_empty(fast_almost_empty),
              .disable_static_reservations(disable_static_reservations),
              .reset_type(reset_type))
        shared_fcs
             (.clk(clk),
              .reset(reset),
              .active(shared_fb_fcs_active),
              .flit_valid(shared_fb_fcs_flit_valid),
              .flit_head(flit_head_q),
              .flit_tail(flit_tail_q),
              .flit_sel_ovc(shared_flit_sel_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .fc_event_valid(shared_fb_fc_event_valid),
              .fc_event_sel_ovc(shared_fc_event_sel_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .fc_active(shared_fb_fc_active[fc]),
              .empty_ovc(shared_empty_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .almost_full_ovc(shared_almost_full_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .full_ovc(shared_full_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]), 
              .full_prev_ovc(shared_full_prev_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .errors_ovc(shared_fcs_errors_ovc[fc*num_vcs_per_bank*2+:2*num_vcs_per_bank]));
    end
    endgenerate

   
   genvar ovc;
   generate
      for(ovc = 0; ovc < num_vcs; ovc = ovc + 1)
	  begin:ovcs 
	   wire vc_gnt;
	   assign vc_gnt = vc_gnt_ovc[ovc];
	   
	   wire [0:num_ports-1] vc_sel_ip;
	   assign vc_sel_ip = vc_sel_ovc_ip[ovc*num_ports:(ovc+1)*num_ports-1];
	   
	   wire [0:num_vcs-1] 	vc_sel_ivc;
	   assign vc_sel_ivc = vc_sel_ovc_ivc[ovc*num_vcs:(ovc+1)*num_vcs-1];
	  
	   wire			vc_sel_shared_ivc;
	   assign vc_sel_shared_ivc = vc_sel_ovc_shared_ivc[ovc];

	   wire 		empty;
	   assign empty = empty_ovc[ovc];
	   
	   wire 		full;
	   assign full = full_ovc[ovc];
	   
	   wire 		full_prev;
	   assign full_prev = full_prev_ovc[ovc];
	   
	   wire			allocated;
	   wire 		flit_sel;
	   wire 		elig;

	   vcr_ovc_ctrl
	     #(.num_vcs(num_vcs),
	       .num_ports(num_ports),
	       .sw_alloc_spec(sw_alloc_spec),
	       .elig_mask(elig_mask),
	       .reset_type(reset_type))
	   ovcc
	     (.clk(clk),
	      .reset(reset),
	      .vc_active(vc_active),
	      .vc_gnt(vc_gnt),
	      .vc_sel_ip(vc_sel_ip),
	      .vc_sel_ivc(vc_sel_ivc),
	      .vc_sel_shared_ivc(vc_sel_shared_ivc),
		  .sw_active(sw_active),
	      .sw_gnt(sw_gnt),
	      .sw_sel_ip(sw_sel_ip),
	      .sw_sel_ivc(sw_sel_ivc),
	      .sw_sel_shared_ivc(sw_sel_shared_ivc),
		  .flit_valid(flit_valid_q),
	      .flit_tail(flit_tail_q),
	      .flit_sel(flit_sel),
	      .elig(elig),
	      .full(full),
	      .full_prev(full_prev),
		  .allocated_ovc(allocated),
	      .empty(empty));
	   
	   assign flit_sel_ovc[ovc] = flit_sel;
	   assign elig_ovc[ovc] = elig;

	   wire			shared_vc_gnt;
	   assign shared_vc_gnt = vc_gnt_shared_ovc[ovc];

	   wire [0:num_ports-1] shared_vc_sel_ip;
	   assign shared_vc_sel_ip = vc_sel_shared_ovc_ip[ovc*num_ports:(ovc+1)*num_ports-1];
	   
	   wire [0:num_vcs-1] 	shared_vc_sel_ivc;
	   assign shared_vc_sel_ivc = vc_sel_shared_ovc_ivc[ovc*num_vcs:(ovc+1)*num_vcs-1];
	   
	   wire			shared_vc_sel_shared_ivc;
	   assign shared_vc_sel_shared_ivc = vc_sel_shared_ovc_shared_ivc[ovc];

	   wire 		shared_empty;
	   assign shared_empty = shared_empty_ovc[ovc];
	   
	   wire 		shared_full;
	   assign shared_full = shared_full_ovc[ovc];
	   
	   wire 		shared_full_prev;
	   assign shared_full_prev = shared_full_prev_ovc[ovc];
	   
	   wire 		shared_elig;
	   wire 		shared_flit_sel;
	   wire			shared_allocated;

	   vcr_ovc_ctrl
	     #(.num_vcs(num_vcs),
	       .num_ports(num_ports),
	       .sw_alloc_spec(sw_alloc_spec),
	       .elig_mask(elig_mask),
	       .reset_type(reset_type))
	   shared_ovcc
	     (.clk(clk),
	      .reset(reset),
	      .vc_active(shared_vc_active),
	      .vc_gnt(shared_vc_gnt),
	      .vc_sel_ip(shared_vc_sel_ip),
	      .vc_sel_ivc(shared_vc_sel_ivc),
	      .vc_sel_shared_ivc(shared_vc_sel_shared_ivc),
		  .sw_active(sw_active),
	      .sw_gnt(sw_gnt),
	      .sw_sel_ip(sw_sel_ip),
	      .sw_sel_ivc(sw_sel_ivc),
	      .sw_sel_shared_ivc(sw_sel_shared_ivc),
		  .flit_valid(flit_valid_q),
	      .flit_tail(flit_tail_q),
	      .flit_sel(shared_flit_sel),
	      .elig(shared_elig),
	      .full(shared_full),
	      .full_prev(shared_full_prev),
		  .allocated_ovc(shared_allocated),
	      .empty(shared_empty));
	  
	   assign shared_ovc_allocated[ovc] = shared_allocated;
	   assign shared_flit_sel_ovc[ovc] = shared_flit_sel;
	   assign shared_elig_ovc[ovc] = shared_elig;
	 end
   endgenerate
   
   wire	error_unmatched;
   
   generate
    if(sw_alloc_spec)
	    assign error_unmatched = 1'b0;
    else
	    assign error_unmatched = (((~shared_vc_q) & (~|flit_sel_ovc))|(shared_vc_q & (~|shared_flit_sel_ovc))) & flit_valid_q;
   endgenerate
   
   wire	flit_multisel;
   c_multi_hot_det
     #(.width(num_vcs))
   flit_multisel_mhd
     (.data(flit_sel_ovc),
      .multi_hot(flit_multisel));
   
   wire	shared_flit_multisel;
   c_multi_hot_det
     #(.width(num_vcs))
   shared_flit_multisel_mhd
     (.data(shared_flit_sel_ovc),
      .multi_hot(shared_flit_multisel));
   
   wire	error_multimatch;
   assign error_multimatch = flit_valid_q & (flit_multisel | shared_flit_multisel | (|(flit_sel_ovc & shared_flit_sel_ovc)));
   
  
   //---------------------------------------------------------------------------
   // output staging
   //---------------------------------------------------------------------------
   wire	cho_active;
   assign cho_active = flit_valid_q;

   wire [0:num_vcs-1] flit_sel_ovc_o;
   assign flit_sel_ovc_o = shared_flit_sel_ovc | flit_sel_ovc;

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
	  .flit_valid_in(flit_sent),
      .flit_head_in(flit_head_q),
      .flit_tail_in(flit_tail_q),
      .flit_data_in(flit_data),
      .flit_sel_in_ovc(flit_sel_ovc_o),
      .channel_out(channel_out));
   
	     
	   wire shared_vc_out_s, shared_vc_out_q;
	   assign shared_vc_out_s = shared_vc_q;
	   c_dff
	   #(.width(1),
		 .reset_type(reset_type))
	   shared_vc_dq
	    (.clk(clk),
		 .reset(reset),
		 .active(cho_active),
		 .d(shared_vc_out_s),
		 .q(shared_vc_out_q));

   assign shared_vc_out = shared_vc_out_q;

   //---------------------------------------------------------------------------
   // error checking
   //---------------------------------------------------------------------------
   // synopsys translate_off
   always @(posedge clk)
   begin
	if(error_unmatched)
	  $display("ERROR: Unmatched flit in module %m.");
	if(error_multimatch)
	  $display("ERROR: Multiply matched flit in module %m.");
   end
   
   // synopsys translate_on
   generate
    if(error_capture_mode != `ERROR_CAPTURE_MODE_NONE)
	begin   
	   wire [0:2+num_vcs*2-1] errors_s, errors_q;
	   assign errors_s = {error_unmatched, error_multimatch, fcs_errors_ovc};
	   c_err_rpt
	     #(.num_errors(2+num_vcs*2),
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
