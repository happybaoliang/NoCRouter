module free_buffer_tracker(clk,reset,available_flit_addr,allocate_addr,freed_flit_addr,reclaim_addr,tracker_full,tracker_empty);


`include "c_functions.v"


parameter memory_bank_depth=32;


localparam memory_addr_width=clogb(memory_bank_depth);


input clk;

input reset;

input allocate_addr;

input reclaim_addr;

output tracker_full;
wire tracker_full;

output tracker_empty;
wire tracker_empty;

input [0:memory_addr_width-1] freed_flit_addr;

output [0:memory_addr_width-1] available_flit_addr;
wire [0:memory_addr_width-1] available_flit_addr;


reg [0:memory_addr_width] counter;
reg [0:memory_addr_width-1] read_ptr;
reg [0:memory_addr_width-1] write_ptr;
reg [0:memory_addr_width-1] tracker [0:memory_bank_depth-1];


generate
genvar item;
for (item=0;item<memory_bank_depth;item=item+1)
begin:inital
always @(posedge clk)
if (reset)
	tracker[item]<=item;
end
endgenerate


always @(posedge clk)
if (reset)
begin
	read_ptr<=0;
	write_ptr<=0;
	counter<=memory_bank_depth;
end
else
case ({allocate_addr,reclaim_addr})
2'b00:	// nop
	counter<=counter;
2'b01:	// write
begin
	tracker[write_ptr]<=freed_flit_addr;
	counter<=(counter==memory_bank_depth)?0:(counter+1);
	write_ptr<=(write_ptr==memory_bank_depth-1)?0:(write_ptr+1);
end
2'b10:	// read
begin
	counter<=(counter==0)?memory_bank_depth:(counter-1);
	read_ptr<=(read_ptr==memory_bank_depth-1)?0:(read_ptr+1);
end
2'b11:	// read and write
begin
	tracker[write_ptr]<=freed_flit_addr;
	read_ptr<=(read_ptr==memory_bank_depth-1)?0:(read_ptr+1);
	write_ptr<=(write_ptr==memory_bank_depth-1)?0:(write_ptr+1);
end
endcase

assign available_flit_addr=(counter==0)?freed_flit_addr:tracker[read_ptr];

assign tracker_full=(counter==memory_bank_depth);
assign tracker_empty=(counter==0);

endmodule
