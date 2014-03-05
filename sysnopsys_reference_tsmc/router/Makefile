dc:
	dc_shell-xg-t -topographical_mode -f rm_dc_scripts/dc.tcl |tee dc.log

fm:
	/cad/synopsys/fm/2010.03/bin/fm_shell -f rm_dc_scripts/fm.tcl |tee fm.log

icc:
	make -f rm_setup/Makefile_zrt ic

clean_icc:
	make -f rm_setup/Makefile_zrt clean
	rm -rf cpd_pre_*
	rm -f *_icc
	rm -f reports_par/*
	rm -f results_par/*

clean_dc:
	rm -rf WORK
	rm -rf alib-52
	rm -f reports/*
	rm -f results/*
	rm -f filenames*.log
	rm -rf router_wrap_LIB

clean_fm:
	rm -rf formality_svf

clean_all: clean_dc clean_fm clean_icc
	rm -f router.saif
	rm -f teds_power*
	rm -f power_break*
	rm -f area_break*
	rm -f *.log
	rm -f *~


power:
	icc_shell -f rm_icc_zrt_scripts/teds_power.tcl |tee power.log
