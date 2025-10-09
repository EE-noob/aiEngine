# SIMULATOR = VCS for Synopsys's VCS
BUILD_DIR ?= .

SIMULATOR = VCS

FILELIST= ../flist/tb1.f

SEED ?= automatic

VERB ?= UVM_LOW#UVM_MEDIUM

CASE ?= default

# 每个 case 使用独立目录
BUILD_CASE_DIR := $(BUILD_DIR)/build_case$(CASE)
SIMV := $(BUILD_CASE_DIR)/simv
COM_LOG := com.log
SIM_LOG := sim.log
FSDB_FILE := $(BUILD_CASE_DIR)/wave$(CASE).fsdb
COV_DIR := $(BUILD_CASE_DIR)/cov_case$(CASE)

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
	mkdir -p $(BUILD_CASE_DIR)
	cd $(BUILD_CASE_DIR) && \
	vcs -l $(COM_LOG) -timescale=1ns/1ps -sverilog -ntb_opts uvm-1.2 \
	-debug_access+pp -full64 -j8  -f $(abspath $(FILELIST)) +define+ICS_CASE$(CASE)

capcov_VCS:
	mkdir -p $(BUILD_CASE_DIR)
	cd $(BUILD_CASE_DIR) && \
	vcs -l $(COM_LOG) -timescale=1ns/1ps -sverilog -ntb_opts uvm-1.2 \
	-debug_access+all -cm line+cond+tgl+fsm -cm_dir ./cov_case \
	-cm_hier coverage_hierarchy.cfg -full64 -j8 -kdb -lca -f $(abspath $(FILELIST)) +define+ICS_CASE$(CASE)


sim_VCS:
	mkdir -p $(BUILD_CASE_DIR)
ifeq ($(SEED), automatic)
	cd $(BUILD_CASE_DIR) && ./simv -l $(SIM_LOG) +fsdbfile+wave$(CASE).fsdb -cm line+cond+tgl+fsm \
	+ntb_random_seed_automatic +vcs+parallel+on +vcs+num_threads=8 +UVM_TESTNAME=ics_base_test \
	+UVM_VERBOSITY=$(VERB) +UVM_TREE
else
	cd $(BUILD_CASE_DIR) && ./simv -l $(SIM_LOG) +fsdbfile+wave$(CASE).fsdb -cm line+cond+tgl+fsm \
	+ntb_random_seed=$(SEED) +vcs+parallel+on +vcs+num_threads=8 +UVM_TESTNAME=ics_base_test \
	+UVM_VERBOSITY=$(VERB) +UVM_TREE
endif

run_VCS: comp_VCS sim_VCS
	
wave_VCS: 
	verdi -ssf $(FSDB_FILE) -rcFile ~/dark.rc &

merge_VCS:
	@echo "[INFO] Searching for .vdb files to merge..."
	find $(BUILD_DIR) -type d -name "cov_case*" | grep build_case | sort > .cov_dirs.txt
	@echo "[INFO] Found coverage dirs:"
	cat .cov_dirs.txt
	@echo "[INFO] Running URG to merge coverage..."
	urg -full64 -dir `cat .cov_dirs.txt` -dbname merged -parallel -report urgReport

cov_VCS:
	verdi -cov -covdir merged.vdb/ -full64 &

clean_VCS:
	rm -rf $(BUILD_DIR)/build_case* simv* csrc* *.tmp *.vpd *.vdb *.key *.log* *hdrs.h urgReport* *.fsdb novas* verdi* *.txt ./cov ./vdCovLog ./logs .cov_dirs.txt
	clear

syn:
	cd ../../syn_qmh/work && \
    dc_shell -64 -f ../script/SynFlow28.tcl
fl:
	find ../tb ../uvc/sa ../uvc/m ../env ../test  -name *.v -o -name *.sv -printf "../%p\n"> ../flist/env.f
	find ../../rtl   -name *.v -o -name *.sv -printf "../%p\n"> ../flist/dut.f