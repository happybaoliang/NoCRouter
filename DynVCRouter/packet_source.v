//==============================================================================
// pseudo-random packet source
//==============================================================================

module packet_source (clk, reset, router_address, channel, shared_vc, memory_bank_grant, 
			flit_valid, flow_ctrl, credit_for_shared, run, error);
   
`include "c_functions.v"
`include "c_constants.v"
`include "rtr_constants.v"
`include "vcr_constants.v"
   
   parameter initial_seed = 0;
   
   // maximum number of packets to generate (-1 = no limit)
   parameter max_packet_count = 1000;
   
   // packet injection rate (percentage of cycles)
   parameter packet_rate = 25;
   
   // width of packet count register
   parameter packet_count_reg_width = 32;

   // select packet length mode (0: uniform random, 1: bimodal)
   parameter packet_length_mode = 0;
   
   // select network topology
   parameter topology = `TOPOLOGY_FBFLY;
   
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
   parameter num_vcs_per_class = 2;
   
   // number of VCs
   localparam num_vcs = num_packet_classes * num_vcs_per_class;
   
   // width required to select individual VC
   localparam vc_idx_width = clogb(num_vcs);
  
   // total number of nodes
   parameter num_nodes = 64;
   
   // number of nodes per router (a.k.a. concentration factor)
   parameter num_nodes_per_router = 4;

   // total number of routers
   localparam num_routers = (num_nodes + num_nodes_per_router - 1) / num_nodes_per_router;
   
   // number of dimensions in network
   parameter num_dimensions = 2;
   
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
   
   // total buffer size per memory bank
   localparam memory_bank_size = buffer_size/num_ports;
 
   // number of VCs of each memory bank
   localparam num_vcs_per_bank = num_vcs/num_ports;

   // width required to select individual port
   localparam port_idx_width = clogb(num_ports);
   
   // width required to select individual node at current router
   localparam node_addr_width = clogb(num_nodes_per_router);
   
   // width of global addresses
   localparam addr_width = router_addr_width + node_addr_width;
   
   // select packet format
   parameter packet_format = `PACKET_FORMAT_EXPLICIT_LENGTH;
   
   // select type of flow control
   parameter flow_ctrl_type = `FLOW_CTRL_TYPE_CREDIT;
   
   // make incoming flow control signals bypass the output VC state tracking 
   // logic
   parameter flow_ctrl_bypass = 1;
   
   // width of flow control signals
   localparam flow_ctrl_width = (flow_ctrl_type == `FLOW_CTRL_TYPE_CREDIT) ? (1 + vc_idx_width) : -1;
   
   // maximum payload length (in flits)
   parameter max_payload_length = 4;
   
   // minimum payload length (in flits)
   parameter min_payload_length = 0;
   
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
   
   // width required for lookahead routing information
   localparam lar_info_width = port_idx_width + resource_class_idx_width;
   
   // select routing function type
   parameter routing_type = `ROUTING_TYPE_PHASED_DOR;
   
   // total number of bits required for storing routing information
   localparam dest_info_width=(routing_type==`ROUTING_TYPE_PHASED_DOR)?(num_resource_classes*router_addr_width+node_addr_width):-1;
   
   // total number of bits required for routing-related information
   localparam route_info_width = lar_info_width + dest_info_width;
   
   // total number of bits required for storing header information
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
   
   // which router port is this packet source attached to?
   parameter port_id = 0;
   
   // which dimension does the current input port belong to?
   localparam curr_dim = port_id / num_neighbors_per_dim;
   
   // maximum packet length (in flits)
   localparam max_packet_length = 1 + max_payload_length;
   
   // total number of bits required to represent maximum packet length
   localparam packet_length_width = clogb(max_packet_length);
   
   parameter reset_type = `RESET_TYPE_ASYNC;
   
   input clk;
   input reset;
   
   input [0:router_addr_width-1] 	router_address;
   
   output [0:channel_width-1] 	 	channel;
   wire [0:channel_width-1] 	 	channel;
  
   output			 				shared_vc;
   wire				 				shared_vc;

   // The total number of shared memory bank is equal to the number of ports.
   input [0:num_ports-1]	 		memory_bank_grant;

   // This signal is used for the testbench to count the number of flit sent by this source. 
   output 			 				flit_valid;
   wire 			 				flit_valid;
   
   input [0:flow_ctrl_width-1] 	 	flow_ctrl;

   input 			 				credit_for_shared;
   
   input 			 				run;
   
   output 			 				error;
   wire 			 				error;
   
   integer 			 				seed = initial_seed;
   
   integer 			 				i;
   
   reg 				 				new_packet;
 

   wire								shared_vc_out;

   // whether a packet should be generated by the source at each clock cycle. 
   always @(posedge clk, posedge reset)
   begin
	new_packet <= ($dist_uniform(seed, 0, 9999) < packet_rate) && run && !reset;// && (router_address == 2 | router_address == 4);//TODO
   end
   
   wire waiting_packet_count_zero;

   // packet_ready: whether a packet should be generated and put into the source buffer at each cycle. 
   wire packet_ready;
   assign packet_ready = new_packet & ~waiting_packet_count_zero;
   
   // whether the number of packet generated has reach the maximal value.
   // the waiting_packet_count decrease whenever 'the packet_ready' signal asserts, 
   // meanwhile, the 'waiting_packet_count_zero' single is updated.
   generate
    if(max_packet_count >= 0)
	begin   
	   wire [0:packet_count_reg_width-1] waiting_packet_count_s;
	   wire [0:packet_count_reg_width-1] waiting_packet_count_q;
	   assign waiting_packet_count_s = waiting_packet_count_q - packet_ready;
	   c_dff
	     #(.width(packet_count_reg_width),
	       .reset_value(max_packet_count),
	       .reset_type(reset_type))
	   waiting_packet_countq
	     (.clk(clk),
	      .reset(reset),
	      .active(1'b1),
	      .d(waiting_packet_count_s),
	      .q(waiting_packet_count_q));
	   
	   assign waiting_packet_count_zero = ~|waiting_packet_count_q;
	end
    else
		assign waiting_packet_count_zero = 1'b0;
   endgenerate
   
   // 'waiting_packet_count_*' singal mean the number of packets has not been generated. 
   // Whereas, 'ready_packet_count_*' signals mean the number of packets at the source node 
   // and waiting to be injected. this part of source code generate the required singal 'ready_packet_count_zero'.
   wire 				 				packet_sent;
   wire					 				flit_pending_q;
   wire 				 				ready_packet_count_zero;
   wire [0:packet_count_reg_width-1] 	ready_packet_count_s;
   wire [0:packet_count_reg_width-1] 	ready_packet_count_q;
   // 'ready_packet_count_s' means the number of packet queued at the buffer of source node. When the packet has 
   // been fully injected, this counted decrease by one, whereas, it increase by one when 'packet_ready' asserts.
   assign ready_packet_count_s = run 
		? (ready_packet_count_q - ((!flit_pending_q || packet_sent) && !ready_packet_count_zero) + packet_ready) 
		: {packet_count_reg_width{1'b0}};
   c_dff
     #(.width(packet_count_reg_width),
       .reset_type(reset_type))
   ready_packet_countq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(ready_packet_count_s),
      .q(ready_packet_count_q));
   
   assign ready_packet_count_zero = ~|ready_packet_count_q;
  
   // generate the required control singals and data signals connected to the injection router. 
   wire 				 		flit_head;
   wire 				 		flit_tail;
   wire [0:flit_data_width-1] 	flit_data;
   wire [0:num_vcs-1] 			sel_ovc;
   rtr_channel_output
     #(.num_vcs(num_vcs),
       .packet_format(packet_format),
       .enable_link_pm(enable_link_pm),
       .flit_data_width(flit_data_width),
       .reset_type(reset_type))
   cho
     (.clk(clk),
      .reset(reset),
      .active(flit_valid),
      .flit_valid_in(flit_valid),
      .flit_head_in(flit_head),
      .flit_tail_in(flit_tail),
      .flit_data_in(flit_data),
      .flit_sel_in_ovc(sel_ovc),
      .channel_out(channel));

   wire [0:flow_ctrl_width-1] shared_flow_ctrl;
   assign shared_flow_ctrl = credit_for_shared ? flow_ctrl : {flow_ctrl_width{1'b0}};

   wire [0:flow_ctrl_width-1] private_flow_ctrl;
   assign private_flow_ctrl = credit_for_shared ? {flow_ctrl_width{1'b0}} : flow_ctrl;

   // handle the necessary flow control singals from the injection router.
   wire					 fc_active;
   wire 				 fc_event_valid;
   wire [0:num_vcs-1] 	 fc_event_sel_ovc;
   rtr_flow_ctrl_input
     #(.num_vcs(num_vcs),
       .flow_ctrl_type(flow_ctrl_type),
       .reset_type(reset_type))
   fci
     (.clk(clk),
      .reset(reset),
      .active(fc_active),
      .flow_ctrl_in(private_flow_ctrl),
      .fc_event_valid_out(fc_event_valid),
      .fc_event_sel_out_ovc(fc_event_sel_ovc));

   wire	[0:num_ports-1]	 shared_fc_active;
   wire 				 shared_fc_event_valid;
   wire [0:num_vcs-1] 	 shared_fc_event_sel_ovc;
   rtr_flow_ctrl_input
     #(.num_vcs(num_vcs),
       .flow_ctrl_type(flow_ctrl_type),
       .reset_type(reset_type))
   shared_fci
     (.clk(clk),
      .reset(reset),
      .active(|shared_fc_active),
      .flow_ctrl_in(shared_flow_ctrl),
      .fc_event_valid_out(shared_fc_event_valid),
      .fc_event_sel_out_ovc(shared_fc_event_sel_ovc));

   // 'flit_*_s' signals are equal to the corresponding 'flit_*' singals, 
   // these signals will be delayed for a cycle and used for the flow_control_tracker
   //  module to update the credit statistics. All these signals and the signals connected
   // to rtr_output_channel based on the 'flit_*' singals.
   wire  flit_valid_s, flit_valid_q;
   assign flit_valid_s = flit_valid;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_validq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(flit_valid_s),
      .q(flit_valid_q));
   
   wire  flit_head_s, flit_head_q;
   assign flit_head_s = flit_head;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_headq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(flit_head_s),
      .q(flit_head_q));
   
   wire  flit_tail_s, flit_tail_q;
   assign flit_tail_s = flit_tail;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_tailq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(flit_tail_s),
      .q(flit_tail_q));
   
   wire [0:num_vcs-1] flit_sel_ovc_s, flit_sel_ovc_q;
   assign flit_sel_ovc_s = sel_ovc;
   c_dff
     #(.width(num_vcs),
       .reset_type(reset_type))
   flit_sel_ovcq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(flit_sel_ovc_s),
      .q(flit_sel_ovc_q));
   
   // the delayed control singals are used to update the corresponding credit information of the injection router.
   // Then, the VC occupancy information can be derived from these statistics.
   wire [0:num_vcs-1] 			 full_ovc;
   wire [0:num_vcs-1] 			 empty_ovc;
   wire							 fcs_active;
   wire 						 shared_vc_s;
   wire							 shared_vc_q;
   wire [0:num_vcs-1] 			 full_prev_ovc;
   wire [0:num_vcs*2-1] 		 fcs_errors_ovc;
   wire [0:num_vcs-1] 			 almost_full_ovc;
  

   assign fcs_active = (~shared_vc & flit_valid_q) | fc_event_valid;

   wire fc_flit_valid;
   assign fc_flit_valid = (~shared_vc) & flit_valid_q & (|flit_sel_ovc_q);

   rtr_fc_state
     #(.num_vcs(num_vcs),
       .buffer_size(buffer_size),
       .flow_ctrl_type(flow_ctrl_type),
       .flow_ctrl_bypass(flow_ctrl_bypass),
       .mgmt_type(fb_mgmt_type),
       .disable_static_reservations(disable_static_reservations),
       .reset_type(reset_type))
   fcs
     (.clk(clk),
      .reset(reset),
      .active(fcs_active),
      .flit_valid(fc_flit_valid),
      .flit_head(flit_head_q),
      .flit_tail(flit_tail_q),
      .flit_sel_ovc(flit_sel_ovc_q),
      .fc_event_valid(fc_event_valid),
      .fc_event_sel_ovc(fc_event_sel_ovc),
      .fc_active(fc_active),
      .empty_ovc(empty_ovc),
      .almost_full_ovc(almost_full_ovc),
      .full_ovc(full_ovc),
      .full_prev_ovc(full_prev_ovc),
      .errors_ovc(fcs_errors_ovc));

   wire [0:num_vcs-1] 			 shared_full_ovc;
   wire [0:num_vcs-1] 			 shared_empty_ovc;
   wire [0:num_vcs-1] 			 shared_full_prev_ovc;
   wire [0:num_vcs*2-1] 		 shared_fcs_errors_ovc;
   wire [0:num_vcs-1] 			 shared_almost_full_ovc;

    genvar fc;
    generate
	for (fc=0; fc<num_ports; fc=fc+1)
    begin:fcss
        wire shared_fb_fcs_flit_valid;
        assign shared_fb_fcs_flit_valid = shared_vc & flit_valid_q & (|flit_sel_ovc_q[fc*num_vcs_per_bank+:num_vcs_per_bank]);

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
              .disable_static_reservations(disable_static_reservations),
              .reset_type(reset_type))
        shared_fcs
             (.clk(clk),
              .reset(reset),
              .active(shared_fb_fcs_active),
              .flit_valid(shared_fb_fcs_flit_valid),
              .flit_head(flit_head_q),
              .flit_tail(flit_tail_q),
              .flit_sel_ovc(flit_sel_ovc_q[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .fc_event_valid(shared_fb_fc_event_valid),
              .fc_event_sel_ovc(shared_fc_event_sel_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .fc_active(shared_fc_active[fc]),
              .empty_ovc(shared_empty_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .almost_full_ovc(shared_almost_full_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .full_ovc(shared_full_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .full_prev_ovc(shared_full_prev_ovc[fc*num_vcs_per_bank+:num_vcs_per_bank]),
              .errors_ovc(shared_fcs_errors_ovc[fc*num_vcs_per_bank*2+:2*num_vcs_per_bank]));
   end
   endgenerate


   // this part source code is used to generate the neccesaary full/empty indicator and eligibility of each output VC. 
   wire [0:num_vcs-1]	elig_ovc;
   wire [0:num_vcs-1]	shared_elig_ovc;
   
   genvar				ovc;
   generate
    for(ovc = 0; ovc < num_vcs; ovc = ovc + 1)
	begin:ovcs
	   wire allocated;
	   wire shared_allocated;
	   wire allocated_s, allocated_q;
	   assign allocated_s = allocated;
	   
	   wire shared_allocated_s, shared_allocated_q;
	   assign shared_allocated_s = shared_allocated;
	   c_dff
	     #(.width(1),
	       .reset_type(reset_type))
	   allocatedq
	     (.clk(clk),
	      .reset(reset),
	      .active(1'b1),
	      .d(allocated_s),
	      .q(allocated_q));

	   c_dff
	     #(.width(1),
	       .reset_type(reset_type))
	   shared_allocatedq
	     (.clk(clk),
	      .reset(reset),
	      .active(1'b1),
	      .d(shared_allocated_s),
	      .q(shared_allocated_q));

       // if flit is valid and the ovc for this flit is ready to accept new flits, 
       //then we can infer that this flit must be sent this cycle.
	   wire flit_sent;
	   assign flit_sent = flit_valid_q & flit_sel_ovc_q[ovc];
	   
       // this allocated signal only update when the tail flit has been transmitted. 
	   assign allocated = flit_sent ? (~shared_vc_q) & (~flit_tail_q) : allocated_q;

	   assign shared_allocated = flit_sent ? (~flit_tail_q) & shared_vc_q : shared_allocated_q;

	   wire empty;
	   assign empty = empty_ovc[ovc];

	   wire shared_empty;
	   assign shared_empty = shared_empty_ovc[ovc];

	   wire full;
	   assign full = full_ovc[ovc];
	   
	   wire shared_full;
	   assign shared_full = shared_full_ovc[ovc];

	   wire elig;
	   wire shared_elig;

	   case(elig_mask)
	     `ELIG_MASK_NONE:
		 begin
	       assign elig = ~allocated;
		   assign shared_elig = ~shared_allocated;
		 end
	     `ELIG_MASK_FULL:
		 begin
	       assign elig = ~allocated & ~full;
		   assign shared_elig = ~shared_allocated & ~shared_full;
		 end
	     `ELIG_MASK_USED:
		 begin
	       assign elig = ~allocated & empty;
		   assign shared_elig = ~shared_allocated & shared_empty;
	 	 end
	   endcase
	   assign elig_ovc[ovc] = elig;
	   assign shared_elig_ovc[ovc] = memory_bank_grant[ovc/num_vcs_per_bank] ? shared_elig : 1'b0;
	end
   endgenerate


   // this part of source code utilize the mux module to select the corresponding full/eligible singals for the ovc.
   // 'sel_ovc' was generated at the end of this file by a decoder. This signal is used to generate the full/eligible signals.
   wire 	full;
   c_select_1ofn
     #(.num_ports(num_vcs),
       .width(1))
   full_sel
     (.select(sel_ovc),
      .data_in(full_ovc),
      .data_out(full));

   wire 	shared_full;
   c_select_1ofn
     #(.num_ports(num_vcs),
       .width(1))
   shared_full_sel
     (.select(sel_ovc),
      .data_in(shared_full_ovc),
      .data_out(shared_full));

   wire 	elig;
   c_select_1ofn
     #(.num_ports(num_vcs),
       .width(1))
   elig_sel
     (.select(sel_ovc),
      .data_in(elig_ovc),
      .data_out(elig));

   wire 	shared_elig;
   c_select_1ofn
     #(.num_ports(num_vcs),
       .width(1))
   shared_elig_sel
     (.select(sel_ovc),
      .data_in(shared_elig_ovc),
      .data_out(shared_elig));

   // if there are pending flits, and the injection router is not full, the corresponding OVC is not full, then we can
   // infer that the flit must be successfully transmitted. 
   wire 	flit_sent;
   assign flit_sent = flit_pending_q & ~(shared_vc_q ? shared_full : full) & ((shared_vc_q ? shared_elig : elig) | ~flit_head);
  
   // a flit is valid only when this flit can be sent and the corresponding information (e.g. routing info) is valid.  
   wire 	flit_kill;
   assign flit_valid = flit_sent & ~flit_kill;
   
   // 'packet_sent' signal asserts when the sent flit is a tail flit.
   assign packet_sent = flit_tail & flit_sent;
   
   // update the 'flit_pending' singal. 'flit_pending_s' signal asserts when the source queue is not empty or there is
   // partial transmitted packet.
   wire 	flit_pending_s;
   assign flit_pending_s = (flit_pending_q & ~packet_sent) | ~ready_packet_count_zero;
   c_dff
     #(.width(1),
       .reset_type(reset_type))
   flit_pendingq
     (.clk(clk),
      .reset(reset),
      .active(1'b1),
      .d(flit_pending_s),
      .q(flit_pending_q));
  
   // fill the content of each flit with random number. 
   // added by myself, record the packet number of each source.
   reg [0:packet_count_reg_width-1] pkt_sent;

   reg [0:flit_data_width-1] data_q;
   always @(posedge clk, posedge reset)
     begin
	if(reset | flit_valid)
	  for(i = 0; i < flit_data_width; i = i + 1)
	    data_q[i] <= $dist_uniform(seed, 0, 1);
     end
   
   // fill the content of header_info of each flit. 
   // The header_info includes dest addr, lar_info, length, tail/head, etc.
   // only the 'flit_data' of header flit includes the header_info. 
   wire [0:header_info_width-1] header_info;
   assign flit_data[0:header_info_width-1] = flit_head ? header_info : data_q[0:header_info_width-1];
   //   assign flit_data[header_info_width:flit_data_width-1] = data_q[header_info_width:flit_data_width-1];
   assign flit_data[header_info_width:flit_data_width-router_addr_width-packet_count_reg_width-1]
		=data_q[header_info_width:flit_data_width-router_addr_width-packet_count_reg_width-1];
   assign flit_data[flit_data_width-router_addr_width-packet_count_reg_width:flit_data_width-router_addr_width-1]
		=pkt_sent[0:packet_count_reg_width-1];
   assign flit_data[flit_data_width-router_addr_width:flit_data_width-1]=router_address[0:2*dim_addr_width-1];
 
   // This part of code checks whether a specific packet class (#message_class X #resource_class) request
   // their specific output virtual channel.
   reg [0:dest_info_width-1] dest_info;
   wire [0:num_message_classes*num_resource_classes-1] sel_mc_orc;
   c_mat_mult
     #(.dim1_width(num_message_classes*num_resource_classes),
       .dim2_width(num_vcs_per_class),
       .dim3_width(1),
       .prod_op(`BINARY_OP_AND),
       .sum_op(`BINARY_OP_OR))
   sel_mc_orc_mmult
     (.input_a(sel_ovc),
      .input_b({num_vcs_per_class{1'b1}}),
      .result(sel_mc_orc));
   
   // This part of code checks whether a specific message class request its specific resource class.
   wire [0:num_message_classes-1] 		       sel_mc;
   c_mat_mult
     #(.dim1_width(num_message_classes),
       .dim2_width(num_resource_classes),
       .dim3_width(1),
       .prod_op(`BINARY_OP_AND),
       .sum_op(`BINARY_OP_OR))
   sel_mc_mmult
     (.input_a(sel_mc_orc),
      .input_b({num_resource_classes{1'b1}}),
      .result(sel_mc));
   
   // This part of code generate the reversed request vector according to the sel_mc_orc;
   wire [0:num_resource_classes*num_message_classes-1] sel_orc_mc;
   c_interleave
     #(.width(num_message_classes*num_resource_classes),
       .num_blocks(num_message_classes))
   sel_orc_mc_intl
     (.data_in(sel_mc_orc),
      .data_out(sel_orc_mc));
   
   // This part of code generates the specific output resource class for each message class.
   wire [0:num_resource_classes-1] 		       sel_orc;
   c_mat_mult
     #(.dim1_width(num_resource_classes),
       .dim2_width(num_message_classes),
       .dim3_width(1),
       .prod_op(`BINARY_OP_AND),
       .sum_op(`BINARY_OP_OR))
   sel_orc_mmult
     (.input_a(sel_orc_mc),
      .input_b({num_message_classes{1'b1}}),
      .result(sel_orc));
   
   // generate the routing information. The message class refers to the request/reply information.
   // The 'resource' refer to the minimal and adaptive. 
   // These information are quite important for the routing algorithm to avoid deadlock.
   // To avoid deadlock, we should ensure that, at least one VC is reserved for each class.
   wire [0:num_ports-1] 		   route_op;
   wire [0:num_resource_classes-1] route_orc;
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
      .sel_mc(sel_mc),
      .sel_irc(sel_orc),
      .dest_info(dest_info),
      .route_op(route_op),
      .route_orc(route_orc));
   
   // the output port should be encoded to save space.
   wire [0:port_idx_width-1]	route_port;
   c_encode
     #(.num_ports(num_ports))
   route_port_enc
     (.data_in(route_op),
      .data_out(route_port));
  
   // The next hop routing information might be computed with the look ahead routing.
   // In other words, the routing information of next hold will go along with the flit,
   // and need not to be recomputed when the flit arrives at the next router and written into the buffer. 
   wire [0:lar_info_width-1] 		       lar_info;
   assign lar_info[0:port_idx_width-1] = route_port;
  
   // this part fill the lar_info with the next hold resource information. 
   generate
    if(num_resource_classes > 1)
	begin
	   wire [0:resource_class_idx_width-1] route_rcsel;
	   c_encode
	     #(.num_ports(num_resource_classes))
	   route_rcsel_enc
	     (.data_in(route_orc),
	      .data_out(route_rcsel));
	   assign lar_info[port_idx_width:port_idx_width+resource_class_idx_width-1] = route_rcsel;
	end
   endgenerate
   
   // the lar_info is part of header_info.
   assign header_info[0:lar_info_width-1] = lar_info;
   
   // the dest addr is also a part of header_info.
   wire [0:num_resource_classes*router_addr_width-1] dest_info_addresses;
   assign dest_info_addresses = dest_info[0:num_resource_classes*router_addr_width-1];
   
   // the resource class of destination should also be selected from the group.
   wire [0:router_addr_width-1]		rc_dest;
   c_select_1ofn
     #(.num_ports(num_resource_classes),
       .width(router_addr_width))
   rc_dest_sel
     (.select(sel_orc),
      .data_in(dest_info_addresses),
      .data_out(rc_dest));
   
   // the addr_width includes the router address and node addr. 
   // if there is only one node connected to each router, 
   // then the source_address of a packet is the address of its injection router.
   // Or else, the source_address of a packet is the address of the node that generates this packet.
   wire [0:addr_width-1] 			     source_address;
   assign source_address[0:router_addr_width-1] = router_address;
   
   wire [0:router_addr_width-1] 		     curr_dest_addr;
  
   // this part of code update the 'flit_kill' singal, 
   // the default port_id the node connected to is zero. 
   generate
    case(routing_type)
	`ROUTING_TYPE_PHASED_DOR:
	  begin
	     if(port_id >= (num_ports - num_nodes_per_router))
	     begin
		  assign flit_kill = (dest_info[dest_info_width-addr_width:dest_info_width-1] == source_address);
	     end
	     else
	     begin
		  case(connectivity)
		    `CONNECTIVITY_LINE, `CONNECTIVITY_RING:
		    begin
			 wire flit_kill_base;
			 if(connectivity == `CONNECTIVITY_LINE)
			   assign flit_kill_base
			     = (((port_id % 2) == 0) && (rc_dest[curr_dim*dim_addr_width:(curr_dim+1)*dim_addr_width-1] <
				 router_address[curr_dim*dim_addr_width:(curr_dim+1)*dim_addr_width-1])) ||
			       (((port_id % 2) == 1) && (rc_dest[curr_dim*dim_addr_width:(curr_dim+1)*dim_addr_width-1] >
				 router_address[curr_dim*dim_addr_width:(curr_dim+1)*dim_addr_width-1]));
			 else
			   assign flit_kill_base = 1'b0;
			 
			 if((dim_order == `DIM_ORDER_ASCENDING) && (curr_dim > 0))
 			 begin
			      assign flit_kill = (rc_dest[0:curr_dim*dim_addr_width-1] 
						!= router_address[0:curr_dim*dim_addr_width-1]) || flit_kill_base;
			 end
			 else if((dim_order == `DIM_ORDER_DESCENDING) && (curr_dim < (num_dimensions - 1)))
			 begin
			      assign flit_kill = (rc_dest[(curr_dim+1)*dim_addr_width:router_addr_width-1] 
						!= router_address[(curr_dim+1)*dim_addr_width:router_addr_width-1]) || flit_kill_base;
			 end
			 else if(dim_order == `DIM_ORDER_BY_CLASS)
			 begin
			      // FIXME: add implementation here!
			      initial
				  begin
				   $display({"ERROR: The packet source module ", "does not properly support class-",
					     "based dimension order traversal ", "in the flit kill logic yet."});
				   $stop;
			 	  end
			 end
			 else
			 begin
			      assign flit_kill = flit_kill_base;
			 end
		    end
		    
		    `CONNECTIVITY_FULL:
		     begin
			 assign flit_kill
			   = ((dim_order == `DIM_ORDER_ASCENDING) && (rc_dest[0:(curr_dim+1)*dim_addr_width-1] !=
			       router_address[0:(curr_dim+1)*dim_addr_width-1])) ||
			     ((dim_order == `DIM_ORDER_DESCENDING) && (rc_dest[curr_dim*dim_addr_width:
				       router_addr_width-1] != router_address[curr_dim*dim_addr_width:router_addr_width-1]));
		     end
		  endcase
	     end
	  end
      endcase
   endgenerate
   
   integer d;
   
   // the next code segment generate the random destination address.
   reg [0:router_addr_width-1] random_router_address;
   
   generate
   // if the number of nodes connected to a single router is greater than one, the next code segment
   // compute the related stochstic destination node address and fill them into corresponding fields.
    if(num_nodes_per_router > 1)
	begin
	   wire [0:node_addr_width-1] node_address;
	   if(port_id >= (num_ports - num_nodes_per_router))
	     assign node_address = port_id - (num_ports - num_nodes_per_router);
	   else
	     assign node_address = {node_addr_width{1'b0}};

	   assign source_address[router_addr_width:addr_width-1] = node_address;
	   
	   reg [0:node_addr_width-1]  random_node_address;
	   always @(posedge clk, posedge reset)
	   begin
		if(reset | packet_sent)
		begin
		     for(d = 0; d < num_dimensions; d = d + 1)
		       random_router_address[d*dim_addr_width +: dim_addr_width] 
			= (router_address[d*dim_addr_width +: dim_addr_width] +
			    $dist_uniform(seed, 0, num_routers_per_dim-1)) % num_routers_per_dim;

		     random_node_address = (node_address + $dist_uniform(seed,((port_id >= (num_ports - num_nodes_per_router)) &&
					 	(random_router_address == router_address)) ? 1 : 0, num_nodes_per_router - 1)) % num_nodes_per_router;
		     dest_info[dest_info_width-addr_width:dest_info_width-1] = {random_router_address, random_node_address};
		end		
	   end
	end
    else // fill the corresponding destionation field.
	begin
	   always @(posedge clk, posedge reset)
	    begin
		if(reset | packet_sent)
		  begin
		     for(d = 0; d < num_dimensions - 1; d = d + 1)
		       random_router_address[d*dim_addr_width +: dim_addr_width]
			 	= (router_address[d*dim_addr_width +: dim_addr_width] + $dist_uniform(seed, 0, num_routers_per_dim-1)) 
					% num_routers_per_dim;

		     random_router_address[router_addr_width-dim_addr_width:router_addr_width-1]
		       = router_address[router_addr_width-dim_addr_width:router_addr_width-1];
		     
			 random_router_address[router_addr_width-dim_addr_width:router_addr_width-1]
		       = (router_address[router_addr_width-dim_addr_width:router_addr_width-1] +
			  $dist_uniform(seed,((port_id >= (num_ports - num_nodes_per_router)) && (random_router_address == 
					  router_address)) ? 1 : 0, num_routers_per_dim - 1)) % num_routers_per_dim;
		    // TODO
			dest_info[dest_info_width-addr_width:dest_info_width-1] = 0;
			//dest_info[dest_info_width-addr_width:dest_info_width-1] = ((router_address[0:dim_addr_width-1]*num_routers_per_dim
			// + router_address[dim_addr_width:router_addr_width-1]) + 1) % num_routers_per_dim;
			//dest_info[dest_info_width-addr_width:dest_info_width-1] = random_router_address;
		  end
	     end
	end
      
    // if the resource class is greater than one, we should also compute the random resource class.
    if(num_resource_classes > 1)
	begin
	   reg [0:router_addr_width-1] last_router_address;
	   reg [0:router_addr_width-1] random_intm_address;
	   always @(random_router_address)
	   begin
		last_router_address = random_router_address;
		for(i = num_resource_classes - 2; i >= 0; i = i - 1)
		begin
		     for(d = 0; d < num_dimensions - 1; d = d + 1)
		       random_intm_address[d*dim_addr_width +: dim_addr_width]
			 	= (last_router_address[d*dim_addr_width +: dim_addr_width] +
			    	$dist_uniform(seed, 0, num_routers_per_dim-1)) % num_routers_per_dim;

		     random_intm_address[router_addr_width-dim_addr_width:router_addr_width-1]
		       = last_router_address[router_addr_width-dim_addr_width:router_addr_width-1];
		     
			 random_intm_address[router_addr_width-dim_addr_width:router_addr_width-1]
		       = (last_router_address[router_addr_width-dim_addr_width:router_addr_width-1] +
			  	$dist_uniform(seed, (random_router_address == last_router_address) ? 1 : 0, 
					num_routers_per_dim - 1)) % num_routers_per_dim;
		     
			 dest_info[i*router_addr_width +: router_addr_width] = random_intm_address;
		     
			 last_router_address = random_intm_address;
		  end
	     end
	end
     
    // fill the header_info filed of each packet with dest_info. 
    assign header_info[lar_info_width:route_info_width-1] = dest_info;
     
    // generate the head/tail signal according to the packet length distribution. 
    if(max_payload_length > 0)
	begin
	   reg [0:packet_length_width-1] random_length_q;
	   reg [0:packet_length_width-1] flit_count_q;
	   reg 				 tail_q;
       // update the flit_count_q and tail_q each clock cycle.
	   always @(posedge clk, posedge reset)
	   begin
		case(packet_length_mode)
		  0:
		    random_length_q <= $dist_uniform(seed, min_payload_length, max_payload_length);
		  1:
		    random_length_q <= ($dist_uniform(seed, 0, 1) < 1) ? min_payload_length : max_payload_length;
		endcase
		if(reset)
		  begin
		     flit_count_q <= min_payload_length;
		     tail_q <= (min_payload_length == 0);
		  end
		else if(packet_sent)
		  begin
		     flit_count_q <= random_length_q;
		     tail_q <= ~|random_length_q;
		  end
		else if(flit_sent)
		  begin
		     flit_count_q <= flit_count_q - |flit_count_q;
		     tail_q <= ~|(flit_count_q - |flit_count_q);
		  end
	     end
	   
       // update flit_head, the next flit is a header flit if the previous packet has been sent, or this flit is the first flit.
	   wire head_s, head_q;
	   assign head_s = (head_q & ~flit_sent) | packet_sent;
	   c_dff
	     #(.width(1),
	       .reset_value(1'b1),
	       .reset_type(reset_type))
	   headq
	     (.clk(clk),
	      .reset(reset),
	      .active(1'b1),
	      .d(head_s),
	      .q(head_q));

	   assign shared_vc_s = head_s ? shared_vc_out : shared_vc_q;
	   c_dff
	     #(.width(1),
	       .reset_value(1'b1),
	       .reset_type(reset_type))
	   shared_vcq
	     (.clk(clk),
	      .reset(reset),
	      .active(1'b1),
	      .d(shared_vc_s),
	      .q(shared_vc_q));

		wire shared_vcq_s, shared_vcq_q;
   		assign shared_vcq_s = shared_vc_q;
   		c_dff
     	#(.width(1),
		  .reset_type(reset_type))
		shared_vcqq
		 (.clk(clk),
		  .reset(1'b0),
          .active(flit_valid),
          .d(shared_vcq_s),
          .q(shared_vcq_q));

       // the head and tail information connected to the injeciton router.	   
	   assign flit_head = head_q;
	   assign flit_tail = tail_q;
	   assign shared_vc = shared_vcq_q;

       // whether the packet length be stored in the header_info.
	   if((packet_format == `PACKET_FORMAT_EXPLICIT_LENGTH) && (payload_length_width > 0))
	   begin
		wire [0:payload_length_width-1] payload_length;
		assign payload_length = (flit_count_q - min_payload_length);
		assign header_info[route_info_width:route_info_width+payload_length_width-1] = payload_length;
	   end
	end
    else
	begin
	   assign flit_head = 1'b1;
	   assign flit_tail = 1'b1;
	end
      
    // if the number of VC is greater than one, we should also select a output vc for each packet randomly.
    if(num_vcs > 1)
	begin
	   reg random_shared;
	   reg [0:vc_idx_width-1] random_vc;
	   always @(posedge clk, posedge reset)
	   begin
		if(reset | packet_sent)
		begin
			random_shared <= $dist_uniform(seed, 0, 1);
			random_vc <= $dist_uniform(seed, 0, num_vcs-1);
		end
	   end
	   
	   c_decode
	     #(.num_ports(num_vcs))
	   sel_ovc_dec
	     (.data_in(random_vc),
	      .data_out(sel_ovc));

		wire [0:num_ports-1] sel_bank;
		c_reduce_bits
		  #(.op(`BINARY_OP_OR),
			.num_ports(num_ports),
			.width(num_vcs_per_bank))
		bank_sel
		   (.data_in(sel_ovc),
			.data_out(sel_bank));
        
        //TODO
	    assign shared_vc_out = (|(sel_bank & memory_bank_grant)) ? random_shared : 1'b0;

        // 'curr_dest_addr' seems not be used throughout this souce code.
	    assign curr_dest_addr = dest_info[((random_vc / num_vcs_per_class) % num_resource_classes)*router_addr_width +: router_addr_width];
	end
    else
	begin
	   assign sel_ovc = 1'b1;
	   assign curr_dest_addr = dest_info[0:router_addr_width-1];
	end
   endgenerate
   
   assign error = |fcs_errors_ovc |(|shared_fcs_errors_ovc);


	// Dump the generation time of each packet.
	// used for the end-to-end latency calculation.
	reg [0:packet_count_reg_width-1] pkt_gened;

	always @(posedge clk, posedge reset)
	if (reset)
		pkt_gened<=0;
	else if(packet_ready)
	begin
		pkt_gened<=pkt_gened+1;
		$display("gen:\n %7d %7d %7d %7d", 
			router_address[0:dim_addr_width-1], 
			router_address[dim_addr_width:2*dim_addr_width-1], 
			pkt_gened, 
			($time-8)/2);
	end


	// Dump the destination time of each packet.
	reg [0:dest_info_width-1] dest_info_q;

	always @(posedge clk, posedge reset)
	if (reset)
		dest_info_q<=0;
	else
		#1 dest_info_q<=dest_info;

	always @(negedge packet_sent, posedge reset)
	if (reset)
		pkt_sent<=0;
	else if (!packet_sent)
	begin
	  pkt_sent<=pkt_sent+1;
	  $display("dst:\n %7d %7d %7d %7d %7d",
		router_address[0:dim_addr_width-1],
		router_address[dim_addr_width:2*dim_addr_width-1], 
	  	pkt_sent,
		dest_info_q[0:dim_addr_width-1],
		dest_info_q[dim_addr_width:2*dim_addr_width-1]);
	end

endmodule
