module memory_bank(clk,reset,flit_in,vc_written_into,flit_out,vc_read_from);
`include "c_functions.v"


parameter max_vc_number=10;	

parameter memory_bank_width=64;	// in bits

parameter memory_bank_depth=32;	// in flits


localparam pointer_depth=max_vc_number;

localparam pointer_width=clogb(memory_bank_depth);


input clk;

input reset;

input [0:memory_bank_width-1] flit_in;

input [0:max_vc_number-1] vc_read_from;

input [0:max_vc_number-1] vc_written_into;

output [0:memory_bank_width-1] flit_out;
reg [0:memory_bank_width-1] flit_out;


reg [0:memory_bank_width-1] memory_bank[0:memory_bank_depth-1];

reg [0:pointer_width-1] head_pointer_regfile[0:pointer_depth-1];

reg [0:pointer_width-1] tail_pointer_regfile[0:pointer_depth-1];

reg [0:pointer_width-1] next_pointer_regfile[0:pointer_depth-1];


// next_pointer_buffer
wire [0:memory_bank_depth*pointer_width-1] wnext_pointer;

generate
genvar item;
for (item=0;item<memory_bank_depth;item=item+1)
begin:anonymous1
	assign wnext_pointer[item*pointer_width:(item+1)*pointer_width-1]=next_pointer_regfile[item];
end
endgenerate

wire [0:pointer_width-1] next_ptr;

c_select_1ofn #(
	.num_ports(memory_bank_depth),
	.width(pointer_width))
    next_ptr_selector(
	.select(read_ptr),
	.data_in(wnext_pointer),
	.data_out(next_ptr));


// read from buffer
wire [0:max_vc_number*pointer_width-1] whead_pointer;

generate
genvar vc;
for (vc=0;vc<max_vc_number;vc=vc+1)
begin:anonymous2
	assign whead_pointer[vc*pointer_width:(vc+1)*pointer_width-1]=head_pointer_regfile[vc];
end
endgenerate

wire [0:pointer_width-1] read_ptr;

c_select_1ofn #(
	.num_ports(max_vc_number),
	.width(pointer_width))
    head_ptr_selector(
	.select(vc_read_from),
	.data_in(whead_pointer),
	.data_out(read_ptr));

always @(posedge clk or negedge reset)
	if (~reset)
		flit_out <= 0;
	else	
		flit_out <= memory_bank[read_ptr];


// write into buffer
wire [0:max_vc_number*pointer_width-1] wtail_pointer;

generate
genvar vc;
for (vc=0;vc<max_vc_number;vc=vc+1)
begin:anonymous3
	assign wtail_pointer[vc*pointer_width:(vc+1)*pointer_width-1]=tail_pointer_regfile[vc];
end
endgenerate

wire [0:pointer_width-1] write_ptr;

c_select_1ofn #(
	.num_ports(max_vc_number),
	.width(pointer_width))
    tail_ptr_selector(
	.select(vc_write_into),
	.data_in(wtail_pointer),
	.data_out(write_ptr));

always @(posedge clk or negedge reset)
	if (~reset)
		memory_bank[write_ptr]<=0;
	else
		memory_bank[write_ptr]<=flit_in;



endmodule
