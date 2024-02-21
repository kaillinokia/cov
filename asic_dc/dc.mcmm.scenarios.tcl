#################################################################################
# Design Compiler MCMM Scenarios Setup File Reference
# Script: dc.mcmm.scenarios.tcl
# Version: Q-2019.12-SP4  
# Copyright (C) 2011-2020 Synopsys, Inc. All rights reserved.
#################################################################################

#################################################################################
# This is an example of the MCMM scenarios setup file for Design Compiler.
# Please note that this file will not work as given and must be edited for your
# design.
#
# Create this file for each design in your MCMM flow and configure the filename
# with the value of the ${DCRM_MCMM_SCENARIOS_SETUP_FILE} in
# rm_setup/dc_setup_filenames.tcl
#
# It is recommended to use a minimum set of worst case setup scenarios
# and a worst case leakage scenario in Design Compiler.
# Further refinement to optimize across all possible scenarios is recommended
# to be done in IC Compiler.
#################################################################################

#################################################################################
# Additional Notes
#################################################################################
#
# In MCMM, good leakage and dynamic power optimization results can be obtained by
# using a worst case leakage scenario along with scenario-independent clock gating
# (compile_ultra -gate_clock).
#
# A recommended scenario naming convention (used by Lynx) is the following:
#
# <MM_TYPE>.<OC_TYPE>.<RC_TYPE>
#
# MM_TYPE - Label that identifies the operating mode or set of timing constraints
#           Example values: mode_norm, mode_slow, mode_test
#
# OC_TYPE - Label that identifies the library operating conditions or PVT corner
#           Example values: OC_WC, OC_BC, OC_TYP, OC_LEAK, OC_TEMPINV
#
# RC_TYPE - Label that identifies an extraction corner (TLUPlus files)
#           Example values: RC_MAX_1, RC_MIN_1, RC_TYP
#################################################################################

#################################################################################
# Worst Case Setup Scenario
#################################################################################

set scenario cworst_ccworst

create_scenario ${scenario}

# Read in scenario-specific constraints file

puts "RM-Info: Sourcing script file ${DCRM_CONSTRAINTS_INPUT_FILE}\n"
source ${DCRM_CONSTRAINTS_INPUT_FILE}

# puts "RM-Info: Reading SDC file [which [dcrm_mcmm_filename ${DCRM_SDC_INPUT_FILE} ${scenario}]]\n"
# read_sdc [dcrm_mcmm_filename ${DCRM_SDC_INPUT_FILE} ${scenario}]

set_operating_conditions -max_library tcbn05_bwph210l6p51cnod_base_lvtllssgnp_0p675v_m40c_cworst_CCworst_T_ccs -max ssgnp_0p675v_m40c_cworst_CCworst_T

set_tlu_plus_files -max_tluplus /projectsqum/techlib/tsmc/tcbn05/tech/TLU/cworst/Tech/cworst_CCworst_T/cln5_1p15m_1x1xb1xe1ya1yb5y2yy2r_shdmim_ut-alrdl_cworst_CCworst_T.nxtgrd \
                   -tech2itf_map ${MAP_FILE}

check_tlu_plus_files

# Include scenario specific SAIF file, if possible, for power analysis.
# Otherwise, the default toggle rate of 0.1 will be used for propagating
# switching activity.

# read_saif -auto_map_names -input ${DESIGN_NAME}.${scenario}.saif -instance < DESIGN_INSTANCE > -verbose

# Set options for worst case setup scenario
set_scenario_options -setup true -hold false -leakage_power true -dynamic_power true

report_scenario_options

# Define additional setup scenarios here as needed, using the same format.

#################################################################################
# Worst Case Leakage Scenario
#################################################################################

#set scenario mode_norm.OC_LEAK.RC_MAX_1

#create_scenario ${scenario}

# Read in scenario-specific constraints file

#puts "RM-Info: Sourcing script file [which [dcrm_mcmm_filename ${DCRM_CONSTRAINTS_INPUT_FILE} ${scenario}]]\n"
#source [dcrm_mcmm_filename ${DCRM_CONSTRAINTS_INPUT_FILE} ${scenario}]

# puts "RM-Info: Reading SDC file [which [dcrm_mcmm_filename ${DCRM_SDC_INPUT_FILE} ${scenario}]]\n"
# read_sdc [dcrm_mcmm_filename ${DCRM_SDC_INPUT_FILE} ${scenario}]

#set_operating_conditions -max_library <OC_LEAK_LIB_NAME> -max <OC_LEAK>

#set_tlu_plus_files -max_tluplus <OC_LEAK_TLUPLUS_MAX_FILE> \
                   -tech2itf_map ${MAP_FILE}

#check_tlu_plus_files

# Include scenario specific SAIF file, if possible, for power optimization and analysis.
# Otherwise, the default toggle rate of 0.1 will be used for propagating
# switching activity.

# read_saif -auto_map_names -input ${DESIGN_NAME}.${scenario}.saif -instance < DESIGN_INSTANCE > -verbose

# Set options for worst case leakage scenario
#set_scenario_options -setup false -hold false -leakage_power true

#report_scenario_options
