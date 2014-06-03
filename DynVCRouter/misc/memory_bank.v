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

input [0:vc_pointer_width-1] vc_read_from;

input [0:vc_pointer_width-1] vc_written_into;

output [0:memory_bank_width-1] flit_out;
reg [0:memory_bank_width-1] flit_out;

output memory_bank_full;
wire memory_bank_full;

output memory_bank_empty;
wire memory_bank_empty;


reg vc_valid [0:max_vc_number-1];

reg [0:memory_bank_width-1] memory_bank[0:memory_bank_depth-1];

reg [0:memory_addr_width-1] head_pointer_regfile[0:max_vc_number-1];

reg [0:memory_addr_width-1] tail_pointer_regfile[0:max_vc_number-1];

reg [0:memory_addr_width-1] next_pointer_regfile[0:memory_bank_depth-1];


generate
genvar i;
for (i=0;i<max_vc_number;i=i+1)
begin:valid
always @(posedge clk)
if (reset)
	vc_valid[i]<=0;
else if (vc_written_into==i)
	vc_valid[i]<=1;
end
endgenerate


// free buffer tracker
wire [0:memory_addr_width-1] memory_bank_read_ptr;

wire [0:memory_addr_width-1] memory_bank_write_ptr;

free_buffer_tracker #(
	.memory_bank_depth(memory_bank_depth))
    tracker(
	.clk(clk),
	.reset(reset),
	.available_flit_addr(memory_bank_write_ptr),
	.freed_flit_addr(memory_bank_read_ptr),
	.allocate_addr(write_enable),		// free buffer read=> memory bank write
	.reclaim_addr(read_enable),		// free buffer write=> memory bank read
	.tracker_full(memory_bank_empty),	// free buffer full=> memory bank empty
	.tracker_empty(memory_bank_full));	// free buffer empty=> memory bank full


// memory write
always @(posedge clk)
	if (reset)
		memory_bank[memory_bank_write_ptr]<=0;
	else if (write_enable&&~memory_bank_full)
	begin
		memory_bank[memory_bank_write_ptr]<=flit_in;
		//$display($time," write memory, addr=%H, data=%H", memory_bank_write_ptr,flit_in);
	end


// tail pointer update
always @(posedge clk)
	if (reset)
		tail_pointer_regfile[vc_written_into]<=0;
	else if (write_enable&&~memory_bank_full)
	begin
		tail_pointer_regfile[vc_written_into]<=memory_bank_write_ptr;
		//$display($time," record vc tail, recorded addr=%H",memory_bank_write_ptr);
	end


// next pointer update
always @(posedge clk)
	if (reset)
		next_pointer_regfile[tail_pointer_regfile[vc_written_into]]<=0;
	else if (write_enable&&~memory_bank_full)
	begin
		if (!vc_valid[vc_written_into])
			next_pointer_regfile[memory_bank_write_ptr]<=memory_bank_write_ptr;
		else
			next_pointer_regfile[tail_pointer_regfile[vc_written_into]]<=memory_bank_write_ptr;
		//$display($time," record next pointer, recorded pointer=%H",memory_bank_write_ptr);
	end


// head pointer update
always @(posedge clk)
	if (reset)
		head_pointer_regfile[vc_read_from]<=0;
	else if (!vc_valid[vc_written_into])
	begin
		head_pointer_regfile[vc_written_into]<=memory_bank_write_ptr;
		//$display($time," create an new vc, head addr=%H",memory_bank_write_ptr);
	end
	else if (read_enable&&~memory_bank_empty)
	begin
		//$display($time," update head pointer, new head addr=%H,next index is=%H",next_pointer_regfile[memory_bank_read_ptr],memory_bank_read_ptr);
		head_pointer_regfile[vc_read_from]<=next_pointer_regfile[memory_bank_read_ptr];
	end


// memory read
assign memory_bank_read_ptr=head_pointer_regfile[vc_read_from];

always @(posedge clk)
	if (reset)
		flit_out <= 0;
	else if (read_enable&&~memory_bank_empty)	
		flit_out <= memory_bank[memory_bank_read_ptr];

endmodule
