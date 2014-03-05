# Setup some variable to set the clock frequency
# These can be put in the common_options.tcl file 
#  if you want them chip-wide
set ALU_CLK_FREQ 500.0
set ALU_CLK_TRAN 0.1
set ALU_CLK_PER [expr 1000.0 / $ALU_CLK_FREQ]
set ALU_CLK_SETUP_MARGIN [expr 0.1 * $ALU_CLK_PER]
set ALU_CLK_HOLD_MARGIN [expr 0.1 * $ALU_CLK_PER]


# This is the basic command for creating a clock
# This creates a clock with a period $ALU_CLK_PER on pin alu_clk
create_clock -p $ALU_CLK_PER clk 

# Clock transition time, in our library this is the 20-80 time
# If you want you can describe different rise/fall times
set_clock_transition $ALU_CLK_TRAN [get_clock clk]

#sets a clock margin
set_clock_uncertainty -setup $ALU_CLK_SETUP_MARGIN [get_clock clk]
set_clock_uncertainty -hold $ALU_CLK_HOLD_MARGIN [get_clock clk]

# set the driver to be a Size 8 inverter
set_driving_cell -lib_cell INVD8BWP  [all_inputs]

# set load of the outputs
set_load [load_of [get_lib_pins tcbn45gsbwpwc/INVD8BWP/I]] [all_outputs]

# Set the IO Constraints
#set_input_delay 0.3 [remove_from_collection [all_inputs]  [all_clocks] ]

set_input_delay 0.1 -clock clk  [remove_from_collection [all_inputs] [get_port clk] ]
set_output_delay 0.1 -clock clk  [all_outputs]

#setup combination path delays
set_max_delay 1.0 -from [all_inputs] -to [all_outputs]
