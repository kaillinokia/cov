MODULES_PATH = ../../../../../../fe/sinr_deocc
export MODULES_PATH

todaysdate = $(shell date  +%d%b%Y_%H%M)
export todaysdate
CONF ?= 16
IMG ?= ${todaysdate}

ifeq ($(CONF),16)
bsub_mem = 64000
endif
ifeq ($(CONF),32)
bsub_mem = 128000
endif
ifeq ($(CONF),64)
bsub_mem = 1024000
endif


synth:
	bsub -q b_soc_rh7 -R "rusage[mem=$(bsub_mem)]" -cwd ../synth_${IMG} dcnxt_shell -topo -64  -output_log_file dc_${IMG}.log -f rm_dc_scripts/dc.tcl

clean:
	@rm -rf ./*.log
	@rm -rf ./WORK/
	@rm -rf ./reports/
	@rm -rf ./results/
	@rm -rf ./*.svf
	@rm -rf ./CLIBs/
	@rm -rf ./cd_LIB/
	@rm -rf ./alib-52/
	@rm -rf ./icc2_workdir/
	@rm -rf ./workdir/


copy:
	@mkdir arch_${IMG}
	@cp ./reports ./arch_${IMG}/ -R
	@cp ./results ./arch_${IMG}/ -R

run: clean synth

work_space:
	@mkdir  ../synth_${IMG}/
	@mkdir  ../synth_${IMG}/src
	@cp ./* ../synth_${IMG}/ -R
	@cp ../../hdl/ ../synth_${IMG}/src/hdl/ -R
	@cp ../../../common/ ../synth_${IMG}/src/common/ -R


help:
	@echo "-----------------------------------------------------------------------------------------------------------"
	@echo "Target to run:"
	@echo "make synth"
	@echo "make clean"
	@echo "make run CONF=16 : create work space ../synth_(date) + synth for biger config more RAM will be allocated"
	@echo "make run IMG={my_ws} : create work space ../synth_{my_ws} + synth"
	@echo "-----------------------------------------------------------------------------------------------------------"
