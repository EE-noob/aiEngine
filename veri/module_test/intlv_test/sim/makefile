# SIMULATOR = VCS for Synopsys's VCS
BUILD_DIR ?= .

SIMULATOR = VCS

FILELIST= ../flist/tb1.f

SEED ?= automatic

VERB ?= UVM_LOW#UVM_MEDIUM

CASE ?= default

help:
	@echo =============================================================================================================
	@echo "! USAGE   	--  make target                  								!"
	@echo "! clean   	=>  clean the earlier log and intermediate files.  						!"
	@echo "! comp    	=>  Create library and compile the code.           						!"
	@echo "! run	=>  clean, compile & run the simulation for axi2spi_base_test in batch mode.		        !" 
	@echo "! wave =>  To view the waveform of axi2spi_base_test		    						!" 
	@echo "! merge     =>  To merge coverage reports for all testcases and  convert to html format.			!"
	@echo "! cov        =>  To open merged coverage report in html format.							!"
	@echo ====================================================================================================================

clean : clean_$(SIMULATOR)
comp : comp_$(SIMULATOR)
sim : sim_$(SIMULATOR)
run : run_$(SIMULATOR)
wave : wave_$(SIMULATOR)
merge : merge_$(SIMULATOR)
cov : cov_$(SIMULATOR)


# ----------------------------- Start of Definitions for Synopsys's VCS Specific Targets -------------------------------#

comp_VCS:
	vcs -l com.log -timescale=1ns/1ps -sverilog -ntb_opts uvm-1.2 -debug_access+all -cm line+cond+tgl+fsm -cm_dir ./cov/cov_case$(CASE) -cm_hier coverage_hierarchy.cfg -full64 -j8 -kdb -lca -f $(FILELIST) +define+ICS_CASE$(CASE)

sim_VCS:
ifeq ($(SEED), automatic)
	./simv -l sim.log0 +fsdbfile+wave$(CASE).fsdb -cm line+cond+tgl+fsm \
	+ntb_random_seed_automatic +vcs+parallel+on +vcs+num_threads=8 +UVM_TESTNAME=ics_base_test \
	+UVM_VERBOSITY=$(VERB) +UVM_TREE
else
	./simv -l sim.log0 +fsdbfile+wave$(CASE).fsdb -cm line+cond+tgl+fsm \
	+ntb_random_seed=$(SEED) +vcs+parallel+on +vcs+num_threads=8 +UVM_TESTNAME=ics_base_test \
	+UVM_VERBOSITY=$(VERB) +UVM_TREE
endif

run_VCS: comp_VCS
ifeq ($(SEED), automatic)
	./simv -l sim.log0 +fsdbfile+wave$(CASE).fsdb -cm line+cond+tgl+fsm \
	+ntb_random_seed_automatic +UVM_TESTNAME=ics_base_test \
	+UVM_VERBOSITY=$(VERB) +UVM_TREE
else
	./simv -l sim.log0 +fsdbfile+wave$(CASE).fsdb -cm line+cond+tgl+fsm \
	+ntb_random_seed=$(SEED) +UVM_TESTNAME=ics_base_test \
	+UVM_VERBOSITY=$(VERB) +UVM_TREE
endif
	
wave_VCS: 
	verdi -ssf wave$(CASE).fsdb -rcFile ~/dark.rc &
	
merge_VCS:
	urg -full64 -dir ./cov/*.vdb -dbname merged -parallel -report urgReport

cov_VCS:
	verdi -cov -covdir merged.vdb/ -full64 &

clean_VCS:
	rm -rf simv* csrc* *.tmp *.vpd *.vdb *.key *.log* *hdrs.h urgReport* *.fsdb novas* verdi* *.txt ./cov ./vdCovLog ./logs
	clear

syn:
	cd ../../syn_qmh/work && \
    dc_shell -64 -f ../script/SynFlow28.tcl