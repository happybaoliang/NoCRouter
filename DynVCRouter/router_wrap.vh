
module router_wrap ( clk, reset, router_address, channel_in_ip, 
        memory_bank_grant_in, flow_ctrl_out_ip, channel_out_op, 
        memory_bank_grant_out, flow_ctrl_in_op, credit_for_shared_in, 
        shared_vc_in, credit_for_shared_out, shared_vc_out, error );
  input [0:3] router_address;
  input [0:359] channel_in_ip;
  input [0:24] memory_bank_grant_in;
  output [0:24] flow_ctrl_out_ip;
  output [0:359] channel_out_op;
  output [0:24] memory_bank_grant_out;
  input [0:24] flow_ctrl_in_op;
  input [0:4] credit_for_shared_in;
  input [0:4] shared_vc_in;
  output [0:4] credit_for_shared_out;
  output [0:4] shared_vc_out;
  input clk, reset;
  output error;

  tri   clk;
  tri   reset;
  tri   [0:3] router_address;
  tri   [0:359] channel_in_ip;
  tri   [0:24] memory_bank_grant_in;
  tri   [0:24] flow_ctrl_out_ip;
  tri   [0:359] channel_out_op;
  tri   [0:24] memory_bank_grant_out;
  tri   [0:24] flow_ctrl_in_op;
  tri   [0:4] credit_for_shared_in;
  tri   [0:4] shared_vc_in;
  tri   [0:4] credit_for_shared_out;
  tri   [0:4] shared_vc_out;
  tri   error;

  vcr_top vcr ( .clk(clk), .reset(reset), .router_address(router_address), 
        .channel_in_ip(channel_in_ip), .memory_bank_grant_in(
        memory_bank_grant_in), .memory_bank_grant_out(memory_bank_grant_out), 
        .shared_vc_in(shared_vc_in), .shared_vc_out(shared_vc_out), 
        .flow_ctrl_out_ip(flow_ctrl_out_ip), .credit_for_shared_in(
        credit_for_shared_in), .credit_for_shared_out(credit_for_shared_out), 
        .channel_out_op(channel_out_op), .flow_ctrl_in_op(flow_ctrl_in_op), 
        .error(error) );
endmodule

