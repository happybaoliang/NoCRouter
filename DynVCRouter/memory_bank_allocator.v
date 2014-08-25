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
	reg ready_for_allocation;


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
        memory_bank_grant_out <= {5'b10000}>>bank_id;
        ready_for_allocation <= 1'b1;
        state <= ENABLE_ALLOCATION;
    end
    else
    begin
        case (state)
        ENABLE_ALLOCATION:
        begin
            ready_for_allocation <= 1'b1;
            if (congestion!=congestion_new)
            begin
                state <= DISABLE_ALLOCATION;
            end
        end
        CHANGE_ALLOCATION:
        begin
            state <= ENABLE_ALLOCATION;
		    casex(congestion)
			    5'b10xxx: memory_bank_grant_out <= 5'b10000;
			    5'b01xxx: memory_bank_grant_out <= 5'b01000;
			    5'b11xxx: memory_bank_grant_out <= (router_address[dim_addr_width:2*dim_addr_width-1]>=num_routers_per_dim/2) ? 5'b10000 : 5'b01000;
			    5'b0001x: memory_bank_grant_out <= 5'b00010;
			    5'b0010x: memory_bank_grant_out <= 5'b00100;
			    5'b0011x: memory_bank_grant_out <= (router_address[0:dim_addr_width-1]<=num_routers_per_dim/2) ? 5'b00010 : 5'b00100;
			    5'b00001: memory_bank_grant_out <= 5'b00001;
		    endcase
        end
        DISABLE_ALLOCATION:
        begin
            ready_for_allocation <= 1'b0;
            state <= CHANGE_ALLOCATION;
        end
        default:
        begin
            memory_bank_grant_out <= {5'b10000}>>bank_id;
            ready_for_allocation <= 1'b1;
            state <= ENABLE_ALLOCATION;
        end
        endcase
    end

endmodule
