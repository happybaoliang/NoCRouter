source -echo ./rm_setup/icc_setup.tcl 
##Open Design
#ted's skiping the metal layer
#open_mw_cel $ICC_METAL_FILL_CEL -lib $MW_DESIGN_LIBRARY
open_mw_cel $ICC_CHIP_FINISH_CEL -lib $MW_DESIGN_LIBRARY

#this reports unannotated power for reference
report_power

read_saif -input router.saif -instance testbench/rtr 
#-verbose # use verbose to list warnings

redirect -tee -file power_break_hier.log "report_power  -analysis high -cell  -hier"
redirect -tee -file power_break_flat.log "report_power -analysis high -cell -flat"
report_area -hierarchy > area_break_hier.log
report_area  > area_break_flat.log

exit
