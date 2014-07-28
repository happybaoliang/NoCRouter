module memory_bank_allocator(clk, reset, allocated_ip_ivc, allocated_ip_shared_ivc, 
				router_address, ready_for_allocation, memory_bank_grant_out);

`include "parameters.v"
`include "c_functions.v"
`include "c_constants.v"
`include "vcr_constants.v"


	parameter num_vcs = 1;
	parameter bank_id = 0;
	parameter num_ports = 5;
	parameter counter_width = 4;
	parameter dim_addr_width = 2;
	parameter num_vcs_per_bank = 2;
	parameter router_addr_width = 4;
	parameter num_routers_per_dim = 4;
	
	parameter ENABLE_ALLOCATION = 2'b01;
	parameter CHANGE_ALLOCATION = 2'b11;
	parameter DISABLE_ALLOCATION = 2'b10;


	input clk;
	input reset;
	input [0:router_addr_width-1] router_address;
	input [0:num_ports*num_vcs-1] allocated_ip_ivc;
	input [0:num_ports*num_vcs-1] allocated_ip_shared_ivc;

	output [0:num_ports-1] memory_bank_grant_out;
	reg [0:num_ports-1] memory_bank_grant_out;

	output ready_for_allocation;
	wire ready_for_allocation;


	reg [0:num_ports-1] congestion;
	wire [0:num_ports-1] congestion_new;
	reg [0:num_ports*counter_width-1] counter;

	genvar ip;
	generate
	for (ip=0;ip<num_ports;ip=ip+1)
	begin:ips
		always @(posedge clk, reset)
		if (reset)
		begin
			counter[ip*counter_width:(ip+1)*counter_width-1] <= {counter_width{1'b0}};
		end
		else if (&allocated_ip_ivc[ip*num_vcs+bank_id*num_vcs_per_bank+:num_vcs_per_bank])
		begin
			if (counter[ip*counter_width:(ip+1)*counter_width-1]!={counter_width{1'b1}})
				counter[ip*counter_width:(ip+1)*counter_width-1] <= counter[ip*counter_width:(ip+1)*counter_width-1] + 1;
		end
		else
		begin
			counter[ip*counter_width:(ip+1)*counter_width-1] <= {counter_width{1'b0}};
		end

		assign congestion_new[ip] = counter[ip*counter_width:(ip+1)*counter_width-1] == {counter_width{1'b1}};
	end
	endgenerate


	reg [0:1] state;
	wire [0:1] next_state;

	always @(posedge clk, reset)
	if (reset)
	begin
		congestion<=congestion_new;
		state <= ENABLE_ALLOCATION;
	end
	else
	begin
		state <= next_state;
		congestion<=congestion_new;
	end

	assign ready_for_allocation = (state==DISABLE_ALLOCATION) ? 1'b0 
								: (state==CHANGE_ALLOCATION) ? 1'b0
								: (state==ENABLE_ALLOCATION) ? 1'b1 : 1'b0;

	assign next_state = ((state==DISABLE_ALLOCATION)&&(~(|allocated_ip_shared_ivc[bank_id]))) ? CHANGE_ALLOCATION
					  : (state==CHANGE_ALLOCATION) ? ENABLE_ALLOCATION
					  : ((state==ENABLE_ALLOCATION)&&(congestion==congestion_new)) ? ENABLE_ALLOCATION
					  : DISABLE_ALLOCATION;
	
	always @(posedge clk, reset)
	if (reset)
	begin
		memory_bank_grant_out <= {5'b10000}>>bank_id;
	end
	else if (next_state==CHANGE_ALLOCATION)
		casex(congestion)
			5'b10xxx: memory_bank_grant_out <= 5'b10000;
			5'b01xxx: memory_bank_grant_out <= 5'b01000;
			5'b11xxx: memory_bank_grant_out <= (router_address[dim_addr_width:2*dim_addr_width-1]>=num_routers_per_dim/2) 
											? 5'b10000 : 5'b01000;
			5'b0001x: memory_bank_grant_out <= 5'b00010;
			5'b0010x: memory_bank_grant_out <= 5'b00100;
			5'b0011x: memory_bank_grant_out <= (router_address[0:dim_addr_width-1]<=num_routers_per_dim/2) 
											? 5'b00010 : 5'b00100;
			5'b00001: memory_bank_grant_out <= 5'b00001;
			default:  memory_bank_grant_out <= {5'b10000}>>bank_id;
		endcase

endmodule
