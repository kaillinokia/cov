#-------------------------------------------------------------
#-------------------------------------------------------------
# Generic Tcl script for Quartus Project Creation
#-------------------------------------------------------------
#-------------------------------------------------------------

if { $argc < 1 } {
  puts "This script requires at least one argument to be inputed : the project name"
  puts "=> Please try again."
  return -1
} else {
  set proj_name [lindex $argv 0]
}

#-------------------------------------------------------------
# Normally, nothing has to be changed below
#-------------------------------------------------------------

# Load Quartus Prime Tcl Project package
package require ::quartus::project

set need_to_close_project 0
set make_assignments 1

# set FE_PATH "../../" 
# set TB_PATH "../../" 

# Check that the right project is open
if {[is_project_open]} {
  if {[string compare $quartus(project) ${proj_name}]} {
    puts "Project ${proj_name} is not open"
    set make_assignments 0
  }
} else {
  # Only open if not already open
  if {[project_exists ${proj_name}]} {
    project_open -revision ${proj_name} ${proj_name}
  } else {
    project_new -revision ${proj_name} ${proj_name}
  }
  set need_to_close_project 1
}

# Make assignments,  unless project already exists
if {$make_assignments} {        
	
  # Project Top Level entity
  set_global_assignment -name TOP_LEVEL_ENTITY ${proj_name}
	
  # Project & Flow Settings
  set_global_assignment -name ORIGINAL_QUARTUS_VERSION "20.3.0 SP0.02,0.08FW,0.14,0.50"
  set_global_assignment -name PROJECT_CREATION_TIME_DATE "14:01:51  SEP 25, 2023"
  set_global_assignment -name LAST_QUARTUS_VERSION "20.3.0 SP0.02,0.08fw,0.14,0.50 Pro Edition"
  set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
  set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
  set_global_assignment -name MAX_CORE_JUNCTION_TEMP 100
  set_global_assignment -name FLOW_DISABLE_ASSEMBLER ON
  set_global_assignment -name TIMING_ANALYZER_MULTICORNER_ANALYSIS ON
  set_global_assignment -name NUM_PARALLEL_PROCESSORS 4
  set_global_assignment -name ENABLE_INTERMEDIATE_SNAPSHOTS ON
  
  # FPGA and Device to use
  set_global_assignment -name DEVICE AGIB027R29A1E2VR0
  set_global_assignment -name FAMILY Agilex
  
  # Write Netlist for GLS
  set_global_assignment -name EDA_SIMULATION_TOOL "VCS MX (Verilog)"
  set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
  set_global_assignment -name EDA_OUTPUT_DATA_FORMAT "VERILOG HDL" -section_id eda_simulation  
  
  # HDL list file, through Tcl scripts :
  #  * one for pure HDL (VHDL, Verilog, SystemVerilog)
  #  * one for Intel IPs : .qsys/.ip files
  source set_quartus_env.tcl
  source ${proj_name}_filelist_hdl.tcl
  #source ${proj_name}_filelist_ip.tcl
  
  # General Timing Constraints File, containing general contraints such as :
  #  - clocks constraints 
  #  - clock groups (to cut Clock Domain Crossing analysis)
  #  - false_path on IP Inputs and Outputs
  set_global_assignment -name SDC_FILE ${proj_name}.sdc
  
  # IP Specific Timing Constraints Exceptions File, containing specific contraints such as :
  #  - register to register false_path 
  #  - multicycles (not recommended)
  #  - set_max_skew
  #  - set_net_delay / set_data_delay
  set_global_assignment -name SDC_FILE ${proj_name}_timing_exceptions.sdc
  
  # IP Specific Timing Constraints CDC File, containing specific CDC contraints
  # This file is re-built automatically at each run
  set_global_assignment -name SDC_FILE ${proj_name}_timing_cdc.sdc
  
  # Virtual Pins Definition, on all IP Top Level "pins"
  source ${proj_name}_virtual_pins.tcl
  
  # IP Specific Assignments, to be re-used at Upper Level (Loner top)
  source ${proj_name}_fit_assignments.tcl
    
  # Commit assignments
  export_assignments
  
  # Close project
  if {$need_to_close_project} {
    project_close
  }
}
