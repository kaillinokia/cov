#-------------------------------------------------------------
# Virtual Pins for Quartus Project
#-------------------------------------------------------------

# Virtual Pins Definition, on all IP Top Level "pins"
set_instance_assignment -name VIRTUAL_PIN ON -to clk
set_instance_assignment -name VIRTUAL_PIN ON -to arst_n
set_instance_assignment -name VIRTUAL_PIN ON -to reset
set_instance_assignment -name VIRTUAL_PIN ON -to comb_*
set_instance_assignment -name VIRTUAL_PIN ON -to psinr_*
set_instance_assignment -name VIRTUAL_PIN ON -to UCI_*