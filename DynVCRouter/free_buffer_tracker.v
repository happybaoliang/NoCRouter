module free_buffer_tracker(clk,reset,next_available_slot,new_freed_slot,read_enable,write_enable,memory_bank_full,memory_bank_empty);


`include "c_functions.v"


parameter memory_bank_depth=32;

parameter memory_bank_width=64;


localparam memory_addr_width=clogb(memory_bank_depth);


input clk;

input reset;

input read_enable;

input write_enable;

input [0:memory_addr_width-1] new_freed_slot;

output [0:memory_addr_width-1] next_available_slot;
reg [0:memory_addr_width-1] next_available_slot;

output memory_bank_full;
reg memory_bank_full;

output memory_bank_empty;
reg memory_bank_empty;


reg [0:memory_addr_width-1] read_ptr;
reg [0:memory_addr_width-1] write_ptr;
reg [0:memory_bank_width-1] tracker [0:memory_bank_depth-1];


// next free buffer indicator
always @(posedge clk or negedge reset)
if (!reset)
	next_available_slot<=0;
else
	next_available_slot<=tracker[read_ptr];


// tracker update
generate
genvar item;
for (item=0;item<memory_bank_depth;item=item+1)
begin:anonymous
	always @(posedge clk or negedge reset)
	if (!reset)
		tracker[item]<=item;// free slot addr, initially
	else if (write_enable&&~memory_bank_full&&(write_ptr==item))
		tracker[item]<=new_freed_slot;
end
endgenerate


// write pointer update
always @(posedge clk or negedge reset)
if (!reset)
	write_ptr<=memory_bank_depth-1;
else if (write_enable&&~memory_bank_full)
	write_ptr<=write_ptr+1;


// read pointer update
always @(posedge clk or negedge reset)
if (!reset)
	read_ptr<=0;
else if (read_enable&&~memory_bank_empty)
	read_ptr<=read_ptr+1;


// full signal genration
always @(posedge clk or negedge reset)
if (!reset)
	memory_bank_full<=1;// full, initially
else if ((~read_enable&&write_enable)&&((write_ptr==read_ptr-1)||(read_ptr==0&&write_ptr==memory_bank_depth-1)))
	memory_bank_full<=1;
else if (memory_bank_full && read_enable)
	memory_bank_full<=0;


// empty signal generation
always @(posedge clk or negedge reset)
if (!reset)
	memory_bank_empty<=0;
else if ((read_enable&&~write_enable)&&((read_ptr==write_ptr-1)||(read_ptr==memory_bank_depth&&write_ptr==0)))
	memory_bank_empty<=1;
else if (memory_bank_empty&&write_enable)
	memory_bank_empty<=0;


endmodule
