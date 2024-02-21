####################
# Timing constraints


####################
# Clock constraints


# Periods
set period_clk 1
#set clk2 1

# Clocks
set clock_names [list \
		     CLK   \
		    ]
#CLK2
#]

# Clock ports
foreach clock_name $clock_names {
    set clock_ports($clock_name) $clock_name
}

# Clock periods
foreach clock_name [lsearch -all -inline $clock_names *CLK*] {
    set clock_periods($clock_name) $period_clk
}

# Create clocks
foreach clock_name $clock_names {
    create_clock -name $clock_name -period $clock_periods($clock_name) [get_ports $clock_ports($clock_name)] -add
}

# Clock uncertainties
foreach clock_name $clock_names {
    set_clock_uncertainty [expr 0.15 * $clock_periods($clock_name)] -setup $clock_name
}


####################
# Clock groups, In case there are multiple asynchronous clks
if {[llength $clock_names] > 1} {
set_clock_groups -name all_clocks -asynchronous \
    -group [get_clocks [lsearch -all -inline $clock_names *CLK*]] \
    -group [get_clocks [lsearch -all -inline $clock_names *CLK2*]] \
}

####################
# IO constraints

# Input delays
foreach clock_name $clock_names {
    set_input_delay [expr 0.6 * $clock_periods($clock_name)] -max -clock $clock_name [remove_from_collection [all_inputs] $clock_names] -add_delay
}

# Output delays
foreach clock_name $clock_names {
    set_output_delay [expr 0.6 * $clock_periods($clock_name)] -max -clock $clock_name [all_outputs] -add_delay
}

# Output load
set_load 0.01 [all_outputs]


####################
# Group paths
foreach clock_name $clock_names {
    group_path -name $clock_name -weight 1
}

set mem  [get_object_name [get_cells -hier * -filter "is_hierarchical == false && (ref_name =~ sram*||ref_name =~ snps*||ref_name =~ RR*||ref_name =~ TS6*||ref_name =~ TS1*)"]]
if {[sizeof_collection [get_cells $mem]]} {
    group_path -name TO_MEM   -to   [get_cells $mem] -weight 1
    group_path -name FROM_MEM -from [get_cells $mem] -weight 1
}

#foreach clock_port_name $clock_ports  {
group_path -name INPUT -from [remove_from_collection [all_inputs] $clock_ports($clock_name)]  -weight 0.0001
group_path -name FEEDTHROUGH -from [remove_from_collection [all_inputs] $clock_ports($clock_name)] -to [all_outputs]  -weight 0.0001
#}

group_path -name OUTPUT -from [all_registers] -to [all_outputs] -weight 0.0001
if {[sizeof_collection [get_flat_pins */E]]} {
group_path -name CLOCK_GATING -to [get_flat_pins */E]
}
