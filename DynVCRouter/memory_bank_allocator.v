module memory_bank_allocator(clk, reset, allocated_ip_ivc, allocated_ip_shared_ivc, 
		shared_ivc_empty, router_address, ready_for_allocation, memory_bank_grant_out);

`include "parameters.v"
`include "c_functions.v"
`include "c_constants.v"
`include "vcr_constants.v"


	parameter num_vcs = 1;
	parameter bank_id = 0;
	parameter num_ports = 5;
	parameter counter_width = 4;
	parameter dim_addr_width = 2;
	parameter router_addr_width = 4;
	parameter num_routers_per_dim = 4;
	localparam num_vcs_per_bank = num_vcs / num_ports;
	
    parameter ENABLE_ALLOCATION = 2'b01;
	parameter CHANGE_ALLOCATION = 2'b11;
	parameter DISABLE_ALLOCATION = 2'b10;


	input clk;
	input reset;
	input [0:router_addr_width-1] router_address;
	input [0:num_vcs_per_bank-1] shared_ivc_empty;
	input [0:num_ports*num_vcs-1] allocated_ip_ivc;
	input [0:num_ports*num_vcs-1] allocated_ip_shared_ivc;

	output [0:num_ports-1] memory_bank_grant_out;
	reg [0:num_ports-1] memory_bank_grant_out;

	output ready_for_allocation;
	wire ready_for_allocation;


	reg [0:1] state;
	reg [0:1] next_state;

	reg [0:num_ports-1] congestion;
	wire [0:num_ports-1] congestion_new;
	reg [0:num_ports*counter_width-1] counter;

	wire [0:num_ports*num_vcs_per_bank-1] shared_vc_allocated;

	genvar ip;
	generate
	for (ip=0;ip<num_ports;ip=ip+1)
	begin:ips
		always @(posedge clk or posedge reset)
		if (reset)
		begin
			counter[ip*counter_width:(ip+1)*counter_width-1] <= {counter_width{1'b0}};
		end
		else if ((&allocated_ip_ivc[ip*num_vcs+bank_id*num_vcs_per_bank+:num_vcs_per_bank]) && (state==ENABLE_ALLOCATION))
		begin
			if (counter[ip*counter_width:(ip+1)*counter_width-1]!={counter_width{1'b1}})
				counter[ip*counter_width:(ip+1)*counter_width-1] <= counter[ip*counter_width:(ip+1)*counter_width-1] + 1;
		end
		else
		begin
			counter[ip*counter_width:(ip+1)*counter_width-1] <= {counter_width{1'b0}};
		end

		assign shared_vc_allocated[ip*num_vcs_per_bank+:num_vcs_per_bank] = 
							allocated_ip_shared_ivc[ip*num_vcs+bank_id*num_vcs_per_bank+:num_vcs_per_bank];

		assign congestion_new[ip] = counter[ip*counter_width:(ip+1)*counter_width-1] == {counter_width{1'b1}};
	end
	endgenerate


	always @(posedge clk or posedge reset)
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
								: (state==ENABLE_ALLOCATION) ? 1'b1 
								: 1'b0;

	//TODO
    //always @(state)
    always @(*)
	begin
		case(state)
			DISABLE_ALLOCATION:
				if ((~(|shared_vc_allocated))&&(&shared_ivc_empty))
					next_state = CHANGE_ALLOCATION;
			CHANGE_ALLOCATION:
				next_state = ENABLE_ALLOCATION;
			ENABLE_ALLOCATION:
				if (congestion!=congestion_new)
					next_state = DISABLE_ALLOCATION;
			default:
				next_state = ENABLE_ALLOCATION;
		endcase
	end
	
	always @(posedge clk or posedge reset)
	if (reset)
	begin
		memory_bank_grant_out <= {5'b10000}>>bank_id;
	end
	else if (next_state==CHANGE_ALLOCATION)
		casex(congestion)
			5'b10xxx: memory_bank_grant_out <= 5'b10000;
			5'b01xxx: memory_bank_grant_out <= 5'b01000;
			5'b11xxx: memory_bank_grant_out <= (router_address[dim_addr_width:2*dim_addr_width-1]>=num_routers_per_dim/2) ? 5'b10000 : 5'b01000;
			5'b0001x: memory_bank_grant_out <= 5'b00010;
			5'b0010x: memory_bank_grant_out <= 5'b00100;
			5'b0011x: memory_bank_grant_out <= (router_address[0:dim_addr_width-1]<=num_routers_per_dim/2) ? 5'b00010 : 5'b00100;
			5'b00001: memory_bank_grant_out <= 5'b00001;
		endcase

    initial
    begin
        $monitor("memory_bank_grant_out=%b\n",memory_bank_grant_out);
    end

endmodule
