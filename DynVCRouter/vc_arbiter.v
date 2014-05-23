module vc_arbiter(clk, reset, active_ip, active_op, req_ip_ivc, route_ip_ivc_op, elig_op_ovc, gnt_ip_ivc, gnt_op_ovc, sel_ip_ivc_ovc, sel_op_ovc_ip, sel_op_ovc_ivc);
`include "c_functions.v"
`include "c_constants.v"


parameter num_ports = 5;
parameter max_vc_number = 20;
parameter reset_type=RESET_TYPE_ASYNC;
parameter reset_type = `RESET_TYPE_ASYNC;

input clk;
input reset;

// input-side activity indicator
input [0:num_ports-1] active_ip;

// output-side activity indicator
input [0:num_ports-1] active_op;

// request vector
input [0:num_ports*max_vc_number-1] 	req_ip_ivc;

// request destination port
input [0:num_ports*max_vc_number*num_ports-1] route_ip_ivc_op;

// output is not currently allocated
input [0:num_ports*max_vc_number-1]	elig_op_ovc;

// grant vector
output [0:max_vc_number*num_ports-1] 	gnt_ip_ivc;
wire [0:max_vc_number*num_ports-1]  	gnt_ip_ivc;


output [0:max_vc_number*num_ports-1]	gnt_op_ovc;
wire [0:max_vc_number*num_ports-1]	gnt_op_ovc;

output [0:max_vc_number*num_ports*max_vc_number-1] sel_ip_ivc_ovc;
wire [0:max_vc_number*num_ports*max_vc_number-1] sel_ip_ivc_ovc;

output [0:max_vc_number*num_ports*max_vc_number-1] sel_op_ovc_ip;
wire [0:max_vc_number*num_ports*max_vc_number-1] sel_op_ovc_ip;

output [0:max_vc_number*num_ports*max_vc_number-1] sel_op_ovc_ivc;
wire [0:max_vc_number*num_ports*max_vc_number-1] sel_op_ovc_ivc;


c_rr_arbiter#(
	.num_ports(num_ports),
	.num_priorities(num_priorities),
	.encode_state(1'b1),
	.reset_type(reset_type))
    rr_arb(
	.clk(clk),
	.reset(reset),
	.req_pr(req_pr),
	.gnt_pr(gnt_pr),
	.gnt(gnt),
	.update(update));

endmodule
