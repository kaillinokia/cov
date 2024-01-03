
if { $argc < 1 } {
  puts "This script requires at least one argument to be inputed : the project name"
  puts "=> Please try again."
  return -1
} else {
  set PROJECT [lindex $argv 0]
}

# Load packages needed for the commands in this script
load_package project
load_package flow

# Open project
project_open $PROJECT -revision $PROJECT

###########################################################
# Run stages
# Note: These execute_module commands will export all assigments from qsf automatically,
#	unless this is used: --read_settings_files[=on|off]
# Note: These commands have similar arguments as quartus_fit etc.. commands.

puts "----------------------------"
puts "INFO: syn starting"
puts "----------------------------"
execute_module -tool syn -args "--read_settings_files=off"

puts "----------------------------"
puts "INFO: generate netlist starting"
puts "----------------------------"

exec quartus_eda --read_settings_files=on --write_settings_files=off $PROJECT -c $PROJECT --simulation --tool=vcs --format=verilog --output_directory=simulation/vcs

# exec quartus_eda --read_settings_files=on --write_settings_files=off $PROJECT -c $PROJECT --simulation --tool=questasim --format=verilog --output_directory=simulation/questa
