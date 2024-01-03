################################################################################
# General paths, directories and settings.
################################################################################
# General paths. MODULES_PATH may be needed somewhere as environment variable, so export it here.
WS_ROOT = $(BUILD_ROOT)/../../../../..
export FE_PATH = $(WS_ROOT)/fe/sinr_deocc
export TB_PATH = $(WS_ROOT)/verif/sinr_deocc/psinr_verif/src

ALT_LIBS := /sitework/soc/LEKA011/common_libs/SIM_LIBS_quartus_pro_21_4_11fw_vcs_P_2019_06_SP2_3
DC_LIBS := /projectsqum/techlib/tsmc/tcbn05/libraries/TSMCHOME/digital/Front_End/verilog

BUFFSKRD_LIB := tcbn05_bwph210l6p51cnod_base_lvtll_110a

MM_COVS_DIR = covs
MM_LOGS_DIR = logs
MM_LIBS_DIR = libs
MM_SIMS_DIR = sims
MM_TAGS_DIR = tags
COV_REPORT_DIR = $(MM_ABSPATH_IMG_BUILD_DIR)/coverage_report
# Default libraries.
MM_LIB_DUT_NAME = dut_lib
MM_LIB_TB_NAME = tb_lib
MM_LIB_TENNM_NAME = tennm_atoms
MM_LIB_BUFF_NAME = bufferSkrd
MM_LIB_RECP_NAME = ac_recip
MM_LIB_DUT_DIR = $(MM_LIBS_DIR)/$(MM_LIB_DUT_NAME)
MM_LIB_TB_DIR = $(MM_LIBS_DIR)/$(MM_LIB_TB_NAME)
MM_LIB_TENNM_DIR = $(MM_LIBS_DIR)/$(MM_LIB_TENNM_NAME)
MM_LIB_BUFF_DIR = $(MM_LIBS_DIR)/$(MM_LIB_BUFF_NAME)
MM_LIB_RECP_DIR = $(MM_LIBS_DIR)/$(MM_LIB_RECP_NAME)
MM_TEST_BASE = $(NAME)_$(SEED)
MM_SIM_DIR = $(MM_SIMS_DIR)/$(MM_TEST_BASE)
################################################################################
# Simulation parameters setting.
################################################################################
TOP_MODULES := tb_top dut_top
TIMESCALE ?= 1ns/1ps
UVM_TEST      = 
NAME          = 
VERB          = UVM_LOW
SEED          = 1
SIM           = 
GUI           = 0
COV           = 0
DEBUG         = 0
GLS           = 0

VHDL_TOOL     ?= 
SVLOG_TOOL    ?= 
ELAB_TOOL     ?= 
RUN_TOOL      ?= 

TB_SVLOG_OPTS ?=
ELAB_OPTS     ?=
RUN_OPTS      ?=

MAX_UVM_ERRORS = 1000

MM_TIME_UNIT = 1ns
MM_TIME_RES = 1ps


# Default elaborated image name.
MM_ELAB_IMAGE_NAME = simv
# Default base name for simulation runtime files, like logs and waves.
MM_SIMFILE_BASE_NAME = sim
# vcs coverage scope file
COVERAGE_SCOPE_FILE = $(MM_ABSPATH_IMG_BUILD_DIR)/cov_scopes.txt
# Path to the TCL script file.
MM_SIM_DIR_TCL_FILE = $(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_SIM_DIR)/$(MM_SIMFILE_BASE_NAME).tcl
# Simulator bit modes. If 0 is defined, 64 bit mode is used.
MM_ENABLE_32BIT_MODE_QUESTA = 1
MM_ENABLE_32BIT_MODE_VCS = 0
# Default code coverage collection types for Questa.
# - s: statement (or line)
# - b: branch
# - c: condition
# - e: expression
# - t: toggle
# - f: fsm
MM_CODE_COVERAGE_OPTS_QUESTA = sbcetf
# Default coverage collection types for VCS/Verdi. Define by separating the following types with "+" sign
# - line: statement (or line)
# - branch: branch
# - cond: condition
# - tgl: toggle
# - fsm: fsm
# - assert: assert
MM_CODE_COVERAGE_OPTS_VCS = line+branch+cond+tgl+fsm+assert
# Defines for how many lines "UVM_ERROR" and "UVM_FATAL" numbers are searched at the end of simulation logs.
MM_TAIL_SEARCH_LINES = 500

# Set tools for compilation elaboration simulation.
ifeq ($(SIM), questa)
  VHDL_TOOL = vcom
  SVLOG_TOOL = vlog
  ELAB_TOOL = vopt
  RUN_TOOL = vsim 
else
  VHDL_TOOL = vhdlan
  SVLOG_TOOL = vlogan
  ELAB_TOOL = vcs
  RUN_TOOL = ../../$(MM_ELAB_IMAGE_NAME)
endif

# Set sv compile options.
ifeq ($(SIM), questa)
  TB_SVLOG_OPTS += -L $(QUESTA_HOME)/uvm-1.2
  TB_SVLOG_OPTS += -nologo -incr -lint -hazards -assertdebug -linedebug -fsmdebug
  TB_SVLOG_OPTS += +define+NUM_PARA_RE=$(NUM_PARA_RE)
  TB_SVLOG_OPTS += +define+UVM_REG_DATA_WIDTH=64
  TB_SVLOG_OPTS += +define+UVM_REG_ADDR_WIDTH=64
else
  TB_SVLOG_OPTS += -ntb_opts uvm-1.2
  TB_SVLOG_OPTS += +define+NUM_PARA_RE=$(NUM_PARA_RE)
  TB_SVLOG_OPTS += +define+UVM_REG_DATA_WIDTH=32
  TB_SVLOG_OPTS += +define+UVM_REG_ADDR_WIDTH=32
  ifeq ($(GLS), 1)
  TB_SVLOG_OPTS += +define+GLS=1
  endif
endif

# Set sv elab options.
ifeq ($(SIM), questa)
  ELAB_OPTS += -L $(MM_LIB_DUT_DIR)
  ELAB_OPTS += -L $(QUESTA_HOME)/uvm-1.2
  ELAB_OPTS += -incr -hazards +checkALL +acc -error 3473 -timescale=$(TIMESCALE)
  ifeq ($(DEBUG), 1)
    ELAB_OPTS += -assertdebug -linedebug -fsmdebug
  endif
  ELAB_OPTS += -Gnum_parallel_re=$(NUM_PARA_RE)
  ELAB_OPTS += -Gfpga_opt_g=$(FPGA_OPT)
else
  ifeq ($(DEBUG), 1)
    ELAB_OPTS += -debug_access+all +UVM_TR_RECORD
  else
    ELAB_OPTS += -debug_access+r+fn
  endif
  ELAB_OPTS += -ntb_opts uvm-1.2 
  ELAB_OPTS += -gv num_parallel_re=$(NUM_PARA_RE) 
  ELAB_OPTS += -gv fpga_opt_g=$(FPGA_OPT)
  ELAB_OPTS += -timescale=$(TIMESCALE)
  ifeq ($(GLS), 1)
  ELAB_OPTS += -liblist $(MM_LIB_DUT_NAME)+$(MM_LIB_TB_NAME)+altera_lnsim+altera_mf+altera+$(MM_LIB_TENNM_NAME)+$(MM_LIB_BUFF_NAME)+$(MM_LIB_RECP_NAME)
  endif
endif

# Set sv run options.
ifeq ($(SIM), questa)
  RUN_OPTS += -lib $(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_LIB_TB_DIR) $(MM_ELAB_IMAGE_NAME)
  RUN_OPTS += $(MM_TOOL_BITMODE) -sv_seed $(SEED) -suppress 12003 -error 3473
  RUN_OPTS += -L $(QUESTA_HOME)/uvm-1.2
#   RUN_OPTS += -L dut_lib
  ifeq ($(GUI), 1)
    RUN_OPTS += -i
  else
    RUN_OPTS += -batch
  endif
  ifeq ($(DEBUG), 1)
    RUN_OPTS += -wlf ./$(MM_SIMFILE_BASE_NAME).wlf
	RUN_OPTS += -assertdebug -fsmdebug
  endif
  RUN_OPTS += -solvefaildebug -printsimstats
  RUN_OPTS += +UVM_MAX_QUIT_COUNT=$(MAX_UVM_ERRORS)
  RUN_OPTS += -do "do $(MM_SIMFILE_BASE_NAME).tcl"
#   RUN_OPTS += +UVM_TIMEOUT=5_000_000_000_000,YES
else
  RUN_OPTS += +vcs+flush -licwait 600
endif


ifdef TASK0_PATH
	RUN_OPTS += +task0_path=$(TASK0_PATH)
endif
ifdef TASK1_PATH
	RUN_OPTS += +task1_path=$(TASK1_PATH)
endif
ifdef TASK2_PATH
	RUN_OPTS += +task2_path=$(TASK2_PATH)
endif
ifdef TASK3_PATH
	RUN_OPTS += +task3_path=$(TASK3_PATH)
endif
ifdef TASK4_PATH
	RUN_OPTS += +task4_path=$(TASK4_PATH)
endif
ifdef CHUNK_SIZE
	RUN_OPTS += +chunk_size=$(CHUNK_SIZE)
endif
ifdef NUM_PARA_RE
	RUN_OPTS += +num_parallel_re=$(NUM_PARA_RE)
endif
ifdef FPGA_OPT
	RUN_OPTS += +fpga_opt=$(FPGA_OPT)
endif

# Coverage scopes and settings.
ifeq ($(COV), 1)
	ifeq ($(SIM), questa)
		ELAB_OPTS += +cover=$(MM_CODE_COVERAGE_OPTS_QUESTA)+/dut_top/inst_dut_top.
		ELAB_OPTS += -toggleportsonly
		RUN_OPTS += -coverage
	else
		ELAB_OPTS += -cm_hier $(COVERAGE_SCOPE_FILE)
	endif
endif

ifeq ($(VERDI), 1)
    TB_SVLOG_OPTS += -kdb -debug_access+all+reverse
    ELAB_OPTS += -kdb -debug_access+all+reverse
endif


################################################################################
# vcs uvm compile specific settings.
################################################################################
UVM_COMP_OPTS += -sverilog
UVM_COMP_OPTS += +define+UVM_VERDI_NO_PORT_RECORDING
UVM_COMP_OPTS += +define+UVM_REG_DATA_WIDTH=32
UVM_COMP_OPTS += +define+UVM_REG_ADDR_WIDTH=32
UVM_COMP_OPTS += -full64
UVM_COMP_OPTS  = -ntb_opts uvm-1.2

# Set uvm lib compile options
INCDIR+=+incdir+$(TB_PATH)/env
INCDIR+=+incdir+$(TB_PATH)/common
INCDIR+=+incdir+$(TB_PATH)/sequence
INCDIR+=+incdir+$(TB_PATH)/tc
INCDIR+=+incdir+$(TB_PATH)/top

#specifies system verilog compile variant 
SVLOG_OPTS = $(TB_SVLOG_OPTS)
SVLOG_OPTS += $(INCDIR)
SVLOG_OPTS += -timescale=$(TIMESCALE)

# *********************************************************************************************
# Standard modularmake project specific targets (called by mm_base.mk).
# - init:         Actions for any needed initializations for compilation and simulations.
# - comp_dut:     Actions for DUT compilation..
# - comp_tb:      Actions for TB compilation..
# - elab:         Actions for DUT and TB elaboration/optimization.
# - init_sim:     Actions for initializing any files or TCL commands the simulation needs
#                      before launch. The directory or the TCL file can be accessed by using 
#                      MM_SIM_DIR and MM_SIM_DIR_TCL_FILE variables.
# - post_sim:     Actions for any post-simulations related stuff, like status checking.
# *********************************************************************************************
.PHONY: proj_init
.PHONY: proj_comp_dut
.PHONY: proj_comp_tb
.PHONY: proj_elab
.PHONY: proj_pre_sim
.PHONY: proj_post_sim
.PHONY: cov_rpt


proj_init:
ifeq ($(SIM), questa)
	vlib $(MM_LIB_DUT_DIR)
	vlib $(MM_LIB_TB_DIR)
else
	mkdir -p ./$(MM_LIB_DUT_DIR)
	mkdir -p ./$(MM_LIB_TB_DIR)
	mkdir -p ./$(MM_LIB_TENNM_DIR)
	mkdir -p ./$(MM_LIB_BUFF_DIR)
	mkdir -p ./$(MM_LIB_RECP_DIR)
	@echo "+tree dut_top.inst_dut_top" >> $(COVERAGE_SCOPE_FILE)
	@echo "-tree dut_top.inst_dut_top.U_COMBINER.I_GAIN_SYNC_FIFO_GENQ" >> $(COVERAGE_SCOPE_FILE)
	@echo "-tree dut_top.inst_dut_top.U_COMBINER.I_PSINR_SYNC_FIFO_GENQ" >> $(COVERAGE_SCOPE_FILE)
	@echo "-tree dut_top.inst_dut_top.U_PSINR_CALC.I_LAYER_DMAP_SYNC_FIFO_GENQ" >> $(COVERAGE_SCOPE_FILE)
	@echo "-tree dut_top.inst_dut_top.U_PSINR_CALC.I_PSINR_OUT_SYNC_FIFO_GENQ" >> $(COVERAGE_SCOPE_FILE)
	# @echo "-file $(FE_PATH)/common/hdl/vhdl/reciprocal_rtl/ac_reciprocal_pwl.vhd" >> $(COVERAGE_SCOPE_FILE)
	rm -f ./synopsys_sim.setup
	@echo "WORK > $(MM_LIB_DUT_NAME)" >> ./synopsys_sim.setup
	@echo "$(MM_LIB_DUT_NAME): ./$(MM_LIB_DUT_DIR)" >> ./synopsys_sim.setup
	@echo "$(MM_LIB_TB_NAME): ./$(MM_LIB_TB_DIR)" >> ./synopsys_sim.setup
  ifeq ($(GLS), 1)
	@echo "altera_lnsim : $(ALT_LIBS)/altera_lnsim" >> ./synopsys_sim.setup
	@echo "altera_mf : $(ALT_LIBS)/altera_mf" >> ./synopsys_sim.setup
	@echo "altera : $(ALT_LIBS)/altera" >> ./synopsys_sim.setup
	@echo "$(MM_LIB_TENNM_NAME): ./$(MM_LIB_TENNM_DIR)" >> ./synopsys_sim.setup
	@echo "$(MM_LIB_BUFF_NAME): ./$(MM_LIB_BUFF_DIR)" >> ./synopsys_sim.setup
	@echo "$(MM_LIB_RECP_NAME): ./$(MM_LIB_RECP_DIR)" >> ./synopsys_sim.setup
	@if [ ! -e ${BUILD_ROOT}/netlist/simulation/vcs/psinr_top_wrapper.vo ] ; then cd $(BUILD_ROOT)/netlist ; $(MAKE) gen_netlist ;fi
  endif
endif

proj_comp_dut: 
ifeq ($(SIM), questa)
	@echo 'compiling DUT with QUESTA'
	cd $(MM_ABSPATH_IMG_BUILD_DIR) && $(VHDL_TOOL) -work $(MM_LIB_DUT_NAME)  $(MM_TOOL_BITMODE) -nologo -f $(TB_PATH)/filelist_dut.f -l $(MM_LOGS_DIR)/psinr_dut_top.log
else
	@echo 'compiling DUT with vcs'
  ifeq ($(GLS), 1)
	#cd $(MM_ABSPATH_IMG_BUILD_DIR) && $(SVLOG_TOOL) -work $(MM_LIB_DUT_NAME) -debug_all -full64 ${BUILD_ROOT}/netlist/simulation/vcs/psinr_top_wrapper.vo -l $(MM_LOGS_DIR)/psinr_dut_top.log
	cd $(MM_ABSPATH_IMG_BUILD_DIR) && $(SVLOG_TOOL) -work $(MM_LIB_DUT_NAME) -debug_all -full64 ${BUILD_ROOT}/psinr_top_wrapper.mapped.v -l $(MM_LOGS_DIR)/psinr_dut_top.log
	cd $(MM_ABSPATH_IMG_BUILD_DIR) && $(SVLOG_TOOL) -work $(MM_LIB_TENNM_NAME) -full64 -nc -q -v2005 -sverilog ${QUARTUS_ROOTDIR}/eda/sim_lib/tennm_atoms.sv ${QUARTUS_ROOTDIR}/eda/sim_lib/synopsys/tennm_atoms_ncrypt.sv -l ${MM_LOGS_DIR}/tennm_atoms_lib.log
	cd $(MM_ABSPATH_IMG_BUILD_DIR) && $(SVLOG_TOOL) -work $(MM_LIB_BUFF_NAME) -full64 -nc -q ${DC_LIBS}/$(BUFFSKRD_LIB)/tcbn05_bwph210l6p51cnod_base_lvtll.v -l ${MM_LOGS_DIR}/buffSkrd_lib.log
	cd $(MM_ABSPATH_IMG_BUILD_DIR) && $(VHDL_TOOL) -work $(MM_LIB_RECP_NAME) -full64 ${FE_PATH}/common/hdl/vhdl/reciprocal_rtl/ac_reciprocal_pwl.vhd -l ${MM_LOGS_DIR}/ac_reciprocal_pwl_lib.log
  else
	cd $(MM_ABSPATH_IMG_BUILD_DIR) && $(VHDL_TOOL) $(MM_TOOL_BITMODE) -no_opt -vhdl08 -work $(MM_LIB_DUT_NAME) -f $(TB_PATH)/filelist_dut.f -l $(MM_LOGS_DIR)/psinr_dut_top.log
  endif
endif

comp_uvm_lib:
ifeq ($(SIM), vcs)
	@echo "Compiling UVM lib ..."
	cd $(MM_ABSPATH_IMG_BUILD_DIR) && $(SVLOG_TOOL) $(UVM_COMP_OPTS) -l $(MM_LOGS_DIR)/comp_uvm_lib.log
	@echo " compile uvm lib done"
endif

proj_comp_tb: comp_uvm_lib
	cd $(MM_ABSPATH_IMG_BUILD_DIR) && $(SVLOG_TOOL) $(SVLOG_OPTS) -f $(TB_PATH)/filelist_tb.f -l $(MM_LOGS_DIR)/psinr_tb.log 

proj_elab:
ifeq ($(SIM), questa)
	$(ELAB_TOOL) $(ELAB_OPTS) $(TOP_MODULES) -o $(MM_ELAB_IMAGE_NAME) -l $(MM_LOGS_DIR)/psinr_elab.log
	@if grep -q 'Error:' $(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_LOGS_DIR)/psinr_elab.log; then \
		echo "Elab error, check $(MM_LOGS_DIR)/psinr_elab.log"; \
		exit 1; \
	fi
else
	$(ELAB_TOOL) $(ELAB_OPTS) $(TOP_MODULES) -o $(MM_ELAB_IMAGE_NAME) -l $(MM_LOGS_DIR)/psinr_elab.log
endif

proj_pre_sim:
	cd $(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_SIM_DIR) ; mkdir -p matchpoints_logs

proj_post_sim: 
	$(eval SIM_LOG := $(shell echo "$(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_SIM_DIR)/$(MM_SIMFILE_BASE_NAME).log"))
	$(eval TAIL_CMD := $(shell echo "tail -n $(MM_TAIL_SEARCH_LINES) $(SIM_LOG)"))
	$(eval UVM_FATAL_CNT := $(shell $(TAIL_CMD) | grep "UVM_FATAL :" | sed 's/.*UVM_FATAL ://' | awk '{print $$1}'))
	$(eval UVM_ERROR_CNT := $(shell $(TAIL_CMD) | grep "UVM_ERROR :" | sed 's/.*UVM_ERROR ://' | awk '{print $$1}'))
	@if [[ "$(UVM_FATAL_CNT)" == "0" && "$(UVM_ERROR_CNT)" == "0" && "$(DEBUG)" == "2" ]]; then rm -f $(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_SIM_DIR)/*.vpd $(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_SIM_DIR)/*.wlf; fi

cov_rpt: 
  ifeq ($(SIM), questa)
	  vcover merge $(MM_TOOL_BITMODE) $(MM_ABSPATH_IMG_BUILD_DIR)/mergefile.ucdb $(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_COVS_DIR)/*.ucdb
	  vcover report $(MM_TOOL_BITMODE) -html -details -annotate -showexcluded -output $(COV_REPORT_DIR) $(MM_ABSPATH_IMG_BUILD_DIR)/mergefile.ucdb
  else 
	  urg $(MM_TOOL_BITMODE) +urg+lic+wait -show fullhier -show hvpfullhier -format both \
		-log $(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_COVS_DIR)/covs.log \
		-dir $(MM_ABSPATH_IMG_BUILD_DIR)/$(MM_COVS_DIR)/covdb.vdb \
		-report $(COV_REPORT_DIR) 
  endif 