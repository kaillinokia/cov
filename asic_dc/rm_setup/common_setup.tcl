puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Variables common to all reference methodology scripts
# Script: common_setup.tcl
# Version: Q-2019.12-SP4 
# Copyright (C) 2007-2020 Synopsys, Inc. All rights reserved.
##########################################################################################

set DESIGN_NAME                   "psinr_top"  ;#  The name of the top-level design

set MODULES_PATH "../../../../../../../fe/sinr_deocc"

set DESIGN_REF_DATA_PATH          ""  ;#  Absolute path prefix variable for library/design data.
                                       #  Use this variable to prefix the common absolute path  
                                       #  to the common variables defined below.
                                       #  Absolute paths are mandatory for hierarchical 
                                       #  reference methodology flow.

##########################################################################################
# Hierarchical Flow Design Variables
##########################################################################################

set HIERARCHICAL_DESIGNS           "" ;# List of hierarchical block design names "DesignA DesignB" ...
set HIERARCHICAL_CELLS             "" ;# List of hierarchical block cell instance names "u_DesignA u_DesignB" ...

##########################################################################################
# Library Setup Variables
##########################################################################################

# For the following variables, use a blank space to separate multiple entries.
# Example: set TARGET_LIBRARY_FILES "lib1.db lib2.db lib3.db"

set ADDITIONAL_SEARCH_PATH        "";#  Additional search path to be added to the default search path (used by all tools)

set TARGET_LIBRARY_FILES          "/projectsqum/techlib/tsmc/tcbn05/libraries/TSMCHOME/digital/Front_End/LVF/CCS/tcbn05_bwph210l6p51cnod_base_lvtll_110a/tcbn05_bwph210l6p51cnod_base_lvtllssgnp_0p675v_m40c_cworst_CCworst_T_hm_lvf_p_ccs.db \
				   /projectsqum/techlib/tsmc/tcbn05/libraries/TSMCHOME/digital/Front_End/LVF/CCS/tcbn05_bwph210l6p51cnod_mb_lvtll_110a/tcbn05_bwph210l6p51cnod_mb_lvtllssgnp_0p675v_m40c_cworst_CCworst_T_hm_lvf_p_ccs.db"  ;#  Target technology logical libraries (used by DC, DCCNT)

set ADDITIONAL_LINK_LIB_FILES     "/projectsqum/techlib/tsmc/tcbn05/libraries/TSMCHOME/digital/Front_End/LVF/CCS/tcbn05_bwph210l6p51cnod_base_lvt_110a/tcbn05_bwph210l6p51cnod_base_lvtssgnp_0p675v_m40c_cworst_CCworst_T_hm_lvf_p_ccs.db \
				   /projectsqum/techlib/tsmc/tcbn05/libraries/TSMCHOME/digital/Front_End/LVF/CCS/tcbn05_bwph210l6p51cnod_mb_lvt_110a/tcbn05_bwph210l6p51cnod_mb_lvtssgnp_0p675v_m40c_cworst_CCworst_T_hm_lvf_p_ccs.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x128m2sbzhocp_110c/DB/ts6n05lvta512x128m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvtb1024x128m4bzhodxcp_110b/DB/ts1n05sblvtb1024x128m4bzhodxcp_ssgnp_0p675v_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta1024x10m4wbzhocp_110b/DB/ts1n05hslvta1024x10m4wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta1024x24m4wbzhocp_110b/DB/ts1n05hslvta1024x24m4wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta256x8m2wbzhocp_110b/DB/ts1n05hslvta256x8m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta512x20m2wbzhocp_110b/DB/ts1n05hslvta512x20m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta512x46m2wbzhocp_110b/DB/ts1n05hslvta512x46m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta512x98m2wbzhocp_110b/DB/ts1n05hslvta512x98m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x128m2wbzhocp_110b/DB/ts1n05hslvta64x128m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x136m2wbzhocp_110b/DB/ts1n05hslvta64x136m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x16m2wbzhocp_110b/DB/ts1n05hslvta64x16m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x20m2wbzhocp_110b/DB/ts1n05hslvta64x20m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x32m2wbzhocp_110b/DB/ts1n05hslvta64x32m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x40m2wbzhocp_110b/DB/ts1n05hslvta64x40m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x56m2wbzhocp_110b/DB/ts1n05hslvta64x56m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x64m2wbzhocp_110b/DB/ts1n05hslvta64x64m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x74m2wbzhocp_110b/DB/ts1n05hslvta64x74m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x80m2wbzhocp_110b/DB/ts1n05hslvta64x80m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x88m2wbzhocp_110b/DB/ts1n05hslvta64x88m2wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta4096x128m4qwbzhocp_110b/DB/ts1n05mblvta4096x128m4qwbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta4096x20m4qwbzhocp_110b/DB/ts1n05mblvta4096x20m4qwbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta4096x64m4qwbzhocp_110b/DB/ts1n05mblvta4096x64m4qwbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta8192x13m8qwbzhocp_110b/DB/ts1n05mblvta8192x13m8qwbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvta16x32m1wbzhocp_110c/DB/ts1n05sblvta16x32m1wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta1024x10m4swbzhocp_110c/DB/ts6n05lvta1024x10m4swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta1024x13m4swbzhocp_110d/DB/ts6n05lvta1024x13m4swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta1024x24m4swbzhocp_110c/DB/ts6n05lvta1024x24m4swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta128x112m2sbzhocp_110d/DB/ts6n05lvta128x112m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta128x128m2sbzhocp_110d/DB/ts6n05lvta128x128m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvta128x128m1bzhocp_110c/DB/ts1n05sblvta128x128m1bzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvta128x128m1wbzhocp_120a/DB/ts1n05sblvta128x128m1wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta128x18m2sbzhocp_110d/DB/ts6n05lvta128x18m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta128x8m2sbzhocp_110d/DB/ts6n05lvta128x8m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta256x16m1swbzhocp_110c/DB/ts6n05lvta256x16m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta256x20m1swbzhocp_110d/DB/ts6n05lvta256x20m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x128m1swbzhocp_110c/DB/ts6n05lvta32x128m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x136m1swbzhocp_110c/DB/ts6n05lvta32x136m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x16m1swbzhocp_110c/DB/ts6n05lvta32x16m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x20m1swbzhocp_110c/DB/ts6n05lvta32x20m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x32m1swbzhocp_110d/DB/ts6n05lvta32x32m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x40m1swbzhocp_110c/DB/ts6n05lvta32x40m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x56m1swbzhocp_110c/DB/ts6n05lvta32x56m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x64m1swbzhocp_110c/DB/ts6n05lvta32x64m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x76m1swbzhocp_110d/DB/ts6n05lvta32x76m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x88m1swbzhocp_110c/DB/ts6n05lvta32x88m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x10m2sbzhocp_110d/DB/ts6n05lvta512x10m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta2048x32m4qbzhocp_110c/DB/ts1n05mblvta2048x32m4qbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvta32x48m1wbzhocp_120a/DB/ts1n05sblvta32x48m1wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x48m1sbzhocp_120a/DB/ts6n05lvta32x48m1sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x112m2sbzhocp_110d/DB/ts6n05lvta512x112m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x120m2sbzhocp_110d/DB/ts6n05lvta512x120m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x16m2sbzhocp_110d/DB/ts6n05lvta512x16m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x20m2swbzhocp_110d/DB/ts6n05lvta512x20m2swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x24m2sbzhocp_110d/DB/ts6n05lvta512x24m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x28m2sbzhocp_110d/DB/ts6n05lvta512x28m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x46m2swbzhocp_110d/DB/ts6n05lvta512x46m2swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x8m2sbzhocp_110d/DB/ts6n05lvta512x8m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x98m2swbzhocp_110d/DB/ts6n05lvta512x98m2swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta64x128m2sbzhocp_110d/DB/ts6n05lvta64x128m2sbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta64x40m1swbzhocp_110c/DB/ts6n05lvta64x40m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta64x80m1swbzhocp_110d/DB/ts6n05lvta64x80m1swbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvtb16x32m1wbzhocp_110b/DB/ts6n05lvtb16x32m1wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db \
				   /projectsqum/memories/tsmc_memories/ts6n05lvtb8x74m1wbzhocp_110b/DB/ts6n05lvtb8x74m1wbzhocp_ssgnp_0p675v_m40c_cworst_ccworst_t.db"  ;#  Extra link logical libraries not included in TARGET_LIBRARY_FILES (used by DC, DCNXT)

set MIN_LIBRARY_FILES             ""  ;#  List of max min library pairs "max1 min1 max2 min2 max3 min3"...

set MW_REFERENCE_LIB_DIRS         ""  ;#  Milkyway reference libraries (include IC Compiler ILMs here) (used by DC, DCNXT)

set MW_REFERENCE_CONTROL_FILE     ""  ;#  Reference Control file to define the Milkyway reference libs

set TECH_FILE                     "/projectsqum/techlib/tsmc/tcbn05/tech/PRTF_ICC2_5nm_014_Syn_V11a/PR_tech/Synopsys/TechFile/Standard/VHV/PRTF_ICC2_N5_15M_1X1Xb1Xe1Ya1Yb5Y2Yy2R_UTRDL_M1P34_M2P35_M3P42_M4P42_M5P76_M6P80_M7P76_M8P80_M9P76_M10P80_M11P76_H210_SHDMIM.11a.tf"  ;#  Milkyway technology file (used by DC, DCNXT)

set NDM_REFERENCE_LIB_DIRS        "/projectsqum/techlib/tsmc/tcbn05/libraries/TSMCHOME/digital/Back_End/ndm/tcbn05_bwph210l6p51cnod_base_lvtll_110a/tcbn05_bwph210l6p51cnod_base_lvtll_physicalonly.ndm \
				   /projectsqum/techlib/tsmc/tcbn05/libraries/TSMCHOME/digital/Back_End/ndm/tcbn05_bwph210l6p51cnod_mb_lvtll_110a/tcbn05_bwph210l6p51cnod_mb_lvtll_physicalonly.ndm \
				   /projectsqum/techlib/tsmc/tcbn05/libraries/TSMCHOME/digital/Back_End/ndm/tcbn05_bwph210l6p51cnod_base_lvt_110a/tcbn05_bwph210l6p51cnod_base_lvt_physicalonly.ndm \
				   /projectsqum/techlib/tsmc/tcbn05/libraries/TSMCHOME/digital/Back_End/ndm/tcbn05_bwph210l6p51cnod_mb_lvt_110a/tcbn05_bwph210l6p51cnod_mb_lvt_physicalonly.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x128m2sbzhocp_110c/NDM/ts6n05lvta512x128m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvtb1024x128m4bzhodxcp_110b/NDM/ts1n05sblvtb1024x128m4bzhodxcp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta1024x10m4wbzhocp_110b/NDM/ts1n05hslvta1024x10m4wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta1024x24m4wbzhocp_110b/NDM/ts1n05hslvta1024x24m4wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta256x8m2wbzhocp_110b/NDM/ts1n05hslvta256x8m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta512x20m2wbzhocp_110b/NDM/ts1n05hslvta512x20m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta512x46m2wbzhocp_110b/NDM/ts1n05hslvta512x46m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta512x98m2wbzhocp_110b/NDM/ts1n05hslvta512x98m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x128m2wbzhocp_110b/NDM/ts1n05hslvta64x128m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x136m2wbzhocp_110b/NDM/ts1n05hslvta64x136m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x16m2wbzhocp_110b/NDM/ts1n05hslvta64x16m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x20m2wbzhocp_110b/NDM/ts1n05hslvta64x20m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x32m2wbzhocp_110b/NDM/ts1n05hslvta64x32m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x40m2wbzhocp_110b/NDM/ts1n05hslvta64x40m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x56m2wbzhocp_110b/NDM/ts1n05hslvta64x56m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x64m2wbzhocp_110b/NDM/ts1n05hslvta64x64m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x74m2wbzhocp_110b/NDM/ts1n05hslvta64x74m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x80m2wbzhocp_110b/NDM/ts1n05hslvta64x80m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05hslvta64x88m2wbzhocp_110b/NDM/ts1n05hslvta64x88m2wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta4096x128m4qwbzhocp_110b/NDM/ts1n05mblvta4096x128m4qwbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta4096x20m4qwbzhocp_110b/NDM/ts1n05mblvta4096x20m4qwbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta4096x64m4qwbzhocp_110b/NDM/ts1n05mblvta4096x64m4qwbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta8192x13m8qwbzhocp_110b/NDM/ts1n05mblvta8192x13m8qwbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvta16x32m1wbzhocp_110c/NDM/ts1n05sblvta16x32m1wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta1024x10m4swbzhocp_110c/NDM/ts6n05lvta1024x10m4swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta1024x13m4swbzhocp_110d/NDM/ts6n05lvta1024x13m4swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta1024x24m4swbzhocp_110c/NDM/ts6n05lvta1024x24m4swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta128x112m2sbzhocp_110d/NDM/ts6n05lvta128x112m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta128x128m2sbzhocp_110d/NDM/ts6n05lvta128x128m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvta128x128m1bzhocp_110c/NDM/ts1n05sblvta128x128m1bzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvta128x128m1wbzhocp_120a/NDM/ts1n05sblvta128x128m1wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta128x18m2sbzhocp_110d/NDM/ts6n05lvta128x18m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta128x8m2sbzhocp_110d/NDM/ts6n05lvta128x8m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta256x16m1swbzhocp_110c/NDM/ts6n05lvta256x16m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta256x20m1swbzhocp_110d/NDM/ts6n05lvta256x20m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x128m1swbzhocp_110c/NDM/ts6n05lvta32x128m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x136m1swbzhocp_110c/NDM/ts6n05lvta32x136m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x16m1swbzhocp_110c/NDM/ts6n05lvta32x16m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x20m1swbzhocp_110c/NDM/ts6n05lvta32x20m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x32m1swbzhocp_110d/NDM/ts6n05lvta32x32m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x40m1swbzhocp_110c/NDM/ts6n05lvta32x40m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x56m1swbzhocp_110c/NDM/ts6n05lvta32x56m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x64m1swbzhocp_110c/NDM/ts6n05lvta32x64m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x76m1swbzhocp_110d/NDM/ts6n05lvta32x76m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x88m1swbzhocp_110c/NDM/ts6n05lvta32x88m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x10m2sbzhocp_110d/NDM/ts6n05lvta512x10m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x112m2sbzhocp_110d/NDM/ts6n05lvta512x112m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x120m2sbzhocp_110d/NDM/ts6n05lvta512x120m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x16m2sbzhocp_110d/NDM/ts6n05lvta512x16m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x20m2swbzhocp_110d/NDM/ts6n05lvta512x20m2swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x24m2sbzhocp_110d/NDM/ts6n05lvta512x24m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x28m2sbzhocp_110d/NDM/ts6n05lvta512x28m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x46m2swbzhocp_110d/NDM/ts6n05lvta512x46m2swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x8m2sbzhocp_110d/NDM/ts6n05lvta512x8m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta512x98m2swbzhocp_110d/NDM/ts6n05lvta512x98m2swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05mblvta2048x32m4qbzhocp_110c/NDM/ts1n05mblvta2048x32m4qbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta32x48m1sbzhocp_120a/NDM/ts6n05lvta32x48m1sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts1n05sblvta32x48m1wbzhocp_120a/NDM/ts1n05sblvta32x48m1wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta64x128m2sbzhocp_110d/NDM/ts6n05lvta64x128m2sbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta64x40m1swbzhocp_110c/NDM/ts6n05lvta64x40m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvta64x80m1swbzhocp_110d/NDM/ts6n05lvta64x80m1swbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvtb16x32m1wbzhocp_110b/NDM/ts6n05lvtb16x32m1wbzhocp.ndm \
				   /projectsqum/memories/tsmc_memories/ts6n05lvtb8x74m1wbzhocp_110b/NDM/ts6n05lvtb8x74m1wbzhocp.ndm"  ;#  NDM Reference Library (used by DCNXT)

set MAP_FILE                      "/projectsqum/techlib/tsmc/tcbn05/tech/PRTF_ICC2_5nm_014_Syn_V11a/PR_tech/Synopsys/StarRCMap/PRTF_ICC2_N5_starrc_15M_1X1Xb1Xe1Ya1Yb5Y2Yy2R.11a.map"  ;#  Mapping file for TLUplus  (used by DC, DCNXT)
set TLUPLUS_MAX_FILE              "/projectsqum/techlib/tsmc/tcbn05/tech/TLU/cworst/Tech/cworst_CCworst_T/cln5_1p15m_1x1xb1xe1ya1yb5y2yy2r_shdmim_ut-alrdl_cworst_CCworst_T.nxtgrd"  ;#  Max TLUplus file  (used by DC, DCNXT)
set TLUPLUS_MIN_FILE              "/projectsqum/techlib/tsmc/tcbn05/tech/TLU/cworst/Tech/cworst/cln5_1p15m_1x1xb1xe1ya1yb5y2yy2r_shdmim_ut-alrdl_cworst.nxtgrd"  ;#  Min TLUplus file  (used by DC, DCNXT)

set MIN_ROUTING_LAYER            "M2"   ;# Min routing layer (used by DC, DCNXT)
set MAX_ROUTING_LAYER            "M13"   ;# Max routing layer (used by DC, DCNXT)

set LIBRARY_DONT_USE_FILE        "./user_scripts/dont_use.tcl"   ;# Tcl file with library modifications for dont_use
set LIBRARY_DONT_USE_PRE_COMPILE_LIST ""; #Tcl file for customized don't use list before first compile
set LIBRARY_DONT_USE_PRE_INCR_COMPILE_LIST "";# Tcl file with library modifications for dont_use before incr compile
##########################################################################################
# Multivoltage Common Variables
#
# Define the following multivoltage common variables for the reference methodology scripts 
# for multivoltage flows. 
# Use as few or as many of the following definitions as needed by your design.
##########################################################################################

set PD1                          ""           ;# Name of power domain/voltage area  1
set VA1_COORDINATES              {}           ;# Coordinates for voltage area 1
set MW_POWER_NET1                "VDD1"       ;# Power net for voltage area 1

#set PD2                          ""           ;# Name of power domain/voltage area  2
#set VA2_COORDINATES              {}           ;# Coordinates for voltage area 2
#set MW_POWER_NET2                "VDD2"       ;# Power net for voltage area 2

#set PD3                          ""           ;# Name of power domain/voltage area  3
#set VA3_COORDINATES              {}           ;# Coordinates for voltage area 3
#set MW_POWER_NET3                "VDD3"       ;# Power net for voltage area 3

#set PD4                          ""           ;# Name of power domain/voltage area  4
#set VA4_COORDINATES              {}           ;# Coordinates for voltage area 4
#set MW_POWER_NET4                "VDD4"       ;# Power net for voltage area 4

puts "RM-Info: Completed script [info script]\n"

