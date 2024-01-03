# This file only directs commands to correct build/<img>_<sim>/Makefile and possibly launches the commands in GRID.
# When a 'make ...' command is executed in terminal, it is first directed here to '%' target, except 'make clean'.
# Depending on the IMG and SIM parameters, the following actions will happen:
#   1. If not already exists, a new directory is created under build/<img>_<sim>/.
#   2. mm_base.mk is copied under build/<img>_<sim>/, mm_base.mk is renamed to Makefile.
#   3. The whole 'make ...' command is directed to build/<img>_<sim>/Makefile and launched in GRID if GRID=1.

.DEFAULT_GOAL := all
################################################################################
# Default argument values.
################################################################################
IMG         = re$(NUM_PARA_RE)
SIM         ?= vcs

GRID        ?= 1
GRID_MEM    ?= 4000
GRID_NAME   ?= modmake
GRID_QUEUES ?= i_soc_rh7

COMD        ?= 0

BUILD_ROOT := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
#$(error ERROR: Please define the path to Modularmake folder and remove this error)
MM_ROOT := $(BUILD_ROOT)/../../../../modularmake

MM_COPY_PATH := $(MM_ROOT)/templates
# If you have local copy of the mm_base.mk, use this path instead
#MM_COPY_PATH := $(BUILD_ROOT)

################################################################################
# General paths and directories.
################################################################################
MM_BUILD_DIR = build
MM_ABSPATH_IMG_BUILD_DIR = $(BUILD_ROOT)/$(MM_BUILD_DIR)/$(SIM)_$(IMG)

################################################################################
# GRID settings.
################################################################################
ifeq ($(GRID), 1)
  MM_EXEC_CMD = bsub -J $(GRID_NAME) -R "rusage[mem=$(GRID_MEM)]" -q $(GRID_QUEUES)
else
  MM_EXEC_CMD = sh -c
endif

################################################################################
# Export all variables from this level to build/<img>_<sim>/Makefile.
################################################################################
export

.PHONY: %
%:
        # Check IMG because it always needs to have a value.
	@if [ "$(IMG)" == "" ]; then \
		echo "IMG is empty. Image must be defined."; \
		exit 1; \
	fi
        # Check SIM because it always needs to have a value.
	@if [[ "$(SIM)" != "questa" && "$(SIM)" != "vcs" && "$(SIM)" != "verdi" ]]; then \
		echo "Illegal SIM value. Allowed values: questa, vcs, verdi."; \
		exit 1; \
	fi
        # Checks if build directory for the IMG exists, and creates one if doesn't.
	@if [ ! -d "$(MM_ABSPATH_IMG_BUILD_DIR)" ]; then \
		mkdir -p $(MM_ABSPATH_IMG_BUILD_DIR); \
		echo "Created build directory for image '$(IMG)': $(MM_ABSPATH_IMG_BUILD_DIR)."; \
	fi
        # Copy mm_base.mk to build/<img>_<sim>/Makefile if it is not up-to-date.
	@cmp --silent $(MM_COPY_PATH)/mm_base.mk $(MM_ABSPATH_IMG_BUILD_DIR)/Makefile || { \
		cp $(MM_COPY_PATH)/mm_base.mk $(MM_ABSPATH_IMG_BUILD_DIR)/Makefile; \
		chmod +w $(MM_ABSPATH_IMG_BUILD_DIR)/Makefile; \
	}
        # Direct the 'make' command to build/<img>_<sim>//Makefile and if GRID=1, launch it in GRID.
	$(eval $@_CMD := $(MM_EXEC_CMD) "$(MAKE) -e -C $(MM_ABSPATH_IMG_BUILD_DIR) $@")
	@echo -e 'Makefile: > $($@_CMD)' && $($@_CMD)

.PHONY: clean
clean:
	@echo "Removing '$(MM_BUILD_DIR)' directory."
	$(eval $@_CMD := cd $(BUILD_ROOT) && rm -rf ./$(MM_BUILD_DIR))
	@echo "Removing netlist."
	cd ./netlist ; $(MAKE) clean
	rm -rf *.csv 
	rm -rf *.txt 
	rm -rf regression
	@echo -e 'Makefile: > $($@_CMD)' && $($@_CMD)
