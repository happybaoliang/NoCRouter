source -echo -verbose ./rm_setup/common_setup.tcl
source -echo -verbose ./rm_setup/dc_setup_filenames.tcl

#################################################################################
# Design Compiler Top-Down Reference Methodology Setup
# Script: dc_setup.tcl
# Version: D-2010.03 (March 29, 2010)
# Copyright (C) 2007-2010 Synopsys, Inc. All rights reserved.
#################################################################################

#################################################################################
#Ted's changes
#-Set max cores to 4
#-Added list of src files, does NOT include parameters.v (place the desired parameters.v in the current directory)
#-
#################################################################################


#################################################################################
# Setup Variables
#
# Modify settings in this section to customize your DC-RM run.
#################################################################################

# Portions of dc_setup.tcl may be used by other tools so do check for DC only commands
if {$synopsys_program_name == "dc_shell"}  {

  # Use the set_host_options command to enable multicore optimization to improve runtime.
  # Note that this feature has special usage and license requirements.  Please refer
  # to the "Support for Multicore Technology" section in the Design Compiler User Guide
  # for multicore usage guidelines.
  # Note: This is a DC Ultra feature and is not supported in DC Expert.

  set_host_options -max_cores 4

  # Change alib_library_analysis_path to point to a central cache of analyzed libraries
  # to save some runtime and disk space.  The following setting only reflects the
  # the default value and should be changed to a central location for best results.

  set_app_var alib_library_analysis_path .

  # Add any additional DC variables needed here
}

set rtl_dir ../../src

# These are the verilog files to be included in the design
set RTL_SOURCE_FILES  [list\
        $rtl_dir/c_constants.v\
	$rtl_dir/vcr_constants.v\
	$rtl_dir/whr_constants.v\
	$rtl_dir/c_add_nto1.v\
	$rtl_dir/c_align.v\
	$rtl_dir/c_arbiter.v\
	$rtl_dir/c_binary_op.v\
	$rtl_dir/c_clkgate.v\
	$rtl_dir/c_crossbar.v\
	$rtl_dir/c_decode.v\
	$rtl_dir/c_decr.v\
	$rtl_dir/c_dff.v\
	$rtl_dir/c_encode.v\
	$rtl_dir/c_err_rpt.v\
	$rtl_dir/c_fbgen.v\
	$rtl_dir/c_fbmult.v\
	$rtl_dir/c_fifo_ctrl.v\
	$rtl_dir/c_fifo_tracker.v\
	$rtl_dir/c_fifo.v\
	$rtl_dir/c_gather.v\
	$rtl_dir/c_incr.v\
	$rtl_dir/c_interleave.v\
	$rtl_dir/c_lfsr.v\
	$rtl_dir/c_lod.v\
	$rtl_dir/c_mat_mult.v\
	$rtl_dir/c_matrix_arbiter.v\
	$rtl_dir/c_multi_hot_det.v\
	$rtl_dir/c_one_hot_filter.v\
	$rtl_dir/c_prio_enc.v\
	$rtl_dir/c_prio_sel.v\
	$rtl_dir/c_regfile.v\
	$rtl_dir/c_reverse.v\
	$rtl_dir/c_rotate.v\
	$rtl_dir/c_rr_arbiter.v\
	$rtl_dir/c_scatter.v\
	$rtl_dir/c_select_1ofn.v\
	$rtl_dir/c_select_mofn.v\
	$rtl_dir/c_shift_reg.v\
	$rtl_dir/c_tree_arbiter.v\
	$rtl_dir/c_wf_alloc_dpa.v\
	$rtl_dir/c_wf_alloc_loop.v\
	$rtl_dir/c_wf_alloc_mux.v\
	$rtl_dir/c_wf_alloc_rep.v\
	$rtl_dir/c_wf_alloc_rot.v\
	$rtl_dir/c_wf_alloc.v\
	$rtl_dir/router_wrap.v\
	$rtl_dir/rtr_alloc_mac.v\
	$rtl_dir/rtr_channel_input.v\
	$rtl_dir/rtr_channel_output.v\
	$rtl_dir/rtr_crossbar_mac.v\
	$rtl_dir/rtr_flags_mux.v\
	$rtl_dir/rtr_flow_ctrl_input.v\
	$rtl_dir/rtr_flow_ctrl_output.v\
	$rtl_dir/rtr_ip_ctrl_mac.v\
	$rtl_dir/rtr_next_hop_addr.v\
	$rtl_dir/rtr_op_ctrl_mac.v\
	$rtl_dir/rtr_route_filter.v\
	$rtl_dir/rtr_routing_logic.v\
	$rtl_dir/rtr_top.v\
	$rtl_dir/rtr_vc_state.v\
	$rtl_dir/tc_cfg_bus_ifc.v\
	$rtl_dir/tc_chan_test_mac.v\
	$rtl_dir/tc_node_ctrl_mac.v\
	$rtl_dir/tc_node_mac.v\
	$rtl_dir/tc_router_wrap.v\
	$rtl_dir/vcr_ip_ctrl_mac.v\
	$rtl_dir/vcr_ivc_ctrl.v\
	$rtl_dir/vcr_op_ctrl_mac.v\
	$rtl_dir/vcr_ovc_ctrl.v\
	$rtl_dir/vcr_sw_alloc_mac.v\
	$rtl_dir/vcr_sw_alloc_sep_if.v\
	$rtl_dir/vcr_sw_alloc_sep_of.v\
	$rtl_dir/vcr_sw_alloc_wf.v\
	$rtl_dir/vcr_top.v\
	$rtl_dir/vcr_vc_alloc_mac.v\
	$rtl_dir/vcr_vc_alloc_sep_if.v\
	$rtl_dir/vcr_vc_alloc_sep_of.v\
	$rtl_dir/vcr_vc_alloc_wf.v\
	$rtl_dir/whr_alloc_mac.v\
	$rtl_dir/whr_ip_ctrl_mac.v\
	$rtl_dir/whr_op_ctrl_mac.v\
	$rtl_dir/whr_top.v]

#set RTL_SOURCE_FILES  "$verilogfiles"      ;# Enter the list of source RTL files if reading from RTL

# The following variables are used by scripts in dc_scripts to direct the location
# of the output files

set REPORTS_DIR "reports"
set RESULTS_DIR "results"

file mkdir ${REPORTS_DIR}
file mkdir ${RESULTS_DIR}

#################################################################################
# Library Setup
#
# This section is designed to work with the settings from common_setup.tcl
# without any additional modification.
#################################################################################

# Define all the library variables shared by all the front-end tools

set_app_var search_path ". ${ADDITIONAL_SEARCH_PATH} $search_path"


# Milkyway variable settings

# Make sure to define the following Milkyway library variables
# mw_logic1_net, mw_logic0_net and mw_design_library are needed by write_milkyway


set_app_var mw_logic1_net ${MW_POWER_NET}
set_app_var mw_logic0_net ${MW_GROUND_NET}

set mw_reference_library ${MW_REFERENCE_LIB_DIRS}
set mw_design_library ${DCRM_MW_LIBRARY_NAME}

set mw_site_name_mapping [list CORE unit Core unit core unit]

# The remainder of the setup below should only be performed in Design Compiler
if {$synopsys_program_name == "dc_shell"}  {

  # Include all libraries for multi-Vth leakage power optimization

  set_app_var target_library ${TARGET_LIBRARY_FILES}
  set_app_var synthetic_library dw_foundation.sldb
  set_app_var link_library "* $target_library $ADDITIONAL_LINK_LIB_FILES $synthetic_library"

  # Set min libraries if they exist
  foreach {max_library min_library} $MIN_LIBRARY_FILES {
    set_min_library $max_library -min_version $min_library
  }

  if {[shell_is_in_topographical_mode]} {

    # Only create new Milkyway design library if it doesn't already exist
    if {![file isdirectory $mw_design_library ]} {
      create_mw_lib   -technology $TECH_FILE \
                      -mw_reference_library $mw_reference_library \
                      $mw_design_library
    } else {
      # If Milkyway design library already exists, ensure that it is consistent with specified Milkyway reference libraries
      set_mw_lib_reference $mw_design_library -mw_reference_library $mw_reference_library
    }

    open_mw_lib     $mw_design_library

    check_library

    set_tlu_plus_files -max_tluplus $TLUPLUS_MAX_FILE \
                       -min_tluplus $TLUPLUS_MIN_FILE \
                       -tech2itf_map $MAP_FILE

    check_tlu_plus_files

  }

  #################################################################################
  # Library Modifications
  #
  # Apply library modifications here after the libraries are loaded.
  #################################################################################

  if {[file exists [which ${LIBRARY_DONT_USE_FILE}]]} {
    source -echo -verbose ${LIBRARY_DONT_USE_FILE}
  }
} 
