#------------------------------------------------------
# Makefile Variables
#------------------------------------------------------
# Define Project Name here
proj_name = psinr_top_wrapper

# ON grid by default
on_grid = true
GRID_QUEUES ?= i_soc_rh7
#------------------------------------------------------
# Makefile Targets
#------------------------------------------------------

gui:   
ifeq ($(on_grid),true)
	bsub -Is -q $(GRID_QUEUES) -R "rusage[mem=100000]" quartus ${proj_name} -c ${proj_name}
else
	quartus ${proj_name} -c ${proj_name}
endif

create_proj: clean_project_files   
ifeq ($(on_grid),true)
	bsub -Is -q $(GRID_QUEUES) -R "rusage[mem=16000]" 'quartus_sh -t create_project.tcl ${proj_name}'
else
	quartus_sh -t create_project.tcl ${proj_name}
endif

gen_netlist: clean create_proj
ifeq ($(on_grid),true)
	bsub -Is -q $(GRID_QUEUES) -R "rusage[mem=16000]" 'quartus_sh -t run_gen_netlist.tcl ${proj_name} | tee gen_netlist.log'
else 
	quartus_sh -t run_gen_netlist.tcl ${proj_name} | tee gen_netlist.log
endif
	# cp ./simulation/questa/$(proj_name).vo ./simulation/questa/$(proj_name).vo_bak
	# sed -e 's:"low":"dont_care":g' -i ./simulation/questa/$(proj_name).vo 
	cp ./simulation/vcs/$(proj_name).vo ./simulation/vcs/$(proj_name).vo_bak
	sed -e 's:"low":"dont_care":g' -i ./simulation/vcs/$(proj_name).vo

clean_results:
	rm -rf *.log
	rm -rf qdb
	rm -rf cdc
	rm -rf output_files
	rm -rf tmp-clearbox
	rm -rf synth_dumps
	rm -rf simulation
	rm -rf netlist
	rm -rf support_logic

clean_project_files:
	rm -f *.qpf
	rm -f *.qsf
	rm -f *.qws
	rm -f *.qdf

clean: clean_results clean_project_files


help:
	@echo "--------------------------------------------------------------------------------------------------------------------------------------------------------"
	@echo "TARGETS TO RUN : "
	@echo "     make help        # Print this help"
	@echo "     make clean       # Clean Directory"
	@echo "     make create_proj # Create the Project from create_project.tcl Tcl file"
	@echo "     make compile     # Launch the Compilation in Batch mode, using the run_compilation.tcl Tcl file"
	@echo "     make all         # Clean, Recreate the project, and Launch the Compilation in Batch mode"
	@echo "     make gui         # Open the Quartus Project in GUI mode, for manual Compilation Start through GUI"
	@echo "     make gen_netlist # generation netlist for vcs/questasim simulation"
	@echo "--------------------------------------------------------------------------------------------------------------------------------------------------------"
