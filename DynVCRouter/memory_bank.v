module memory_bank(clk,reset,vc_written_into,flit_in,write_enable,vc_read_from,flit_out,read_enable,memory_bank_full,memory_bank_empty);
`include "c_functions.v"


parameter max_vc_number=10;	

parameter memory_bank_width=64;	// in bits

parameter memory_bank_depth=32;	// in flits


localparam vc_pointer_width=clogb(max_vc_number);

localparam memory_addr_width=clogb(memory_bank_depth);


input clk;

input reset;

input read_enable;

input write_enable;

input [0:memory_bank_width-1] flit_in;

input [0:max_vc_number-1] vc_read_from;

input [0:max_vc_number-1] vc_written_into;

output [0:memory_bank_width-1] flit_out;
reg [0:memory_bank_width-1] flit_out;

output memory_bank_full;
wire memory_bank_full;

output memory_bank_empty;
wire memory_bank_empty;


reg [0:memory_bank_width-1] memory_bank[0:memory_bank_depth-1];

reg [0:memory_addr_width-1] head_pointer_regfile[0:max_vc_number-1];

reg [0:memory_addr_width-1] tail_pointer_regfile[0:max_vc_number-1];

reg [0:memory_addr_width-1] next_pointer_regfile[0:memory_bank_depth-1];


// free buffer tracker
wire [0:memory_addr_width-1] memory_bank_read_ptr;

wire [0:memory_addr_width-1] memory_bank_write_ptr;

free_buffer_tracker #(
	.memory_bank_depth(memory_bank_depth),
	.memory_bank_width(memory_bank_width))
    tracker(
	.clk(clk),
	.reset(reset),
	.next_available_slot(memory_bank_write_ptr),
	.new_freed_slot(memory_bank_read_ptr),
	.read_enable(read_enable),
	.write_enable(write_enable),
	.memory_bank_full(memory_bank_full),
	.memory_bank_empty(memory_bank_empty));


// memory write
always @(posedge clk or negedge reset)
	if (!reset)
		memory_bank[memory_bank_write_ptr]<=0;
	else if (write_enable)
		memory_bank[memory_bank_write_ptr]<=flit_in;


// tail pointer update
always @(posedge clk or negedge reset)
	if (!reset)
		tail_pointer_regfile[vc_written_into]<=0;
	else if (write_enable)
		tail_pointer_regfile[vc_written_into]<=memory_bank_write_ptr;


// next pointer update
wire [0:memory_addr_width-1] wtail_pointer;
wire [0:max_vc_number*memory_addr_width-1] group_tail_pointer;

generate
genvar item;

for (item=0;item<max_vc_number;item=item+1)
begin:next_ptr
	assign group_tail_pointer[item*memory_addr_width:(item+1)*memory_addr_width-1]=head_pointer_regfile[item];
end

endgenerate

c_select_1ofn #(
	.num_ports(max_vc_number),
	.width(memory_addr_width))
    tail_ptr_selector(
	.select(vc_written_into),
	.data_in(group_tail_pointer),
	.data_out(wtail_pointer));

always @(posedge clk or negedge reset)
	if (!reset)
		next_pointer_regfile[wtail_pointer]<=0;
	else if (write_enable)
		next_pointer_regfile[wtail_pointer]<=memory_bank_write_ptr;


// head pointer update
always @(posedge clk or negedge reset)
	if (!reset)
		head_pointer_regfile[vc_read_from]<=0;
	else if (read_enable)
		head_pointer_regfile[vc_read_from]<=next_pointer_regfile[memory_bank_read_ptr];


// memory read
wire [0:max_vc_number*memory_addr_width-1] whead_pointer;

generate
genvar vc;
for (vc=0;vc<max_vc_number;vc=vc+1)
begin:read_ptr
	assign whead_pointer[vc*memory_addr_width:(vc+1)*memory_addr_width-1]=head_pointer_regfile[vc];
end
endgenerate

c_select_1ofn #(
	.num_ports(max_vc_number),
	.width(memory_addr_width))
    head_ptr_selector(
	.select(vc_read_from),
	.data_in(whead_pointer),
	.data_out(memory_bank_read_ptr));

always @(posedge clk or negedge reset)
	if (!reset)
		flit_out <= 0;
	else if (read_enable)	
		flit_out <= memory_bank[memory_bank_read_ptr];


endmodule
