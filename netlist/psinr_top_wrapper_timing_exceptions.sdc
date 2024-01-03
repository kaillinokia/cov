#---------------------------------------------
# IP Timing Exceptions 
#---------------------------------------------

# This file should only contain IP Specific Timing "Exceptions" :
#  - register to register false_path 
#  - multicycles (not recommended)
#  - set_max_skew
#  - set_net_delay / set_data_delay

# It should NOT contain any :
#  - create_clock 
#  - set_clock_groups
#  - set_false_path related to IP IOs (Inputs/Outputs of IP Top Level entity)

# Low-Level Paths must include wildcards as a prefix (*), to be sure
# the constraint can be reused as-is at upper level 

# Note : this file can stay empty !!!

# Example : Quasi-Static Register -> False Paths
# set_false_path -from [get_registers *out_cur_ifft_size*]