#/**************************************************/
#/* Compile Script for Synopsys                    */
#/*                                                */
#/* dc_shell-t -f compile_dc.tcl                   */
#/*                                                */
#/* OSU FreePDK 45nm                               */
#/**************************************************/

#/* All verilog files, separated by spaces         */
set my_verilog_files [list router_wrap.v vcr_top.v rtr_flow_ctrl_input.v vcr_ovc_ctrl.v rtr_flow_ctrl_output.v vcr_sw_alloc_sep_if.v rtr_channel_input.v memory_bank_allocator.v rtr_channel_output.v rtr_next_hop_addr.v rtr_crossbar_mac.v rtr_route_filter.v vcr_alloc_mac.v vcr_vc_alloc_sep_if.v rtr_fc_state.v rtr_routing_logic.v rtr_flags_mux.v vcr_ip_ctrl_mac.v vcr_op_ctrl_mac.v rtr_flit_buffer.v vcr_ivc_ctrl.v rtr_flit_type_check.v clib/c_add_nto1.v clib/c_err_rpt.v clib/c_matrix_arbiter.v clib/c_rr_arbiter.v clib/c_align.v clib/c_fbgen.v clib/c_multi_hot_det.v clib/c_samq_ctrl.v clib/c_arbiter.v clib/c_fbmult.v clib/c_one_hot_filter.v clib/c_samq_tracker.v clib/c_binary_op.v clib/c_fifo_ctrl.v clib/c_one_hot_therm_conv.v clib/c_scatter.v clib/c_clkgate.v clib/c_fifo_tracker.v clib/c_prefix_arbiter_base.v clib/c_select_1ofn.v  clib/c_fifo.v clib/c_prefix_arbiter.v clib/c_select_mofn.v clib/c_crossbar.v clib/c_prefix_net.v clib/c_shift_reg.v clib/c_damq_ctrl.v clib/c_gate_bits.v  clib/c_prio_enc.v clib/c_wf_alloc_dpa.v clib/c_damq_tracker.v  clib/c_gather.v clib/c_prio_sel.v clib/c_wf_alloc_loop.v clib/c_decode.v clib/c_incr.v clib/c_reduce_bits.v clib/c_wf_alloc_mux.v clib/c_decr.v clib/c_interleave.v clib/c_regfile.v clib/c_wf_alloc_rep.v clib/c_dff.v clib/c_lfsr.v clib/c_reverse.v clib/c_wf_alloc_rot.v clib/c_diag_op.v clib/c_lod.v clib/c_rotate.v clib/c_wf_alloc_sdpa.v clib/c_encode.v clib/c_mat_mult.v clib/c_rr_arbiter_base.v clib/c_wf_alloc.v]

#/* Top-level Module                               */
set my_toplevel router_wrap

#/* The name of the clock pin. If no clock-pin     */
#/* exists, pick anything                          */
set my_clock_pin clk

#/* Target frequency in MHz for optimization       */
set my_clk_freq_MHz 200

#/* Delay of input signals (Clock-to-Q, Package etc.)  */
set my_input_delay_ns 0.1

#/* Reserved time for output signals (Holdtime etc.)   */
set my_output_delay_ns 0.1


#/**************************************************/
#/* No modifications needed below                  */
#/**************************************************/
set OSU_FREEPDK [format "%s%s"  [getenv "PDK_DIR"] "/osu_soc/lib/files"]
set search_path [concat  $search_path $OSU_FREEPDK]
set alib_library_analysis_path $OSU_FREEPDK

set link_library [set target_library [concat  [list gscl45nm.db] [list dw_foundation.sldb]]]
set target_library "gscl45nm.db"
set designer "happybaoliang"
set company "Tsinghua Univ."

define_design_lib WORK -path ./WORK
set verilogout_show_unconnected_pins "true"

set_ultra_optimization true

set_ultra_optimization -force

analyze -f verilog $my_verilog_files

elaborate $my_toplevel

current_design $my_toplevel

link

uniquify

set my_period [expr 1000 / $my_clk_freq_MHz]

set find_clock [ find port [list $my_clock_pin] ]
if {  $find_clock != [list] } {
   set clk_name $my_clock_pin
   create_clock -period $my_period $clk_name
} else {
   set clk_name vclk
   create_clock -period $my_period -name $clk_name
}

set_driving_cell  -lib_cell INVX1  [all_inputs]
set_input_delay $my_input_delay_ns -clock $clk_name [remove_from_collection [all_inputs] $my_clock_pin]
set_output_delay $my_output_delay_ns -clock $clk_name [all_outputs]

compile -ungroup_all -map_effort medium

check_design

compile -incremental_mapping -map_effort medium

check_design

report_constraint -all_violators

set filename [format "%s%s"  $my_toplevel ".vh"]
write -f verilog -output $filename

set filename [format "%s%s"  $my_toplevel ".sdc"]
write_sdc $filename

set filename [format "%s%s"  $my_toplevel ".sdf"]
write_sdf $filename

if {[shell_is_in_xg_mode]==0} {
set filename [format "%s%s"  $my_toplevel ".db"]
write -f db -hier -output $filename
} else {
set filename [format "%s%s" $my_toplevel ".ddc"]
write -f ddc -hier -o $filename }

redirect cell.rep {report_cell}
redirect timing.rep {report_timing}
redirect power.rep {report_power -nosplit -hier}
redirect area.rep {report_area -nosplit -hierarchy}
redirect resources.rep {report_resources -nosplit -hierarchy}
redirect reference.rep {report_reference -nosplit -hierarchy}

quit
