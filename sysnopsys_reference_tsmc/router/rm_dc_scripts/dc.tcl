source -echo -verbose ./rm_setup/dc_setup.tcl

#################################################################################
# Design Compiler Reference Methodology Script for Top-Down Flow
# Script: dc.tcl
# Version: D-2010.03 (March 29, 2010)
# Copyright (C) 2007-2010 Synopsys, Inc. All rights reserved.
#################################################################################

#######################
#Ted's changes
#-comment out "set_max_leakage_power 0", suggested by script
#-enable clock gating through hierachy, suggested by script
#-run a check_only compile_ultra before compiling for real, sanity check
#-compile ultra extra options " -retime -timing_high_effort_script", suggested 
#-comment out gui and congestion reporting, no license
#######################

#################################################################################
# Additional Variables
#
# Add any additional variables needed for your flow here.
#################################################################################

# No additional flow variables are being recommended

#################################################################################
# Setup for Formality verification
#
# SVF should always be written to allow Formality verification
# for advanced optimizations.
#################################################################################

set_svf ${RESULTS_DIR}/${DCRM_SVF_OUTPUT_FILE}

#################################################################################
# Setup SAIF Name Mapping Database
#
# Include an RTL SAIF for better power optimization and analysis.
#
# saif_map should be issued prior to RTL elaboration to create a name mapping
# database for better annotation.
################################################################################

# saif_map -start

#################################################################################
# Read in the RTL Design
#
# Read in the RTL source files or read in the elaborated design (DDC).
# Use the -format option to specify: verilog, sverilog, or vhdl as needed.
#################################################################################

define_design_lib WORK -path ./WORK

analyze -format verilog ${RTL_SOURCE_FILES}
elaborate ${DESIGN_NAME}

# OR

# You can read an elaborated design from the same release.
# Using an elaborated design from an older release will not give the best results.

# read_ddc ${DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE}

write -hierarchy -format ddc -output ${RESULTS_DIR}/${DCRM_ELABORATED_DESIGN_DDC_OUTPUT_FILE}


#################################################################################
# Apply Logical Design Constraints
#################################################################################

source -echo -verbose ${DCRM_CONSTRAINTS_INPUT_FILE}

# You can enable analysis and optimization for multiple clocks per register.
# To use this, you must constrain to remove false interactions between mutually exclusive
# clocks.  This is needed to prevent unnecessary analysis that can result in
# a significant runtime increase with this feature enabled.
#
# set_clock_groups -physically_exclusive | -logically_exclusive | -asynchronous \
#                  -group {CLKA, CLKB} -group {CLKC, CLKD} 
#
# set_app_var timing_enable_multiple_clocks_per_reg true

#################################################################################
# Apply The Operating Conditions
#################################################################################

# Set operating condition on top level

# set_operating_conditions -max <max_opcond> -min <min_opcond>

#################################################################################
# Create Default Path Groups
#
# Separating these paths can help improve optimization.
# Remove these path group settings if user path groups have already been defined.
#################################################################################

set ports_clock_root [filter_collection [get_attribute [get_clocks] sources] object_class==port]
group_path -name REGOUT -to [all_outputs] 
group_path -name REGIN -from [remove_from_collection [all_inputs] $ports_clock_root] 
group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] $ports_clock_root] -to [all_outputs]

#################################################################################
# Power Optimization Section
#################################################################################

    #############################################################################
    # Clock Gating Setup
    #############################################################################

    # Default clock_gating_style suits most designs.  Change only if necessary.
    # set_clock_gating_style ...

    # Clock gate insertion is now performed during compile_ultra -gate_clock
    # so insert_clock_gating is no longer recommended at this step.

    # The following setting can be used to enable global clock gating.
    # With global clock gating, common enables are extracted across hierarchies
    # which results in fewer redundant clock gates. 

    set compile_clock_gating_through_hierarchy true 

    # For better timing optimization of enable logic, clock latency for 
    # clock gating cells can be optionally specified.

    # set_clock_gate_latency -clock <clock_name> -stage <stage_num> \
    #         -fanout_latency {fo_range1 latency_val1 fo_range2 latency_val2 ...}

    #############################################################################
    # Apply Power Optimization Constraints
    #############################################################################

    # Include a SAIF file, if possible, for power optimization.  If a SAIF file
    # is not provided, the default toggle rate of 0.1 will be used for propagating
    # switching activity.

    # read_saif -auto_map_names -input ${DESIGN_NAME}.saif -instance < DESIGN_INSTANCE > -verbose

    # Enable both of the following settings for total power optimization.
    # Note: set_max_total_power should no longer be used.

    # Only use set_max_leakage_power if you have multiple-Vt libraries.
    #set_max_leakage_power 0
    # set_max_dynamic_power 0

    if {[shell_is_in_topographical_mode]} {
      # Use the following command to enable power prediction using clock tree estimation.

      # set_power_prediction true -ct_references <LIB CELL LIST>
    }

if {[shell_is_in_topographical_mode]} {

  ##################################################################################
  # Apply Physical Design Constraints
  #
  # Optional: Floorplan information can be read in here if available.
  # This is highly recommended for irregular floorplans.
  #
  # Floorplan constraints can be provided from one of the following sources:
  # 	* extract_physical_constraints with a DEF file
  #	* read_floorplan with a floorplan file (written by write_floorplan)
  #	* User generated Tcl physical constraints
  #
  ##################################################################################

  # Specify ignored layers for routing to improve correlation
  # Use the same ignored layers that will be used during place and route

  if { ${MIN_ROUTING_LAYER} != ""} {
    set_ignored_layers -min_routing_layer ${MIN_ROUTING_LAYER}
  }
  if { ${MAX_ROUTING_LAYER} != ""} {
    set_ignored_layers -max_routing_layer ${MAX_ROUTING_LAYER}
  }

  report_ignored_layers

  # If the macro names change after mapping and writing out the design due to
  # ungrouping or Verilog change_names renaming, it may be necessary to translate 
  # the names to correspond to the cell names that exist before compile.

  # During DEF constraint extraction, extract_physical_constraints automatically
  # matches DEF names back to precompile names in memory using standard matching rules.
  # read_floorplan will also automatically perform this name matching.

  # Modify fuzzy_query_options if other characters are used for hierarchy separators
  # or bus names. 

  # set_fuzzy_query_options -hierarchical_separators {/ _ .} \
  #                         -bus_name_notations {[] __ ()} \
  #                         -class {cell pin port net} \
  #                         -show

  ## For DEF floorplan input

  # The DEF file for DCT can be written from ICC using the following recommended options
  # icc_shell> write_def -version 5.7 -rows_tracks_gcells -macro -pins -blockages -specialnets \
  #                      -vias -region_groups -verbose -output ${DCRM_DCT_DEF_INPUT_FILE}

  if {[file exists [which ${DCRM_DCT_DEF_INPUT_FILE}]]} {
    extract_physical_constraints ${DCRM_DCT_DEF_INPUT_FILE}
  }
  
  # OR

  ## For floorplan file input

  # The floorplan file for DCT can be written from ICC using the following recommended options
  # icc_shell> write_floorplan -placement {io hard_macro soft_macro} -create_terminal \
  #                            -row -create_bound -preroute ${DCRM_DCT_FLOORPLAN_INPUT_FILE}

  if {[file exists [which ${DCRM_DCT_FLOORPLAN_INPUT_FILE}]]} {
    read_floorplan ${DCRM_DCT_FLOORPLAN_INPUT_FILE}
  }

  # OR

  ## For Tcl file input

  # For Tcl constraints, the name matching feature must be explicitly enabled
  # and will also use the set_fuzzy_query_options setttings.  This should 
  # be turned off after the constraint read in order to minimize runtime.

  if {[file exists [which ${DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE}]]} {
    set_app_var fuzzy_matching_enabled true 
    source -echo -verbose ${DCRM_DCT_PHYSICAL_CONSTRAINTS_INPUT_FILE}
    set_app_var fuzzy_matching_enabled false 
  }


  # Use write_floorplan to save the applied floorplan.
  # Note: write_physical_constraints should no longer be used.
  write_floorplan -all ${RESULTS_DIR}/${DCRM_DCT_FLOORPLAN_OUTPUT_FILE}

  # Verify that all the desired physical constraints have been applied
  # Add the -pre_route option to include pre-routes in the report
  report_physical_constraints > ${REPORTS_DIR}/${DCRM_DCT_PHYSICAL_CONSTRAINTS_REPORT}
}

#################################################################################
# Apply Additional Optimization Constraints
#################################################################################

# Prevent assignment statements in the Verilog netlist.
set_fix_multiple_port_nets -all -buffer_constants

#################################################################################
# Compile the Design
#
# Recommended Options:
#
#     -scan
#     -gate_clock
#     -retime
#     -timing_high_effort_script
#     -congestion
#
# Use compile_ultra as your starting point. For test-ready compile, include
# the -scan option with the first compile and any subsequent compiles.
#
# Use -gate_clock to insert clock-gating logic during optimization.  This
# is now the recommended methodology for clock gating.
#
# Use -retime to enable adaptive retiming optimization for further timing
# benefit without any runtime or memory overhead.
#
# The -timing_high_effort_script option can be used to try and improve the
# optimization results at the tradeoff of some additional runtime.
#
# Note: The -area_high_effort_script option is not needed as it is aliased to
#       the default compile_ultra optimization.  The default compile_ultra
#       optimization is tuned to provide good area optimization.
#
# The -congestion option (topographical mode only) enables specialized optimizations that
# reduce routing related congestion during synthesis and scan compression insertion
# with DFT Compiler.  Only enable congestion optimization if required.
# This option requires a license for Design Compiler Graphical.
#
# Note: The -num_cpus option is obsolete and should no longer be
#       used to enable multicore optimization.  It has been replaced by the
#       set_host_options command which can be found in the dc_setup.tcl script.
#
#################################################################################

if {[shell_is_in_topographical_mode]} {
# Use the "-check_only" option of "compile_ultra" to verify that your
# libraries and design are complete and that optimization will not fail
# in topographical mode.  Use the same options as will be used in compile_ultra.
echo "Ultra Check"
 compile_ultra -scan -gate_clock  -retime -timing_high_effort_script  -check_only
}
echo "Ultra Run"
compile_ultra -scan -gate_clock -retime -timing_high_effort_script


#################################################################################
# Save Design after First Compile
#################################################################################

write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_COMPILE_ULTRA_DDC_OUTPUT_FILE}

#################################################################################
# DFT Compiler Optimization Section
#################################################################################

    #############################################################################
    # DFT Signal Type Definitions
    #
    # These are design-specific settings that should be modified.
    # The following are only examples and should not be used.
    #############################################################################

    # It is recommended that top-level test ports be defined as a part of the
    # RTL design and included in the netlist for floorplanning.

    # If you create test ports here and they are not in your floorplan, you should
    # set_port_location for these additional test ports for topographical mode synthesis.

    # create_port ScanPortName ... (repeat for each new test port)

    if {[shell_is_in_topographical_mode]} {
      # set_port_location -coordinate {x y} ScanPortName ... (repeat for each new test port)
    }

    # set_dft_signal -view spec -type ScanDataOut -port SO
    # set_dft_signal -view spec -type ScanDataIn -port SI
    # set_dft_signal -view spec -type ScanEnable -port SCAN_ENABLE
    # set_dft_signal -view existing_dft -type ScanClock -port [list CLK] -timing {45 55}
    # set_dft_signal -view existing_dft -type Reset -port RESET -active 0

    source -echo -verbose ${DCRM_DFT_SIGNAL_SETUP_INPUT_FILE}

    #############################################################################
    # DFT for Clock Gating
    #
    # This section includes variables and commands used only when clock-gating
    # has been performed in the design.
    #############################################################################

    # Use the following command to initialize clock gating cells for test that are
    # made transparent with a signal held constant for testing, e.g. of type 'Constant'.
    # The value set depends on the hierarchy depth of the clock gating cells.
    # This setting is not needed where clock gating cells are controlled with a scan enable.

    # set_dft_drc_configuration -clock_gating_init_cycles 1

    # To specify a dedicated ScanEnable/TestMode signal to be used for clock-gating,
    # use the "-usage clock_gating" option of the "set_dft_signal" command

    # set_dft_signal -view spec -type <ScanEnable|TestMode> -port <dedicated port> -usage clock_gating

    # You can specify the clock-gating connectivity of the ScanEnable/TestMode signals
    # after they are predefined with set_dft_signal -usage clock_gating

    # set_dft_connect <LABEL> -type clock_gating_control -source <DFT signal> [-target ...]

    #############################################################################
    # DFT Configuration
    #############################################################################

    set_dft_insertion_configuration -preserve_design_name true

    # Do not run incremental compile as a part of insert_dft
    set_dft_insertion_configuration -synthesis_optimization none

    ## DFT Clock Mixing Specification
    # For a hierarchical flow, don't mix clocks at the block-level:
    # set_scan_configuration -clock_mixing no_mix

    # For top-down methodology clock mixing is recommended, if possible:
    set_scan_configuration -clock_mixing mix_clocks

    #############################################################################
    # DFT Adaptive Scan Compression Configuration
    #############################################################################

    # Use the following to enable adaptive scan compression

    # set_dft_configuration -scan_compression enable

    # DFTMAX Adaptive Scan Compression Options
    # 
    #  -min_power true
    #     This specifies that compressor inputs are to be gated for functional power saving. 
    #     It also reduces glitching during functional and capture operations
    #     Default for -min_power option is false. Recommend that you set this to true. 
    #
    #  -xtolerance: value is set to tool default. 
    #     Specify "high" to generate adaptive scan architecture that has 100% X-tolerance
    #
    #  -minimum_compression: tool default is a target compression ratio of 10
    #
    #  -location <compressor_decompressor_location>
    #      Specifies the instance name in which the compressor and decompressor will be instantiated
    #      The default location is the top-level of the current design.
    # 
    # For details on these and other adaptive scan options please refer to the
    # DFTMAX Compression User Guide, Chapter 2, "Using Adaptive Scan Technology"
    # and Chapter 4, "X-Tolerant Adaptive Scan"
     
    # set_scan_compression_configuration -xtolerance default -min_power true

    # Use the following to define the test-mode to be used for adaptive scan compression
    # Ensure that that test mode signals to be used for clock-gating have
    # been configured with set_dft_signal -usage clock_gating.

    # set_dft_signal -view spec -type TestMode -port scan_compression_enable

    #############################################################################
    # DFT Additional Setup
    #############################################################################

    # Add any additional design-specific DFT constraints here

    #############################################################################
    # DFT Test Protocol Creation
    #############################################################################

    # "-capture_procedure multi_clock" is default for "create_test_protocol"
    # since the B-2008.09-SP2 release.  This is the recommended value.
    # If necessary, you can use the "-capture_procedure single_clock" option. 

    create_test_protocol

    #############################################################################
    # DFT Scan Chain Insertion
    #############################################################################

    # Use the -verbose version of dft_drc to assist in debugging if necessary
    
    dft_drc                                > ${REPORTS_DIR}/${DCRM_DFT_DRC_CONFIGURED_SUMMARY_REPORT}
    dft_drc -verbose                       > ${REPORTS_DIR}/${DCRM_DFT_DRC_CONFIGURED_VERBOSE_REPORT}
    report_scan_configuration              > ${REPORTS_DIR}/${DCRM_DFT_SCAN_CONFIGURATION_REPORT}
    report_dft_insertion_configuration     > ${REPORTS_DIR}/${DCRM_DFT_PREVIEW_CONFIGURATION_REPORT}

    # Use the -show all version to preview_dft for more detailed report
    preview_dft                            > ${REPORTS_DIR}/${DCRM_DFT_PREVIEW_DFT_SUMMARY_REPORT}
    preview_dft -show all -test_points all > ${REPORTS_DIR}/${DCRM_DFT_PREVIEW_DFT_ALL_REPORT}

    insert_dft

    #################################################################################
    # DFT Incremental Compile
    #
    # Only required if scan chain insertion has been performed.
    #
    # Include the -timing_high_effort_script option here if this option was used
    # during the full compile_ultra optimization step.
    #################################################################################

    compile_ultra -incremental -scan

#################################################################################
# Write Out Final Design and Reports
#
#        .ddc:   Recommended binary format used for subsequent Design Compiler sessions
#    Milkyway:   Recommended binary format for IC Compiler
#        .v  :   Verilog netlist for ASCII flow (Formality, PrimeTime, VCS)
#       .spef:   Topographical mode parasitics for PrimeTime
#        .sdf:   SDF backannotated topographical mode timing for PrimeTime
#        .sdc:   SDC constraints for ASCII flow
#
#################################################################################

change_names -rules verilog -hierarchy

    #############################################################################
    # DFT Write out Test Protocols and Reports
    #############################################################################

    # write_scan_def adds SCANDEF info to the design database in memory so this
    # must be performed prior to writing out the design for binary SCANDEF.

    write_scan_def -output ${RESULTS_DIR}/${DCRM_DFT_FINAL_SCANDEF_OUTPUT_FILE}
    check_scan_def > ${REPORTS_DIR}/${DCRM_DFT_FINAL_CHECK_SCAN_DEF_REPORT}
    write_test_model -format ctl -output ${RESULTS_DIR}/${DCRM_DFT_FINAL_CTL_OUTPUT_FILE}

    report_dft_signal > ${REPORTS_DIR}/${DCRM_DFT_FINAL_DFT_SIGNALS_REPORT}

    # DFT outputs for regular scan

    write_test_protocol -test_mode Internal_scan -output ${RESULTS_DIR}/${DCRM_DFT_FINAL_PROTOCOL_OUTPUT_FILE}
    report_scan_path > ${REPORTS_DIR}/${DCRM_DFT_FINAL_SCAN_PATH_REPORT}
    current_test_mode Internal_scan
    dft_drc > ${REPORTS_DIR}/${DCRM_DFT_DRC_FINAL_REPORT}

    # DFT outputs for adaptive scan compression

    # write_test_protocol -test_mode ScanCompression_mode -output ${RESULTS_DIR}/${DCRM_DFT_FINAL_SCAN_COMPR_PROTOCOL_OUTPUT_FILE}
    # current_test_mode ScanCompression_mode
    # report_scan_path > ${REPORTS_DIR}/${DCRM_DFT_FINAL_SCAN_COMPR_SCAN_PATH_REPORT}
    # dft_drc > ${REPORTS_DIR}/${DCRM_DFT_DRC_FINAL_SCAN_COMPR_REPORT}

#################################################################################
# Write out Design
#################################################################################

# Write and close SVF file and make it available for immediate use
set_svf -off

write -format ddc -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_DDC_OUTPUT_FILE}
write -f verilog -hierarchy -output ${RESULTS_DIR}/${DCRM_FINAL_VERILOG_OUTPUT_FILE}


#################################################################################
# Write out Design Data
#################################################################################

if {[shell_is_in_topographical_mode]} {

  # Note: write_physical_constraints should no longer be used.
  write_floorplan -all ${RESULTS_DIR}/${DCRM_DCT_FINAL_FLOORPLAN_OUTPUT_FILE}

  # Write parasitics data from DCT placement for static timing analysis
  write_parasitics -output ${RESULTS_DIR}/${DCRM_DCT_FINAL_SPEF_OUTPUT_FILE}

  # Write SDF backannotation data from DCT placement for static timing analysis
  write_sdf ${RESULTS_DIR}/${DCRM_DCT_FINAL_SDF_OUTPUT_FILE}

  # Do not write out net RC info into SDC
  set_app_var write_sdc_output_lumped_net_capacitance false
  set_app_var write_sdc_output_net_resistance false
}

write_sdc -nosplit ${RESULTS_DIR}/${DCRM_FINAL_SDC_OUTPUT_FILE}

# If SAIF is used, write out SAIF name mapping file for PrimeTime-PX
# saif_map -type ptpx -write_map ${RESULTS_DIR}/${DESIGN_NAME}.mapped.SAIF.namemap

#################################################################################
# Generate Final Reports
#################################################################################

report_qor > ${REPORTS_DIR}/${DCRM_FINAL_QOR_REPORT}
report_timing -transition_time -nets -attributes -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_TIMING_REPORT}

if {[shell_is_in_topographical_mode]} {
  report_area -physical -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_AREA_REPORT}
} else {
  report_area -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_AREA_REPORT}
}

#TED: stanford does not have the commands needed for congestion reporting and gui

if {[shell_is_in_topographical_mode]} {
    # report_congestion (topographical mode only) reports estimated routing related congestion
  # after topographical mode synthesis.
  # This command requires a license for Design Compiler Graphical.

  #report_congestion > ${REPORTS_DIR}/${DCRM_DCT_FINAL_CONGESTION_REPORT}

  # Use the following to generate and write out a congestion map from batch mode
  # This requires a GUI session to be temporarily opened and closed so a valid DISPLAY
  # must be set in your UNIX environment.

#  if {[info exists env(DISPLAY)]} {
#    gui_start

    # Create a layout window
#    set MyLayout [gui_create_window -type LayoutWindow]

    # Build congestion map in case report_congestion was not previously run
#    report_congestion -build_map

    # Display congestion map in layout window
#    gui_show_map -map "Global Route Congestion" -show true

    # Zoom full to display complete floorplan
#    gui_zoom -window [gui_get_current_window -view] -full

    # Write the congestion map out to an image file
    # You can specify the output image type with -format png | xpm | jpg | bmp

    # The following saves only the congestion map without the legends
#    gui_write_window_image -format png -file ${REPORTS_DIR}/${DCRM_DCT_FINAL_CONGESTION_MAP_OUTPUT_FILE}

    # The following saves the entire congestion map layout window with the legends
#    gui_write_window_image -window ${MyLayout} -format png -file ${REPORTS_DIR}/${DCRM_DCT_FINAL_CONGESTION_MAP_WINDOW_OUTPUT_FILE}

#    gui_stop
#  } else {
#    puts "Information: The DISPLAY environment variable is not set. Congestion map generation has been skipped."
#  }
}

# Use SAIF file for power analysis
# read_saif -auto_map_names -input ${DESIGN_NAME}.saif -instance < DESIGN_INSTANCE > -verbose

report_power -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_POWER_REPORT}
report_clock_gating -nosplit > ${REPORTS_DIR}/${DCRM_FINAL_CLOCK_GATING_REPORT}

#################################################################################
# Write out Milkyway Design for Top-Down Flow
#
# This should be the last step in the script
#################################################################################

if {[shell_is_in_topographical_mode]} {
  # write_milkyway uses: mw_logic1_net, mw_logic0_net and mw_design_library variables from dc_setup.tcl
  write_milkyway -overwrite -output ${DCRM_FINAL_MW_CEL_NAME}
}

exit
