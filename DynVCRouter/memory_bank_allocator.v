module memory_bank_allocator(clk, reset, allocated_ip_shared_ivc, shared_ivc_empty, ready_for_allocation, memory_bank_grant_out);

`include "parameters.v"
`include "c_functions.v"
`include "c_constants.v"
`include "vcr_constants.v"


	parameter num_vcs = 1;
	parameter bank_id = 0;
	parameter num_ports = 5;
	parameter threshold = 4;
    localparam thres_width = clogb(threshold);
	localparam num_vcs_per_bank = num_vcs / num_ports;


    parameter EAST  = 3'b001;
    parameter WEST  = 3'b010;
    parameter NORTH = 3'b011;
    parameter SOUTH = 3'b100;
    parameter LOCAL = 3'b101;

    parameter ENABLE_ALLOCATION = 2'b01;
	parameter CHANGE_ALLOCATION = 2'b11;
	parameter DISABLE_ALLOCATION = 2'b10;


	input clk;
	input reset;

	input [0:num_vcs_per_bank-1]          shared_ivc_empty;
	input [0:num_ports*num_vcs-1]         allocated_ip_shared_ivc;

	output [0:num_ports-1]                memory_bank_grant_out;
	reg [0:num_ports-1]                   memory_bank_grant_out;

	output                                ready_for_allocation;
    reg                                   ready_for_allocation;


	reg  [0:1]                            state;
    reg [0:thres_width-1]                 counter;
    reg [0:2]                             direction;
	wire [0:num_ports*num_vcs_per_bank-1] shared_vc_allocated;

	genvar ip;
	generate
	for (ip=0;ip<num_ports;ip=ip+1)
	begin:ips
		assign shared_vc_allocated[ip*num_vcs_per_bank+:num_vcs_per_bank] = 
							allocated_ip_shared_ivc[ip*num_vcs+bank_id*num_vcs_per_bank+:num_vcs_per_bank];
	end
	endgenerate

    wire idle;
    assign idle = (&shared_ivc_empty) && (~(|shared_vc_allocated));

    always @(posedge clk, posedge reset)
    if (reset)
        counter <= {thres_width{1'b0}};
    else if ((state==ENABLE_ALLOCATION) && idle)
        counter <= counter+1;
    else
        counter <= {thres_width{1'b0}};


    always @(posedge clk, posedge reset)
    if (reset)
    begin
        direction <= bank_id;
        state <= ENABLE_ALLOCATION;
        ready_for_allocation <= 1'b1;
        memory_bank_grant_out <= {5'b10000}>>bank_id;
    end
    else
    begin
    case(state)
    ENABLE_ALLOCATION:
    begin
        ready_for_allocation <= (idle && (counter>=threshold)) ? 1'b0 : 1'b1;
        state <= (idle && (counter>=threshold)) ? DISABLE_ALLOCATION : ENABLE_ALLOCATION;
    end
    DISABLE_ALLOCATION:
    begin
        ready_for_allocation <= 1'b0;
        state <= idle ? CHANGE_ALLOCATION : DISABLE_ALLOCATION;
    end
    CHANGE_ALLOCATION:
    begin
        state <= ENABLE_ALLOCATION;
        ready_for_allocation <= 1'b1;
        case(direction)
        EAST:
            begin
                direction <= WEST;
                memory_bank_grant_out <= 5'b01000;
            end
        WEST:
            begin
                direction <= SOUTH;
                memory_bank_grant_out <= 5'b00100;
            end
        SOUTH:
            begin
                direction <= NORTH;
                memory_bank_grant_out <= 5'b00010;
            end
        NORTH:
            begin
                direction <= LOCAL;
                memory_bank_grant_out <= 5'b00001;
            end
        LOCAL:
            begin
                direction <= EAST;
                memory_bank_grant_out <= 5'b10000;
            end
        default:
            begin
                direction <= EAST;
                memory_bank_grant_out <= 5'b10000;
            end
        endcase
    end
    default:
    begin
        direction <= bank_id;
        state <= ENABLE_ALLOCATION;
        ready_for_allocation <= 1'b1;
        memory_bank_grant_out <= {5'b10000}>>bank_id;
    end
    endcase
    end


endmodule
