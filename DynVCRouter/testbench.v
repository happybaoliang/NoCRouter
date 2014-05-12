`timescale 1ns/1ns


module testbench();


`include "c_functions.v"


parameter memory_bank_depth=32;
parameter memory_bank_width=64;


localparam memory_addr_width=clogb(memory_bank_depth);


reg clk;
reg reset;

reg read_enable;
reg write_enable;

reg [0:memory_addr_width-1] new_freed_slot;
wire [0:memory_addr_width-1] next_available_slot;

wire memory_bank_full;
wire memory_bank_empty;


initial
begin
	$display($time,"simulation started.\n");

	clk=0;
	reset=0;

	read_enable=0;
	write_enable=0;
	new_freed_slot=0;

	#1  reset=1;
	#1  reset=0;
	#1  reset=1;

	read_enable=0;
	write_enable=0;
	new_freed_slot=0;

	#100 $finish;
	$display($time,"simulation finalized.\n");
end


initial
begin
$dumpfile("debug.vcd");
$dumplimit(100000);
$dumpvars;
end


initial
begin
	$monitor($time," memory_bank_full=%d, memory_bank_empty=%d, read_enable=%d, write_enable=%d, next_available_slot=%h, new_freed_slot=%h",memory_bank_full,memory_bank_empty,read_enable,write_enable,next_available_slot,new_freed_slot);
end


always
	#1 clk=~clk;


always 
begin
	#1;
	read_enable=memory_bank_empty?0:{$random}%5;
	write_enable=memory_bank_full?0:{$random}%10;
	new_freed_slot={$random}%memory_bank_depth;
end


free_buffer_tracker #(
	.memory_bank_depth(memory_bank_depth),
	.memory_bank_width(memory_bank_width))
    tracker(
	.clk(clk),
	.reset(reset),
	.next_available_slot(next_available_slot),
	.new_freed_slot(new_freed_slot),
	.read_enable(read_enable),
	.write_enable(write_enable),
	.memory_bank_full(memory_bank_full),
	.memory_bank_empty(memory_bank_empty));


endmodule
