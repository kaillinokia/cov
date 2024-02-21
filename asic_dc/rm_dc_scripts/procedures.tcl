#######################################################################################################################
# get original frequency from scaled clock
#######################################################################################################################

proc get_freq {clk} {
    global scale_factor
    format "%.3f MHz" [expr (1/([get_attribute [get_clocks $clk] period] / $scale_factor)) *1000000]
}

#######################################################################################################################
#
#######################################################################################################################
proc calc_no_newline {te} {
    upvar 2 i var
    incr var
    set s [format " \[%s\]%s" ${var} ${te}]
    puts -nonewline "$s\r"
    flush stdout
}


#######################################################################################################################
# 
#######################################################################################################################
proc find_useless_sync { args } {
    
    global timing_mode
    
    # Parse arguments
    parse_proc_arguments -args $args results
    
    if { [info exists results(-sync_path_sync_ffs)] } {
        upvar $results(-sync_path_sync_ffs) SYNC_PATH_SYNC_FFS
    }
    
    if { [info exists results(-fixed_sync_ffs)] } {
        upvar $results(-fixed_sync_ffs) FIXED_SYNC_FFS
    }
    
    if { [info exists results(-verbose)] } {
        set VERBOSE $results(-verbose)
	if { ! (($VERBOSE == "partial") || ($VERBOSE == "full")) } {
	    echo "Nokia Error: allowed values for \"-verbose\" are \"partial\" or \"full\"."
	    return 0
	}
    } else {
	set VERBOSE 0
    }
    
    set SYNC_PATH_SYNC_FFS ""
    set FIXED_SYNC_FFS ""
    
    if {$timing_mode != "normal"} {
	echo "Error: this proc should be used only in normal mode!"
	return
    }

    set sync_ffs [get_cells * -h -f "ref_name=~ec0fmw*"]

    if { ($VERBOSE == "partial") || ($VERBOSE == "full") } {
	set sync_ffs_cnt [sizeof_collection $sync_ffs]
	set i 0
	set step 5
	set step_perc -1
    }

    foreach_in_collection sync_ff $sync_ffs {

	if { ($VERBOSE == "partial") || ($VERBOSE == "full") } {
	    incr i
	    set new_step_perc [expr (100*${i})/(${sync_ffs_cnt}*${step})]
	    if { $new_step_perc > $step_perc } {
		set step_perc $new_step_perc
		echo "Processed: [expr $step_perc * $step]%"
	    }
	}

	if { $VERBOSE == "full" } {
	    echo "Processing cell : [get_object_name $sync_ff]"
	}

	set sync_d [get_pins [get_object_name $sync_ff]/d]
	if {[get_attribute $sync_d case_value -q] ne 0 && [get_attribute $sync_d case_value -q] ne 1} { 
	    set x [get_timing_path -to $sync_d -slack_lesser_than infinity -max_paths 1]
	    # source sync datacheck removed (endpoint_setup_time_value > 0) and data from ports (blocks != *Port*)
	    foreach c $x {
		if  {[get_attribute $c endpoint_setup_time_value -q] > 0 && [get_attribute [get_attribute $c startpoint] object_class] != "port"} {            
		    lappend SYNC_PATH_SYNC_FFS "[get_object_name $sync_ff]"
		}
	    }
	} else {
	    lappend FIXED_SYNC_FFS "[get_object_name $sync_ff]"
	}
    }
}


define_proc_attributes find_useless_sync \
    -info "Procedure for useless synchronizers finding." \
    -define_args {
        {-sync_path_sync_ffs "List name for synchronous path synchronizers." "" string required}
        {-fixed_sync_ffs "List name for fixed synchronizers." "" string required}
        {-verbose "Verbose level (partial or full)" "" string optional}
    }




#######################################################################################################################
#
#######################################################################################################################
proc convert_pt_name_to_vcs_name { args } {
    
    # Parse arguments
    parse_proc_arguments -args $args results
    
    if { [info exists results(-name)] } {
        set C_FN $results(-name)
    }
    
    if { [info exists results(-verbose)] } {
        set VERBOSE 1
    } else {
	set VERBOSE 0
    }
    
    set C_FN_SIM ""
    set C_FN_DOT ""

    if { [regexp {\.|\/} $C_FN tmp] } {
	while { [regexp {\.|\/} $C_FN tmp] } {
	
	    if { $VERBOSE == "1" } {
		echo "C_FN : $C_FN"
		echo "C_FN_SIM : $C_FN_SIM"
		echo "C_FN_DOT : $C_FN_DOT"
		echo ""
	    }
	    
	    regexp {(.*?)[\/|\.]} $C_FN full f1
	    regsub $full $C_FN {} C_FN
	    
	    if { [regexp {\/} $full] } {
		regsub {\/} $full {} tmp
		if { $C_FN_DOT == "" } {
		    set C_FN_SIM "${C_FN_SIM}.${tmp}"
		} else {
		    set C_FN_SIM "${C_FN_SIM}.\\${C_FN_DOT}${tmp} "
		    set C_FN_DOT ""
		}
	    } elseif { [regexp {\.} $full] } {
		set C_FN_DOT "${C_FN_DOT}${full}"
	    }
	    
	}
	
	if { [regexp {[\[\]]} ${C_FN}] } {
	    set C_FN "\\${C_FN}"
	}
	
	if { ${C_FN_DOT} == "" } {
	    set C_FN_SIM "top.udut_w.i_dut${C_FN_SIM}.${C_FN}"
	} else {
	    set C_FN_SIM "top.udut_w.i_dut${C_FN_SIM}.\\${C_FN_DOT}${C_FN}"
	}
    
    } else {
	regsub -all {/} $C_FN {.} C_FN_SIM
    }
    
    return $C_FN_SIM
    
}


define_proc_attributes convert_pt_name_to_vcs_name \
    -info "Procedure for Primetime names conversion to VCS naming." \
    -define_args {
        {-name "Primetime name to be converted." "" string required}
        {-verbose "Verbose level (partial or full)" "" string optional}
    }



#######################################################################################################################
# 
#######################################################################################################################
proc create_async_path_sync_ffs_file_for_vcs { args } {
    
    # Parse arguments
    parse_proc_arguments -args $args results
    
    if { [info exists results(-output)] } {
        set OUTPUT $results(-output)
    }
    
    if { [file exists $OUTPUT] } {
	echo "Nokia Error: File $OUTPUT already exists. Exiting..."
	return 0
    }
    
    if { [info exists results(-format)] } {
        set FORMAT $results(-format)
	if { ! (($FORMAT == "tcl") || ($FORMAT == "txt")) } {
	    echo "Nokia Error: allowed values for \"-format\" are \"tcl\" or \"txt\". Exiting..."
	    return 0
	}
    } else {
	set FORMAT tcl
    }
        
    find_useless_sync -sync_path_sync_ffs sync_path_sync_ffs -fixed_sync_ffs fixed_sync_ffs
    
    set async_path_sync_ffs [sort_collection [remove_from_collection [get_cells * -h -f "ref_name=~ec0fmw*"] [get_cells $sync_path_sync_ffs]] full_name]
    
    if { $FORMAT == "txt" } {
	redirect $OUTPUT {
	    foreach_in_collection c $async_path_sync_ffs {
		set c_fn [get_attribute $c full_name]
		set c_fn_sim [convert_pt_name_to_vcs_name -name $c_fn]
		echo $c_fn_sim
	    }
	}
    }
    
    if { $FORMAT == "tcl" } {
	redirect $OUTPUT {
	    foreach_in_collection c $async_path_sync_ffs {
		set c_fn [get_attribute $c full_name]
		set c_fn_sim [convert_pt_name_to_vcs_name -name $c_fn]
		echo "tcheck \{$c_fn_sim\} SETUPHOLD -xgen -msg -disable"
	    }
	}
    }

}



define_proc_attributes create_async_path_sync_ffs_file_for_vcs \
    -info "Procedure for asynchronous paths synchronizer file creation for VCS simulator." \
    -define_args {
        {-output "Output file name." "" string required}
        {-format "File format selection (tcl or txt). Default format is tcl." "" string optional}
    }



#####################################################################################################################
# return multibit register output 
#####################################################################################################################
# search autovector names and find the register index in name 
# output the index of output port based on autovector name 

if {0} {
    proc get_multibit_pin pin_name {
	set reg_name  "[lindex [split ${pin_name} \/] end-1]"
	set pin       "[lindex [split ${pin_name} \/] end]"
	set inst_path "[string map {" " "/"} [lrange [split ${pin_name} \/]  0 end-2]]/*"
	set a [get_cells -hier *${reg_name}* -f "full_name=~${inst_path}&&is_integrated_clock_gating_cell==false&&is_hierarchical==false" -q]
	set lst ""
	if {${a} != ""} {
	    foreach_in_collection b ${a} {
		if {[string match */auto_vector* [get_object_name ${b}]]} {
		    set output_index [lsearch -all [split [string map {__ _\#} [get_object_name ${b}]] \#] *${reg_name}_*]
		    foreach oi ${output_index} {
			# check if indexed pin exists (d/o) - if not (clk/rb) do notreturn 
			if {[get_pins [get_object_name ${b}]/${pin}${oi} -q] == ""} {
			    echo "Nokia Error: Multibit register do not use constraints with common register pins"
			} else {
			    set pin_resolved [get_object_name ${b}]/${pin}${oi}
			    echo "Nokia Info: Converting ${pin_name} to multibit ff pin ${pin_resolved}"
			    lappend lst [get_pins ${pin_resolved}]
			}
		    }
		} else {
		    # search string might have also auto_vectored and and normal registers
		    lappend lst [get_pins [get_object_name ${b}]/${pin}]
		}
	    }
	} else {
	    lappend lst [get_pins ${pin_name}]
	} 
	echo [sizeof_c  [get_pins $lst]]
	return $lst
    }
}

#######################################################################################################################
# Procedure for fixing indentical net and cell names.
#######################################################################################################################

proc fix_identical_net_and_cell_names { args } {

    # Parse arguments
    parse_proc_arguments -args $args results

    set DESIGN ""
    if { [info exists results(-design)] } {
        set DESIGN $results(-design)
    }
    
    set INPUT ""
    if { [info exists results(-input)] } {
        set INPUT $results(-input)
    }
    
    set OUTPUT ""
    if { [info exists results(-output)] } {
        set OUTPUT $results(-output)
    }
     
    redirect -variable read_verilog_log {read_verilog -netlist $INPUT}
    current_design $DESIGN
    link

    set nets ""
    foreach line [split $read_verilog_log "\n"] {
	if { [regexp {Warning:(.*?)'(.*?)'(.*)VER-936(.*)} $line full_line f1 f2 f3 f4] } {
	    lappend nets $f2
	}
    }
    set nets [lsort -unique $nets]

    foreach net $nets {
	set cnets [collection_to_list [get_nets -hierarchical -filter "full_name =~ */${net}"]]
	foreach cnet $cnets {
	    set cnet_fn [get_attribute $cnet full_name]
	    set new_cnet_fn ${cnet_fn}_nokia_net_fix
	    set pins [all_connected $cnet]
	    remove_net $cnet
	    create_net $new_cnet_fn
	    connect_net $new_cnet_fn $pins
	}
    }
    
    write -hierarchy -format verilog -output $OUTPUT
    remove_design -all
}

define_proc_attributes fix_identical_net_and_cell_names \
    -info "Procedure for fixing indentical net and cell names." \
    -define_args {
        {-design "Top level design name." "" string required}
        {-input "Input verilog file name." "" string required}
        {-output "Output verilog file name." "" string required}
    }


######################################################################################################################
# Procedure for hardmacro boundary clocks reporting from flat STA.
######################################################################################################################
proc report_hardmacro_boundary_clocks { args } {

    global CT_SCALING

    parse_proc_arguments -args $args results
    
    if { [info exists results(-cells)] } {
        set HMS [get_cells $results(-cells)]
    }
    
    set VERBOSE 0
    if { [info exists results(-verbose)] } {
        set VERBOSE 1
    }
    
    foreach_in_collection HM $HMS {

	set HM_FN [get_attribute $HM full_name]

	echo ""
	echo "Processing $HM_FN :"

	if { [string match [get_attribute -quiet [get_cells ss_hp_pss_pp1_i0] is_hierarchical] "true"] } {

	    set CLOCK_PINS ""

	    foreach_in_collection PIN [sort_collection [get_pins -of_objects $HM] "pin_direction full_name"] {
		
		set PIN_FN [get_attribute $PIN full_name]
		set PIN_PD [get_attribute $PIN pin_direction]
		
		set DRV_PIN [filter_collection [all_connected -leaf [all_connected $PIN]] "pin_direction == out"]
		set DRV_PIN_FN [get_attribute $DRV_PIN full_name]
		
		set CLOCKS [get_attribute -quiet $DRV_PIN clocks]
		
		set MAX_FREQ 0

		foreach_in_collection CLOCK $CLOCKS {
		    
		    lappend CLOCK_PINS $PIN_FN

		    set CLOCK_FN [get_attribute $CLOCK full_name]
		    set FREQ [format "%.2f" [expr [expr $CT_SCALING / [expr [get_attribute [get_clocks $CLOCK -quiet] period]]] * 1000000]]
		    
		    if { $MAX_FREQ < $FREQ } {
			set MAX_FREQ $FREQ
			set MAX_CLOCK_ARR($PIN_FN) $CLOCK_FN
			set MAX_FREQ_ARR($PIN_FN) $FREQ
		    }
		    
		    if { $VERBOSE == 1 } {
			echo "$PIN_PD $PIN_FN $CLOCK_FN $FREQ"
		    }

		}

		set CLOCK_PINS [lsort -unique $CLOCK_PINS]

	    }

	    if { $VERBOSE == 0 } {
		foreach_in_collection CLOCK_PIN [sort_collection [get_pins $CLOCK_PINS] "pin_direction full_name"] {
		    set CLOCK_PIN_FN [get_attribute $CLOCK_PIN full_name]
		    set CLOCK_PIN_PD [get_attribute $CLOCK_PIN pin_direction]
		    echo "$CLOCK_PIN_PD $CLOCK_PIN_FN $MAX_CLOCK_ARR($CLOCK_PIN_FN) $MAX_FREQ_ARR($CLOCK_PIN_FN)"
		}
	    }

	}

    }

}

define_proc_attributes report_hardmacro_boundary_clocks \
    -info "Procedure for hardmacro boundary clocks reporting from flat STA." \
    -define_args {
        {-cells "List or collection of hardmacro cells" "" string required}
	{-verbose "Verbose reports all clocks instead of maximum frequency clock." "" boolean optional}}




#######################################################################################################################
# Procedure for macro_lib_setup.tcl file creation
# Usage example :
# csh % make dct_gui-
# dc-topo % read_ddc ../work/dc/ss_hp_ul_bb.elab.orig.ddc
# dc-topo % create_memory_macro_lib_setup -memories_path /projects/made_es2/library/intel_1274d31/memories/made/ICKB0P05RTL1IFC1V2
#######################################################################################################################
proc create_memory_macro_lib_setup { args } {

    # Global variables
    global link_library
    global search_path
    global mw_reference_library

    # Parse arguments
    parse_proc_arguments -args $args results

    # Define files
    set MEMORIES_PATH ""
    if { [info exists results(-memories_path)] } {
        set MEMORIES_PATH $results(-memories_path)
    }

    # Find library files
    set LDB_FILES [sh find ${MEMORIES_PATH}/timing -name "*tttt_0.65v*_100c.ldb"]    
    foreach LDB_FILE $LDB_FILES {
	regexp {(.*)/(.*)_tttt_(.*)} $LDB_FILE TMP PATH REF SUFFIX
	set MEM_LIB_MODELS(${REF}) "${PATH}/${REF}_tttt_${SUFFIX}"
    }

    # Find milkyway files
    set MW_FILES [sh find ${MEMORIES_PATH}/physical/fram -name "*.mwlib"]
    foreach MW_FILE $MW_FILES {
	regexp {(.*)/(.*)\.mwlib} $MW_FILE TMP PATH REF
	set MEM_MW_MODELS(${REF}) "${PATH}/${REF}.mwlib"
    }
    
    # Save original data
    set LINK_LIBRARY_ORIG $link_library
    set SEARCH_PATH_ORIG $search_path
    set MW_REFERENCE_LIBRARY_ORIG $mw_reference_library

    # Create variables for additions
    set LINK_LIBRARY_ADDITION ""
    set SEARCH_PATH_ADDITION ""
    set MW_REFERENCE_LIBRARY_ADDITION ""
    
    # Add all lib & MW in first iteration
    foreach KEY [lsort [array names MEM_LIB_MODELS]] {
	
	set LIB_MODEL_FULL_PATH $MEM_LIB_MODELS($KEY)
	
	regexp {(.*)/(.*)} $LIB_MODEL_FULL_PATH TMP PATH DB
	
	lappend LINK_LIBRARY_ADDITION $DB
	set LINK_LIBRARY_ADDITION [lsort -unique $LINK_LIBRARY_ADDITION]
	
	lappend SEARCH_PATH_ADDITION $PATH
	set SEARCH_PATH_ADDITION [lsort -unique $SEARCH_PATH_ADDITION]
	
    }

    foreach KEY [lsort [array names MEM_MW_MODELS]] {
	
	set MW_MODEL_FULL_PATH $MEM_MW_MODELS($KEY)
	
	regexp {(.*)/(.*)} $MW_MODEL_FULL_PATH TMP PATH POSTFIX
	
	lappend MW_REFERENCE_LIBRARY_ADDITION $PATH
	set MW_REFERENCE_LIBRARY_ADDITION [lsort -unique $MW_REFERENCE_LIBRARY_ADDITION]
	
    }

    set link_library [concat $link_library $LINK_LIBRARY_ADDITION]
    set search_path  [concat $search_path $SEARCH_PATH_ADDITION]
    set mw_reference_library [concat $mw_reference_library $MW_REFERENCE_LIBRARY_ADDITION]

    link

    # Find memory references actually used in design
    set DESIGN_REFS ""
    foreach_in_collection CELL [get_cells -hierarchical -filter "(ref_name =~ ip7431rf* || ref_name =~ ip7431sr*) && is_hierarchical == false"] {
	lappend DESIGN_REFS [get_attribute $CELL ref_name]
	set DESIGN_REFS [lsort -unique $DESIGN_REFS]
    }

    # Echo macro_lib_setup.tcl scripting for memories
    echo "######################################################################################################################"
    echo "# MEMORIES_PATH used in generation : ${MEMORIES_PATH}"
    echo "# Copy following lines to your local macro_lib_setup.tcl file :"
    echo "######################################################################################################################"

    echo ""
    echo "######################################################################################################################"
    echo "# Library files"
    echo "######################################################################################################################"

    foreach DESIGN_REF $DESIGN_REFS {
	regsub ${MEMORIES_PATH} $MEM_LIB_MODELS($DESIGN_REF) "" MEM_LIB_MODEL
	echo "lappend ADDITIONAL_LINK_LIB_FILES \$env(MEMORIES_PATH)${MEM_LIB_MODEL}"
    }

    echo ""
    echo "######################################################################################################################"
    echo "# Milkyway directories"
    echo "######################################################################################################################"
    foreach DESIGN_REF $DESIGN_REFS {
	regsub ${MEMORIES_PATH} $MEM_MW_MODELS($DESIGN_REF) "" MEM_MW_MODEL
	echo "lappend MW_REFERENCE_LIB_DIRS \$env(MEMORIES_PATH)${MEM_MW_MODEL}"
    }
    echo ""

}

define_proc_attributes create_memory_macro_lib_setup \
    -info "Procedure for macro_lib_setup.tcl file creation." \
    -define_args {
        {-memories_path "Memories path." "" string required}
    }


######################################################################################################################
## LPMCOLD internal tracker setting for LVC SRAM 
## to allow lowest possible voltage to be used at -40C with no bitcell yield risk
## 0.71V @ -40C using LPMCOLD mode
## Sets case analysis to enable timing checks
######################################################################################################################

proc set_lpmcold {} {
    foreach_in_collection ram_inst  [get_cells -q -h * -f "is_memory_cell==true||ref_name=~ip7431*"] {
	set pin_name ""
	if { [get_pins -q -of_objects $ram_inst -f "full_name=~*fusedatsa_mc00b[*]"] != ""} {
	    # case analysis 0 for [0-4]
	    for {set i 0} {${i} < 5} {incr i} {
		set pin_name [get_pins -q -of_objects $ram_inst -f "full_name=~*fusedatsa_mc00b[${i}]"] 
		set_case_analysis 0 ${pin_name}  
		echo "Nokia Info: Case analysis 0 set for [get_object_name ${pin_name}  ]" 
	    }
	    # case analysis 1 for [5]
	    set pin_name [get_pins -q -of_objects $ram_inst -f "full_name=~*fusedatsa_mc00b[5]"]
	    set_case_analysis 1 ${pin_name}
	    echo "Nokia Info: Case analysis 1 set for [get_object_name ${pin_name}]" 
	}  
    }
}

######################################################################################################################
## Convert DEF file 1274d3 type memories to 1274d31 type memories
######################################################################################################################
proc def_1274d3_to_1274d31_memory_converter { args } {

    # Global variables
    global DESIGN_NAME

    # Parse arguments
    parse_proc_arguments -args $args results

    # Define files
    set INPUT_FILENAME ""
    if { [info exists results(-input_filename)] } {
	set INPUT_FILENAME $results(-input_filename)
    }

    set OUTPUT_FILENAME ""
    if { [info exists results(-output_filename)] } {
	set OUTPUT_FILENAME $results(-output_filename)
    }

    # Open files
    if [catch {set f_in_id [open ${INPUT_FILENAME} r]} msg] {
	echo "Nokia Error: Cannot open file ${INPUT_FILENAME} for reading: $msg"
    }

    if [catch {set f_out_id [open ${OUTPUT_FILENAME} w+]} msg] {
	echo "Nokia Error: Cannot open file ${OUTPUT_FILENAME} for writing: $msg"
    }

    # Header
    puts $f_out_id "#"
    puts $f_out_id "# Updated with Nokia DEF converter procedure."


    # Process input file
    set COMPONENT_SECTION 0

    while {[gets $f_in_id line] >=0 } {

	# Update component section
	if { $COMPONENT_SECTION } {

	    if { [regexp {ip743rfshpm1r1w} $line] } {
		regexp { \-(\s*)(.*)/ip743rfshpm1r1w(\D*)(\d*)x(\d*)(.*)ip743rfshpm1r1w(\D*)(\d*)x(\d*)(\s*)(\S*)(\s*)(.*)} $line full_string f0 hc_fn f2 width depth f5 f6 f7 f8 f9 f10 f11 end_of_line
		set c [get_cells ${hc_fn}/*${width}x${depth}*]
		set c_fn [get_attribute $c full_name]
		set c_rn [get_attribute $c ref_name]
		if { [sizeof_collection $c] == 1 } {
		    puts $f_out_id " - ${c_fn} ${c_rn} ${end_of_line}"
		}
	    } elseif { [regexp {ip743rfsstl2r2w} $line] } {
		regexp { \-(\s*)(.*)/ip743rfsstl2r2w(\D*)(\d*)x(\d*)(.*)ip743rfsstl2r2w(\D*)(\d*)x(\d*)(\s*)(\S*)(\s*)(.*)} $line full_string f0 hc_fn f2 width depth f5 f6 f7 f8 f9 f10 f11 end_of_line
		set c [get_cells ${hc_fn}/*${width}x${depth}*]
		set c_fn [get_attribute $c full_name]
		set c_rn [get_attribute $c ref_name]
		if { [sizeof_collection $c] == 1 } {
		    puts $f_out_id " - ${c_fn} ${c_rn} ${end_of_line}"
		}
	    } elseif { [regexp {ip743srmbdlv} $line] } {
		regexp { \-(\s*)(.*)/ip743srmbdlv(\D*)(\d*)x(\d*)(.*)ip743srmbdlv(\D*)(\d*)x(\d*)(\s*)(\S*)(\s*)(.*)} $line full_string f0 hc_fn f2 width depth f5 f6 f7 f8 f9 f10 f11 end_of_line
		set c [get_cells ${hc_fn}/*${width}x${depth}*]
		set c_fn [get_attribute $c full_name]
		set c_rn [get_attribute $c ref_name]
		if { [sizeof_collection $c] == 1 } {
		    puts $f_out_id " - ${c_fn} ${c_rn} ${end_of_line}"
		}
	    } elseif { [regexp {ip743srmbslv} $line] } {
		regexp { \-(\s*)(.*)/ip743srmbslv(\D*)(\d*)x(\d*)(.*)ip743srmbslv(\D*)(\d*)x(\d*)(\s*)(\S*)(\s*)(.*)} $line full_string f0 hc_fn f2 width depth f5 f6 f7 f8 f9 f10 f11 end_of_line
		set c [get_cells ${hc_fn}/*${width}x${depth}*]
		set c_fn [get_attribute $c full_name]
		set c_rn [get_attribute $c ref_name]
		if { [sizeof_collection $c] == 1 } {
		    puts $f_out_id " - ${c_fn} ${c_rn} ${end_of_line}"
		}
	    } elseif { [regexp {ip7431rfshpm1r1w} $line] } {
		regexp { \-(\s*)(.*)/ip7431rfshpm1r1w(\D*)(\d*)x(\d*)(.*)ip7431rfshpm1r1w(\D*)(\d*)x(\d*)(\s*)(\S*)(\s*)(.*)} $line full_string f0 hc_fn f2 width depth f5 f6 f7 f8 f9 f10 f11 end_of_line
		set c [get_cells ${hc_fn}/*${width}x${depth}*]
		set c_fn [get_attribute $c full_name]
		set c_rn [get_attribute $c ref_name]
		if { [sizeof_collection $c] == 1 } {
		    puts $f_out_id " - ${c_fn} ${c_rn} ${end_of_line}"
		}
	    } elseif { [regexp {ip7431rfsstl2r2w} $line] } {
		regexp { \-(\s*)(.*)/ip7431rfsstl2r2w(\D*)(\d*)x(\d*)(.*)ip7431rfsstl2r2w(\D*)(\d*)x(\d*)(\s*)(\S*)(\s*)(.*)} $line full_string f0 hc_fn f2 width depth f5 f6 f7 f8 f9 f10 f11 end_of_line
		set c [get_cells ${hc_fn}/*${width}x${depth}*]
		set c_fn [get_attribute $c full_name]
		set c_rn [get_attribute $c ref_name]
		if { [sizeof_collection $c] == 1 } {
		    puts $f_out_id " - ${c_fn} ${c_rn} ${end_of_line}"
		}
	    } elseif { [regexp {ip7431srmbdlv} $line] } {
		regexp { \-(\s*)(.*)/ip7431srmbdlv(\D*)(\d*)x(\d*)(.*)ip7431srmbdlv(\D*)(\d*)x(\d*)(\s*)(\S*)(\s*)(.*)} $line full_string f0 hc_fn f2 width depth f5 f6 f7 f8 f9 f10 f11 end_of_line
		set c [get_cells ${hc_fn}/*${width}x${depth}*]
		set c_fn [get_attribute $c full_name]
		set c_rn [get_attribute $c ref_name]
		if { [sizeof_collection $c] == 1 } {
		    puts $f_out_id " - ${c_fn} ${c_rn} ${end_of_line}"
		}
	    } elseif { [regexp {ip7431srmbslv} $line] } {
		regexp { \-(\s*)(.*)/ip7431srmbslv(\D*)(\d*)x(\d*)(.*)ip7431srmbslv(\D*)(\d*)x(\d*)(\s*)(\S*)(\s*)(.*)} $line full_string f0 hc_fn f2 width depth f5 f6 f7 f8 f9 f10 f11 end_of_line
		set c [get_cells ${hc_fn}/*${width}x${depth}*]
		set c_fn [get_attribute $c full_name]
		set c_rn [get_attribute $c ref_name]
		if { [sizeof_collection $c] == 1 } {
		    puts $f_out_id " - ${c_fn} ${c_rn} ${end_of_line}"
		}

	    } else {
		# Hardmacro
		puts $f_out_id $line
	    }
	} else {
	    # Outside component section
	    puts $f_out_id $line
	}

	# Start of component section
	if { [regexp {COMPONENTS} $line] } {
	    set COMPONENT_SECTION 1
	}

	# End of component section
	if { [regexp {END COMPONENTS} $line] } {
	    set COMPONENT_SECTION 0
	}


    }


    # Close files
    close $f_in_id
    close $f_out_id

}

define_proc_attributes def_1274d3_to_1274d31_memory_converter \
    -info "Procedure for DEF file 1274d3 memories updating to 1274d3.1 memories." \
    -define_args {
        {-input_filename "Input filename" "" string required}
        {-output_filename "Output filename" "" string required}
    }


######################################################################################################################
## Color hierarchies in DCT
## select hierarchy in browser and use command
######################################################################################################################

proc colour_hier {} {
   
    global csel
    set col [list blue light_blue yellow purple light_purple orange light_orange red light_red green light_green]

    if {![info exists csel]} {
	set csel 0
    } elseif {${csel} < [expr [llength ${col}] -1]} {
	incr csel
    } else {
	set csel 0
    }

    change_selection [get_selection]
    change_selection [::snpsGuiSyn::get_leaf_cells_of_selected_cells]
      
    echo [lindex ${col} ${csel}]
    gui_change_highlight -color [lindex ${col} ${csel}] -collection [get_selection]
}
 

######################################################################################################################
## Print shift registers
######################################################################################################################
proc dc_print_shift_registers { args } {

    # Parse arguments
    parse_proc_arguments -args $args results

    echo "#########################"
    echo "# Format:"
    echo "#########################"
    echo "# Head: Head register (ref_name)"
    echo "# Tail0: first register after head (ref_name)"
    echo "# Tail1: second register after head (ref_name)"
    echo "# ..."
    echo "# Note, there can possibly be more than 1 tail-flop behind a single stage"
    echo "#########################"
    

foreach_in_collection reg [sort_collection [filter_collection [all_registers -edge_triggered] "shift_register_head==true"] full_name] {
    
    echo "Head: [get_object_name [get_cells $reg]] ([get_attribute [get_cells $reg] ref_name])"

    set tails [filter_collection [get_cells -of_objects [all_fanout -flat -endpoints_only -from [get_pins -of_objects [get_cells $reg] -filter "direction==out && lib_pin_name==o"]]] "shift_register_flop==true"]

    set depth 0
    while {[sizeof_collection $tails]} {
	set first 1
	foreach_in_collection tt $tails {
	    echo "Tail${depth}: [get_object_name [get_cells $tt]] ([get_attribute [get_cells $tt] ref_name])"
	    if {$first} {
		set newtails [filter_collection [get_cells -of_objects [all_fanout -flat -endpoints_only -from [get_pins -of_objects [get_cells $tt] -filter "direction==out && lib_pin_name==o"]]] "shift_register_flop==true"]
		set first 0
	    } else {
		append_to_collection newtails [filter_collection [get_cells -of_objects [all_fanout -flat -endpoints_only -from [get_pins -of_objects [get_cells $tt] -filter "direction==out && lib_pin_name==o"]]] "shift_register_flop==true"]
	    }
	}
	set tails $newtails
	incr depth
    }
}
}

define_proc_attributes dc_print_shift_registers \
    -info "Procedure for printing shift registers." \
    -define_args {
    }


######################################################################################################################
## Print clkgates: instance names and reference names
######################################################################################################################
proc dc_print_clkgates { args } {

    echo "#################################"
    echo "# all clockgates"
    echo "# instance_name : reference_name"
    echo "#################################"

    foreach_in_collection cg [sort_collection -dictionary [all_clock_gates] full_name] {
	echo "[get_attribute [get_cells $cg] full_name] : [get_attribute [get_cells $cg] ref_name]"
    }
}

define_proc_attributes dc_print_clkgates \
    -info "Procedure for printing clkgate names and references."


######################################################################################################################
#
######################################################################################################################
proc is_attribute {collection attribute} {
    if {[get_attribute -quiet $collection $attribute] == ""} {
        return false
    } else {
        return true
    }
}


######################################################################################################################
## Buggy DC versions (at least <- 2016_03-SP4) leave some arguments for create_power_switch out
## with "save_upf" / "save_upf -full_upf" commands
######################################################################################################################
proc dc_fix_create_power_switch { args } {

   # Parse arguments
    parse_proc_arguments -args $args results

    set INPUT_FILENAME ""
    if { [info exists results(-input_filename)] } {
	set INPUT_FILENAME $results(-input_filename)
    }

    set OUTPUT_FILENAME ""
    if { [info exists results(-output_filename)] } {
	set OUTPUT_FILENAME $results(-output_filename)
    }

    set PWR_SWITCH_CTRL_PORT "coreSD"
    if { [info exists results(-pwr_switch_ctrl_port)] } {
	set PWR_SWITCH_CTRL_PORT $results(-pwr_switch_ctrl_port)
    }

    set PWR_SWITCH_ACK_PORT "coreSD_done"
    if { [info exists results(-pwr_switch_ack_port)] } {
	set PWR_SWITCH_ACK_PORT $results(-pwr_switch_ack_port)
    }

    # Open files
    if [catch {set f_in_id [open ${INPUT_FILENAME} r]} msg] {
	echo "Nokia Error: Cannot open file ${INPUT_FILENAME} for reading: $msg"
    }

    if [catch {set f_out_id [open ${OUTPUT_FILENAME} w+]} msg] {
	echo "Nokia Error: Cannot open file ${OUTPUT_FILENAME} for writing: $msg"
    }
   
    while {[gets $f_in_id line] >=0 } {
	if { [regexp {^\s*create_power_switch\s+(\S+)\s+-domain\s+(\S+)/pd_(\S+)\s+-output_supply_port\s+{(\S+)\s+\S+/(vcc\S+)}\s+-input_supply_port\s+{(\S+)\s+\S+/(v\S+)}\s+-on_state\s+(.+)\s*$} $line -> f1 f2 f3 f4 f5 f6 f7 f8] } {
	    if {[string match $f3 "regfile"]} {
		set pwrin "ipwreninb"
		set pwrout "opwrenoutb"
	    } elseif {[string match $f3 "sram"]} {
		set pwrin "pwrenb_in"
		set pwrout "pwrenb_out"
	    } elseif {[string match $f3 "rfrom"]} {
		set pwrin "shutoff"
		set pwrout "opwrenoutb"
	    } else {
		echo "Nokia Error: not regfile nor sram instance in full.upf: $f2"
		set pwrin "pwrenb_in"
		set pwrout "pwrenb_out"
	    }
	    set line "create_power_switch $f1 -domain ${f2}/pd_$f3 -output_supply_port {$f4 ${f2}/$f5} -input_supply_port {$f6 ${f2}/$f7} -on_state $f8 -control_port {sleep_ctrl ${f2}/${pwrin}} -ack_port {ack ${f2}/$pwrout {sleep_ctrl}}"
	} elseif { [regexp {^\s*create_power_switch\s+(\S+)\s+-domain\s+(\S+)/(ss_\S+sw_domain)\s+-output_supply_port\s+{(\S+)\s+\S+/(v\S+)}\s+-input_supply_port\s+{(\S+)\s+\S+/(vc\S+)}\s+-on_state\s+{(\S+)\s+(\S+)\s+(\S+)}\s+-off_state\s+{(\S+)\s+(\S+)}\s*$} $line -> f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12] } {

	    set line "create_power_switch ${f1} -domain ${f2}/${f3} -output_supply_port {${f4} ${f2}/${f5}} -input_supply_port {${f6} ${f2}/${f7}} -on_state {${f8} ${f9} ${f10}} -off_state {${f11} ${f12}} -control_port {a ${f2}/${PWR_SWITCH_CTRL_PORT}} -ack_port {ack ${f2}/${PWR_SWITCH_ACK_PORT} {a}}" 
	}
	puts $f_out_id $line
    }

    close $f_in_id
    close $f_out_id
}

define_proc_attributes dc_fix_create_power_switch \
    -info "Procedure for fixing created UPF (by buggy DCs save_upf)." \
    -define_args {
	{-input_filename "Input filename" "" string required}
	{-output_filename "Output filename" "" string required}
	{-pwr_switch_ctrl_port "core shutdown enable port name" "" string optional}
	{-pwr_switch_ack_port "core shutdown status port name" "" string optional}
    }


######################################################################################################################
## Exclude input pins from automatic clock gating, skip pins which have an instantiated cg
######################################################################################################################
proc exclude_inputregs_from_acg { args } {

    global input_clock_ports_list
    global reset_ports_list

    parse_proc_arguments -args $args arguments

    set SKIP_PORTS [list ]
    if {[info exists arguments(-skip_ports)]} {
        set SKIP_PORTS $arguments(-skip_ports)
    }

    set inputs [get_ports * -filter "direction==in"]
    if {[info exists input_clock_ports_list]} {
	set inputs [remove_from_collection $inputs $input_clock_ports_list]
    }
    if {[info exists reset_ports_list]} {
	set inputs [remove_from_collection $inputs $reset_ports_list]
    }
    if {[sizeof_collection $SKIP_PORTS] > 0} {
	echo "Nokia Info: exclude_inputregs_from_acg, skipping [sizeof_collection $SKIP_PORTS] ports:"
	echo "[get_attribute ${SKIP_PORTS} full_name]"
	set inputs [remove_from_collection $inputs $SKIP_PORTS]
    }

    # check if there is an instantiated clock gate already connected to input port
    foreach_in_collection ip $inputs {
	set cgs [filter_collection [get_lib_cells -of [all_fanout -flat -endpoints_only -only_cells -from $ip]] "defined(clock_gating_integrated_cell)"]
	if {[sizeof_collection $cgs] > 0} {
	    echo "Nokia Error: clockgate in fanout of input: [get_attribute $ip full_name]"
	    set inputs [remove_from_collection $inputs $ip]
	}
    }

    echo "Nokia Info: Excluding [sizeof_collection $inputs] input ports from clock gating:"
    echo "[get_attribute ${inputs} full_name]"
    set_clock_gating_enable -exclude $inputs

}

define_proc_attributes exclude_inputregs_from_acg  \
    -info "Exclude registers connected to input ports (excluding resets and clocks) from ACG." \
	-define_args {
	    {-skip_ports "List of input ports to skip from exclusion" "" list optional}
	}


# Parse dcgtech_compile file

proc dcgtech_source {file} {
    
    global env
    global synopsys_program_name
    if { [string match $synopsys_program_name "dc_shell"] } {

	set fl [open $file]
	set data [read $fl]
	close $fl
	set file_line [split $data \n]

	set parse 0

	foreach x $file_line {
	    if {[string match "*#Compilation step*" $x]} {
		set parse 1
	    } elseif {[string match "*#elaboration step*" $x]} {
		set parse 0
	    }
	    if {!$parse} {
		lappend infotext $x
	    } else {
		lappend commands $x
	    }
	}

	echo "Nokia Info: Removing lines from $file"
	echo "--- Start ---"
	
	foreach x $infotext {
	    echo $x
	}
	echo "--- End ---\nSourcing ./dcgtech_parsered.tcl"
	
	set flo [open "./dcgtech_parsered.tcl" w] 
	foreach x $commands {
	    puts $flo $x
	}

	close $flo
	##    source ./dcgtech_parsered.tcl
    }
}

############

proc collection_to_list2 {args} {
    parse_proc_arguments -args $args arguments
    
    set ret {}
    
    if {[info exists arguments(-attributes)]} {
        set attributes $arguments(-attributes)
    } else {
        set attributes full_name
    }

    foreach_in_collection x $arguments(coll) {
        # Check that all atributes exist for object x
        set skip false
        foreach attribute $attributes {
            if {! [is_attribute $x $attribute]} {
                set skip true
                break
            }
        }
        if {$skip} {
            continue
        }
        
        set item ""
        foreach attribute $attributes {
            set attr [get_attribute $x $attribute]
            if {[string match _sel* $attr]} {
                set attr [get_collection_names $attr]
            }
            set item [concat $item $attr]
        }
        lappend ret $item
    }
    return $ret
}

define_proc_attributes collection_to_list2 \
    -info "(Proc) Converts Synopsys collection to TCL list data structure" \
    -define_args {
        {coll  "Collection to convert" "coll" string required}
        {-attributes "List of attributes" "list_of_attributes" list optional}
    }

####


# write_path_summary.tcl
#  writes customizable summary table for a collection of paths
#
# v1.0 chrispy 04/02/2004
#  initial release
# v1.1 chrispy 05/12/2004
#  added startpoint/endpoint clock latency, clock skew, CRPR
#  (thanks to John S. for article feedback!)
# v1.2 chrispy 06/15/2004
#  changed net/cell delay code to work in 2003.03
#  (thanks John Schritz @ Tektronix for feedback on this!)
# v1.3 chrispy 08/31/2004
#  fixed append_to_collection bug (again, thanks to John Schritz @ Tektronix!)
# v1.4 chrispy 03/26/2006
#  fixed handling of unconstrained paths
# v1.5 chrispy 09/01/2006
#  fixed slowest_cell reporting (thanks Pradeep @ OpenSilicon!)
# v1.6 chrispy 11/17/2010
#  fix harmless warning when a path has no cells (ie, feedthrough)
#  fix harmless warning when a path has no startpoint or endpoint clock
# v1.7 chrispy 01/31/2012
#  rename total_xtalk as total_xtalk_data
#  add total_xtalk_clock, total_xtalk (clock+data)


namespace eval path_summary {
 set finfo(index) {int {index number of path in original path collection (0, 1, 2...)} {{index} {#}}}
 set finfo(startpoint) {string {name of path startpoint} {{startpoint} {name}}}
 set finfo(endpoint) {string {name of path endpoint} {{endpoint} {name}}}
 set finfo(start_clk) {string {name of startpoint launching clock} {{startpoint} {clock}}}
 set finfo(end_clk) {string {name of endpoint capturing clock} {{endpoint} {clock}}}
 set finfo(launch_latency) {real {launching clock latency} {{launch} {latency}}}
 set finfo(capture_latency) {real {capturing clock latency} {{capture} {latency}}}
 set finfo(skew) {real {skew between launch/capture clock (negative is tighter)} {{clock} {skew}}}
 set finfo(crpr) {real {clock reconvergence pessimism removal amount} {{CRPR} {amount}}}
 set finfo(path_group) {string {path group name} {{path} {group}}}
 set finfo(slack) {real {path slack} {{path} {slack}}}
     set finfo(arrival) {real {path arrival} {{path} {arrival}}}
 set finfo(duration) {real {combinational path delay between startpoint and endpoint} {{path} {duration}}}
 set finfo(levels) {real {levels of combinational logic} {{levels} {of logic}}}
 set finfo(hier_pins) {int {number of hierarchy pins in path} {{# hier} {pins}}}
 set finfo(num_segments) {int {number of segments in path} {{#} {segments}}}
 set finfo(num_unique_segments) {int {number of unique segments in path} {{# unique} {segments}}}
 set finfo(num_segment_crossings) {int {number of segment crossings in path} {{# segment} {crossings}}}
 set finfo(average_cell_delay) {real {average combinational cell delay (duration / levels)} {{average} {cell delay}}}
 set finfo(slowest_cell) {string {name of slowest cell in path} {{slowest} {cell}}}
 set finfo(slowest_cell_delay) {real {cell delay of slowest cell in path} {{slowest} {cell delay}}}
 set finfo(slowest_net) {string {name of slowest net in path} {{slowest} {net}}}
 set finfo(slowest_net_delay) {real {net delay of slowest net in path} {{slowest} {net delay}}}
 set finfo(slowest_net_R) {real {resistance of slowest net in path} {{slowest} {net R}}}
 set finfo(slowest_net_C) {real {capacitance of slowest net in path} {{slowest} {net C}}}
 set finfo(total_net_delay) {real {summation of all net delays in path} {{total} {net delay}}}
 set finfo(max_trans) {real {slowest pin transition in path} {{max} {transition}}}
 set finfo(total_xtalk_data) {real {summation of all crosstalk deltas in data path} {{data} {xtalk}}}
 set finfo(total_xtalk_clock) {real {summation of all crosstalk deltas in clock path} {{clock} {xtalk}}}
 set finfo(total_xtalk) {real {summation of all crosstalk deltas in clock/data path} {{total} {xtalk}}}
 set finfo(xtalk_ratio) {real {percentage ratio of 'total_xtalk_data' versus 'duration'} {{xtalk} {ratio}}}
 set known_fields {arrival index startpoint endpoint start_clk end_clk launch_latency capture_latency skew crpr path_group slack duration levels hier_pins num_segments num_unique_segments num_segment_crossings average_cell_delay slowest_cell slowest_cell_delay slowest_net slowest_net_delay slowest_net_R slowest_net_C total_net_delay max_trans total_xtalk_data total_xtalk_clock total_xtalk xtalk_ratio}

 proc max {a b} {
  return [expr $a > $b ? $a : $b]
 }

 proc min {a b} {
  return [expr $a < $b ? $a : $b]
 }
}

proc process_paths {args} {
	global synopsys_program_name
  if { [string match $synopsys_program_name "pt_shell"] } {
 set results(-ungrouped) {}
 parse_proc_arguments -args $args results

 if {[set paths [filter_collection $results(paths) {object_class == timing_path}]] == ""} {
  echo "Error: no timing paths provided"
  return 0
 }

 set ungrouped_cells {}
 if {[set cells [get_cells -quiet $results(-ungrouped) -filter "is_hierarchical == true"]] != ""} {
  echo "Assuming the following instances have been ungrouped and flattened for segment processing:"
  foreach_in_collection cell $cells {
   echo " [get_object_name $cell]"
  }
  echo ""

  # now build a list of all ungrouped hierarchical cells
  while {$cells != ""} {
   set cell [index_collection $cells 0]
   set hier_cells [get_cells -quiet "[get_object_name $cell]/*" -filter "is_hierarchical == true"]
   set cells [remove_from_collection $cells $cell]
   set cells [append_to_collection -unique cells $hier_cells]
   set ungrouped_cells [append_to_collection -unique ungrouped_cells $cell]
  }
 }

 # come up with a list of index numbers where we want to print progress
 if {[set num_paths [sizeof $paths]] >= 25} {
  set index_notice_point 0
  set index_notice_messages {"\n(0%.."}
  set index_notice_points {}
  for {set i 10} {$i <= 90} {incr i 10} {
   lappend index_notice_points [expr {int($i * ($num_paths - 1) / 100)}]
   lappend index_notice_messages "${i}%.."
  }
  lappend index_notice_points [expr {$num_paths - 1}]
  lappend index_notice_messages "100%)\n"
 } else {
  set index_notice_point 25
 }

 # store path data in this namespace
 set path_summary::data_list {}

 # we start at an index number of 0
 set index 0

 foreach_in_collection path $paths {
  # print progress message if needed
  if {$index == $index_notice_point} {
   echo -n "[lindex $index_notice_messages 0]"
   set index_notice_point [lindex $index_notice_points 0]
   set index_notice_messages [lrange $index_notice_messages 1 [expr [llength $index_notice_messages]-1]]
   set index_notice_points [lrange $index_notice_points 1 [expr [llength $index_notice_points]-1]]
  }

  set hier_pins 0
  set combo_cell_pins 0
  set last_cell_port {}
  set slowest_cell {}
  set slowest_cell_delay "-INFINITY"
  set slowest_net_delay "-INFINITY"
  set total_net_delay 0
  set max_trans 0
  set total_xtalk_data 0.0
  set total_xtalk_clock 0.0
  set hier_cell_paths {}
  set last_cell_or_port {}
  set change_in_hier 1
  set last_cell_or_port {}
  set cell_delay {}
  set input_pin_arrival {}
  foreach_in_collection point [set points [get_attribute $path points]] {
   set object [get_attribute $point object]
   set port [get_ports -quiet $object]
   set pin [get_pins -quiet $object]
   set cell [get_cells -quiet -of $pin]
   set arrival  [get_attribute -quiet $point arrival]
   set is_hier [get_attribute -quiet $cell is_hierarchical]
   set annotated_delta_transition [get_attribute -quiet $point annotated_delta_transition]

   if {$is_hier == "true"} {
    # if the pin is hierarchical, increment (these are always in pairs)
    incr hier_pins
    if {[remove_from_collection $cell $ungrouped_cells] != ""} {
     set change_in_hier 1
    }
    continue
   }

   # if we are looking at a new cell just after a change in hierarchy,
   # add this to our list
   if {$change_in_hier} {
    if {$cell != ""} {
     # add cell path to list
     set basename [get_attribute $cell base_name]
     set fullname [get_attribute $cell full_name]
     lappend hier_cell_paths [string range $fullname 0 [expr [string last $basename $fullname]-2]]
    } else {
     # port, which is base level
     lappend hier_cell_paths {}
    }
   }

   # we've handled any change in hierarchy
   set change_in_hier 0


   # use the fact that a true expression evaluates to 1, count combinational pins
   incr combo_cell_pins [expr {[get_attribute -quiet $cell is_sequential] == "false"}]

   if {[set annotated_delay_delta [get_attribute -quiet $point annotated_delay_delta]] != ""} {
    set total_xtalk_data [expr $total_xtalk_data + $annotated_delay_delta]
   }

   set max_trans [path_summary::max $max_trans [get_attribute $point transition]]

   # at this point, we have either a leaf pin or a port
   # net delay - delay from previous point to current point with annotated_delay_delta
   # cell delay - delay from previous point with annotated_delay_delta to current point
   set this_arrival [get_attribute $point arrival]
   set this_cell_or_port [add_to_collection $port $cell]

   if {[compare_collection $this_cell_or_port $last_cell_or_port]} {
     if {$last_cell_or_port != ""} {
      if {[set net_delay [expr $this_arrival-$last_arrival]] > $slowest_net_delay} {
       set slowest_net_delay $net_delay
       set slowest_net [get_nets -quiet -segments -top_net_of_hierarchical_group [all_connected $object]]
      }
      set total_net_delay [expr $total_net_delay + $net_delay]
     }
     if {$input_pin_arrival != ""} {
      set cell_delay [expr {$last_arrival - $input_pin_arrival}]
      if {$cell_delay > $slowest_cell_delay} {
       set slowest_cell_delay $cell_delay
       set slowest_cell $last_cell_or_port
      }
     }
     if {$cell != ""} {
      set input_pin_arrival $this_arrival
     }
     set last_cell_or_port $this_cell_or_port
   }
   set last_arrival $this_arrival
  }

  # get first data arrival time, but skip any clock-as-data pins
  set i 0
  while {1} {
   set startpoint_arrival [get_attribute [set point [index_collection $points $i]] arrival]
   if {[get_attribute -quiet [get_attribute $point object] is_clock_pin] != "true"} {
    break
   }
   incr i
  }

  # get clock crosstalk
  # 1. pins may appear twice at gclock boundaries, but the delta only appears once
  # and is not double-counted
  # 2. capture clock deltas are subtracted to account for inverted sign
  foreach_in_collection point [get_attribute -quiet [get_attribute -quiet $path launch_clock_paths] points] {
   if {[set annotated_delay_delta [get_attribute -quiet $point annotated_delay_delta]] != ""} {
    set total_xtalk_clock [expr $total_xtalk_clock + $annotated_delay_delta]
   }
  }
  foreach_in_collection point [get_attribute -quiet [get_attribute -quiet $path capture_clock_paths] points] {
   if {[set annotated_delay_delta [get_attribute -quiet $point annotated_delay_delta]] != ""} {
    set total_xtalk_clock [expr $total_xtalk_clock - $annotated_delay_delta]
   }
  }

  set data(startpoint) [get_object_name [get_attribute $path startpoint]]
  set data(endpoint) [get_object_name [get_attribute $path endpoint]]
  set data(start_clk) [get_attribute -quiet [get_attribute -quiet $path startpoint_clock] full_name]
  set data(end_clk) [get_attribute -quiet [get_attribute -quiet $path endpoint_clock] full_name]
  if {[set data(launch_latency) [get_attribute -quiet $path startpoint_clock_latency]] == {}} {set data(launch_latency) 0.0}
  if {[set data(capture_latency) [get_attribute -quiet $path endpoint_clock_latency]] == {}} {set data(capture_latency) 0.0}
  set data(skew) [expr {($data(capture_latency)-$data(launch_latency))*([get_attribute $path path_type]=="max" ? 1 : -1)}]
  if {[set data(crpr) [get_attribute -quiet $path common_path_pessimism]] == ""} {set data(crpr) 0}
  set data(path_group) [get_object_name [get_attribute -quiet $path path_group]]
  set data(duration) [format "%.8f" [expr {[get_attribute $path arrival]-$data(launch_latency)-$startpoint_arrival}]]
  set data(arrival) $arrival
  set data(slack) [get_attribute $path slack]
  set data(hier_pins) [expr $hier_pins / 2]
  set data(num_segments) [llength $hier_cell_paths]
  set data(num_segment_crossings) [expr $data(num_segments) - 1]
  set data(num_unique_segments) [llength [lsort -unique $hier_cell_paths]]
  set data(levels) [expr {$combo_cell_pins / 2.0}]
  set data(average_cell_delay) [expr {$data(levels) == 0 ? 0.0 : [format "%.7f" [expr {($data(duration) / $data(levels))}]]}]
  set data(slowest_cell) [get_attribute -quiet $slowest_cell full_name]
  set data(slowest_cell_delay) $slowest_cell_delay
  set data(total_net_delay) $total_net_delay
  set data(slowest_net) [get_object_name $slowest_net]
  set data(slowest_net_delay) $slowest_net_delay
  set data(slowest_net_R) [get_attribute $slowest_net net_resistance_max]
  set data(slowest_net_C) [get_attribute $slowest_net total_capacitance_max]
  set data(index) $index
  set data(max_trans) $max_trans
  set data(total_xtalk_data) $total_xtalk_data
  set data(total_xtalk_clock) $total_xtalk_clock
  set data(total_xtalk) [expr {$total_xtalk_data + $total_xtalk_clock}]
  set data(xtalk_ratio) [expr {$data(duration) == 0.0 ? 0 : (100.0 * $total_xtalk_data / $data(duration))}]
  incr index

  set list_entry {}
  foreach field $path_summary::known_fields {
   lappend list_entry $data($field)
  }
  lappend path_summary::data_list $list_entry
 }
 echo "Path information stored."
 echo ""
}
}
define_proc_attributes process_paths \
 -info "Extract information from paths for write_path_summary" \
 -define_args {\
  {paths "Timing paths from get_timing_paths" "timing_paths" string required}
  {-ungrouped "Assume these instances have been ungrouped" ungrouped list optional}
 }




proc write_path_summary {args} {
    	global synopsys_program_name
      if { [string match $synopsys_program_name "pt_shell"] } {
# if user asks for help, remind him of what info is available
 if {[lsearch -exact $args {-longhelp}] != -1} {
  echo "Available data fields:"
  foreach field $path_summary::known_fields {
   echo " $field - [lindex $path_summary::finfo($field) 1]"
  }
  echo ""
  return
 }

 # process arguments
 set results(-fields) {startpoint endpoint levels slack}
 set results(-csv) 0
 set results(-descending) 0
 parse_proc_arguments -args $args results
 set num_fields [llength $results(-fields)]

 # did the user ask for any fields we don't understand?
 set leftovers [lminus $results(-fields) $path_summary::known_fields]
 if {$leftovers != ""} {
  echo "Error: unknown fields $leftovers"
  echo " (Possible values: $path_summary::known_fields)"
  return 0
 }

 # get sort type and direction, if specified
 if {[info exists results(-sort)]} {
  if {[set sort_field [lsearch -exact $path_summary::known_fields $results(-sort)]] == -1} {
   echo "Error: unknown sort field $results(-sort)"
   echo " (Possible values: $path_summary::known_fields)"
   return 0
  }
  set sort_type [lindex $path_summary::finfo($results(-sort)) 0]
  set sort_dir [expr {$results(-descending) ? "-decreasing" : "-increasing"}]
 }

 # obtain saved data from namespace, apply -sort and -max_paths
 set data_list $path_summary::data_list
 if {[info exists sort_field]} {
  set data_list [lsort $sort_dir -$sort_type -index $sort_field $data_list]
 }

 set data_list_length [llength $data_list]
 if {[info exists results(-max_paths)] && $data_list_length > $results(-max_paths)} {
  set data_list [lrange $data_list 0 [expr $results(-max_paths)-1]]
 }

 # generate a list of field index numbers relating to our known fields
 set field_indices {}
 foreach field $results(-fields) {
  lappend field_indices [lsearch $path_summary::known_fields $field]
 }

 # generate report
 if {$results(-csv)} {
  # join multi-line headers together
  set headers {}
  foreach index $field_indices {
   lappend headers [join [lindex $path_summary::finfo([lindex $path_summary::known_fields $index]) 2] { }]
  }

  # print headers
  echo [join $headers {,}]

  # print data
  foreach item $data_list {
   set print_list {}
   foreach index $field_indices {
    lappend print_list [lindex $item $index]
   }
   echo [join $print_list {,}]
  }
 } else {
  # determine maximum column widths
  echo ""
  echo "Legend:"
  foreach index $field_indices {
   set this_field [lindex $path_summary::known_fields $index]
   set this_finfo $path_summary::finfo($this_field)

   set this_max_length 0

   # check widths of each line of header
   foreach header [lindex $this_finfo 2] {
    set this_max_length [path_summary::max $this_max_length [string length $header]]
   }

   # check widths of data

   switch [lindex $this_finfo 0] {
    real {
     set max_pre 0
     set max_post 0
     foreach item $data_list {
      if {[set this_item [lindex $item $index]] == {INFINITY} || $this_item == {-INFINITY}} {
       set max_pre 3
       set max_post 0
      } else {
       regexp {([-0-9]*\.?)(.*)} [expr $this_item] dummy pre post
       set max_pre [path_summary::max $max_pre [string length $pre]]
       set max_post [path_summary::max $max_post [string length $post]]
      }
     }

     if {[info exists results(-significant_digits)]} {
      set max_post $results(-significant_digits)
     } else {
      set max_post [path_summary::min $max_post 7]
     }

     set this_max_length [path_summary::max $this_max_length [expr $max_pre + $max_post]]
    }
    default {
     foreach item $data_list {
      set this_max_length [path_summary::max $this_max_length [string length [lindex $item $index]]]
     }
    }
   }

   set max_length($index) $this_max_length

   switch [lindex $this_finfo 0] {
    int {
     set formatting($index) "%${this_max_length}d"
    }
    real {
     set formatting($index) "%${this_max_length}.${max_post}f"
    }
    string {
     set formatting($index) "%-${this_max_length}s"
    }
   }

   echo "$this_field - [lindex $this_finfo 1]"
  }

  # now print header
  echo ""
  for {set i 0} {$i <= 1} {incr i} {
   set print_list {}
   foreach index $field_indices {
    set this_field [lindex $path_summary::known_fields $index]
    set this_finfo $path_summary::finfo($this_field)
    lappend print_list [format "%-$max_length($index)s" [lindex [lindex $this_finfo 2] $i]]
   }
   echo [join $print_list { }]
  }

  set print_list {}
  foreach index $field_indices {
   lappend print_list [string repeat {-} $max_length($index)]
  }
  echo [join $print_list {+}]

  # print all data
  foreach item $data_list {
   set print_list {}
   foreach index $field_indices {
    lappend print_list [format $formatting($index) [lindex $item $index]]
   }
   echo [join $print_list { }]
  }
  echo ""
 }
}
}
define_proc_attributes write_path_summary \
 -info "Generate a summary report for given timing paths" \
 -define_args {\
  {-longhelp "Show description of available data fields" "" boolean optional}
  {-max_paths "Limit report to this many paths" "num_paths" int optional}
  {-fields "Information fields of interest" "fields" list optional}
  {-sort "Sort by this field" "field" string optional}
  {-descending "Sort in descending order" "" boolean optional}
  {-csv "Generate CSV report for spreadsheet" "" boolean optional}
  {-significant_digits "Number of digits to display" digits int optional}
 }

##############################################################################################################
# get constant clocks
#######################################################################################################################
proc get_constant_clocks {} {
    	global synopsys_program_name
    if { [string match $synopsys_program_name "pt_shell"] } {
	set const1_ckpins  ""
	set const0_ckpins  ""
	set allregckpins [all_registers -clock_pins]
	set const1_ckpins [filter_collection $allregckpins "case_value==1 || constant_value==1"]                                                    
	set const0_ckpins [filter_collection $allregckpins "case_value==0 || constant_value==0"]      
	#echo "[get_attr $const0_ckpin full_name] is tied to [get_attr $const0_ckpin case_value]" 
	return [add_to_collection $const1_ckpins  $const0_ckpins]    
    }
}
#######################################################################################################################
## get constant resets, fix needed
#######################################################################################################################
proc get_constant_resets { } {

    global synopsys_program_name
    
    if { [string match $synopsys_program_name "pt_shell"] } {
		
	# Registers with asynchronous preset and/or clear pins tied to constant_value
	append_to_collection -unique regs [get_cells -of_objects [filter_collection [all_registers -async_pins] "defined(constant_value)"]]

	# Registers with both asynchronous preset and clear pins with controllable preset or clear are ok.
	foreach_in_collection r $regs {
	    set rb_pin     [get_pins -quiet -of_objects $r -filter "full_name =~ */rb"]
	    set psb_pin    [get_pins -quiet -of_objects $r -filter "full_name =~ */psb"]
	    set rb_pin_cv  [get_attribute -quiet $rb_pin constant_value]
	    set psb_pin_cv [get_attribute -quiet $psb_pin constant_value]
	    if { ( ( [sizeof_collection $rb_pin] == 1 ) && ( [sizeof_collection $psb_pin] == 1 ) ) && ( ( $rb_pin_cv == "" ) || ( $psb_pin_cv == "" ) ) } {
		append_to_collection -unique regs_with_no_issue $r
	    }
	}

    }
    
    # Report constant registers
    return [get_pins -quiet -of_objects [remove_from_collection $regs $regs_with_no_issue] -filter "full_name =~ */rb || full_name =~ */psb"]

}


#######################################################################################################################
## report sources where clock does not exist
#######################################################################################################################
# Usage:  report_no_clock_source > no_clock_source.txt
#  # example report
#sizeof_col, startpin, first load, clocks (if exist)
# 452 , HP_DUL_UCS0_axistrmcbr002_i0_B_Clk -to hp_dul_i0/HP_DUL_UCS0_axistrmcbr002_i0/inst_RX/B_TXPReg_reg_0/clk ,
# 452 , HP_DUL_UCS1_axistrmcbr002_i0_B_Clk -to hp_dul_i0/HP_DUL_UCS1_axistrmcbr002_i0/inst_RX/B_TXPReg_reg_0/clk ,
# 1220 , HP_DUL_UIS0_axistrmcbr002_i0_B_Clk -to hp_dul_i0/HP_DUL_UIS0_axistrmcbr002_i0/inst_RX/B_TXPReg_reg_0/clk ,
# 1220 , HP_DUL_UIS1_axistrmcbr002_i0_B_Clk -to hp_dul_i0/HP_DUL_UIS1_axistrmcbr002_i0/inst_RX/clk_gate_B_TXWrap_reg_0/latch/clk ,
# 236970 , clk_conn_dfeif_d1 -to hp_dul_i0/HP_DUL_UCS1_axistrmcbr002_i0/inst_RX/ILockForceOpen_reg/clk ,
# 628 , clk_cpri_obsai307_d2 -to hp_dul_i0/i_conn002_dul/I_DUL_CDC_1/CDC_STR_MSG_DATA_reg_101/clk ,

# 

proc report_no_clock_source {  {trace false}  {no_clock_print false} {print false}  } {
    	global synopsys_program_name
    if { [string match $synopsys_program_name "pt_shell"] } {
	set temp [all_registers -clock_pins]

	set no_clock_col []
	set no_clock_col2 []
	set no_clock_col_temp []
	set no_clock_col2_temp []
	
	set startpoints_col []
	set startpoints_col_temp []
	
	if {$trace == "true"} {
	    foreach_in_collection i $temp {
		if {[sizeof_collection [get_attribute -quiet $i clocks] ] == 0} {
		    set no_clock_col [add_to_collection $no_clock_col $i]
		    
		    if {$print == "true"} {
			
			set apu [all_fanin -flat -to $i -start -trace_arcs all]
			
			#if  [sizeof_collection [filter_collection $apu full_name!~*Logic*]] > 0
			
			if { [sizeof_collection $apu] > 0 && [sizeof_collection [filter_collection $apu full_name=~*Logic*]] == 0 } {
			    echo [get_object_name $i] , [get_object_name $apu] , [get_object_name [get_attribute -quiet $i clocks]]
			    set no_clock_col2 [add_to_collection $no_clock_col2 $i]
			}
		    }
		}
	    }
	}
	
	#echo "1"
	
	foreach_in_collection i $temp {
	    if {[sizeof_collection [get_attribute -quiet $i clocks] ] == 0} {
		set no_clock_col_temp [add_to_collection $no_clock_col_temp $i]
		
		if {$print == "true"} {
		    
		    redirect /dev/null {set apu [all_fanin -flat -to $i -start ] } 
		    
                #if  [sizeof_collection [filter_collection $apu full_name!~*Logic*]] > 0
		    
		    if { [sizeof_collection $apu] > 0 && [sizeof_collection [filter_collection $apu full_name=~*Logic*]] == 0 } {
			echo [get_object_name $i] , [get_object_name $apu] , [get_object_name [get_attribute -quiet $i clocks]]
			set no_clock_col2_temp [add_to_collection $no_clock_col2_temp $i]
		    }
		}
	    }
	}
	
	#echo "2"
	
    if {$trace == "true"} {
        echo "\# with trace args \#"
        foreach_in_collection i $no_clock_col {
	    
            redirect /dev/null {set temp [all_fanin -trace_arcs all -flat -start -to $i ] }
	    
            set startpoints_col [add_to_collection $startpoints_col  $temp -unique] 
            
            #set apu [join [concat [get_object_name $i] "," [collection_to_list [get_attribute -quiet $i clocks]] [all_fanin  -flat -start -to $i -trace_arcs all] ]]
            #echo $apu
        }

	
        foreach_in_coll i [sort_collection [filter_collection $startpoints_col full_name!~*Logic*] full_name] {
            
            set apu [join [concat [get_object_name $i] "," [sizeof_collection [filter_collection [all_fanout -trace_arcs all -flat -from $i]  "undefined(clocks) && is_clock_pin == true"]] "," [collection_to_list2 [get_attribute -quiet $i clocks]] "," [get_first_clock_pin $i]]]
            echo $apu

            if {$no_clock_print== "true" } {
		
                #echo [afof_no_clocks3 [get_ports_pins [get_object_name $i]]]
            }
        }
    }

	
	#echo " \# no trace args \#"
	echo "sizeof_col, startpin, first load, clocks (if exist)"
	foreach_in_collection i $no_clock_col_temp {
	    redirect /dev/null {set temp [all_fanin  -flat -start -to $i ] }
	    
	    set startpoints_col_temp [add_to_collection $startpoints_col_temp $temp -unique] 
	    
	    #set apu [join [concat [get_object_name $i] "," [collection_to_list [get_attribute -quiet $i clocks]] [all_fanin  -flat -start -to $i -trace_arcs all] ]]
	    #echo $apu
	}
	
	
	foreach_in_coll i [sort_collection [filter_collection $startpoints_col_temp full_name!~*Logic*] full_name] {
	    set apu [join [concat [sizeof_collection [filter_collection [all_fanout -end -flat -from $i]  "undefined(clocks) && is_clock_pin == true"]] "," [get_object_name $i]  " -to " [get_object_name [get_first_clock_pin $i]]  ","   [collection_to_list2 [get_attribute -quiet $i clocks]] ]]
	    echo $apu 
	    #echo [afof_no_clocks2 [get_ports_pins [get_object_name $i]]]
	    
	    if {$no_clock_print == "true" } {
		#echo [afof_no_clocks2 [get_ports_pins [get_object_name $i]]]
	    }
	}
	
	foreach_in_collection i $no_clock_col2 {
	    set startpoints_col [add_to_collection $startpoints_col [all_fanin -trace_arcs all -flat -start -to $i ] -unique] 
	    #set apu [join [concat [get_object_name $i] "," [collection_to_list [get_attribute -quiet $i clocks]] [all_fanin  -flat -start -to $i -trace_arcs all] ]]
	    #echo $apu
	}
    }
}
#######################################################################################################################
## sub procedure needed by report_no_clock_source
#######################################################################################################################

proc get_first_clock_pin {my_pin} {
    #set temp []
    set temp1 [all_fanout -from $my_pin -flat]
    foreach_in_collection i  [remove_from_collection  $temp1 [index_collection $temp1 0]] { 
        
        if  {[get_attribute -quiet $i is_clock_pin] == true} { 
            return $i
            #add_to_collection $temp $i 
            #echo [get_object_name $i]
            #break 
        }
    }
    #return $temp
}


#######################################################################################################################
## report number of registers per clock domain
#######################################################################################################################
proc get_regs_per_clock {} {
                         foreach_in_collection i [get_clocks *] {
                             echo [get_object_name $i]  [sizeof_collection [all_register -clock $i]] 
                         }
                     }


#######################################################################################################################
## Check that ip/macro output/input is connected directly to ff
#######################################################################################################################
# Usage from toplevel: get_ip_io_comb_cells u_hcm_top/dfe_top_inst_0/HM_DL_CLIPPER1_top_inst "INV* BUF* DEL* ISOL*"
# Usage at ip/HM level: get_ip_io_comb_cells "" "ec0i ec0b ecof"
# Note also logic_* can be added to filter list ie. "INV* BUF* DEL* ISOL* logic_*"

proc get_ip_io_comb_cells {hm filt} {

    if {${hm} == ""} {
	set output_pins [get_ports * -f "pin_direction==out" -q]
	set input_pins  [get_ports * -f "pin_direction==in" -q]
    } else {
	set output_pins [get_pins ${hm}/* -f "pin_direction==out" -q]
	set input_pins  [get_pins ${hm}/* -f "pin_direction==in" -q]
    }
    
    set i 0
    # add registers to filter
#    set filt "$filt SDF*"
    set fl [string map {" " "\|"} $filt ]
  
    foreach_in_collection x $output_pins {
	set comb ""
	# all fanin cells except the top level
	set rf_name [lsearch -not -all -inline \
			 [get_attribute [all_fanin -to $x -flat -only_cells -trace_arcs all] ref_name] \
			 [get_attribute [get_cells ${hm}] ref_name] \
			 ]
	# filter out other cells
	set comb [lsearch -inline -all -not -regexp $rf_name $fl]
	if {$comb != ""} {
	    incr i
	    echo "$i : [get_object_name $x] output has comb - example: [lindex $comb 0]"
	}
    }	

    set i 0

    foreach_in_collection x $input_pins {
	set comb ""
	# all fanin cells except the top level
	set rf_name [lsearch -not -all -inline \
			 [get_attribute [all_fanout -from $x -flat -only_cells -trace_arcs all] ref_name] \
			 [get_attribute [get_cells ${hm}] ref_name] \
			 ]
	# filter out other cells
	set comb [lsearch -inline -all -not -regexp $rf_name $fl]
	if {$comb != ""} {
	    incr i
	    echo "$i : [get_object_name $x] input has comb - example: [lindex $comb 0]"
	}
    }	

}

######################################################################################################################
## Helper procedure for print_io_registers
######################################################################################################################
proc print_fanout_recurs { ipins level &reglevel } {

    set IPINS $ipins
    set LEVEL $level
    upvar ${&reglevel} REGLEVEL

    foreach_in_collection ip $IPINS {
	set cell [get_cells -of_objects [get_pins $ip]]
	set c_rn [get_attribute $cell ref_name]
	set pin_fn [get_attribute $ip full_name]

	if {![regexp {^ec0([a-z]+)\d+\S+\d+x\d+$} $c_rn -> obfs_rn]} {
	    #echo "what ref_name: ${c_rn}"
	    set obfs_rn $c_rn
	}

	if {[get_attribute $cell is_sequential] || [regexp {^ip7431\S+} $c_rn]} {
	    if {[info exists REGLEVEL($pin_fn)]} {
		if {$REGLEVEL($pin_fn) < $LEVEL} {
		    set REGLEVEL($pin_fn) $LEVEL
		}
	    } else {
		set REGLEVEL($pin_fn) $LEVEL
	    }		
	    continue
	}

	set opins [get_pins -of_objects [get_cells $cell] -filter "direction==out"]
	if {[regexp {ec0*bf*} $c_rn] || [regexp {ec0*inv*} $c_rn]} {
	    # skip buffers and inverters
	    foreach_in_collection op $opins {
		set fanout [filter_collection [filter_collection [all_fanout -flat -from [get_pins $op] -levels 1] "direction==in"] "object_class!=port"]
		print_fanout_recurs $fanout $LEVEL REGLEVEL
	    }
	} else {
	    foreach_in_collection op $opins {
		set fanout [filter_collection [filter_collection [all_fanout -flat -from [get_pins $op] -levels 1] "direction==in"] "object_class!=port"]
		print_fanout_recurs $fanout [expr $LEVEL + 1] REGLEVEL
	    }
	}
    }
}

######################################################################################################################
## Helper procedure for print_io_registers
######################################################################################################################
proc print_fanin_recurs { ipins opin level &reglevel } {

    set IPINS $ipins
    set LEVEL $level
    set OPIN $opin
    upvar ${&reglevel} REGLEVEL

    foreach_in_collection ip $IPINS {
	set cell [get_cells -of_objects [get_pins $ip]]
	set c_rn [get_attribute $cell ref_name]
	set opin_fn [get_attribute $OPIN full_name]

	if {![regexp {^ec0([a-z]+)\d+\S+\d+x\d+$} $c_rn -> obfs_rn]} {
	    #echo "what ref_name: ${c_rn}"
	    set obfs_rn $c_rn
	}

	if {[get_attribute $cell is_sequential] || [regexp {^ip7431\S+} $c_rn]} {
	    if {[info exists REGLEVEL($opin_fn)]} {
		if {$REGLEVEL($opin_fn) < $LEVEL} {
		    set REGLEVEL($opin_fn) $LEVEL
		}
	    } else {
		set REGLEVEL($opin_fn) $LEVEL
	    }		
	    continue
	}

	set fanin_in [remove_from_collection [filter_collection [filter_collection [all_fanin -flat -to [get_pins $ip] -levels 1] "direction==in"] "object_class!=port"] $ip]
	set fanin_out [filter_collection [filter_collection [all_fanin -flat -to [get_pins $ip] -levels 1] "direction==out"] "object_class!=port"]
	if {[regexp {ec0*bf*} $c_rn] || [regexp {ec0*inv*} $c_rn]} {
	    # skip buffers and inverters
	    print_fanin_recurs $fanin_in $fanin_out $LEVEL REGLEVEL
	} else {
	    print_fanin_recurs $fanin_in $fanin_out [expr $LEVEL + 1] REGLEVEL
	}
    }
}

######################################################################################################################
## Print registers directly connected to IO ports and number of logic leves in between
######################################################################################################################
proc print_io_registers { args } {
    global input_clock_ports_list
    global output_clock_ports_list
    global reset_ports_list

    # Parse arguments
    parse_proc_arguments -args $args results

    set MIN_LIMIT 0
    if {[info exists results(-min_limit)]} {
	set MIN_LIMIT $results(-min_limit)
    }

    set MAX_LIMIT 64
    if {[info exists results(-max_limit)]} {
	set MAX_LIMIT $results(-max_limit)
    }

    set ios [sort_collection [get_ports * -filter "direction==in"] full_name]
    if {[info exists input_clock_ports_list]} {
	set ios [remove_from_collection $ios $input_clock_ports_list]
    }
    if {[info exists reset_ports_list]} {
	set ios [remove_from_collection $ios $reset_ports_list]
    }

    echo "#########################"
    echo "# Format (first all inputs, then all outputs)"
    echo "#########################"
    echo "# INPUT: port_name (fanout number)"
    echo "#     {logic levels to register} : register_pin_name"
    echo "# OUTPUT: port_name (fanout number)"
    echo "#     {logic levels to register} : register_pin_name"
    echo "#########################"
    
    

    array unset port_soc_array
    array unset port_reglevel_array
    foreach_in_collection inp $ios {
	set soc [sizeof_collection [filter_collection [remove_from_collection [all_fanout -flat -endpoints_only -from [get_ports $inp]] $inp] "object_class!=port"]]
	if { $soc > $MIN_LIMIT && $soc <= $MAX_LIMIT } {
	    #echo "INPUT: [get_attribute $inp full_name] (${soc})"
	    set port_soc_array([get_attribute $inp full_name]) $soc
	    array unset reglevel
	    print_fanout_recurs [filter_collection [remove_from_collection [filter_collection [all_fanout -flat -from [get_ports $inp] -levels 1] "direction==in"] $inp] "object_class!=port"] 0 reglevel
	    set l [array get reglevel]
	    set port_reglevel_array([get_attribute $inp full_name]) [lsort -stride 2 -integer -decreasing -index 1 $l]
	    #foreach reg [array names reglevel] {
		#set level $reglevel($reg)
		#echo "     \{${level}\}: $reg"
	    #}
	} elseif { $soc > $MAX_LIMIT } {
	    #echo "INPUT: [get_attribute $inp full_name] (${soc})"
	    set port_soc_array([get_attribute $inp full_name]) $soc
	}
    }
    
    # sort array
    set l [array get port_soc_array]
    set lsorted [lsort -stride 2 -integer -decreasing -index 1 $l]
    foreach {inp soc} $lsorted {
	echo "INPUT: $inp (${soc})"
	if {[info exists port_reglevel_array($inp)]} {
	    foreach {reg level} $port_reglevel_array($inp) {
		echo "     \{${level}\}: $reg"
	    }
	}
    }

    set ios [sort_collection [get_ports * -filter "direction==out"] full_name]
    if {[info exists output_clock_ports_list]} {
    	set ios [remove_from_collection $ios $output_clock_ports_list]
    }
   
    array unset port_soc_array
    array unset port_reglevel_array
    foreach_in_collection outp $ios {
    	set soc [sizeof_collection [filter_collection [remove_from_collection [all_fanin -flat -startpoints_only -to [get_ports $outp]] $outp] "object_class!=port"]]
    	if { $soc > $MIN_LIMIT && $soc <= $MAX_LIMIT } {
    	    #echo "OUTPUT: [get_attribute $outp full_name] (${soc})"
	    set port_soc_array([get_attribute $outp full_name]) $soc
	    array unset reglevel
	    set fanin_in [filter_collection [filter_collection [all_fanin -flat -to [get_ports $outp] -levels 1] "direction==in"] "object_class!=port"]
	    set fanin_out [filter_collection [filter_collection [all_fanin -flat -to [get_ports $outp] -levels 1] "direction==out"] "object_class!=port"]
    	    print_fanin_recurs $fanin_in $fanin_out 0 reglevel
	    set l [array get reglevel]
	    set port_reglevel_array([get_attribute $outp full_name]) [lsort -stride 2 -integer -decreasing -index 1 $l]
    	    #foreach reg [array names reglevel] {
    		#set level $reglevel($reg)
    		#echo "     \{${level}\}: $reg"
    	    #}
    	} elseif { $soc > $MAX_LIMIT } {
    	    #echo "OUTPUT: [get_attribute $outp full_name] (${soc})"
	    set port_soc_array([get_attribute $outp full_name]) $soc
    	}
    }

    # sort array
    set l [array get port_soc_array]
    set lsorted [lsort -stride 2 -integer -decreasing -index 1 $l]
    foreach {outp soc} $lsorted {
	echo "OUTPUT: $outp (${soc})"
	if {[info exists port_reglevel_array($outp)]} {
	    foreach {reg level} $port_reglevel_array($outp) {
		echo "     \{${level}\}: $reg"
	    }
	}
    }
}

define_proc_attributes print_io_registers \
    -info "Procedure for printing registers connected to IOs." \
    -define_args {
	{-min_limit "only print IOs which have more registers than this" "" int optional}
	{-max_limit "only print IOs which have less registers than this (runtime increases exponentially)" "" int required}
    }

#######################################################################################################################
## Check that ram output is connected directly to ff
#######################################################################################################################
# This should be run only for netlist without DFT insertion
# Shadow ram wrapper logic will give false reports for dft inserted netlist. 
# Usage: get_ram_path_comb_cells *RR28* Q* "SDF* BUF* INV* RR28* DEL*"

proc get_ram_path_comb_cells {rf pn filt} {
    set start_pt [get_pins -of_object [get_cells -h * -f "ref_name=~${rf} && is_hierarchical!=true" -q] -f "full_name=~*/${pn}" -q]
    set start_2 ""
    set i 0
    set fl [string map {" " "\|"} $filt ]
   
    foreach_in_collection x $start_pt {

	set rf_name [get_attribute [get_cells -of_objects [all_fanout -from $x -flat] -q] ref_name]
	set comb [lsearch -inline -all -not -regexp $rf_name $fl]
  
	set start [string replace [get_object_name $x] [string last / [get_object_name $x]] [string length [get_object_name $x]]]
	
	if {$comb != "" && $start_2 != $start} {
	    incr i
	    echo "$i : $start has comb - example: [lindex $comb 0]"
	    set start_2 $start
	}
    }	
}



#######################################################################################################################
## Check that ram wrapper output is connected directly to ff
#######################################################################################################################
# This should be run only for netlist without DFT insertion
# Shadow ram wrapper logic will give false reports for dft inserted netlist. 
# Usage: get_ram_path_comb_cells *RR28* Q* "SDF* BUF* INV* RR28* DEL*"

proc get_ram_wrapper_path_comb_cells {rf pn filt} {
    set start_pt [get_pins -of_object [get_cells -h * -f "ref_name=~${rf} " -q] -f "full_name=~*/${pn}" -q]
    set start_2 ""
    set i 0
    set fl [string map {" " "\|"} $filt ]
    
    foreach_in_collection x $start_pt {

	set rf_name [get_attribute [get_cells -of_objects [all_fanout -from $x -flat] -q] ref_name]
	set comb [lsearch -inline -all -not -regexp $rf_name $fl]
  
	set start [string replace [get_object_name $x] [string last / [get_object_name $x]] [string length [get_object_name $x]]]
	
	if {$comb != "" && $start_2 != $start} {
	    incr i
	    echo "$i : $start has comb - example: [lindex $comb 0]"
	    set start_2 $start
	}
    }	
}

#######################################################################################################################
# Procedure for library cell pins function attribute reporting
#######################################################################################################################
proc dc_report_function_attributes { } {

    set f_pins [sort_collection [get_lib_pins */*/* -filter "defined(function) && (function == 0 || function == 1) && full_name !~ gtech/* && full_name !~ ec0_*/ec0ti??00*/o"] full_name]

    if { [sizeof_collection $f_pins] } {
	echo "Nokia Warning: Following library cell pins have function attribute definition. Make sure all these definitions are correct. In other case synthesis will incorrectly optimize pins fanout logic with constant propagation."
	pcollection -attributes {full_name function} $f_pins
    }

}


#######################################################################################################################
# Procedure for reporting lib cell distribution.
#######################################################################################################################

proc libs_distribution { des_name out_name} {
    set design [get_object_name [current_design]]
    array set  nbr ""
    
    
    foreach_in_collection CORELIBS  [remove_from_collection [remove_from_collection [remove_from_collection [get_libs] gtech] standard.sldb] dw_foundation.sldb] {
	set nbr([get_object_name $CORELIBS]) 0
    }
    
    set totalnbr 0
    
    foreach_in_collection solu_i [get_cells -hier * -filter "is_hierarchical==false && full_name=~$des_name/*"] {
	set solu          [get_object_name $solu_i]
	set solu_ref [get_attribute [get_cell $solu] ref_name]
	
	if {($solu_ref!="**logic_one**")&&($solu_ref!="**logic_zero**")} {
	    set solu_lib [file dirname [get_object_name [get_lib_cells -of_object $solu_i]]]
	    incr totalnbr
	    
	    if {$solu_lib=="."} {
		puts "Error: procedure libs_distribution: cell $solu / Module $solu_REF_NAME is empty !!"
		
	    } else { 
		if {$solu_lib=="gtech"} {
		    puts "Error: procedure libs_distribution: Your design contains unmapped logic, GTECH cells / FFGEN cells / SEQGEN cells"
		    break
		} else {

		    
		    set Index $nbr($solu_lib)
		    incr   Index
		    set nbr($solu_lib) $Index
		}
		
	    }
	}
	
    }
    
    redirect  ./${out_name}.Libsdistribution.rpt {
	echo ""
	echo ""
	echo " -----------------------------------------------------------------------------------------------------------"
	echo "|              LIBRARY                               |  CellsUsed     |  TotalCells |     Ratio  (%)     |"
	echo "|----------------------------------------------------|----------------|----------------|--------------------|"
	
	foreach i [array names nbr] {
	    set ratio [expr (($nbr($i) * 100 ) / $totalnbr.0)]
	    echo [format "| %50s | %14s | %14s | %18s |" $i $nbr($i) $totalnbr $ratio]
	}
	echo " ------------------------------------------------------------------------------------------------------------"
    }
    echo ""
    echo "###   -> ./${des_name}.Libsdistribution.rpt file generated     "
    echo ""
}

#######################################################################################################################
# Procedure for related supply and ground nets reporting.
#######################################################################################################################
proc dc_report_related_supply_nets { args } {

    # Parse arguments
    parse_proc_arguments -args $args results
    
    # Arguments
    if { [info exists results(-objects)] } {
        set objects $results(-objects)
    } else {
        echo "Nokia Error: objects not defined."
        echo "Exiting..."
        return 0
    }

    echo "Nokia Info: reporting object(s) related supply and ground nets:"

    append_to_collection -unique all_objects [get_pins -quiet $objects]
    append_to_collection -unique all_objects [get_ports -quiet $objects]

    foreach_in_collection p $all_objects {

	set p_fn [get_attribute $p full_name]
	set p_rsn [get_attribute [get_related_supply_net $p] name]
	set p_rgn [get_attribute [get_related_supply_net $p -ground] name]
	set p_class [get_attribute -quiet $p object_class]

	echo "$p_fn $p_rsn $p_rgn ($p_class)"

    }

}

define_proc_attributes dc_report_related_supply_nets \
    -info "Procedure for related supply and ground nets reporting." \
    -define_args {
        {-objects "Collection/list of pin(s) or port(s) to be reported." "" string required}}


#######################################################################################################################
# Script to find if ports has delays for all clocks defined
#######################################################################################################################

proc report_port_constraints {port} {
    set clocks [join [get_attribute [get_ports ${port}] arrival_window]]
    redirect -variable clk_set {report_port ${port} -v}
    for {set i 0} {$i < [llength $clocks]} {incr i} {
	if {[lsearch -all [join $clk_set] [lindex $clocks $i 0]] > 0} {
#	    echo "Port ${port} has constraints with [lindex $clocks $i 0] clock"
	} else {
	    echo "Port [get_object_name ${port}] dont have constraints set to [lindex $clocks $i 0] "
	}
    }
}

#Usage foreach_in_collection x [get_ports *] {report_port_constraints $x } 

#######################################################################################################################
# Procedure for top level power domain isolation policy script creation. Default isolation to low is assumed.
#######################################################################################################################
proc upf_create_top_pd_iso_policy_script { args } {

    # Parse arguments
    parse_proc_arguments -args $args results
    
    # Arguments
    if { [info exists results(-cell)] } {
        set cell $results(-cell)
    } else {
        echo "Nokia Error: cell not defined."
        echo "Exiting..."
        return 0
    }

    if { [info exists results(-isolation_control_pin)] } {
        set isolation_control_pin $results(-isolation_control_pin)
    } else {
        echo "Nokia Error: isolation_control_pin not defined."
        echo "Exiting..."
        return 0
    }
    
    if { [info exists results(-no_iso_pins)] } {
        set no_iso_pins $results(-no_iso_pins)
    } else {
        echo "Nokia Error: no_iso_pins not defined."
        echo "Exiting..."
        return 0
    }

    if { [info exists results(-iso_high_pins)] } {
        set iso_high_pins $results(-iso_high_pins)
    } else {
        echo "Nokia Error: iso_high_pins not defined."
        echo "Exiting..."
        return 0
    }

    set cell_rn [get_attribute $cell ref_name]
    set isolation_control_pin_fn [get_attribute $isolation_control_pin full_name]

    # Iso low pins
    set iso_low_pins [sort_collection [remove_from_collection [remove_from_collection [get_pins -of_objects $cell -filter "pin_direction == out"] $no_iso_pins] $iso_high_pins] full_name]

    # Create UPF script
    echo ""
    echo "########################################################################################################################"
    echo "# ${cell_rn}_ISO_OUT_LOW"
    echo "########################################################################################################################"
    echo "set_isolation ${cell_rn}_ISO_OUT_LOW -domain ${cell_rn}_SW_Domain -isolation_power_net VDD -isolation_ground_net VSS -clamp_value 0 -elements \""
    pcollection ${iso_low_pins}
    echo "\""
    echo "set_isolation_control ${cell_rn}_ISO_OUT_LOW -domain ${cell_rn}_SW_Domain -isolation_signal \"\n${isolation_control_pin_fn}\n\" -isolation_sense high -location parent"
    echo ""

    echo ""
    echo "########################################################################################################################"
    echo "# ${cell_rn}_ISO_OUT_HIGH"
    echo "########################################################################################################################"
    echo "set_isolation ${cell_rn}_ISO_OUT_HIGH -domain ${cell_rn}_SW_Domain -isolation_power_net VDD -isolation_ground_net VSS -clamp_value 1 -elements \""
    pcollection ${iso_high_pins}
    echo "\""
    echo "set_isolation_control ${cell_rn}_ISO_OUT_HIGH -domain ${cell_rn}_SW_Domain -isolation_signal \"\n${isolation_control_pin_fn}\n\" -isolation_sense high -location parent"
    echo ""

    echo ""
    echo "########################################################################################################################"
    echo "# ${cell_rn}_NO_ISO_OUT"
    echo "########################################################################################################################"
    echo "set_isolation ${cell_rn}_NO_ISO_OUT -domain ${cell_rn}_SW_Domain -no_isolation -elements \""
    pcollection ${no_iso_pins}
    echo "\""
    echo "set_isolation_control ${cell_rn}_ISO_OUT_HIGH -domain ${cell_rn}_SW_Domain -isolation_signal \"\n${isolation_control_pin_fn}\n\" -isolation_sense high -location parent"
    echo ""


}

define_proc_attributes upf_create_top_pd_iso_policy_script \
    -info "Procedure for top level power domain isolation policy script creation. Default isolation to low is assumed." \
    -define_args {
	{-cell "Power domain cell." "" string required} \
	    {-isolation_control_pin "Isolation control pin." "" string required} \
            {-no_iso_pins "Pins with no isolation." "" string optional} \
            {-iso_high_pins "Pins with isolation high." "" string optional}}


#######################################################################################################################
# Procedure for output isolation addition
#######################################################################################################################

proc dc_add_output_isolations { args } {

    # Parse arguments
    parse_proc_arguments -args $args results
    
    # Arguments
    if { [info exists results(-pins)] } {
	set pins $results(-pins)
    } else {
	echo "Nokia Error: pins not defined."
        echo "Exiting..."
        return 0
    }

    if { [info exists results(-isolation_control_pin)] } {
	set isolation_control_pin $results(-isolation_control_pin)
    } else {
	echo "Nokia Error: isolation_control_pin not defined."
        echo "Exiting..."
        return 0
    }

    if { [info exists results(-reference)] } {
        set reference $results(-reference)
    } else {
	echo "Nokia Error: reference not defined."
        echo "Exiting..."
        return 0
    }


    foreach_in_collection p $pins {

	# Data for further usage
	set c [get_cells -of_objects $p]
	set n [all_connected $p]
	set c_n [get_attribute $c name]
	set c_fn [get_attribute $c full_name]
	set n_fn [get_attribute $n full_name]
	set hc_fn [regsub {(.*)/(.*)} $c_fn {\1}]
	set p_fn [get_attribute $p full_name]
	set p_n [get_attribute $p name]

	# Isolation pin name
	regsub -all {\]\[} $p_n {_} iso_p_n
	regsub -all {\[} $iso_p_n {_} iso_p_n
	regsub -all {\]$} $iso_p_n {} iso_p_n
	regsub -all {$} $iso_p_n {_UPF_ISO} iso_p_n
	
	# Isolation cell full name
	set iso_c_fn "${c_fn}_${iso_p_n}"

	# Add isolation cells
	create_cell $iso_c_fn $reference
	disconnect_net $n $p
	connect_net $n [get_pins ${iso_c_fn}/Z]
	connect_pin -from $p -to [get_pins ${iso_c_fn}/A]
	connect_pin -from [get_pins $isolation_control_pin] -to [get_pins ${iso_c_fn}/ISO]
    
    }

}

define_proc_attributes dc_add_output_isolations \
    -info "Procedure for output isolations addition." \
    -define_args {
	{-isolation_control_pin "Isolation control pin." "" string required} \
	    {-pins "Output pins to be isolated." "" string required} \
	    {-reference "Isolation cell reference" "" string required}}


#######################################################################################################################
# Procedure for performance library cells linking to density library cells
#######################################################################################################################

proc dc_link_performance_lib_cells_to_density_lib_cells { args } {

    parse_proc_arguments -args $args results

    foreach_in_collection c [get_cells -hierarchical -filter "ref_name =~ *3?P"] {

	set c_fn [get_attribute $c full_name]
	set c_rn [get_attribute $c ref_name]
	regsub {P$} $c_rn {D} c_rn_new
	set l_c [index_collection [get_lib_cells */${c_rn_new}] 0]
	set l_c_fn [get_attribute $l_c full_name]
	
	if { [sizeof_collection $l_c] } {
	    echo "Nokia Info: Changing cell $c_fn reference from $c_rn to $c_rn_new"
	    change_link $c $l_c_fn
	} else {
	    echo "Nokia Error: Can't change cell $c_fn reference from $c_rn to $c_rn_new, because library cell $c_rn_new doesn't exist."
	}

    }

}

define_proc_attributes dc_link_performance_lib_cells_to_density_lib_cells \
    -info "Procedure for performance library cells linking to density library cells." \
    -define_args {}


#######################################################################################################################
# pt_check_synchronizer_drivers checks, that there isn't more than one driver cell for synchronizer.
#######################################################################################################################
proc pt_check_synchronizer_drivers { } {

    foreach_in_collection c [get_cells -hierarchical -filter "ref_name =~ ec0fmw*"] {
	set p [get_pins -of_objects $c -filter "full_name =~ */d"]
	set p_fn [get_attribute $p full_name]
	set drvs [all_fanin -flat -startpoints_only -to $p]
	set drvs_cnt [sizeof_collection $drvs]

	if { $drvs_cnt > 1 } {
	    echo "Nokia Error: Synchronizer fanin cone contains more than one driver cell:"
	    echo "Synchronizer:"
	    echo "$p_fn"
	    echo "Drivers:"
	    pcollection $drvs
	    echo ""
	}
    }
    
}


#######################################################################################################################
# list synchronizer cells in design
#######################################################################################################################
proc list_synchronizer_cells { } {

    foreach_in_collection c [get_cells -hierarchical -filter "ref_name =~ ec0fmw*"] {

        set p_fn [get_attribute $c full_name]
            echo "$p_fn"
    }
    
}



#######################################################################################################################
# pt_create_hm_cdc_paths_array
# Usage example :
# array set cdc_paths [pt_report_hm_cdc_paths -cdc_clocks [get_clocks *_cdc] -main_cdc_clock [get_clocks clk_ref_cdc]]
#######################################################################################################################
proc pt_create_hm_cdc_paths_array { args } {

    # Parse arguments
    parse_proc_arguments -args $args results

    # Cdc clocks
    set cdc_clocks ""
    if { [info exists results(-cdc_clocks)] } {
        set cdc_clocks $results(-cdc_clocks)
    }

    if { [string match $cdc_clocks ""] } {
        echo "Nokia Error: cdc clocks must be defined."
        echo "Exiting..."
        return 0
    }

    # Main cdc clock
    set main_cdc_clock ""
    if { [info exists results(-main_cdc_clock)] } {
        set main_cdc_clock $results(-main_cdc_clock)
    }

    if { [string match $main_cdc_clock ""] } {
        echo "Nokia Error: main clock must be defined."
        echo "Exiting..."
        return 0
    }

    # Create arrays
    array set cdc_ffs ""
    array set cdc_paths ""

    # Create separate ffs collection for each cdc clock
    foreach_in_collection clk $cdc_clocks {
	set clk_fn [get_attribute $clk full_name]
	set clk_ffs [all_registers -clock $clk]
	set cdc_ffs(${clk_fn}) $clk_ffs
    }

    # Create array containing pairs of start- and endpoints for cdc paths
    # Paths starting from HM main cdc clock won't be analyzed
    foreach_in_collection clk [remove_from_collection $cdc_clocks [get_clocks $main_cdc_clock]] {

	set clk_fn [get_attribute $clk full_name]
	set other_cdc_clocks [remove_from_collection $cdc_clocks $clk]

	# Collection of ffs clocked with other cdc clocks
	foreach_in_collection clk2 $other_cdc_clocks {
	    set clk2_fn [get_attribute $clk2 full_name]
	    append_to_collection -unique other_cdc_ffs $cdc_ffs(${clk2_fn})
	}

	# Startpoints for tracing (clock gate can't be startpoint)
	set clk_CP_pins [get_pins -of_objects [filter_collection [all_registers -clock $clk] "full_name !~ */latch && ref_name !~ CLKSGLLX*"] -filter "lib_pin_name == CP"]

	# Find loads clocked with other cdc clock
	foreach_in_collection clk_CP_pin $clk_CP_pins {
	    set clk_CP_pin_fn [get_attribute $clk_CP_pin full_name]
	    set clk_CP_pin_all_loads [all_fanout -flat -endpoints_only -trace_arcs all -only_cells -from $clk_CP_pin]
	    set clk_CP_pin_cdc_loads [intersection_of_collections $other_cdc_ffs $clk_CP_pin_all_loads]
	    if { [sizeof_collection $clk_CP_pin_cdc_loads] } {
		set cdc_paths($clk_CP_pin_fn) [get_pins -of_objects $clk_CP_pin_cdc_loads -filter "full_name =~ */CP || full_name =~ */E"]
	    }
	}
	
    }

    return [array get cdc_paths]

}

define_proc_attributes pt_create_hm_cdc_paths_array \
    -info "Creates hardmacro cdc paths array, which contains cdc paths startpoint names as array keys. Array values are collections of corresponding endpoints." \
    -define_args {
        {-cdc_clocks "All cdc clocks." "" list required} \
            {-main_cdc_clock "Main cdc clock. Paths starting from hardmacro main cdc clock won't be analyzed." "" list required} \
        }


#######################################################################################################################
# pt_report_hm_cdc_paths
#######################################################################################################################
proc pt_report_hm_cdc_paths { args } {

    # Parse arguments
    parse_proc_arguments -args $args results
    
    # cdc_paths array
    if { [info exists results(-cdc_paths)] } {
	set cdc_paths_name $results(-cdc_paths)
	global $cdc_paths_name
    } else {
	echo "Nokia Error: cdc paths array argument must be defined."
    }
    
    # Reporting section
    foreach key [lsort [array names $cdc_paths_name]] {
	foreach_in_collection c $cdc_paths($key) {
	    set c_fn [get_attribute $c full_name]
	    echo "$key $c_fn"
	}
    }
    
}

define_proc_attributes pt_report_hm_cdc_paths \
    -info "Reports data from array created with pt_create_hm_cdc_paths_array procedure." \
    -define_args {
        {-cdc_paths "Cdc paths array name." "" string required}}


#######################################################################################################################
# Primetime procedure for library files pg_pin information post-processing.
# Usage example:
if 0 {
    exec mv ../work/pt/${DESIGN_NAME}_nofunc.lib ../work/pt/${DESIGN_NAME}_nofunc_to_be_processed.lib
    exec sleep 5
    set input_file ../work/pt/${DESIGN_NAME}_nofunc_to_be_processed.lib
    set output_file ../work/pt/${DESIGN_NAME}_nofunc.lib
    array set special_power ""
    array set special_ground ""
    foreach_in_collection ip [get_ports {*PW* *SD* *iso*}] {
	set special_power([get_object_name $ip]) vcc
    }
    pt_post_process_lib_file -input_file $input_file -output_file $output_file -special_power special_power -special_ground special_ground
}
#######################################################################################################################

proc pt_post_process_lib_file { args } {
    # Parse arguments
    parse_proc_arguments -args $args results
    
    # Input file
    set input_file ""
    if { [info exists results(-input_file)] } {
	set input_file $results(-input_file)
    }

    if { [string match $input_file ""] } {
	echo "Nokia Error: input file must be defined."
	echo "Exiting..."
	return 0
    }

    if { ! [file exists $input_file] } {
	echo "Nokia Error: input file $input_file doesn't exist."
	echo "Exiting..."
	return 0
    }

    # Output file
    set output_file ""
    if { [info exists results(-output_file)] } {
	set output_file $results(-output_file)
    }

    if { [string match $output_file ""] } {
	echo "Nokia Error: output file must be defined."
	echo "Exiting..."
	return 0
    }

    # Special power
    if { [info exists results(-special_power)] } {
	upvar $results(-special_power) special_power
    }

    # Special ground
    if { [info exists results(-special_ground)] } {
	upvar $results(-special_ground) special_ground
    }

    # Open files
    if [catch {set f_id [open $input_file r]} msg] {
	puts "Error in opening file, $msg"
	exit
    }

    if [catch {set temp [open $output_file w+]} msg] {
	puts $msg
    }

    # Process input file
    set pin_found 0
    set capa_found 0
    set power_pin_found 0
    set ground_pin_found 0
    
    while {[gets $f_id line] >=0 } {
	
	# Found pin
	if { [regexp {^pin\("(.*)"(.*)} $line tmp pin_name] } {
	    set pin_found 1
	}

	# Update related_power_pin info
	if { $pin_found && [regexp {^(\s*)related_power_pin(\s*):(\s*)"(\S*)"(\s*);(.*)$} $line tmp f1 f2 f3 power_pin f5 f6] } {
	    
	    if { [info exists special_power($pin_name)] } {
		set line "${f1}related_power_pin${f2}:${f3}\"$special_power($pin_name)\"${f5};${f6}"
	    }
	    set power_pin_found 1
	    
	}
	
	# Update related_ground_pin info
	if { $pin_found && [regexp {^(\s*)related_ground_pin(\s*):(\s*)"(\S*)"(\s*);(.*)$} $line tmp f1 f2 f3 ground_pin f5 f6] } {
	    
	    if { [info exists special_ground($pin_name)] } {
		set line "${f1}related_ground_pin${f2}:${f3}\"$special_ground($pin_name)\"${f5};${f6}"
	    }
	    set ground_pin_found 1
	    
	}
	
	# Append text to output file
	puts $temp $line
	
    }

    # Close files
    close $temp
    close $f_id


}


define_proc_attributes pt_post_process_lib_file \
    -info "Primetime procedure for library files pg_pin information and capacitance values post-processing." \
    -define_args {
	{-input_file "Input file." "" string required} \
	    {-output_file "Output file." "" string required} \
	    {-special_power "Name of the array containing special power information." "" string optional} \
	    {-special_ground "Name of the array containing special ground information." "" string optional} \
	}


#######################################################################################################################
# dc_add_output_buffers can be used for buffer addition to output ports.
# Usage example:
# dc_add_output_buffers -ports [get_ports * -filter "pin_direction == out"] -reference tsmc_cln28hp_scsi35d_slow2s_m40c_0p85v_wcleak_noccs/BUFX8BV0SI35D
#######################################################################################################################
proc dc_add_output_buffers { args } {

    # Parse arguments
    parse_proc_arguments -args $args results
    
    # Ports
    set ports ""
    if { [info exists results(-ports)] } {
        set ports $results(-ports)
    }

    # Reference
    set reference ""
    if { [info exists results(-reference)] } {
        set reference $results(-reference)
    }

    # Buffer addition
    foreach_in_collection port $ports {
	set port_dir [get_attribute $port pin_direction]
	set port_name [get_attribute $port name]
	if { [string match $port_dir "out"] } {
	    set cell_name $port_name
	    regsub -all {\[} $cell_name {_} cell_name
	    regsub -all {\]$} $cell_name {} cell_name
	    set cell_name BUF_${cell_name}
	    set net [all_connected $port]
	    set net_name [get_attribute $net name]
	    set driver [remove_from_collection [all_connected $net] $port]
	    if { [sizeof_collection $driver] } {
		disconnect_net $net $driver
		create_net ${net_name}_buf
		connect_net [get_nets ${net_name}_buf] $driver
		create_cell $cell_name $reference
		connect_net $net [get_pins ${cell_name}/o]
		connect_net ${net_name}_buf [get_pins ${cell_name}/a]
	    }
	} else {
	    echo "Nokia Error: port $port_name direction is $port_dir."
	}
    }

}

define_proc_attributes dc_add_output_buffers \
    -info "Add buffer to output ports." \
    -define_args {
        {-ports "Collection of ports." "" list required} \
	    {-reference "Buffer reference." "" string required} \
	}



#######################################################################################################################
# dc_add_input_buffers can be used for buffer addition to input ports.
# Usage example:
# dc_add_input_buffers -ports [get_ports * -filter "pin_direction == in"] -reference tsmc_cln28hp_scsi35d_slow2s_m40c_0p85v_wcleak_noccs/BUFX8BV0SI35D
#######################################################################################################################
proc dc_add_input_buffers { args } {

    # Parse arguments
    parse_proc_arguments -args $args results
    
    # Ports
    set ports ""
    if { [info exists results(-ports)] } {
        set ports $results(-ports)
    }

    # Reference
    set reference ""
    if { [info exists results(-reference)] } {
        set reference $results(-reference)
    }

    # Buffer addition
    foreach_in_collection port $ports {
	set port_dir [get_attribute $port pin_direction]
	set port_name [get_attribute $port name]
	if { [string match $port_dir "in"] } {
	    set cell_name $port_name
	    regsub -all {\[} $cell_name {_} cell_name
	    regsub -all {\]$} $cell_name {} cell_name
	    set cell_name BUF_${cell_name}
	    set net [all_connected $port]
	    set net_name [get_attribute $net name]
	    set loads [remove_from_collection [all_connected $net] $port]
	    if { [sizeof_collection $loads] } {
		disconnect_net $net $loads
		create_net ${net_name}_buf
		connect_net [get_nets ${net_name}_buf] $loads
		create_cell $cell_name $reference
		connect_net $net [get_pins ${cell_name}/A]
		connect_net ${net_name}_buf [get_pins ${cell_name}/Z]
	    }
	} else {
	    echo "Nokia Error: port $port_name direction is $port_dir."
	}
    }

}

define_proc_attributes dc_add_input_buffers \
    -info "Add buffer to input ports." \
    -define_args {
        {-ports "Collection of ports." "" list required} \
	    {-reference "Buffer reference." "" string required} \
	}


#######################################################################################################################
# upf_create_top_io_srsn_script procedure
#######################################################################################################################

#######################################################################################################################
#
# Power           Ball count  Description
# VSS             358         Ground
# VDD             52          Core Logic
# VDDIO18_GPIO    43          1V8 I/O Supply
# VDDIO12_DDR     23          DDR I/O Supply
# VDDA_JESD       8           JESD SerDes Supply
# VDDREF_JESD     8           JESD Reference
# VDDA_RP301      2           CPRI/OBSAI SerDes Supply
# VDDREF_RP301    2           CPRI/OBSAI SerDes Reference
# VDDA_SGMII      1           Ethernet SerDes Logic Supply
# VDDA18_SGMII    1           Ethernet SerDes I/O Supply
# VDDIO18_LVDS    1           LVDS Supply
# VDDIO18_LVDS_1  1           LVDS Supply
# VDDIO18_LVDS_2  1           LVDS Supply
# TOTAL           501
#
# VDDA18
#
#######################################################################################################################

proc upf_create_top_io_srsn_script { } {


    # check_ports collection is used to check that set_related_supply_net has been applied to all ports
    set check_ports [get_ports *]
    

    # Unused ports
    set check_ports [remove_from_collection $check_ports [get_ports "JESD1_FREFN_A_UNUSED JESD1_FREFP_A_UNUSED Vrefdq"]]


    # DDR ports
    set ports ""
    foreach_in_collection pin [get_pins -of_objects [get_cells -hierarchical -filter "ref_name == sdram_subsystem_nahka"]] {
	set net [all_connected $pin]
	if { [sizeof_collection $net] } {
	    append_to_collection -unique ports [filter_collection [all_connected -leaf $net] "object_class == port"]
	}
    }
    echo ""
    echo "########################################################################################################################"
    echo "# DDR"
    echo "########################################################################################################################"
    echo "set_related_supply_net -object_list \""
    pcollection [sort_collection $ports full_name]
    echo "\" -power VDDIO12_DDR -ground VSS"
    echo ""
    set check_ports [remove_from_collection $check_ports $ports]


    # Gigabit Transceiver IFs
    set ports [get_ports RP301*]
    echo ""
    echo "########################################################################################################################"
    echo "# Gigabit Transceiver IFs"
    echo "########################################################################################################################"
    echo "set_related_supply_net -object_list \""
    pcollection [sort_collection $ports full_name]
    echo "\" -power VDDA_RP301 -ground VSS"
    echo ""
    set check_ports [remove_from_collection $check_ports $ports]


    # Gigabit Ethernet IFs
    set ports [get_ports SGMII*]
    echo ""
    echo "########################################################################################################################"
    echo "# Gigabit Ethernet IFs"
    echo "########################################################################################################################"
    echo "set_related_supply_net -object_list \""
    pcollection [sort_collection $ports full_name]
    echo "\" -power VDDA18_SGMII -ground VSS"
    echo ""
    set check_ports [remove_from_collection $check_ports $ports]
    

    # ADC and DAC lanes
    set ports [get_ports "ADC_L* DAC_L*"]
    echo ""
    echo "########################################################################################################################"
    echo "# ADC and DAC lanes"
    echo "########################################################################################################################"
    echo "set_related_supply_net -object_list \""
    pcollection [sort_collection $ports full_name]
    echo "\" -power VDDA_JESD -ground VSS"
    echo ""
    set check_ports [remove_from_collection $check_ports $ports]


    # LVDS
    set ports ""
    foreach_in_collection pin [get_pins -of_objects [get_cells -hierarchical -filter "ref_name =~ LVDS* && is_hierarchical == false"]] {
	set net [all_connected $pin]
	if { [sizeof_collection $net] } {
	    append_to_collection -unique ports [filter_collection [all_connected -leaf $net] "object_class == port"]
	}
    }
    echo ""
    echo "########################################################################################################################"
    echo "# LVDS ports"
    echo "########################################################################################################################"
    echo "set_related_supply_net -object_list \""
    pcollection [sort_collection $ports full_name]
    echo "\" -power VDDIO18_LVDS -ground VSS"
    echo ""
    set check_ports [remove_from_collection $check_ports $ports]


    # 1.8V
    echo ""
    echo "########################################################################################################################"
    echo "# 1.8V ports"
    echo "########################################################################################################################"
    echo "set_related_supply_net -object_list \""
    pcollection [sort_collection $check_ports full_name]
    echo "\" -power VDDIO18_GPIO -ground VSS"
    echo ""
    # set check_ports [remove_from_collection $check_ports $ports]

    # return $check_ports

}


#######################################################################################################################
# Check top level port connections
#######################################################################################################################
proc check_top_port_connections { } {

    foreach_in_collection port [get_ports *] {

	set port_fn [get_attribute $port full_name]
	set net [all_connected $port]
	
	# Check port connection to net
	if { [sizeof_collection $net] } {
	    
	    set pin [remove_from_collection [all_connected -leaf $net] $port]
	    
	    # Check net connection to pin
	    if { [sizeof_collection $pin] } {
		set cell [get_cells -of_objects $pin]
		set cell_fn [get_attribute $cell full_name]
		set cell_rn [get_attribute $cell ref_name]
		
		# Check cell reference
		if { [regexp {INV} $cell_rn] || [regexp {BUF} $cell_rn] } {
		    echo "Nokia Error: Port $port_fn connected to Cell $cell_fn $cell_rn"
		}
		
	    } else {
		echo "Nokia Error: Port $port_fn has no connection."
	    }
	    
	} else {
	    echo "Nokia Error: Port $port_fn has no connection."
	}
	
    }
    
}


#######################################################################################################################
# Report wrapper always on signal issues
#######################################################################################################################
proc dc_report_wrapper_aon_signal_issues { args } {

    # Parse arguments
    parse_proc_arguments -args $args results
    
    # Report level
    set report_all_connections "false"
    if { [info exists results(-report_all_connections)] } {
        set report_all_connections "true"
    }

    # Wrapper always on pins
    set wrapper_AON_pins [sort_collection [get_pins -of_objects [get_cells -hierarchical -filter "ref_name =~ ip75* || ref_name =~ ip74* ||ref_name =~ *cpm*wrapper*"] -filter "full_name =~ */ipwreninb || full_name =~ */endeepsleep_mc00h || full_name =~ */ensleep_mc00h || full_name =~ */pwrenb_in || full_name =~ */fwen_nxxfweh || full_name =~  */cpm_lsi28id_ISO || full_name =~ */isleepenb"] full_name]

    foreach_in_collection p $wrapper_AON_pins {

	set d_Non_AO ""
	set d_Non_AO_fn ""
    
	set p_fn [get_attribute $p full_name]
	set d_Non_AO [filter_collection [all_connected -leaf [all_connected $p]] "pin_direction == out && object_class == pin"]
	set d_Non_AO_fn [get_attribute $d_Non_AO full_name]

	if { [sizeof_collection $d_Non_AO] } {
	    echo "Nokia Error : Always on pin driven by non always on driver:"
	    echo "AO load: $p_fn\nNon AO driver: $d_Non_AO_fn\n"
	} else {
	    set d_AO [filter_collection [all_connected -leaf [all_connected $p]] "pin_direction == in && object_class == port"]
	    set d_AO_fn [get_attribute $d_AO full_name]
	    if {![sizeof_collection $d_AO]} {
		echo "Nokia Error : Always on pin not connected: $p_fn"
	    } elseif { [string match $report_all_connections "true"] } {
		echo "Nokia Info : Always on pin driver by non always on driver:"
		echo "AO load: $p_fn\nAO driver: $d_AO_fn\n"
	    }
	}
	
    }
}

define_proc_attributes dc_report_wrapper_aon_signal_issues \
    -info "Report memory wrapper always on signals" \
    -define_args {
        {-report_all_connections "Report all connections." "" boolean optional}}


#######################################################################################################################
# Report flip flops without asynchronous reset or set
#######################################################################################################################
proc dc_report_flip_flops_without_async_reset_or_set { args } {

    parse_proc_arguments -args $args results

    # Return cells or pins without reporting
    set return_cells "false"
    if { [info exists results(-return_cells)] } {
        set return_cells "true"
    }

    set return_pins "false"
    if { [info exists results(-return_pins)] } {
        set return_pins "true"
    }

    if { [string match $return_cells "true"] && [string match $return_pins "true"] } {
	echo "Nokia Error: dc_report_flip_flops_without_async_reset_or_set can only return either cells or pins."
	return 0
    }

    # Find flip flops with reset/clear, clock gating cells and latches
    set CDN_regs [get_cells -quiet -of_objects [get_pins -of_objects [all_registers] -filter "full_name =~ */rb"]]
    set SDN_regs [get_cells -quiet -of_objects [get_pins -of_objects [all_registers] -filter "full_name =~ */psb"]]
    set AS_regs [get_cells -quiet -of_objects [get_pins -of_objects [all_registers] -filter "full_name =~ */s"]]
    # set CGs [get_cells -quiet -hierarchical -filter "is_integrated_clock_gating_cell == true"]
    set CGs [get_cells -hierarchical -filter "ref_name =~ ec0cilb* && is_hierarchical == false"]
    set latches [all_registers -level_sensitive]
    set macros [get_cells -hierarchical -filter "is_macro_cell == true || area > 100"]

    # Remove flip flops with reset/clear, clock gating cells and latches from all registers collection
    set non_initialized_regs [all_registers]
    set non_initialized_regs [remove_from_collection $non_initialized_regs $CDN_regs]
    set non_initialized_regs [remove_from_collection $non_initialized_regs $SDN_regs]
    set non_initialized_regs [remove_from_collection $non_initialized_regs $AS_regs]
    set non_initialized_regs [remove_from_collection $non_initialized_regs $CGs]
    set non_initialized_regs [remove_from_collection $non_initialized_regs $latches]
    set non_initialized_regs [remove_from_collection $non_initialized_regs $macros]
    set non_initialized_regs [sort_collection $non_initialized_regs full_name]

    # Return or print collection
    if { $return_cells } {
	return $non_initialized_regs
    } elseif { $return_pins } {
	return [get_pins -of_objects $non_initialized_regs -filter "pin_direction == out"]
    } else {
	pcollection $non_initialized_regs
    }

}

define_proc_attributes dc_report_flip_flops_without_async_reset_or_set \
    -info "Report flip flops or flip flop data output pins without asynchronous reset or set." \
    -define_args {
	{-return_cells "Return cells without reporting" "" boolean optional} \
	    {-return_pins "Return pins without reporting" "" boolean optional}}


#######################################################################################################################
# Procedure for IOs set_related_supply_net script generation
#######################################################################################################################
proc upf_create_hm_iso_policy_script { } {

    # Current design name
    set DESIGN_NAME [get_attribute [current_design] full_name]

    # AON cells excluding hardmacro cells.
    set AON_CELLS [sort_collection [get_cells -hierarchical -filter "full_name =~ *_AON && is_hierarchical == true"] full_name]

    # Pins for different isolation policies
    set ISO_IN_LOW_pins [get_pins -of_objects $AON_CELLS -filter "pin_direction == in && full_name !~ */DS && full_name !~ */LS && full_name !~ */DS_global && full_name !~ */MEM_ISO_IN && full_name !~ */cpm_lsi28id_ISO && full_name !~ */u_cpm_lsi28id_AON/resetn && full_name !~ */u_cpm_lsi28id_AON/refrstn"]
    set ISO_IN_HIGH_pins [get_pins -of_objects $AON_CELLS -filter "pin_direction == in && (full_name =~ */u_cpm_lsi28id_AON/resetn || full_name =~ */u_cpm_lsi28id_AON/refrstn)"]
    set ISO_IN_HIGH_LS_pins [get_pins -of_objects $AON_CELLS -filter "pin_direction == in && full_name =~ */LS"]
    set ISO_IN_HIGH_DS_pins [get_pins -of_objects $AON_CELLS -filter "pin_direction == in && full_name =~ */DS"]
    set NO_ISO_IN_pins [get_pins -of_objects $AON_CELLS -filter "pin_direction == in && (full_name =~ */DS_global || full_name =~ */MEM_ISO_IN || full_name =~ */cpm_lsi28id_ISO)"]
    

    # Split isolation low signals based on control signals
    foreach_in_collection p $ISO_IN_LOW_pins {
	set ISO_port [get_attribute [filter_collection [all_fanin -flat -startpoints_only -to [get_pins -of_objects [get_cells -of_objects [all_fanout -flat -levels 1 -from $p] -filter "is_hierarchical == false"] -filter "full_name =~ */ISO"]] "object_class == port"] full_name]
	if { $ISO_port != "" } {
	    append_to_collection -unique ISO_IN_LOW_pins_array($ISO_port) $p
	} else {
	    echo "Nokia Error: [get_attribute $p full_name] pin isolation control isn't connected to input port."
	}
    }

    # Split isolation high signals based on control signals
    foreach_in_collection p $ISO_IN_HIGH_pins {
	set ISO_port [get_attribute [filter_collection [all_fanin -flat -startpoints_only -to [get_pins -of_objects [get_cells -of_objects [all_fanout -flat -levels 1 -from $p] -filter "is_hierarchical == false"] -filter "full_name =~ */ISO"]] "object_class == port"] full_name]
	if { $ISO_port != "" } {
	    append_to_collection -unique ISO_IN_HIGH_pins_array($ISO_port) $p
	} else {
	    echo "Nokia Error: [get_attribute $p full_name] pin isolation control isn't connected to input port."
	}
    }

    # Split isolation high LS signals based on control signals
    foreach_in_collection p $ISO_IN_HIGH_LS_pins {
	set ISO_port [get_attribute [filter_collection [all_fanin -flat -startpoints_only -to [get_pins -of_objects [get_cells -of_objects [all_fanout -flat -levels 1 -from $p] -filter "is_hierarchical == false"] -filter "full_name =~ */ISO"]] "object_class == port"] full_name]
	if { $ISO_port != "" } {
	    append_to_collection -unique ISO_IN_HIGH_LS_pins_array($ISO_port) $p
	} else {
	    echo "Nokia Error: [get_attribute $p full_name] pin isolation control isn't connected to input port."
	}
    }

    # Split isolation high DS signals based on control signals
    foreach_in_collection p $ISO_IN_HIGH_DS_pins {
	set ISO_port [get_attribute [filter_collection [all_fanin -flat -startpoints_only -to [get_pins -of_objects [get_cells -of_objects [all_fanout -flat -levels 1 -from $p] -filter "is_hierarchical == false"] -filter "full_name =~ */ISO"]] "object_class == port"] full_name]
	if { $ISO_port != "" } {
	    append_to_collection -unique ISO_IN_HIGH_DS_pins_array($ISO_port) $p
	} else {
	    echo "Nokia Error: [get_attribute $p full_name] pin isolation control isn't connected to input port."
	}
    }

    # Create UPF script
    set INDEX 0
    foreach key [lsort [array names ISO_IN_LOW_pins_array]] {
	echo ""
	echo "########################################################################################################################"
	echo "# ${DESIGN_NAME}_AON_Domain_ISO_IN_LOW_${INDEX}"
	echo "########################################################################################################################"
	echo "set_isolation ${DESIGN_NAME}_AON_Domain_ISO_IN_LOW_${INDEX} -domain ${DESIGN_NAME}_AON_Domain -isolation_power_net VDD -isolation_ground_net VSS -clamp_value 0 -elements \""
	pcollection $ISO_IN_LOW_pins_array($key)
	echo "\""
	echo "set_isolation_control ${DESIGN_NAME}_AON_Domain_ISO_IN_LOW_${INDEX} -domain ${DESIGN_NAME}_AON_Domain -isolation_signal ${key} -isolation_sense high -location self"
	incr INDEX
    }

    set INDEX 0
    foreach key [lsort [array names ISO_IN_HIGH_pins_array]] {
	echo ""
	echo "########################################################################################################################"
	echo "# ${DESIGN_NAME}_AON_Domain_ISO_IN_HIGH_${INDEX}"
	echo "########################################################################################################################"
	echo "set_isolation ${DESIGN_NAME}_AON_Domain_ISO_IN_HIGH_${INDEX} -domain ${DESIGN_NAME}_AON_Domain -isolation_power_net VDD -isolation_ground_net VSS -clamp_value 1 -elements \""
	pcollection $ISO_IN_HIGH_pins_array($key)
	echo "\""
	echo "set_isolation_control ${DESIGN_NAME}_AON_Domain_ISO_IN_HIGH_${INDEX} -domain ${DESIGN_NAME}_AON_Domain -isolation_signal ${key} -isolation_sense high -location self"
	incr INDEX
    }

    set INDEX 0
    foreach key [lsort [array names ISO_IN_HIGH_LS_pins_array]] {
	echo ""
	echo "########################################################################################################################"
	echo "# ${DESIGN_NAME}_AON_Domain_ISO_IN_HIGH_LS_${INDEX}"
	echo "########################################################################################################################"
	echo "set_isolation ${DESIGN_NAME}_AON_Domain_ISO_IN_HIGH_LS_${INDEX} -domain ${DESIGN_NAME}_AON_Domain -isolation_power_net VDD -isolation_ground_net VSS -clamp_value 1 -elements \""
	pcollection $ISO_IN_HIGH_LS_pins_array($key)
	echo "\""
	echo "set_isolation_control ${DESIGN_NAME}_AON_Domain_ISO_IN_HIGH_LS_${INDEX} -domain ${DESIGN_NAME}_AON_Domain -isolation_signal ${key} -isolation_sense high -location self"
	incr INDEX
    }
    
    set INDEX 0
    foreach key [lsort [array names ISO_IN_HIGH_DS_pins_array]] {
	echo ""
	echo "########################################################################################################################"
	echo "# ${DESIGN_NAME}_AON_Domain_ISO_IN_HIGH_DS_${INDEX}"
	echo "########################################################################################################################"
	echo "set_isolation ${DESIGN_NAME}_AON_Domain_ISO_IN_HIGH_DS_${INDEX} -domain ${DESIGN_NAME}_AON_Domain -isolation_power_net VDD -isolation_ground_net VSS -clamp_value 1 -elements \""
	pcollection $ISO_IN_HIGH_DS_pins_array($key)
	echo "\""
	echo "set_isolation_control ${DESIGN_NAME}_AON_Domain_ISO_IN_HIGH_DS_${INDEX} -domain ${DESIGN_NAME}_AON_Domain -isolation_signal ${key} -isolation_sense high -location self"
	incr INDEX
    }
    
    echo ""
    echo "########################################################################################################################"
    echo "# ${DESIGN_NAME}_AON_Domain_NO_ISO_IN"
    echo "########################################################################################################################"
    echo "set_isolation ${DESIGN_NAME}_AON_Domain_NO_ISO_IN -domain ${DESIGN_NAME}_AON_Domain -no_isolation -elements \""
    pcollection $NO_ISO_IN_pins
    echo "\""

}


#######################################################################################################################
# Procedure for IOs set_related_supply_net script generation
#######################################################################################################################
proc upf_create_hm_io_srsn_script { } {
  
    set DESIGN_NAME [get_attribute [current_design] full_name]

    echo ""
    echo "########################################################################################################################"
    echo "# All inputs are always on (VDD/VSS)"
    echo "########################################################################################################################"
    echo "set_related_supply_net -object_list \""
    pcollection [sort_collection [all_inputs] full_name]
    echo "\" -power VDD -ground VSS"

    echo ""
    echo "########################################################################################################################"
    echo "# Switchable logic (VDD_SW_${DESIGN_NAME}/VSS) can drive all outputs except SleepOut must be driven by always on logic (VDD/VSS)"
    echo "########################################################################################################################"
    echo "set_related_supply_net -object_list \""
    pcollection [sort_collection [remove_from_collection [all_outputs] [get_ports SleepOut]] full_name]
    echo "\" -power VDD_SW_${DESIGN_NAME} -ground VSS"

    echo ""
    echo "set_related_supply_net -object_list \"SleepOut\" -power VDD -ground VSS"

    echo ""

}


#######################################################################################################################
# Procedure for always on domain sript generation
#######################################################################################################################
proc upf_create_hm_aon_domain_script { } {

    set DESIGN_NAME [get_attribute [current_design] full_name]

    set AON_CELLS [sort_collection [get_cells -hierarchical -filter "(full_name =~ *_AON && is_hierarchical == true) || (ref_name =~ ip75* && is_hierarchical == false) || (ref_name =~ ip74* && is_hierarchical == false) || (ref_name == cpm_lsi28id)"] full_name]

    echo "create_power_domain ${DESIGN_NAME}_AON_Domain -elements \""
    pcollection $AON_CELLS
    echo "\""

}


#######################################################################################################################
# Procedure for hardmacro supply net connection script creation
#######################################################################################################################
proc upf_create_hm_supply_net_connection_script { args } {

    # Parse arguments
    parse_proc_arguments -args $args results

    set upf_type synthesis
    
    if { [info exists results(-upf_type)] } {
	set upf_type $results(-upf_type)
    }

    set cells [sort_collection [get_cells -hierarchical -filter "area > 20 && is_hierarchical == false"] full_name]

    foreach_in_collection c $cells {

	# Save report_power_pin_info data to variable
	redirect -variable data {report_power_pin_info $c}

	# Loop data variable lines
	foreach line [split $data "\n"] {

	    # Create list from each line
	    set line_list [regexp -inline -all -- {\S+} $line]
	    
	    # Fields of the line
	    set line_f0 [lindex $line_list 0]
	    set line_f1 [lindex $line_list 1]
	    set line_f2 [lindex $line_list 2]
	    
	    # Find lines with memory PG-pin info
	    if { [string match $line_f2 "internal_power"] || [string match $line_f2 "primary_ground"] || [string match $line_f2 "primary_power"] || [string match $line_f2 "Primary"] || [string match $line_f2 "Internal"] } {
		# Create supply connection scripting using following connections (pin -> net):
		# VDD -> VDD
		# VDDA -> VDD
		# VDDA18 -> VDDA18
		# VDD_AUX -> VDD
		# VDDIO18 -> VDDIO18_GPIO
		# VDDIO18L -> VDDIO18_LVDS
		# VDD085 -> VDD
		# VDDF -> VDD
		# VDDPI -> VDD (No connection for simulation UPF)
		# VDDR -> VDD
		# VSS -> VSS
		# VSSA -> VSS
		if { [string match $line_f1 "VDD"] } {
		    echo "connect_supply_net VDD\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VDD_AUX"] } {
		    echo "connect_supply_net VDD\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VDDA"] } {
		    echo "connect_supply_net VDD\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VDDA18"] } {
		    echo "connect_supply_net VDDA18\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VDDIO18"] } {
		    echo "connect_supply_net VDDIO18_GPIO\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VDDIO18L"] } {
		    echo "connect_supply_net VDDIO18_LVDS\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VDD085"] } {
		    echo "connect_supply_net VDD\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VDDF"] } {
		    echo "connect_supply_net VDD\t-ports ${line_f0}/${line_f1}"
		} elseif { ( [string match $line_f1 "VDDPI"] ) && ( [string match $upf_type "simulation"] ) } {
		    echo "# connect_supply_net VDD\t-ports ${line_f0}/${line_f1}"
		} elseif { ( [string match $line_f1 "VDDPI"] ) && (! [string match $upf_type "simulation"] ) } {
		    echo "connect_supply_net VDD\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VDDR"] } {
		    echo "connect_supply_net VDD\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VSS"] } {
		    echo "connect_supply_net VSS\t\t-ports ${line_f0}/${line_f1}"
		} elseif { [string match $line_f1 "VSSA"] } {
		    echo "connect_supply_net VSS\t\t-ports ${line_f0}/${line_f1}"
		}
	    }
	    
	}

	echo ""
	
    }
    
}

define_proc_attributes upf_create_hm_supply_net_connection_script \
    -info "Procedure for hardmacro supply net connection UPF creation." \
    -define_args {
	{-upf_type "UPF type: simulation or synthesis." "" string optional}}


#######################################################################################################################
# Procedure for timing arcs reporting
#######################################################################################################################

                 
proc tail {pathname} {

    return [lindex [split $pathname / ] end ];
}

proc show_arcs {args} {
    set arcs [eval [concat get_timing_arcs $args]]
    echo [format "%15s %-15s %15s %15s  %10s %10s  %-10s %-15s %-5s %-5s %-5s %-5s %-5s " "from_pin" "to_pin" \
	      "max_rise" "max_fall"  "min_rise" "min_fall" "is_cellarc" "sense" "sdf_cond" "when" "is_disabled" "is_user_disabled" "mode"]
#    echo [format "%15s    %-15s  %10s %10s  %-10s %-15s %-5s %-5s %-5s %-5s %-5s" "--------" "------" \
	#	      "--------" "--------" "----------" "---------------" "--------" "----" "----" "----" "----" ];
    echo "------------------------------------------------------------------------------------------------------------------------"

    foreach_in_collection arc $arcs {
	set is_cellarc [get_attribute -q $arc is_cellarc]
	set fpin [get_attribute -q $arc from_pin]
	set tpin [get_attribute -q $arc to_pin]
	set rise [get_attribute -q $arc delay_max_rise]
	set fall [get_attribute -q $arc delay_max_fall]
        set risemin [get_attribute -q $arc delay_min_rise]
	set fallmin [get_attribute -q $arc delay_min_fall]
	set sense [get_attribute -q $arc sense]
	set sdf_cond [get_attribute -q $arc sdf_cond]
	set when [get_attribute -q $arc when]
	set is_disabled [get_attribute -q $arc is_disabled]
	set is_user_disabled [get_attribute -q $arc is_user_disabled]
	set mode [get_attribute -q $arc mode]

	set from_pin_name [get_attribute $fpin full_name]

	set to_pin_name [get_attribute $tpin full_name]
	echo [format "%15s -> %-15s  %10s %10s %10s %10s %-10s %-15s %-5s %-5s %-5s %-5s %-5s " \
		  [tail $from_pin_name] [tail $to_pin_name] \
		  $rise   $fall \
                  $risemin   $fallmin \
		  $is_cellarc $sense $sdf_cond $when $is_disabled $is_user_disabled $mode]
    }
}
define_proc_attributes show_arcs \
  -info "shows timing arcs and delay values (general_procs.tcl) " \
  -define_args \
    {
	{args "same args as would be given to get_timing_arcs" args string required}
    }

#######################################################################################################################
# Procedure for dont_touch script generation
#######################################################################################################################
proc dc_write_dont_touch { args } {

    suppress_message UID-95

    parse_proc_arguments -args $args results

    # Type of dont_touches to be reported
    set type "all"
    if { [info exists results(-type)] } {
        set type $results(-type)
    }

    if { ! ( [string match $type "user"] || [string match $type "all"] ) } {
	echo "Nokia Warning: Allowed types are user and all."
        echo "Exiting..."
        return 0
    }

    if { [string match $type "user"] } {

	# Cells
	foreach_in_collection c [sort_collection [get_dont_touch_cells -hierarchical -type $type ] full_name] {
	    echo "set_dont_touch \[get_cells [get_attribute $c full_name]\]"
	}
	
	# Nets
	foreach_in_collection c [sort_collection [get_dont_touch_nets -hierarchical -type $type] full_name] {
	    echo "set_dont_touch \[get_nets [get_attribute $c full_name]\]"
	}

    } elseif { [string match $type "all"] } {

	# Cells
	foreach_in_collection c [sort_collection [get_dont_touch_cells -hierarchical] full_name] {
	    echo "set_dont_touch \[get_cells [get_attribute $c full_name]\]"
	}
	
	# Nets
	foreach_in_collection c [sort_collection [get_dont_touch_nets -hierarchical] full_name] {
	    echo "set_dont_touch \[get_nets [get_attribute $c full_name]\]"
	}

    }

    unsuppress_message UID-95

}

define_proc_attributes dc_write_dont_touch \
    -info "Write tcl-script for dont_touch cells and nets." \
    -define_args {
	{-type "Supported types are all (default) and user" "" string optional}}


#######################################################################################################################
# Procedure for enabled clock gates reporting 
#######################################################################################################################
proc dc_report_enabled_clock_gates { args } {

    parse_proc_arguments -args $args results

    # Return cells without reporting
    set return_cells "false"
    if { [info exists results(-return_cells)] } {
        set return_cells "true"
    }

    set fnd 0
    set cells ""

    foreach_in_collection c [get_cells -hierarchical -filter "ref_name =~ ec0cilb*"] {
	
	set c_fn [get_attribute $c full_name]
	set p_e [get_pins -of_objects $c -filter "full_name =~ */en"]
	set p_se [get_pins -of_objects $c -filter "full_name =~ */te"]
	set p_e_c ""
	set p_se_c ""
	set p_e_c [get_attribute -quiet $p_e constant_value]
	set p_se_c [get_attribute -quiet $p_se constant_value]
	
	if { ( $p_e_c == "1" ) || ( $p_se_c == "1" ) } {
	    if { $return_cells } {
		append_to_collection -unique cells $c
	    } else {
		if { $fnd == "0" } {
		    echo "Nokia Error: Found enabled clock gates:"
		}
		echo "$c_fn"
		set fnd 1
	    }
	}
	
    }

    if { $return_cells } {
	return $cells
    }

}

define_proc_attributes dc_report_enabled_clock_gates \
    -info "Report enabled clock gates (Enable or scan enable tied to one)." \
    -define_args {
	{-return_cells "Return cells without reporting" "" boolean optional}}


#######################################################################################################################
# Procedure for disabled clock gates reporting 
#######################################################################################################################
proc dc_report_disabled_clock_gates { args } {

    parse_proc_arguments -args $args results

    # Return cells without reporting
    set return_cells "false"
    if { [info exists results(-return_cells)] } {
        set return_cells "true"
    }

    set fnd 0
    set cells ""

    foreach_in_collection c [get_cells -hierarchical -filter "ref_name =~ ec0cilb*"] {
	
	set c_fn [get_attribute $c full_name]
	set p_e [get_pins -of_objects $c -filter "full_name =~ */en"]
	set p_se [get_pins -of_objects $c -filter "full_name =~ */te"]
	set p_e_c ""
	set p_se_c ""
	set p_e_c [get_attribute -quiet $p_e constant_value]
	set p_se_c [get_attribute -quiet $p_se constant_value]
	
	if { ( $p_e_c == "0" ) && ( $p_se_c == "0" ) } {
	    if { $return_cells } {
		append_to_collection -unique cells $c
	    } else {
		if { $fnd == "0" } {
		    echo "Nokia Error: Found disabled clock gates:"
		}
		echo "$c_fn"
		set fnd 1
	    }
	}
	
    }

    if { $return_cells } {
	return $cells
    }

}

define_proc_attributes dc_report_disabled_clock_gates \
    -info "Report disabled clock gates (Enable and scan enable tied to zero)." \
    -define_args {
	{-return_cells "Return cells without reporting" "" boolean optional}}


#######################################################################################################################
# Procedure for clock tree cells checking
#######################################################################################################################
proc pt_check_clock_tree_cells {args} {

    parse_proc_arguments -args $args results

    # Remove excluded references
    set cells [get_cells -hierarchical * -filter "is_hierarchical == false"]
    if { [ info exist results(-exclude_references) ] } {
        set exclude_references $results(-exclude_references)
	foreach ern $exclude_references {
	    set cells [remove_from_collection $cells [get_cells -quiet -hierarchical -filter "ref_name =~ $ern"]]
	}
    }

    # Remove excluded instances
    if { [ info exist results(-exclude_instances) ] } {
        set exclude_instances $results(-exclude_instances)
	foreach ecn $exclude_instances {
	    set cells [remove_from_collection $cells [get_cells -quiet -hierarchical -filter "full_name =~ $ecn"]]
	}
    }

    # Exclude macros
    if { [ info exist results(-exclude_macros) ] } {

	# Default limit for macro area
	set macro_area_limit 100

	# Override default macro area limit
	if { [ info exist results(-macro_area_limit) ] } {
	    set macro_area_limit $results(-macro_area_limit)
	}

	set cells [remove_from_collection $cells [get_cells -quiet -hierarchical -filter "area > $macro_area_limit && is_hierarchical == false"]]
    }
    
    # Check that only -return_pins or -return_cells option is used
    if { [info exists results(-return_pins)] && [info exists results(-return_cells)] } {
	echo "Nokia Warning: pt_check_clock_tree_cells -return_pins and -return_cells options are mutually exclusive."
	echo "Exiting..."
	return 0
    }

    # Return pins without reporting
    set return_pins "false"
    if { [info exists results(-return_pins)] } {
	set return_pins "true"
    }

    # Return cells without reporting
    set return_cells "false"
    if { [info exists results(-return_cells)] } {
	set return_cells "true"
    }

    # Find output pins with clocks attribute
    set clock_tree_pins [sort_collection [get_pins -of_objects $cells -filter "defined(clocks) && pin_direction == out"] full_name]

    # Loop all pins
    set fnd 0
    set ct_cells ""
    foreach_in_collection p $clock_tree_pins {

	# Pin/Cell full_name & Cell reference
	set pfn [get_attribute $p full_name]
	set c [get_cells -of_objects $p]
	set cfn [get_attribute $c full_name]
	set crn [get_attribute $c ref_name]
	
	# Report only non clock tree cells
	if { ! [regexp {^CLK} $crn] } {
	    append_to_collection ct_cells $c
	    if { ! ( $return_cells || $return_pins ) } {
		if { [string match $fnd "0"] } {
		    echo "Nokia Error: Forbidden cell(s) used in clock tree:\n"
		}
		echo "Cell : $cfn ($crn)"
		set cell_clock_pins [get_pins -of_objects [get_cells $cfn] -filter "defined(clocks) && pin_direction != internal"]
		foreach_in_collection ccp $cell_clock_pins {
		    echo "Pin  : [get_attribute $ccp full_name] ([collection_to_list2 [get_attribute $ccp clocks]])"
		}
		echo ""
		set fnd 1
	    }
	}
	
    }

    if { $return_cells } {
	return $ct_cells
    } elseif { $return_pins } {
	return [get_pins -of_objects $ct_cells -filter "defined(clocks)"]
    }

}

define_proc_attributes pt_check_clock_tree_cells \
    -info "Report non clock tree cells" \
    -define_args {
            {-exclude_references "Exclude listed references from check." "" list optional} \
		{-exclude_instances "Exclude listed instances from check." "" list optional} \
		{-exclude_macros "Exclude macros from check." "" boolean optional} \
		{-macro_area_limit "Macro area limit for check. Default value is 100." "" string optional} \
		{-return_cells "Return cells without reporting." "" boolean optional} \
		{-return_pins "Return pins without reporting." "" boolean optional}}




#######################################################################################################################
# Read netid file and returns value for insert_netid procedure
#######################################################################################################################

proc read_netid_file {fil} {
    set ce "";
    set ca "";
    set cb "";
    set cc "";

    set f [open ${fil}]
    while {[gets $f line] >= 0} {
        if { ![regexp {^# *} $line]} {
            if {[regexp {M} $line]} {
                set ce [lindex [split $line "="] end]  
            }
            if {[regexp {R} $line]} {
                set ca [lindex [split $line "="] end]  
            }
            if {[regexp {S} $line]} {
                set cb [lindex [split $line "="] end]  
            }
            if {[regexp {P} $line]} {
                set cc [lindex [split $line "="] end]  
            }
        }
    }
    close $f;

    if {$ce=="" || $ca=="" || $cb=="" || $cc=="" } {
        echo "Error: R=${ca} or S=${cb} or P=${cc} not specicied completely ${fil}"
 #       exit
    } else {
        return "${ce}_R${ca}S${cb}P${cc}T00L00D00"     
    }
        
}

#######################################################################################################################
# Read netid file and add $MODULES_PATH values for returns value for insert_netid procedure
#######################################################################################################################



proc read_netid_file2 {fil MODULES_PATH} {
    set ce "";
    set ca "";
    set cb "";
    set cc "";

foreach tu [split  $MODULES_PATH "/_"] {
  if {[ regexp  {\.} $tu]} {
	regsub  -all {\.}  $tu "" tut
	regsub  -all {v}  $tut "" ca
  }
}


    set f [open ${fil}]
    while {[gets $f line] >= 0} {
        if { ![regexp {^# *} $line]} {
            if {[regexp {M} $line]} {
                set ce [lindex [split $line "="] end]  
            }
            if {[regexp {S} $line]} {
                set cb [lindex [split $line "="] end]  
            }
            if {[regexp {P} $line]} {
                set cc [lindex [split $line "="] end]  
            }
        }
    }
    close $f;

    if {$ce=="" || $ca=="" || $cb=="" || $cc=="" } {
        echo "Error: R=${ca} or S=${cb} or P=${cc} not specicied completely ${fil}"
 #       exit
    } else {
        return "${ce}_R${ca}S${cb}P${cc}T00L00D00"     
    }
        
}




#######################################################################################################################
# Check if command is found in file - return error if not
#######################################################################################################################
proc check_if_cmd_used {cmd fil} {
    set c "";
    set f [open ${fil}]
    while {[gets $f line] >= 0} {
	if { ![regexp {^# *} $line] && [regexp {set_dont_use} $line]} {
	    lappend c $line  
	} 
    }
    close $f;
    if {$c==""} {
        echo "Nokia Error: ${cmd} command not found in scipt ${fil}"
    }
}


#######################################################################################################################
# Release Design Compiler licenses
#######################################################################################################################
proc dc_release_licenses {} {

    # Save list_license data to variable
    redirect -variable list_licenses_data list_licenses
    
    # This variable is used to mark start and end of the license names
    set license_line 0

    # Loop list_license variable lines
    foreach line [split $list_licenses_data "\n"] {

        # Create list from each line
        set line_list [regexp -inline -all -- {\S+} $line]
        
        # First field of the line
        set line_f1 [lindex $line_list 0]

        # Release license
        if { ( ! [regexp "^1$" $line full_line] ) && ( $license_line == "1" ) && ( ! [regexp "Design-Compiler" $line full_line] ) && ( ! [regexp "DesignWare" $line full_line] ) } {
            puts "Nokia Info: Releasing \'$line_f1\' license."
            remove_license $line_f1
        }

        # Mark start and end of the license names in list_license variable
        if { [regexp "Licenses in use:" $line full_line] } {
            set license_line 1
        }
        if { [regexp "^1$" $line full_line] } {
            set license_line 0
        }
    }

}


#######################################################################################################################
# Procedure for multiple driver nets reporting
#######################################################################################################################
proc dc_report_multiple_driver_nets {} {
    foreach_in_collection n [get_nets -hierarchical *] {
	set d_pins [filter_collection [all_connected -leaf [get_nets $n]] "(object_class == pin && pin_direction == out) || (object_class == port && pin_direction == in) || (pin_direction == inout)"]
	if { [sizeof_collection $d_pins] > 1 } {
	    echo ""
	    echo "Nokia Error: Found multiple driver net: [get_attribute $n full_name]"
	    # echo "Leaf driver pins:"
	    # pcollection $d_pins
	    echo "Tracing net driver:"
	    dc_trace_driver $n
	    echo ""
	}
    }
}

proc dc_report_multiple_driver_nets_old {} {
    set wired_and [get_nets -hierarchical -filter "wired_and == true"]
    return $wired_and
}


#######################################################################################################################
# Report latches
#######################################################################################################################
proc dc_report_latches {} {
    pcollection -attributes {full_name ref_name } [all_registers -level_sensitive]
}


#######################################################################################################################
# Procedure which allows technology pin names usage with GTECH design.
#######################################################################################################################
proc get_gtech_pins { ips } {

    set ops ""

    foreach ip $ips {

	set ip_orig $ip

	# Try to find pin with original name
	set op [get_pins -quiet $ip]
	if { [sizeof_collection $op] > 0 } {
	    append_to_collection -unique ops $op
	}

	# Use GTECH names, if no pins was found with original name
	if { [sizeof_collection $op] == 0 } {
	    regsub {/rb$} $ip {/clear} ip
	    regsub {/psb$} $ip {/preset} ip
	    regsub {/clk$} $ip {/clocked_on} ip
	    regsub {/d$} $ip {/next_state} ip
	    regsub {/o$} $ip {/Q} ip
	    set op [get_pins -quiet $ip]
	    if { [sizeof_collection $op] > 0 } {
		append_to_collection -unique ops $op
	    }
	}
	
	# Echo warning in case pin doesn't exist
	if { [sizeof_collection $op] == 0 } {
	    set dsg_name [get_attribute [current_design] full_name]
	    echo "Nokia Warning: Can't find object '$ip_orig' or '$ip' in design '$dsg_name'."
	}

    }

    # Return pins
    return $ops

}


#######################################################################################################################
# Procedure for design(s) removal in case matching library cells exists
#######################################################################################################################
proc dc_report_lib_cell_designs { } {
    
    suppress_message "UID-341"

    set lib_cell_designs ""

    foreach_in_collection lc [get_lib_cells */*] {

        set lc_name [get_attribute $lc name]

        if { [get_designs $lc_name -quiet] != "" } {
            echo "Nokia Error: Found design and lib_cell with same names : $lc_name"
	    lappend lib_cell_designs $lc
        }
    }

    unsuppress_message "UID-341"

    return $lib_cell_designs

}


#######################################################################################################################
# Procedure for unresolved cells removal
#######################################################################################################################
proc dc_remove_unresolved_cells {} {

    # Save link data to variable
    redirect -variable link_rpt {link}

    # Find missing references
    set refs ""
    foreach line [split $link_rpt "\n"] {
        if { [regexp {Warning: Unable to resolve reference '(.*)' in (.*)} $line fline ref] } {
            lappend refs $ref
        }
    }
    
    # Remove duplicated references
    set refs [lsort -unique $refs]
    
    # Remove unlinked cells
    foreach ref $refs {
        remove_cell [get_cells -hierarchical -filter "ref_name == $ref"]
    }
    
}


#######################################################################################################################
# Procedure for macro cell reporting
#######################################################################################################################
proc dc_report_macro_cells { } {
    pcollection -attributes {full_name ref_name} [get_cells -hierarchical -filter "is_macro_cell == true || area > 100"]
}


#######################################################################################################################
# Procedure for empty module reporting
#######################################################################################################################
proc dc_report_empty_designs { } {
    # Attribute "is_logical_black_box" isn't available anymore...
    # set empty_designs "[get_cells -hierarchical -filter "is_logical_black_box == true"]"
    set empty_designs [get_cells -hierarchical -filter "is_hierarchical == false && hdl_reference == true && undefined(is_macro_cell) && undefined(area) && is_synlib_module == false"]
    if { [sizeof_collection $empty_designs] > 0 } {
	echo "Nokia Error: Empty design instance name(s) & reference name(s):"
	pcollection -attributes { full_name ref_name } $empty_designs
    } else {
	# echo "Nokia Info: No empty designs found from design [current_design_name]."
    }
}


#######################################################################################################################
# Procedure for open inputs reporting
#######################################################################################################################
proc dc_report_open_inputs { } {

    foreach_in_collection p [get_pins -of_objects [get_cells -hierarchical -filter "is_hierarchical == false"] -filter "pin_direction == in"] {
        
        set drvs [filter_collection [all_connected -leaf [all_connected $p]] "pin_direction == out || pin_direction == inout || (object_class == port && pin_direction == in)"]

        if { [sizeof_collection $drvs] == "0" } {
            echo "Warning : There's no driver for pin :"
            echo [get_attribute $p full_name]
            dc_trace_driver $p
            echo "\n"
        }
        
    }
    
}


#######################################################################################################################
# Procedure for driver tracing
#######################################################################################################################
proc dc_trace_driver { input } {

    set driver $input
    set driver_prev ""

    while { [sizeof_collection $driver] == "1" } {

        set driver_fn [get_attribute -quiet $driver full_name]
        set object_class [get_attribute -quiet $driver object_class]

        if { [string match $object_class "net"] } {
            set driver [dc_find_net_driver $driver]
        } elseif { [string match $object_class "pin"] } {
            set driver [dc_find_pin_driver $driver]
        }

        if { [compare_collections $driver $driver_prev] == "0" } {
            # Found driver cell, which isn't hierarchical, buffer or inverter.
            break
        } elseif { [sizeof_collection $driver] > "1" } {
            # There's no support for multiple drivers
            echo "Nokia Error : Multiple drivers found, tracing stopped..."
            pcollection -attribute {full_name object_class} $driver
            break
        } elseif { [string match $object_class "pin"] && [string match [get_attribute -quiet $driver pin_direction] "inout"] } {
            # There's no support for inout pins
            echo "Nokia Error : Inout driver pin found, tracing stopped..."
            pcollection -attribute {full_name object_class} $driver
            break
        }

        pcollection -attribute {full_name object_class} $driver

        set driver_prev $driver
    }
    
}


#######################################################################################################################
# Procedure for hierarchies counting for cell, net or pin
#######################################################################################################################
proc dc_count_hier { input } {
    
    set input_fn [get_attribute -quiet $input full_name]
    set object_class [get_attribute -quiet $input object_class]

    if { [string match $object_class "net"] || [string match $object_class "pin"] } {
        regsub {(.*)/(.*)} $input_fn {\1} input_fn
        set i [get_cells -quiet $input_fn]      
    } elseif { [string match $object_class "cell"] } {
        set i [get_cells -quiet $input_fn]
    }
    
    set i_fn [get_attribute -quiet $i full_name]

    set i_fn_tmp $i_fn
    set coll_i_tmp ""
    while { [string length $i_fn_tmp] > 0 } {
        
        set i_tmp [get_cells -quiet $i_fn_tmp]
        if { [sizeof_collection $i_tmp] > 0 } {
            append_to_collection -unique coll_i_tmp $i_tmp
        }
        
        regsub {(.*)(\S)} $i_fn_tmp {\1} i_fn_tmp
    }

    return [sizeof_collection $coll_i_tmp]
}


#######################################################################################################################
# Find intersection of collections
#######################################################################################################################
proc intersection_of_collections { cola colb } {

   set result {}

   foreach_in_collection obja $cola {
      foreach_in_collection objb $colb {

	 if { [compare_collections $obja $objb] == 0} {

	    set result [add_to_collection $result $obja]

	 }
      }
   }
   return $result
}


#######################################################################################################################
# Procedure for pin driver finding
#######################################################################################################################
proc dc_find_pin_driver { p_input } {

    set p [get_pins $p_input]
    set c [get_cells -of_objects $p]
    set c_fn [get_attribute $c full_name]
    set c_rn [get_attribute $c ref_name]
    set c_ih [get_attribute $c is_hierarchical]
    set p_pd [get_attribute $p pin_direction]

    set drivers ""
    if { [string match $p_pd "in"] } {
        set drivers [all_connected $p]
    } elseif { [string match $c_ih "true"] && [string match $p_pd "out"] } {
        foreach_in_collection n [get_nets ${c_fn}/*] {
            if { [sizeof_collection [intersection_of_collections [all_connected $n] $p ]] } {
                set drivers $n
            }
        }
    } elseif { [string match $c_ih "false"] && [string match $p_pd "out"] && ( [regexp {ec0inv} $c_rn] || [regexp {ec0bf} $c_rn] || [regexp {DEL} $c_rn] ) } {
        set drivers [get_pins -of_objects $c -filter "pin_direction == in"]
    } else {
        set drivers $p
    }

    return $drivers
}



#######################################################################################################################
# Procedure for net driver finding
#######################################################################################################################
proc dc_find_net_driver { n_input } {
    
    set n [get_nets $n_input]
    set n_fn [get_attribute $n full_name]
    
    set n_hier_cnt [dc_count_hier $n]
    set drivers ""
    
    foreach_in_collection p [filter_collection [all_connected $n] "object_class != port && pin_direction == out"] {
        set p_hier_cnt [dc_count_hier $p]
        if { $p_hier_cnt > $n_hier_cnt } {
            append_to_collection -unique drivers $p
        }
    }
    
    foreach_in_collection p [filter_collection [all_connected $n] "object_class != port && pin_direction == in"] {
        set p_hier_cnt [dc_count_hier $p]
        if { $p_hier_cnt == $n_hier_cnt } {
            append_to_collection -unique drivers $p
        }
    }
    
    foreach_in_collection p [filter_collection [all_connected $n] "object_class != port && pin_direction == inout"] {
        append_to_collection -unique drivers $p
    }
    
    foreach_in_collection p [filter_collection [all_connected $n] "object_class == port"] {
        append_to_collection -unique drivers $p
    }
    
    return $drivers
}



#######################################################################################################################
# Print list members
#######################################################################################################################
proc plist { lst } {

    foreach i $lst {
	puts $i
    }

}


#######################################################################################################################
# Print collection members (or attributes)
#######################################################################################################################
proc pcollection {args} {

    parse_proc_arguments -args $args results

    set coll $results(coll)

    set attributes full_name
    if { [ info exist results(-attributes) ] } {
	set attributes $results(-attributes)
    }

    foreach_in_collection i $coll {
	foreach a $attributes {
	    lappend l_output [get_attribute $i $a]
	}
	puts "$l_output"
	set l_output ""
    }
}

define_proc_attributes pcollection \
    -info "print collection" \
    -define_args {
	{coll "input collection or object" coll string required} \
	    {-attributes "defines attributes" "" list optional}}



#######################################################################################################################
# Convert collection to list
#######################################################################################################################
if { ! [string match $synopsys_program_name "icc_shell"] } {
    proc collection_to_list { col } {
	
	foreach_in_collection i $col {	
	    set i_fn [get_attribute $i full_name]
	    lappend lst $i_fn
	}
	return $lst
	
    }
}


#######################################################################################################################
# Get connected pins
#######################################################################################################################
proc get_connected_pins {p} {
    set pins [remove_from_collection [all_connected -leaf [all_connected [get_pins $p]]] $p]
}


if 0 {
#######################################################################################################################
# Create empty modules
#######################################################################################################################
proc create_empty_modules { {refs} } {


    # Find missing designs, if not provided by user
    if {! [info exists refs]} {

	redirect -variable link_data {link}

	set refs [list]
	foreach line [split $link_data "\n"] {
	    if { [regexp {Warning: Unable to resolve reference '(.*)' in '(.*)'} $line full_line ref design] } {
		if {[lsearch $refs $ref] < 0} {
		    lappend refs $ref
		}
	    }
	}
    }

    foreach ref $refs {
	
	# Find input and output pins
	set ipins [list]
	set opins [list]

	foreach_in_collection p [get_pins -of_objects [index_collection [get_cells -hierarchical -filter "ref_name == $ref"] 0]] {
	    set p_n [get_attribute $p name]
	    if { ( [sizeof_collection [filter_collection [get_connected_pins $p] "pin_direction == out"]] == "0" ) && ( [sizeof_collection [filter_collection [get_connected_pins $p] "object_class == port && pin_direction == in"]] == "0" ) } {
		lappend opins $p_n
	    } else {
		lappend ipins $p_n
	    }
	}

	create_design $ref
	current_design $ref

	foreach ipin $ipins {
	    create_port -direction in $ipin
	}

	foreach opin $opins {
	    create_port -direction out $opin
	}

	# Find buses
	set buses [list]
	foreach_in_collection p [get_ports *] {
	    if { [regexp {(.*)\[(.*)\]$} [get_attribute $p name] p_n b_n] } {
		if {[lsearch $buses $b_n] < 0} {
		    lappend buses $b_n
		}
	    }
	}

	# Create buses
	foreach bus $buses {
	    create_bus [get_ports $bus[*]] $bus
	}

    }

}
}


#######################################################################################################################
# Forced linking
#######################################################################################################################
proc dc_forced_link {cells ref} {

    suppress_message "UID-341"
    suppress_message "TIM-103"

    # List of cells
    set cells_lst [collection_to_list $cells]

    # Gather connections
    foreach_in_collection c $cells {	
	foreach_in_collection p [get_pins -of_objects $c] {
	    set p_fn [get_attribute $p full_name]
	    set n_fn [get_attribute [all_connected $p] full_name]
	    set c_arr($p_fn) $n_fn
	}
    }

    # Report connections
    foreach key [array names c_arr] {
	puts "${key}=$c_arr($key)"
    }

    # Remove current cell and create new cell
    remove_cell $cells
    foreach c $cells_lst {
	create_cell $c $ref
    }

    # Recreate connections in case both pin and net exists
    foreach key [array names c_arr] {
	if { ( [sizeof_collection [get_pins $key]] == "1") && ( [sizeof_collection [get_nets $c_arr($key)]] == "1" )  } {
	    connect_net [get_nets $c_arr($key)] [get_pins $key]
	}
    }

    unsuppress_message "UID-341"
    unsuppress_message "TIM-103"

}


#######################################################################################################################
# Create empty designs for unlinked cells 
#######################################################################################################################

proc dc_create_empty_designs { {refs ""} } {
    
    set current_design_name [current_design]
    
    # Find missing designs, if not provided by user
    if { [string match $refs ""] } {

	redirect -variable link_rpt {link}

	set refs [list]
	foreach line [split $link_rpt "\n"] {
	    if { [regexp {Warning: Unable to resolve reference '(.*)' in '(.*)'} $line full_line ref design] } {
		if {[lsearch $refs $ref] < 0} {
		    lappend refs $ref
		}
	    }
	}
    }


    # Remove duplicated references
    set refs [lsort -unique $refs]
    
    # Remove unlinked cells
    foreach ref $refs {
        
        echo "Info : Processing reference $ref"

        set ref_cell_name [get_attribute [index_collection [get_cells -hierarchical -filter "ref_name == $ref"] 0] full_name]

        echo "Info : Processing cell $ref_cell_name"

        set in_pins ""
        foreach_in_collection p [get_pins ${ref_cell_name}/* -filter "pin_direction == in"] {
            lappend in_pins [get_attribute $p name]
        }

        set out_pins ""
        foreach_in_collection p [get_pins ${ref_cell_name}/* -filter "pin_direction == out"] {
            lappend out_pins [get_attribute $p name]
        }
        
        set inout_pins ""
        foreach_in_collection p [get_pins ${ref_cell_name}/* -filter "pin_direction == inout"] {
            lappend inout_pins [get_attribute $p name]
        }

	if { ([llength $in_pins] == 0) && ([llength $out_pins] == 0) && ([llength $inout_pins] > 0) } {

	    create_design $ref
	    current_design $ref
	    
	    if { [info exists in_pins] } {

		foreach p $in_pins {
		    create_port -direction in $p
		}

		foreach_in_collection p [get_ports * -filter "port_direction == in"] {
		    set p_fn [get_attribute $p full_name]
		    if { [regexp {(.*)(\[\d+\])} $p_fn b_fn b_n b_i] } {
			lappend b_ns $b_n
		    } else {
			lappend b_ns $p_fn
		    }
		}
	    }

	    if { [info exists out_pins] } {

		foreach p $out_pins {
		    create_port -direction out $p
		}

		foreach_in_collection p [get_ports * -filter "port_direction == out"] {
		    set p_fn [get_attribute $p full_name]
		    if { [regexp {(.*)(\[\d+\])} $p_fn b_fn b_n b_i] } {
			lappend b_ns $b_n
		    } else {
			lappend b_ns $p_fn
		    }
		}
	    }
	    
	    if { [info exists inout_pins] } {

		foreach p $inout_pins {
		    create_port -direction inout $p
		}

		foreach_in_collection p [get_ports * -filter "port_direction == inout"] {
		    set p_fn [get_attribute $p full_name]
		    if { [regexp {(.*)(\[\d+\])} $p_fn b_fn b_n b_i] } {
			lappend b_ns $b_n
		    } else {
			lappend b_ns $p_fn
		    }
		}
	    }
	    
	    if { [info exists b_ns] } {

		set b_ns [lsort -unique $b_ns]
		
		foreach b_n $b_ns {
		    if { [sizeof_collection [get_ports -quiet ${b_n}\[*]] > 1 } {
			create_bus [get_ports ${b_n}\[*] $b_n
		    }
		}
	    }

	} else {
	    echo "Info: reference $ref contains only inout pins -> empty design not created (verilog empty designs don't have correct pin directions)."
	}

        current_design $current_design_name

    }
    
}



#######################################################################################################################
# Get clock latency
#######################################################################################################################

proc get_clock_latency { args } {

    parse_proc_arguments -args $args args_array
    set clock_name $args_array(clock_name)

    if { [ info exist args_array(-delay_type) ] } {
        set delay_type $args_array(-delay_type)
    }

    if { [sizeof_collection [get_lib_pins -quiet -of_objects [get_lib_cells -quiet */* -filter "is_sequential == true"] -filter "base_name == clk"]] > 100 } {
	set FF_CLK_PIN_NAME clk
    } elseif { [sizeof_collection [get_lib_pins -quiet -of_objects [get_lib_cells -quiet */* -filter "is_sequential == true"] -filter "base_name == CP"]] > 100 } {
	set FF_CLK_PIN_NAME CP
    }

    if { [string match $delay_type "max"] } {
	set arr_time 0
	foreach_in_collection p [filter_collection [get_clock_network_objects -type pin $clock_name] "full_name =~ */${FF_CLK_PIN_NAME}"] {
	    set arr_time_new [get_attribute $p max_rise_arrival]
	    if { $arr_time_new > $arr_time } {
		set arr_time $arr_time_new
	    }
	}
    } elseif { [string match $delay_type "min"] } {
	set arr_time 1000000
	foreach_in_collection p [filter_collection [get_clock_network_objects -type pin $clock_name] "full_name =~ */${FF_CLK_PIN_NAME}"] {
	    set arr_time_new [get_attribute $p min_rise_arrival]
	    if { $arr_time_new < $arr_time } {
		set arr_time $arr_time_new
	    }
	}
    } elseif { [string match $delay_type "average"] } {
	set cnt 0
	set arr_time 0
	foreach_in_collection p [filter_collection [get_clock_network_objects -type pin $clock_name] "full_name =~ */${FF_CLK_PIN_NAME}"] {
	    set arr_time_new [get_attribute $p min_rise_arrival]
	    incr cnt
	    set arr_time [expr $arr_time_new + $arr_time]
	}
	set arr_time [expr $arr_time / $cnt]
    }
    
    return $arr_time
    
}

define_proc_attributes get_clock_latency \
    -info "Get clock latency value (min, max or average)." \
    -define_args {
        {clock_name "Clock name or collection" clock_name string required} \
            {-delay_type "defines attributes" "" list required}}



#######################################################################################################################
# Magnet placement procedure for dc_shell & icc_shell
#######################################################################################################################

proc do_magnet_placement { args } {
    
    global input_clock_ports_list
    global output_clock_ports_list
    global reset_ports_list

    parse_proc_arguments -args $args args_array
    
    set excluded_ports ""
    if { [ info exist args_array(-exclude) ] } {
	append_to_collection excluded_ports [get_ports $args_array(-exclude)]
    }
    
    set DONT_FIX false
    if { [ info exist args_array(-dont_fix) ] } {
	set DONT_FIX true
    }

    # excluding clocks and resets by default
    if {[info exists input_clock_ports_list] && $input_clock_ports_list != ""} {
	append_to_collection -unique excluded_ports [get_ports $input_clock_ports_list]
    }
    if {[info exists output_clock_ports_list] && $output_clock_ports_list != ""} {
	append_to_collection -unique excluded_ports [get_ports $output_clock_ports_list]
    }
    if {[info exists reset_ports_list] && $reset_ports_list != ""} {
	append_to_collection -unique excluded_ports [get_ports $reset_ports_list]
    }

    # move flipflops as well!
    set_app_var magnet_placement_stop_after_seq_cell true
    
    remove_buffer_tree -all
    
    if {$DONT_FIX} {
	magnet_placement -avoid_soft_blockages \
	    -stop_by_sequential_cells \
	    -logical_level 64 \
	    [remove_from_collection [get_ports *] $excluded_ports]
    } else {
	magnet_placement -avoid_soft_blockages \
	    -stop_by_sequential_cells \
	    -logical_level 64 \
	    -mark_fixed \
	    [remove_from_collection [get_ports *] $excluded_ports]
    }
    
}

define_proc_attributes do_magnet_placement \
    -info "Remove all buffers from design and do magnet placement to IOs" \
    -define_args {
	{-exclude "exclude ports from magnet placement" "" list optional}
	{-dont_fix "do not mark moved cells as fixed" "" boolean optional}
    }


#######################################################################################################################
# Filter library cells with predefined vt priority. Procedure returns library cells with highest priority.
#######################################################################################################################
proc filter_lib_cells_with_vt_priority { lc_in_list } {

    set lc_out_list ""

    foreach lc_in $lc_in_list {

	# ARM cln28hpm library
	if { [sizeof_collection [get_libs sc*mc_cln28hpm* -quiet]] > 0 } {
	    
	    # Create separate collection for each Vt and channel length option
	    set lc_in_TL_C31  [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TL_C31"]
	    set lc_in_TL_C35  [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TL_C35"]
	    set lc_in_TL_C38  [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TL_C38"]
	    set lc_in_TS_C31  [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TS_C31"]
	    set lc_in_TS_C35  [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TS_C35"]
	    set lc_in_TS_C38  [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TS_C38"]
	    set lc_in_TUL_C31 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TUL_C31"]
	    set lc_in_TUL_C35 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TUL_C35"]
	    set lc_in_TH_C35  [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TH_C35"]
	    set lc_in_TUH_C35 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TUH_C35"]

	    # Use only first library cell from each collection
	    if { [sizeof_collection $lc_in_TL_C31] > 1 } {
		set lc_in_TL_C31  [index_collection $lc_in_TL_C31 0]
	    } elseif { [sizeof_collection $lc_in_TL_C35] > 1 } {
		set lc_in_TL_C35  [index_collection $lc_in_TL_C35 0]
	    } elseif { [sizeof_collection $lc_in_TL_C38] > 1 } {
		set lc_in_TL_C38  [index_collection $lc_in_TL_C38 0]
	    } elseif { [sizeof_collection $lc_in_TS_C31] > 1 } {
		set lc_in_TS_C31  [index_collection $lc_in_TS_C31 0]
	    } elseif { [sizeof_collection $lc_in_TS_C35] > 1 } {
		set lc_in_TS_C35  [index_collection $lc_in_TS_C35 0]
	    } elseif { [sizeof_collection $lc_in_TS_C38] > 1 } {
		set lc_in_TS_C38  [index_collection $lc_in_TS_C38 0]
	    } elseif { [sizeof_collection $lc_in_TUL_C31] > 1 } {
		set lc_in_TUL_C31 [index_collection $lc_in_TUL_C31 0]
	    } elseif { [sizeof_collection $lc_in_TUL_C35] > 1 } {
		set lc_in_TUL_C35 [index_collection $lc_in_TUL_C35 0]
	    } elseif { [sizeof_collection $lc_in_TH_C35] > 1 } {
		set lc_in_TH_C35  [index_collection $lc_in_TH_C35 0]
	    } elseif { [sizeof_collection $lc_in_TUH_C35] > 1 } {
		set lc_in_TUH_C35 [index_collection $lc_in_TUH_C35 0]
	    }

	    # Use cell with highest priority
	    if { [sizeof_collection $lc_in_TL_C31] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TL_C31 name]
	    } elseif { [sizeof_collection $lc_in_TL_C35] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TL_C35 name]
	    } elseif { [sizeof_collection $lc_in_TL_C38] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TL_C35 name]
	    } elseif { [sizeof_collection $lc_in_TS_C31] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TS_C31 name]
	    } elseif { [sizeof_collection $lc_in_TS_C35] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TS_C35 name]
	    } elseif { [sizeof_collection $lc_in_TS_C38] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TS_C38 name]
	    } elseif { [sizeof_collection $lc_in_TUL_C31] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TUL_C31 name]
	    } elseif { [sizeof_collection $lc_in_TUL_C35] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TUL_C35 name]
	    } elseif { [sizeof_collection $lc_in_TH_C35] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TH_C35 name]
	    } elseif { [sizeof_collection $lc_in_TUH_C35] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TUH_C35 name]
	    }

	} elseif { [sizeof_collection [get_libs sc*mc_cln40g* -quiet]] > 0 } {

	    # Create separate collection for each Vt and channel length option
	    set lc_in_TL40 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TL40"]
	    set lc_in_TL50 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TL50"]
	    set lc_in_TR40 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TR40"]
	    set lc_in_TR50 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TR50"]
	    set lc_in_TH50 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *TH50"]

	    # Use only first library cell from each collection
	    if { [sizeof_collection $lc_in_TL40] > 1 } {
		set lc_in_TL40 [index_collection $lc_in_TL40 0]
	    } elseif { [sizeof_collection $lc_in_TL50] > 1 } {
		set lc_in_TL50 [index_collection $lc_in_TL50 0]
	    } elseif { [sizeof_collection $lc_in_TR40] > 1 } {
		set lc_in_TR40 [index_collection $lc_in_TR40 0]
	    } elseif { [sizeof_collection $lc_in_TR50] > 1 } {
		set lc_in_TR50 [index_collection $lc_in_TR50 0]
	    } elseif { [sizeof_collection $lc_in_TH50] > 1 } {
		set lc_in_TH50 [index_collection $lc_in_TH50 0]
	    }

	    # Use cell with highest priority
	    if { [sizeof_collection $lc_in_TL40] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TL40 name]
	    } elseif { [sizeof_collection $lc_in_TL50] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TL50 name]
	    } elseif { [sizeof_collection $lc_in_TR40] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TR40 name]
	    } elseif { [sizeof_collection $lc_in_TR50] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TR50 name]
	    } elseif { [sizeof_collection $lc_in_TH50] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_TH50 name]
	    }

	} elseif { [sizeof_collection [get_libs C28SOI* -quiet]] > 0 } {

	    # Create separate collection for each Vt and channel length option
	    set lc_in_P0 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *P0"]
	    set lc_in_P4 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *P4"]
	    set lc_in_P10 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *P10"]
	    set lc_in_P16 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *P16"]

	    # Use only first library cell from each collection
	    set lc_in_P0 [index_collection $lc_in_P0 0]
	    set lc_in_P4 [index_collection $lc_in_P4 0]
	    set lc_in_P10 [index_collection $lc_in_P10 0]
	    set lc_in_P16 [index_collection $lc_in_P16 0]

	    # Use cell same priority as fastest CORE library
	    if { ([sizeof_collection $lc_in_P0] == 1) && [sizeof_collection [get_libs -quiet *_CORE_*]] } {
		lappend lc_out_list [get_attribute $lc_in_P0 name]
	    } elseif { ([sizeof_collection $lc_in_P4] == 1) && [sizeof_collection [get_libs -quiet *_COREPBP4_*]] } {
		lappend lc_out_list [get_attribute $lc_in_P4 name]
	    } elseif { ([sizeof_collection $lc_in_P10] == 1) && [sizeof_collection [get_libs -quiet *_COREPBP10_*]] } {
		lappend lc_out_list [get_attribute $lc_in_P10 name]
	    } elseif { ([sizeof_collection $lc_in_P16] == 1) && [sizeof_collection [get_libs -quiet *_COREPBP16_*]] } {
		lappend lc_out_list [get_attribute $lc_in_P16 name]
	    }

	} elseif { [sizeof_collection [get_libs tsmc_cln28hp_sc* -quiet]] > 0 } {

	    # Create separate collection for each Vt and channel length option
	    set lc_in_UI31 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *UI31*"]
	    set lc_in_UI35 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *UI35*"]
	    set lc_in_UI38 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *UI38*"]
	    set lc_in_LI31 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *LI31*"]
	    set lc_in_LI35 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *LI35*"]
	    set lc_in_LI38 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *LI38*"]
	    set lc_in_SI31 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *SI31*"]
	    set lc_in_SI35 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *SI35*"]
	    set lc_in_SI38 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *SI38*"]
	    set lc_in_HI35 [filter_collection [get_lib_cells -quiet $lc_in] "name =~ *HI35*"]

	    # Use only first library cell from each collection
	    if { [sizeof_collection $lc_in_UI31] > 1 } {
		set lc_in_UI31 [index_collection $lc_in_UI31 0]
	    } elseif { [sizeof_collection $lc_in_UI35] > 1 } {
		set lc_in_UI35 [index_collection $lc_in_UI35 0]
	    } elseif { [sizeof_collection $lc_in_UI38] > 1 } {
		set lc_in_UI38 [index_collection $lc_in_UI38 0]
	    } elseif { [sizeof_collection $lc_in_LI31] > 1 } {
		set lc_in_LI31 [index_collection $lc_in_LI31 0]
	    } elseif { [sizeof_collection $lc_in_LI35] > 1 } {
		set lc_in_LI35 [index_collection $lc_in_LI35 0]
	    } elseif { [sizeof_collection $lc_in_LI38] > 1 } {
		set lc_in_LI38 [index_collection $lc_in_LI38 0]
	    } elseif { [sizeof_collection $lc_in_SI31] > 1 } {
		set lc_in_SI31 [index_collection $lc_in_SI31 0]
	    } elseif { [sizeof_collection $lc_in_SI35] > 1 } {
		set lc_in_SI35 [index_collection $lc_in_SI35 0]
	    } elseif { [sizeof_collection $lc_in_SI38] > 1 } {
		set lc_in_SI38 [index_collection $lc_in_SI38 0]
	    } elseif { [sizeof_collection $lc_in_HI35] > 1 } {
		set lc_in_HI35 [index_collection $lc_in_HI35 0]
	    }

	    # Use cell with highest priority
	    if { [sizeof_collection $lc_in_UI31] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_UI31 name]
	    } elseif { [sizeof_collection $lc_in_UI35] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_UI35 name]
	    } elseif { [sizeof_collection $lc_in_UI38] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_UI38 name]
	    } elseif { [sizeof_collection $lc_in_LI31] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_LI31 name]
	    } elseif { [sizeof_collection $lc_in_LI35] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_LI35 name]
	    } elseif { [sizeof_collection $lc_in_LI38] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_LI38 name]
	    } elseif { [sizeof_collection $lc_in_SI31] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_SI31 name]
	    } elseif { [sizeof_collection $lc_in_SI35] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_SI35 name]
	    } elseif { [sizeof_collection $lc_in_SI38] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_SI38 name]
	    } elseif { [sizeof_collection $lc_in_HI35] == 1 } {
		lappend lc_out_list [get_attribute $lc_in_HI35 name]
	    }

	}
    }

    return $lc_out_list
    
}



#######################################################################################################################
# report_qor for primetime
#######################################################################################################################
if { [string match $synopsys_program_name "pt_shell"] } {

    # Copyright (C) 1988-2012 Synopsys, Inc.  All rights reserved.
    # This script is proprietary and confidential information of Synopsys, Inc. and may be 
    # used and disclosed only as authorized per your agreement with Synopsys, Inc. 
    # controlling such use and disclosure.  
    #
    #
    # Procedure to emulate Design Compiler report_qor in PrimeTime
    #
    # Version 1.13 11/2/12 (pjarvis)
    #
    # Revision history
    # 1.0 (pfj) 9/3/03 - Initial release
    # 1.1 (pfj) 9/4/03 - Added hold-time reporting
    # 1.2 (pfj) 9/4/03 - Rewrote report_constraint parser and added all other DRCs
    # 1.3 (pfj) 9/4/03 - Added missing DRCs and fixed a bunch of related problems
    # 1.4 (pfj) 9/5/03 - Rewrote DRC parser to eliminate dependency on list of DRCs
    # 1.5 (pfj) 9/30/03 - Fixed bug with unconstrained path slacks
    # 1.6 (pfj) 5/14/04 - Changed report_constraint to use 5 digits for consistency with its DRC summary values
    # 1.7 (pfj) 4/27/07 - Added DMSA support; switched to redirect -variable instead of using temp file;
    #                     fixed bug with recovery/removal sum/count not being reported in async_default group;
    #                     added -significant_digits switch and dummy -physical switch (compatibility with DC/ICC)
    # 1.8 (pfj) 11/5/07 - Added code to stop script from running in 2007.06-* PrimeTime DMSA mode prior to 2007.06-SP3
    #                     to avoid merged-reporting bug from STAR 9000188708
    # 1.9 (pfj) 11/13/07 - Changed get_pins -of [get_cells $nonhier_cells] to the more-memory-efficient
    #                      get_pins -hier * -filter "is_hierarchical==false" approach; reduces overall memory usage
    # 1.10 (pfj) 6/1/09  - Fixed bug in DMSA mode where zero TNS and path count is reported with nonzero WNS;
    #                      alphabetized display of path groups to avoid nondeterministic get_timing_paths group ordering
    # 1.11 (as) 10/6/11  - Added the option -only_violated to only show the path groups that have timing violations;
    #                      added the option -summary, which shows one number for WNS and TNS that sums up all path groups' WNS/TNS
    # 1.12 (pfj) 2/27/12  - Updated get_timing_paths calls for compatibility with behavior changes in 2011.12+ PT
    # 1.13 (pfj) 11/2/12 - Updated for 9000519357 (DMSA -group *) fix and obsoletion of timing_report_fast_mode in 2012.12

    proc report_qor2 {args} {

	global sh_product_version
	global sh_dev_null
	global report_default_significant_digits
	global synopsys_program_name
	global pt_shell_mode
	global timing_report_fast_mode

	set results(-help) "no help"
	set results(-significant_digits) "none"
	set results(-only_violated) "false"
	set results(-summary) "false"

	parse_proc_arguments -args $args results

	if {$results(-help)==""} {
	    help -verbose report_qor2
	    return 1
	}

	set pt_2011_12_or_later 0
	set pt_2012_12_or_later 0

	if {[lindex [split $sh_product_version -] 1] == "2011.12" || [lindex [split [lindex [split $sh_product_version -] 1] .] 0] > 2011} {
	    set pt_2011_12_or_later 1
	}
	if {[lindex [split $sh_product_version -] 1] == "2012.12" || [lindex [split [lindex [split $sh_product_version -] 1] .] 0] > 2012} {
	    set pt_2012_12_or_later 1
	}

	if {$results(-significant_digits)=="none"} {
	    set significant_digits $report_default_significant_digits
	} else {
	    if {$results(-significant_digits) < 0 || $results(-significant_digits) > 13} {
		echo "Error: value '$results(-significant_digits)' not in range (0 to 13). (CMD-019)"
		return 0
	    } else {
		set significant_digits $results(-significant_digits)
	    }
	}

	proc count_levels {path} {
	    set levels 0
	    set endpoint [get_object_name [get_attribute -quiet $path endpoint]]
	    foreach_in_collection point [get_attribute -quiet $path points] {
		set object [get_attribute -quiet $point object]
		if {[get_attribute -quiet $object object_class] == "pin"} {
		    if {[get_attribute -quiet $object pin_direction] == "in"} {
			if {[get_attribute -quiet $object is_port] == "false"} {
			    if {[get_attribute -quiet $object full_name] != $endpoint} {
				incr levels
			    }
			}
		    }
		}
	    }    
	    return $levels
	}

	proc display_path_group {levels arrival slack cost count significant_digits scenario} {
	    echo "  ---------------------------------------------"
	    echo [format "  Levels of Logic:%29d$scenario" $levels]
	    echo [format "  Critical Path Length:%24.${significant_digits}f$scenario" $arrival]
	    if {[regexp {[^a-zA-Z]} $slack full]} { 
		echo [format "  Critical Path Slack:%25.${significant_digits}f$scenario" $slack]
	    } else {
		echo [format "  Critical Path Slack:            unconstrained$scenario"]
	    }
	    echo [format "  Total Negative Slack:%24.${significant_digits}f" $cost]
	    echo [format "  No. of Violating Paths:%22d" $count]
	    echo "  ---------------------------------------------"
	}

	proc display_cell_count_and_drcs {hier_cells_count nonhier_cells_count area hier_pins_count nonhier_pins_count cost count drc_list significant_digits scenario} {
	    upvar $cost cost_local
	    upvar $count count_local
	    echo "\n\n  Cell Count"
	    echo "  ---------------------------------------------"
	    echo [format "  Hierarchical Cell Count:%21d$scenario" $hier_cells_count]
	    echo [format "  Hierarchical Port Count:%21d$scenario" $hier_pins_count]
	    echo [format "  Leaf Cell Count:%29d$scenario" $nonhier_cells_count]
	    echo "  ---------------------------------------------"
	    echo "\n\n  Area"
	    echo "  ---------------------------------------------"
	    echo [format "  Design Area:%33.6f$scenario" $area]
	    if {[info exists cost_local(max_area)]} {
		echo [format "  Area Cost:%35.6f" $cost_local(max_area)]
	    }
	    echo "  ---------------------------------------------"
	    echo "\n\n  Design Rule Violations"
	    echo "  ---------------------------------------------"
	    echo [format "  Total No. of Pins in Design:%17d$scenario" $nonhier_pins_count]
	    foreach i $drc_list {
		if {$count_local($i) != 0} {
		    set len [expr 38 - [string length $i]]
		    echo [format "  $i Count:%${len}d" $count_local($i)]
		}
	    }
	    set total_cost 0
	    foreach i $drc_list {
		if {$cost_local($i) != 0} {
		    set len [expr 39 - [string length $i]]
		    set total_cost [expr $total_cost + $cost_local($i)]
		    echo [format "  $i Cost:%${len}.${significant_digits}f" $cost_local($i)]
		}
	    }
	    echo [format "  Total DRC Cost:%30.${significant_digits}f" $total_cost]
	    echo "  ---------------------------------------------\n"
	}

	if {$synopsys_program_name != "pt_shell"} {
	    echo "Error: This script only functions properly in PrimeTime."
	    return 0
	}

	set constraint_text ""
	set drc_list ""
	set group_list ""

	if {$pt_shell_mode == "primetime" || $pt_shell_mode == "primetime_slave"} {

	    set cost(unconstrained) 0
	    set count(unconstrained) 0

	    redirect $sh_dev_null {catch {set design [current_design]}}

	    if { $design == "" } {
		echo "Error: Current design is not defined. (DES-001)"
		return 0
	    }

	    echo "\n****************************************"
	    echo "Report : qor"
	    echo "Design : [get_object_name $design]"
	    echo "Version: $sh_product_version"
	    echo "Date   : [date]"
	    echo "****************************************\n"

	    redirect -variable constraint_text {report_constraint -all_violators -nosplit -significant_digits 5}

	    foreach line [split $constraint_text "\n"] {
		switch -regexp $line {
		    {^.* +([-\.0-9]+) +\(VIOLATED} {
			regexp {^.* +([-\.0-9]+) +\(VIOLATED} $line full slack
			set cost($group) [expr $cost($group) + $slack]
			incr count($group)
			continue
		    }
		    { *max_delay/setup.*'(.*)'} {
			regexp { *max_delay/setup.*'(.*)'} $line full group
			set cost($group) 0
			set count($group) 0
			continue
		    }
		    { *min_delay/hold.*'(.*)'} {
			regexp { *min_delay/hold.*'(.*)'} $line full group
			set group ${group}_min
			set cost($group) 0
			set count($group) 0
			continue
		    }
		    {^ *([a-zA-Z_]+) *$} {
			regexp {^ *([a-zA-Z_]+) *$} $line full group
			if {$group == "recovery" } {
			    set group async_default
			}
			if {$group == "removal"} {
			    set group async_default_min
			}
			if ![info exists cost($group)] {
			    set cost($group) 0
			    set count($group) 0
			    if {$group != "max_area" && $group != "async_default" && $group != "async_default_min"} {
				lappend drc_list $group
			    }
			}
			continue
		    }
		}
	    }

	    set WNS 0.0; set TNS 0.0; set NVP 0;
	    set WNS_min 0.0; set TNS_min 0.0; set NVP_min 0;

	    if {$pt_2011_12_or_later} {
		set paths [get_timing_paths -slack_lesser_than inf -group *]
	    } else {
		set paths [get_timing_paths]
	    }

	    foreach_in_collection path [sort_collection $paths path_group] {
		set path_group [get_attribute -quiet [get_attribute -quiet $path path_group] full_name]
		if {$path_group == ""} {
		    set path_group unconstrained
		}
		if {[regexp {\*\*[a-z_]*\*\*} $path_group full]} {
		    set path_group [string map {\* ""} $path_group]
		}
		if {![info exists cost($path_group)]} {
		    set cost($path_group) 0
		    set count($path_group) 0
		}

		set levels [count_levels $path]

		set slack [get_attribute -quiet $path slack]

		if {$slack < $WNS} { set WNS $slack }
		set TNS [expr $TNS + $cost(${path_group})]
		set NVP [expr $NVP + $count(${path_group})]
		
		if {$results(-summary) || ($results(-only_violated) && $count($path_group) == 0)} { continue } 
		echo "\n  Timing Path Group '$path_group' (max_delay/setup)"
		display_path_group $levels [get_attribute -quiet $path arrival] $slack $cost($path_group) $count($path_group) $significant_digits ""
	    }

	    echo ""

	    if {$pt_2011_12_or_later} {
		set paths [get_timing_paths -slack_lesser_than inf -group * -delay min]
	    } else {
		set paths [get_timing_paths -delay min]
	    }

	    foreach_in_collection path [sort_collection $paths path_group] {
		redirect $sh_dev_null {set path_group [get_attribute -quiet [get_attribute -quiet $path path_group] full_name]}
		if {$path_group == ""} {
		    set path_group unconstrained
		}
		if {[regexp {\*\*[a-z_]*\*\*} $path_group full]} {
		    set path_group [string map {\* ""} $path_group]
		}
		if {![info exists cost(${path_group}_min)]} {
		    set cost(${path_group}_min) 0
		    set count(${path_group}_min) 0
		}
		
		set levels [count_levels $path]

		set slack [get_attribute -quiet $path slack]

		if {$slack < $WNS_min} { set WNS_min $slack }
		set TNS_min [expr $TNS_min + $cost(${path_group}_min)]
		set NVP_min [expr $NVP_min + $count(${path_group}_min)]
		
		if {$results(-summary) || ($results(-only_violated) && $count(${path_group}_min) == 0)} { continue } 
		echo "\n  Timing Path Group '$path_group' (min_delay/hold)"
		display_path_group $levels [get_attribute -quiet $path arrival] $slack $cost(${path_group}_min) $count(${path_group}_min) $significant_digits ""
	    }

	    unset paths

	    if {$results(-summary)} {
		puts "  Summary"
		puts "  ---------------------------------------------"
		puts [format "  Setup WNS: %10.${significant_digits}f  TNS: %10.${significant_digits}f  Number of Violating Paths: %d" $WNS $TNS $NVP]
		puts [format "  Hold  WNS: %10.${significant_digits}f  TNS: %10.${significant_digits}f  Number of Violating Paths: %d" $WNS_min $TNS_min $NVP_min]
		puts "  ---------------------------------------------"
	    } 
	    
	    set hier_cells [get_cells -quiet -hier * -filter "is_hierarchical == true"]
	    set nonhier_cells [get_cells -quiet -hier * -filter "is_hierarchical == false"]

	    display_cell_count_and_drcs [sizeof_collection $hier_cells] \
		[sizeof_collection $nonhier_cells] \
		[get_attribute -quiet $design area] \
		[sizeof_collection [get_pins -quiet -of $hier_cells]] \
		[sizeof_collection [get_pins -quiet -hier * -filter "is_hierarchical==false"]] \
		cost \
		count \
		$drc_list \
		$significant_digits \
		""

	    unset hier_cells
	    unset nonhier_cells

	} elseif {$pt_shell_mode == "primetime_master"} {

	    global multi_scenario_message_verbosity_level

	    set old_verbosity_level $multi_scenario_message_verbosity_level
	    set multi_scenario_message_verbosity_level low

	    if [info exists constraint_text] {
		unset constraint_text
	    }

	    if {$sh_product_version=="Z-2007.06"||$sh_product_version=="Z-2007.06-SP1"||$sh_product_version=="Z-2007.06-SP2"||$sh_product_version=="Z-2007.06-SP2-1"} {
		echo "Error: Aborting script execution! Due to a DMSA bug in Z-2007.06 versions prior to Z-2007.06-SP3 (STAR 9000188708),"
		echo "       this script will produce inconsistent and incorrect results. The bug is fixed in Z-2007.06-SP3 PrimeTime." 
		echo "       To use this script in DMSA mode, please use Z-2007.06-SP3 or later PrimeTime instead."
		return 0
	    }

	    echo "\n****************************************"
	    echo "Report : qor"
	    echo "Design : multi-scenario design"
	    echo "Version: $sh_product_version"
	    echo "Date   : [date]"
	    echo "****************************************\n"

	    get_distributed_variables -pre_commands \
		{redirect -variable constraint_text {report_constraint -all_violators -nosplit -significant_digits 5}} \
		-post_commands {unset constraint_text} \
		constraint_text

	    if {$pt_2012_12_or_later} {
		# STAR 9000519357 is fixed; we can use -group * in DMSA
		set max_paths [get_timing_paths -slack_lesser_than inf -group * -attributes "full_name slack path_group points arrival object object_class pin_direction is_port endpoint"]
		set min_paths [get_timing_paths -slack_lesser_than inf -group * -delay min -attributes "full_name slack path_group points arrival object object_class pin_direction is_port endpoint"]
	    } elseif {$pt_2011_12_or_later} {
		# STAR 9000519357 is not fixed; -group * is broken, so revert to pre-2011.12 behavior
		set old_timing_report_fast_mode $timing_report_fast_mode
		set timing_report_fast_mode false
		set max_paths [get_timing_paths -attributes "full_name slack path_group points arrival object object_class pin_direction is_port endpoint"]
		set min_paths [get_timing_paths -delay min -attributes "full_name slack path_group points arrival object object_class pin_direction is_port endpoint"]
		set timing_report_fast_mode $old_timing_report_fast_mode
		unset old_timing_report_fast_mode
	    } else {
		# pre-2011.12 behavior
		set max_paths [get_timing_paths -attributes "full_name slack path_group points arrival object object_class pin_direction is_port endpoint"]
		set min_paths [get_timing_paths -delay min -attributes "full_name slack path_group points arrival object object_class pin_direction is_port endpoint"]
	    }

	    set old_scenario_list [current_scenario]

	    foreach_in_collection scenario $old_scenario_list {
		set first_scenario_name [get_object_name $scenario]
		break
	    }
	    
	    current_scenario $first_scenario_name

	    get_distributed_variables -pre_commands \
		{set hier_cells [get_cells -quiet -hier * -filter "is_hierarchical == true"]; \
		     set hier_cells_count [sizeof_collection $hier_cells]; \
		     set hier_pins_count [sizeof_collection [get_pins -quiet -of $hier_cells]]; \
		     set nonhier_cells_count [sizeof_collection [get_cells -quiet -hier * -filter "is_hierarchical == false"]]; \
		     set nonhier_pins_count [sizeof_collection [get_pins -quiet -hier * -filter "is_hierarchical == false"]]; \
		     set area [get_attribute -quiet [current_design] area]; \
		 } -post_commands {unset hier_cells hier_cells_count hier_pins_count nonhier_cells_count nonhier_pins_count area} \
		"hier_cells_count nonhier_cells_count hier_pins_count nonhier_pins_count area"
	    
	    current_scenario $old_scenario_list

	    set multi_scenario_message_verbosity_level $old_verbosity_level
	    set group ""
	    foreach scenario [array names constraint_text] {
		foreach line [split $constraint_text($scenario) "\n"] {
		    switch -regexp $line {
			{^ +(\S+ ?[\(\)a-zA-Z]*).* ([-\.0-9]+) +\(VIOLATED} {
			    regexp {^ +(\S+ ?[\(\)a-zA-Z]*).* ([-\.0-9]+) +\(VIOLATED} $line full object slack
			    set object [string trimright $object]
			    if ![info exists slack_${group}($object)] {
				set slack_${group}($object) $slack
			    } else {
				if [expr $slack < [set slack_${group}($object)]] {
				    set slack_${group}($object) $slack
				}
				continue
			    }
			}
			{ *max_delay/setup.*'(.*)'} {
			    regexp { *max_delay/setup.*'(.*)'} $line full group
			    if ![info exists slack_$group] {
				array set slack_$group ""
				array set slack_$group ""
				set cost($group) 0
				set count($group) 0
				lappend group_list $group
			    }
			    continue
			}
			{ *min_delay/hold.*'(.*)'} {
			    regexp { *min_delay/hold.*'(.*)'} $line full group
			    set group ${group}_min
			    if ![info exists slack_$group] {
				array set slack_$group ""
				array set slack_$group ""
				set cost($group) 0
				set count($group) 0
				lappend group_list $group
			    }
			    continue
			}
			{^ *([a-zA-Z_]+) *$} {
			    regexp {^ *([a-zA-Z_]+) *$} $line full group
			    if {$group == "recovery"} {
				set group async_default
				if ![info exists slack_async_default] {
				    lappend group_list async_default
				}
			    }
			    if {$group == "removal"} {
				set group async_default_min
				if ![info exists slack_async_default_min] {
				    lappend group_list async_default_min
				}
			    }
			    if ![info exists slack_$group] {
				if {$group != "max_area" && $group != "async_default" && $group != "async_default_min"} {
				    lappend drc_list $group
				}
				array set slack_$group ""
				array set slack_$group ""
				set cost($group) 0
				set count($group) 0
			    }
			    continue
			}
		    }
		}
	    }

	    foreach group "$group_list $drc_list" {
		foreach object [array names slack_$group] {
		    set cost($group) [expr $cost($group) + [set slack_${group}($object)]]
		    incr count($group)
		}
	    }

	    set WNS 0.0; set TNS 0.0; set NVP 0;
	    set WNS_min 0.0; set TNS_min 0.0; set NVP_min 0;
	    
	    foreach_in_collection path [sort_collection $max_paths path_group] {
		set path_group [get_attribute -quiet [get_attribute -quiet $path path_group] full_name]
		if {$path_group == ""} {
		    set path_group unconstrained
		}
		if {[regexp {\*\*[a-z_]*\*\*} $path_group full]} {
		    set path_group [string map {\* ""} $path_group]
		}
		if {![info exists cost($path_group)]} {
		    set cost($path_group) 0
		    set count($path_group) 0
		}

		set levels [count_levels $path]

		set slack [get_attribute -quiet $path slack]
		set scenario_name [get_attribute $path scenario_name]

		if {$slack < $WNS} { set WNS $slack }
		set TNS [expr $TNS + $cost(${path_group})]
		set NVP [expr $NVP + $count(${path_group})]
		
		if {$results(-summary) || ($results(-only_violated) && $count($path_group) == 0)} { continue } 
		echo "\n  Timing Path Group '$path_group' (max_delay/setup)"
		display_path_group $levels [get_attribute -quiet $path arrival] $slack $cost($path_group) $count($path_group) $significant_digits " ($scenario_name)"
	    }

	    echo ""

	    foreach_in_collection path [sort_collection $min_paths path_group] {
		redirect $sh_dev_null {set path_group [get_attribute -quiet [get_attribute -quiet $path path_group] full_name]}
		if {$path_group == ""} {
		    set path_group unconstrained
		}
		if {[regexp {\*\*[a-z_]*\*\*} $path_group full]} {
		    set path_group [string map {\* ""} $path_group]
		}
		if {![info exists cost(${path_group}_min)]} {
		    set cost(${path_group}_min) 0
		    set count(${path_group}_min) 0
		}

		set levels [count_levels $path]

		set slack [get_attribute -quiet $path slack]
		set scenario_name [get_attribute $path scenario_name]

		if {$slack < $WNS_min} { set WNS_min $slack }
		set TNS_min [expr $TNS_min + $cost(${path_group}_min)]
		set NVP_min [expr $NVP_min + $count(${path_group}_min)]
		
		if {$results(-summary) || ($results(-only_violated) && $count(${path_group}_min) == 0)} { continue } 
		echo "\n  Timing Path Group '$path_group' (min_delay/hold)"
		display_path_group $levels [get_attribute -quiet $path arrival] $slack $cost(${path_group}_min) $count(${path_group}_min) $significant_digits " ($scenario_name)"
	    }

	    if {$results(-summary)} {
		puts "  Summary"
		puts "  ---------------------------------------------"
		puts [format "  Setup WNS: %10.${significant_digits}f  TNS: %10.${significant_digits}f  Number of Violating Paths: %d" $WNS $TNS $NVP]
		puts [format "  Hold  WNS: %10.${significant_digits}f  TNS: %10.${significant_digits}f  Number of Violating Paths: %d" $WNS_min $TNS_min $NVP_min]
		puts "  ---------------------------------------------"
	    }
	    
	    display_cell_count_and_drcs $hier_cells_count($first_scenario_name) \
		$nonhier_cells_count($first_scenario_name) \
		$area($first_scenario_name) \
		$hier_pins_count($first_scenario_name) \
		$nonhier_pins_count($first_scenario_name) \
		cost \
		count \
		$drc_list \
		$significant_digits \
		" ($first_scenario_name)"

	    unset max_paths
	    unset min_paths

	}

    }

    define_proc_attributes report_qor2 \
	-info "Report QoR" \
	-define_args {\
			  {-physical "For compatibility with DC/ICC report_qor; ignored in PrimeTime" "" boolean optional}
	    {-significant_digits "Precision level of report (range from 0 to 13)" "<digits>" int optional}
	    {-only_violated "Show only violating path groups" "" boolean optional}
	    {-summary "QoR Summary report" "" boolean optional}
	}

}


#######################################################################################################################
# Technology benchmarking reporting
#######################################################################################################################
proc convert_point_to_comma { input_txt } {
    return [regsub -all {\.} $input_txt {,}]
}

proc report_tech_bm_data {} {

    global env
    global derate_clock_early_value
    global derate_clock_late_value
    global derate_data_early_value
    global derate_data_late_value
    global synopsys_program_name
    global mode
    global corner

    # Common data
    puts ";Vendor:; $env(LIBRARY_VENDOR);"
    puts ";Foundry:; $env(FOUNDRY);"
    puts ";Process:; $env(PROCESS);"
    puts ";Trial tag:; $env(TRIAL_TAG);"

    if {$synopsys_program_name == "pt_shell"} {
	puts ";Operating condition:; [get_attribute [current_design] operating_condition_max];"
	puts ";Derating factor clock early:; $derate_clock_early_value(${mode}_${corner});"
	puts ";Derating factor clock late:; $derate_clock_late_value(${mode}_${corner});"
	puts ";Derating factor data early:; $derate_data_early_value(${mode}_${corner});"
	puts ";Derating factor data late:; $derate_data_late_value(${mode}_${corner});"
    } else {
	puts ";Operating condition:; [get_attribute [current_design] operating_condition_max];"
	puts ";Derating factor clock early:; $derate_clock_early_value;"
	puts ";Derating factor clock late:; $derate_clock_late_value;"
	puts ";Derating factor data early:; $derate_data_early_value;"
	puts ";Derating factor data late:; $derate_data_late_value;"
    }

    # PPA data

    # Power
    set Total_power [convert_point_to_comma [get_attribute [current_design] total_power]]
    set Dynamic_power [convert_point_to_comma [get_attribute [current_design] dynamic_power]]
    set Leakage_power [convert_point_to_comma [get_attribute [current_design] leakage_power]]

    # Cell counts for different Vts and channel lengths
    if { [sizeof_collection [get_libs sc*mc_cln28hpm* -quiet]] > 0 } {
	set cnt_TL_C31  [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TL_C31"]]
	set cnt_TL_C35  [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TL_C35"]]
	set cnt_TL_C38  [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TL_C38"]]
	set cnt_TS_C31  [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TS_C31"]]
	set cnt_TS_C35  [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TS_C35"]]
	set cnt_TS_C38  [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TS_C38"]]
	set cnt_TUL_C31 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TUL_C31"]]
	set cnt_TUL_C35 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TUL_C35"]]
	set cnt_TH_C35  [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TH_C35"]]
	set cnt_TUH_C35 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TUH_C35"]]
	set cnt_cells [expr $cnt_TL_C31 + $cnt_TL_C35 + $cnt_TL_C38 + $cnt_TS_C31 + $cnt_TS_C35 + $cnt_TS_C38 + $cnt_TUL_C31 + $cnt_TUL_C35 + $cnt_TH_C35 + $cnt_TUH_C35]
    } elseif { [sizeof_collection [get_libs sc*mc_cln40g* -quiet]] > 0 } {
	set cnt_TL40 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TL40"]]
	set cnt_TL50 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TL50"]]
	set cnt_TR40 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TR40"]]
	set cnt_TR50 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TR50"]]
	set cnt_TH50 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *TH50"]]
	set cnt_cells [expr $cnt_TL40 + $cnt_TL50 + $cnt_TR40 + $cnt_TR50 +$cnt_TH50]
    } elseif { [sizeof_collection [get_libs C28SOI* -quiet]] > 0 } {
	set cnt_P0 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *P0"]]
	set cnt_P4 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *P4"]]
	set cnt_P10 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *P10"]]
	set cnt_P16 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *P16"]]
	set cnt_cells [expr $cnt_P0 + $cnt_P4 + $cnt_P10 + $cnt_P16]
    } elseif { [sizeof_collection [get_libs tsmc_cln28hp_sc* -quiet]] > 0 } {
	set cnt_UI31 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *UI31*"]]
	set cnt_UI35 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *UI35*"]]
	set cnt_UI38 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *UI38*"]]
	set cnt_LI31 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *LI31*"]]
	set cnt_LI35 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *LI35*"]]
	set cnt_LI38 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *LI38*"]]
	set cnt_SI31 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *SI31*"]]
	set cnt_SI35 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *SI35*"]]
	set cnt_SI38 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *SI38*"]]
	set cnt_HI35 [sizeof_collection [get_cells -quiet -hierarchical -filter "ref_name =~ *HI35*"]]
	set cnt_cells [expr $cnt_UI31 + $cnt_UI35 + $cnt_UI38 + $cnt_LI31 + $cnt_LI35 + $cnt_LI38 + $cnt_SI31 + $cnt_SI35 + $cnt_SI38 + $cnt_HI35]
    }

    # Clock period
    set Period [convert_point_to_comma [get_attribute [get_clocks clock_top] period]]

    set Total_power [convert_point_to_comma [get_attribute [current_design] total_power]]
    set Dynamic_power [convert_point_to_comma [get_attribute [current_design] dynamic_power]]
    set Leakage_power [convert_point_to_comma [get_attribute [current_design] leakage_power]]

    # Memory Area
    set Memory_area 0
    set Memory_total_power 0
    set Memory_dynamic_power 0
    set Memory_leakage_power 0

    # Design specific data

    if { [string match [get_attribute [current_design] full_name] "dl_f1a"] } {
	# ARM, STM & LSI
	foreach_in_collection c [get_cells -quiet -hierarchical -filter "(ref_name =~ rf* || ref_name =~ *DPREG* || ref_name =~ ip7*) && is_hierarchical == false && area > 1000"] {
	    set Memory_area [expr $Memory_area + [get_attribute $c area]]
	    set Memory_total_power [expr $Memory_total_power + [get_attribute $c total_power]]
	    set Memory_dynamic_power [expr $Memory_dynamic_power + [get_attribute $c dynamic_power]]
	    set Memory_leakage_power [expr $Memory_leakage_power + [get_attribute $c leakage_power]]
	}
    }
    
    # Area
    set Total_area [get_attribute [current_design] area]
    set Std_cell_area [expr $Total_area - $Memory_area]
    set Total_area [convert_point_to_comma $Total_area]
    set Memory_area [convert_point_to_comma $Memory_area]
    set Std_cell_area [convert_point_to_comma $Std_cell_area]
    set Memory_total_power [convert_point_to_comma $Memory_total_power]
    set Memory_dynamic_power [convert_point_to_comma $Memory_dynamic_power]
    set Memory_leakage_power [convert_point_to_comma $Memory_leakage_power]

    # Reporting
    if { [sizeof_collection [get_libs sc*mc_cln28hpm* -quiet]] > 0 } {
	puts ";Period; Total area; Std cell area; Memory area; Total power; Dynamic power; Leakage power; Total memory power; Dynamic memory power; Leakage memory power; Cell count; lvt_c31; lvt_c35; lvt_c38; svt_c31; svt_c35; svt_c38; ulvt_c31; ulvt_c35; hvt_c35; uhvt_c35;"
	puts ";$Period; $Total_area; $Std_cell_area; $Memory_area; $Total_power; $Dynamic_power; $Leakage_power; $Memory_total_power; $Memory_dynamic_power; $Memory_leakage_power; $cnt_cells; $cnt_TL_C31; $cnt_TL_C35; $cnt_TL_C38; $cnt_TS_C31; $cnt_TS_C35; $cnt_TS_C38; $cnt_TUL_C31; $cnt_TUL_C35; $cnt_TH_C35; $cnt_TUH_C35;"
    } elseif { [sizeof_collection [get_libs sc*mc_cln40g* -quiet]] > 0 } {
	puts ";Period; Total area; Std cell area; Memory area; Total power; Dynamic power; Leakage power; Total memory power; Dynamic memory power; Leakage memory power; Cell count; lvt_c40; lvt_c50; rvt_c40; rvt_c50; hvt_c50;"
	puts ";$Period; $Total_area; $Std_cell_area; $Memory_area; $Total_power; $Dynamic_power; $Leakage_power; $Memory_total_power; $Memory_dynamic_power; $Memory_leakage_power; $cnt_cells; $cnt_TL40; $cnt_TL50; $cnt_TR40; $cnt_TR50; $cnt_TH50;"
    } elseif { ([sizeof_collection [get_libs C28SOI*_LL* -quiet]] > 0) && ([sizeof_collection [get_libs C28SOI*_LR* -quiet]] > 0) } {
	puts "Nokia Error: It is illegal to mix LL and LR libraries"
    } elseif { [sizeof_collection [get_libs C28SOI*_LL* -quiet]] > 0 } {
	puts ";Period; Total area; Std cell area; Memory area; Total power; Dynamic power; Leakage power; Total memory power; Dynamic memory power; Leakage memory power; Cell count; LL_P0; LL_P4; LL_P10; LL_P16;"
	puts ";$Period; $Total_area; $Std_cell_area; $Memory_area; $Total_power; $Dynamic_power; $Leakage_power; $Memory_total_power; $Memory_dynamic_power; $Memory_leakage_power; $cnt_cells; $cnt_P0; $cnt_P4; $cnt_P10; $cnt_P16;"
    } elseif { [sizeof_collection [get_libs C28SOI*_LR* -quiet]] > 0 } {
	puts ";Period; Total area; Std cell area; Memory area; Total power; Dynamic power; Leakage power; Total memory power; Dynamic memory power; Leakage memory power; Cell count; LR_P0; LR_P4; LR_P10; LR_P16;"
	puts ";$Period; $Total_area; $Std_cell_area; $Memory_area; $Total_power; $Dynamic_power; $Leakage_power; $Memory_total_power; $Memory_dynamic_power; $Memory_leakage_power; $cnt_cells; $cnt_P0; $cnt_P4; $cnt_P10; $cnt_P16;"
    } elseif { [sizeof_collection [get_libs tsmc_cln28hp_sc* -quiet]] > 0 } {
	puts ";Period; Total area; Std cell area; Memory area; Total power; Dynamic power; Leakage power; Total memory power; Dynamic memory power; Leakage memory power; Cell count; UI31; UI35; UI38; LI31; LI35; LI38; SI31; SI35; SI38; HI35;"
	puts ";$Period; $Total_area; $Std_cell_area; $Memory_area; $Total_power; $Dynamic_power; $Leakage_power; $Memory_total_power; $Memory_dynamic_power; $Memory_leakage_power; $cnt_cells; $cnt_UI31; $cnt_UI35; $cnt_UI38; $cnt_LI31; $cnt_LI35; $cnt_LI38; $cnt_SI31; $cnt_SI35; $cnt_SI38; $cnt_HI35;"
    }

}



#######################################################################################################################
# Count logic levels from/to pins(s) and/or port(s)
#######################################################################################################################
proc count_logic_levels { args } {
    
    parse_proc_arguments -args $args args_arr
    
    set coll [get_pins -quiet $args_arr(coll)]
    append_to_collection -unique coll [get_ports -quiet $args_arr(coll)]
    
    if { [info exists args_arr(-from)]} {
	
	foreach_in_collection p $coll {
	    
	    set i 0
	    set loads [all_fanout -flat -levels $i -from $p]
	    incr i
	    set new_loads [all_fanout -flat -levels $i -from $p]
	    
	    while { ([sizeof_collection $new_loads] > [sizeof_collection $loads]) } {
		set loads $new_loads
		incr i
		set new_loads [all_fanout -flat -levels $i -from $p]
	    }
	    
	    echo "[get_attribute $p full_name] [expr $i - 1]"
	}
	
    } elseif { [info exists args_arr(-to)]} {
	
	foreach_in_collection p $coll {
	    
	    set i 0
	    set loads [all_fanin -flat -levels $i -to $p]
	    incr i
	    set new_loads [all_fanin -flat -levels $i -to $p]
	    
	    while { ([sizeof_collection $new_loads] > [sizeof_collection $loads]) } {
		set loads $new_loads
		incr i
		set new_loads [all_fanin -flat -levels $i -to $p]
	    }
	    
	    echo "[get_attribute $p full_name] [expr $i - 1]"
	}
	
    }
}

define_proc_attributes count_logic_levels \
    -info "Count logic levels from/to pin(s) and/or port(s)" \
    -define_args { \
		       {coll "Collection of pin(s) and/or port(s)" coll string required} \
		       {"-from" "Count logic levels from pin(s) and/or port(s)" "" boolean optional} \
		       {"-to" "Count logic levels to pin(s) and/or port(s)" "" boolean optional} \
		   }






#######################################################################################################################
# 
#######################################################################################################################
proc filter_clk_lib_cells_with_core_lib_vts { lc_in_list } {

    set lc_out_list ""

    foreach lc_in $lc_in_list {

	set P0_lc [get_lib_cells $lc_in -filter "full_name =~ *_P0"]
	set P4_lc [get_lib_cells $lc_in -filter "full_name =~ *_P4"]
	set P10_lc [get_lib_cells $lc_in -filter "full_name =~ *_P10"]
	set P16_lc [get_lib_cells $lc_in -filter "full_name =~ *_P16"]


	if { [sizeof_collection [get_libs -quiet C28SOI_SC_*_CORE_LL]] } {
	    lappend lc_out_list $P0_lc
	}

	if { [sizeof_collection [get_libs -quiet C28SOI_SC_*_COREPBP4_LL]] } {
	    lappend lc_out_list $P4_lc
	}


	if { [sizeof_collection [get_libs -quiet C28SOI_SC_*_COREPBP10_LL]] } {
	    lappend lc_out_list $P10_lc
	}


	if { [sizeof_collection [get_libs -quiet C28SOI_SC_*_COREPBP16_LL]] } {
	    lappend lc_out_list $P16_lc
	}

	return $lc_out_list

    }

}


proc get_driving_pin {input_pin} {

    global synopsys_program_name



    if {  $synopsys_program_name == "primetime"  ||  $synopsys_program_name == "pt_shell" ||  $synopsys_program_name == "icc_shell"  ||  $synopsys_program_name == "dc_shell"  ||  $synopsys_program_name == "de_shell"} {
        set DRIVING_PIN [get_object_name [get_pins -filter "pin_direction == out" -leaf -of_objects [get_nets -of_objects $input_pin]]];
        return $DRIVING_PIN
    } else {
        return $input_pin
    }
};



#########################################################################
# Procedure that generates setups for Spotligth & SpyGlass in DC.
# Input for this procedure is list_libs report.
# Usage: Gen_Spotlight_Setup list_libs.rpt output_file.csh 
#########################################################################

proc Gen_Spotlight_Setup {input_file output_file} {

    # Open files:
    if [catch {set f_id [open $input_file r]} msg] {
	puts "Error in opening file, $msg"
	exit
    }
 
    if [catch {set temp [open $output_file w+]} msg] {
	puts $msg
    }

    puts $temp "spyglass_lc \\"

    # Process input file
    while {[gets $f_id line] >=0 } {

	if {[regexp {e8xmid} $line] || [regexp {ip74} $line]  || [regexp {ec0_} $line] || [regexp {cw108} $line] || [regexp {ec0hvt_} $line] || [regexp {ec0hs_} $line] || [regexp {ss_hm_} $line] } {
	    set split_line [split $line " "]
	    set file [lindex $split_line 3]
	    regsub -all ".ldb" $file ".lib" file
	    regsub -all ".db" $file ".lib" file
	    regsub -all ".lib" $file ".lib.gz" file_zipped
	    set path [lindex $split_line 4]
	    

	    if { [file exists ${path}/${file}] && ( ! [file isdirectory ${path}/${file}] ) }  {
		puts $temp "-gateslib ${path}/${file} \\"
	    } elseif {[file exists ${path}/${file_zipped} ] && ( ! [file isdirectory ${path}/${file_zipped}] ) } {
		puts $temp "-gateslib ${path_stdtech}/${file_zipped} \\"
	    } 

	    
	}
    }
    puts $temp "-outsglib aggregate_lib.sglib \\"
    puts $temp "-wdir ./lc_work"
    close $temp
}

########################################################################################
# Procedure to report feedthrough connection in design:
########################################################################################

proc ReportFeedthroughs {} {

    foreach_in_collection p [get_ports * -filter "port_direction==out"] { 
	set name [get_attribute $p full_name]
 
	foreach_in_collection n [all_fanin -flat -startpoints_only -to [get_ports $p]] {
	    if {[get_attribute -quiet [get_ports -quiet $n] port_direction] == "in"} {
		set in_port_name [get_attribute [get_ports $n] name]
		echo "NSN-ERROR: Output port $name is driven by input port $in_port_name"
	    }	    
	}
    }
}


########################################################################################
# Procedure CheckMacroConnections reports macro pins tied to Konstant values:
########################################################################################
proc ReportUncontrolled_MacroPins {coll} {

    foreach_in_collection p $coll { 
	set name [get_attribute $p full_name]
 
	if {[sizeof_collection [filter_collection [all_connected -leaf [all_connected $p]] "pin_direction == out and name == **logic_0**"]]} {
	    echo "$name \t IS DRIVEN BY  \t [get_attribute [filter_collection [all_connected -leaf [all_connected $p]] "pin_direction == out and name == **logic_0**"] full_name]"
	}
    }
 

    foreach_in_collection p $coll { 
	set name [get_attribute $p full_name]
 
	if {[sizeof_collection [filter_collection [all_connected -leaf [all_connected $p]] "pin_direction == out and name == **logic_1**"]]} {
	    echo "$name \t IS DRIVEN BY  \t [get_attribute [filter_collection [all_connected -leaf [all_connected $p]] "pin_direction == out and name == **logic_1**"] full_name]"
	}
    }

}


proc CheckMacroConnections {} {
    foreach_in_collection  c [get_cells -hier -filter "is_macro_cell==true || area > 100"] {

	set fname [get_attribute [get_cells $c] full_name]		      
	set rname [get_attribute [get_cells $c] ref_name]		      
	
	echo ""    
	echo ******************************************************************************
	echo "Instance:   $fname"      
	echo "Reference:  $rname"      
	echo "Macro cell pins connected to constant values (logic_0 or logic_1)"      
	echo ******************************************************************************
	

	ReportUncontrolled_MacroPins [get_pins ${fname}/*]

    }

}




########################################################################################
# Procedure that reports memory macro cell pins connected to constant values or directly to IO.
# Usage:   CheckMemMacroConnections > filename.rpt
########################################################################################
proc ReportUncontrolled_MemMacroPins {coll} {
    # Is section title printed or not?
    set logic0_connections 0;
    set logic1_connections 0;
    set IO_connections 0;
    
    foreach_in_collection p $coll { 
	set name [get_attribute $p full_name]
	
	if {[sizeof_collection [filter_collection [all_connected -leaf [all_connected $p]] "pin_direction == out and name == **logic_0**"]]} {
	    
	    if {$logic0_connections} {
		echo "$name"
	    } else {
		echo ****************************************
		echo "Pins tied to logic_0:"      
		echo ****************************************
		echo "$name"
		set logic0_connections 1;
	    }	    
	}
    }
 	
    foreach_in_collection p $coll { 
	set name [get_attribute $p full_name]
 
	if {[sizeof_collection [filter_collection [all_connected -leaf [all_connected $p]] "pin_direction == out and name == **logic_1**"]]} {

	    if {$logic1_connections} {
		echo "$name"
	    } else {
		echo ****************************************
		echo "Pins tied to logic_1:"      
		echo ****************************************
		echo "$name"
		set logic1_connections 1;
	    }	    
	}
    }

    	
    foreach_in_collection p $coll {

	set p_fn [get_attribute [get_pins $p] name]
	if { !([string equal $p_fn ckgridm1n00] || [string equal $p_fn ickrp0] || [string equal $p_fn ickwp0]) || [string equal $p_fn ckrdp0 ] || [string equal $p_fn ckrdp1 ] || [string equal $p_fn ckwrp0 ] || [string equal $p_fn ckwrp1 ] } {	    
	    set name [get_attribute $p full_name]
	    set dir [get_attribute [get_pins $p] pin_direction]

	    
	    if {[string match $dir out]} {
		if {[sizeof_collection [get_ports -quiet [all_fanout -flat -from [get_pins $p] -endpoints_only]]]} {
		    set pn [get_attribute [get_ports -quiet [all_fanout -flat -from [get_pins $p] -endpoints_only]] full_name]
		
		    if {$IO_connections} {
			echo "$name \t (port: $pn)"
		    } else {
			echo ****************************************
			echo "Pins connected to IO-ports:"      
			echo ****************************************
			echo "$name \t (port: $pn)"
			set IO_connections 1;
		    }
		}
	    }

	    if {[string match $dir in]} {
		if {[sizeof_collection [get_ports -quiet [all_fanin -flat -to [get_pins $p] -startpoints_only]]]} {
		    set pn [get_attribute [get_ports -quiet [all_fanin -flat -to [get_pins $p] -startpoints_only]] full_name]

		    if {$IO_connections} {
			echo "$name \t (port: $pn)"
		    } else {
			echo ****************************************
			echo "Pins connected to IO-ports:"      
			echo ****************************************
			echo "$name \t (port: $pn)"
			set IO_connections 1;
		    }
		}
	    }  
	    
	}
	
    }
}

proc CheckMemMacroConnections {} {

    	echo ""    
	echo "##################################################################"
	echo "#                              MEMORY MACRO CELL CONNECTION REPORT "
	echo "# "
	echo "# This report lists all pins of mem macros that are tied to constant values or are"
	echo "# directly connected to IO ports (other than clocks)." 
        echo "# Main idea is to check following connections:"
	echo "#"
	echo "# -  Read/write enables (WE & RE pins). If these are constants, is memory type used" 
        echo "#    correct? (or could e.g. 211 mem be used instead of 222?)"
	echo "#"
	echo "# -  Memory enable signals (CS pins). If memory is always activated power savings"
	echo "#    are not possible."
	echo "#"
	echo "# -  Sleep signals (LS/DS/SD pins). If these are in constant values, sleep modes are not"
	echo "#    correctly in use."
	echo "##################################################################"    
    
    foreach_in_collection  c [get_cells -hier -filter "is_macro_cell==true && (ref_name=~ip75* || ref_name=~ ip74*) "] {

	set fname [get_attribute [get_cells $c] full_name]		      
	set rname [get_attribute [get_cells $c] ref_name]		      
	
	echo "\n\n"    
	echo ==========================================================================================================
	echo "INSTANCE:     $fname"      
	echo "REFERENCE:  $rname"      
	echo ==========================================================================================================
	
	# Note, the filter_collection list has been approved by Intel for their 10nm technology
	ReportUncontrolled_MemMacroPins [filter_collection [get_pins ${fname}/*] "full_name!~*/ip7431rfshpm*/iclkbyp &&
                                                                                  full_name!~*/ip7431rfshpm*/imce &&
                                                                                  full_name!~*/ip7431rfshpm*/irmce[0] &&
                                                                                  full_name!~*/ip7431rfshpm*/irmce[1] &&
                                                                                  full_name!~*/ip7431rfshpm*/isleepbias[0] &&
                                                                                  full_name!~*/ip7431rfshpm*/isleepbias[1] &&
                                                                                  full_name!~*/ip7431srmbslv*/ensleep_mc00h &&
                                                                                  full_name!~*/ip7431srmbslv*/fusedatsa_mc00b[0] &&
                                                                                  full_name!~*/ip7431srmbslv*/fusedatsa_mc00b[1] &&
                                                                                  full_name!~*/ip7431srmbslv*/fusedatsa_mc00b[2] &&
                                                                                  full_name!~*/ip7431srmbslv*/fusedatsa_mc00b[3] &&
                                                                                  full_name!~*/ip7431srmbslv*/fusedatsa_mc00b[4] &&
                                                                                  full_name!~*/ip7431srmbslv*/fusedatsa_mc00b[5] &&
                                                                                  full_name!~*/ip7431srmbslv*/slppgm_mc00h[0] &&
                                                                                  full_name!~*/ip7431srmbslv*/slppgm_mc00h[1] &&
                                                                                  full_name!~*/ip7431srmbslv*/sramvccbias[0] &&
                                                                                  full_name!~*/ip7431srmbslv*/sramvccbias[1] &&
                                                                                  full_name!~*/ip7431srmbslv*/sramvccbias[2] &&
                                                                                  full_name!~*/ip7431srmbslv*/sramvccbiasen &&
                                                                                  full_name!~*/ip7431srmbslv*/sramvccpwmod[0] &&
                                                                                  full_name!~*/ip7431srmbslv*/sramvccpwmod[1] &&
                                                                                  full_name!~*/ip7431srmbslv*/sramvccpwmod[2] &&
                                                                                  full_name!~*/ip7431srmbslv*/sramvccpwmod[3] &&
                                                                                  full_name!~*/ip7431srmbslv*/sramwlbiasloc[0] &&
                                                                                  full_name!~*/ip7431srmbslv*/sramwlbiasloc[1] &&
                                                                                  full_name!~*/*ip7431rfsstl*/rdlcpp0_fd &&
                                                                                  full_name!~*/*ip7431rfsstl*/rdlcpp0_rd &&
                                                                                  full_name!~*/*ip7431rfsstl*/rdlcpp1_fd &&
                                                                                  full_name!~*/*ip7431rfsstl*/rdlcpp1_rd &&
                                                                                  full_name!~*/*ip7431rfsstl*/wrlcpp0_fd &&
                                                                                  full_name!~*/*ip7431rfsstl*/wrlcpp0_rd &&
                                                                                  full_name!~*/*ip7431rfsstl*/wrlcpp1_fd &&
                                                                                  full_name!~*/*ip7431rfsstl*/wrlcpp1_rd"]
    }

}




###################################################################################################
# Procedure that prints large register banks (larger than $limit
###################################################################################################

proc SearchLargeRegBanks {limit} {
    
    foreach_in_collection c [get_cells -hier -filter "full_name=~*_reg* && ref_name=~ec0f*"] {
	set fname [get_attribute [get_cells $c] full_name]
	set name  [get_attribute [get_cells $c] name]

	regsub {_reg_(.*)} ${fname} "" new_name
	incr banks($new_name) 1
    }
    
    foreach key [lsort [array names banks]] {
	if { [lindex $banks($key) 0]  > $limit } {
	    set count [lindex $banks($key) 0]
	    echo "Nokia info: $count ${key}_reg* registers"
	}
	
    }

}


###################################################################################################
# Procedure that reports removed registers. Data is generated from the DC log file.
# Usage:    ReportRemovedFFs   TOP_design  report_file.rpt   detailed_report.rpt
###################################################################################################

proc ReportRemovedFFs {DESIGN_NAME output_file output_file2} {
    set total_count 0;
    
    # Open files:
    if [catch {set f_id [open ../logs/dc/dc.log r]} msg] {
	puts " Error in opening log file dc.log, $msg"
	exit
    }

    if [catch {set temp [open $output_file w+]} msg] {
	puts $msg
    }

    if [catch {set temp2 [open $output_file2 w+]} msg] {
	puts $msg
    }

    set fname ""
    
    # Process input file
    while {[gets $f_id line] >=0 } {
	if {[regexp {Processing '} $line]} {
	    regsub -all {Processing '} $line "" line
	    regsub -all {'} $line "" dname
	    set fname [get_attribute [get_cells -hier -filter ref_name==$dname] full_name]
	} 
	    
	if {[regexp {OPT-1206} $line]} {
	    regsub -all {Information: The register '} $line "" line
	    regsub -all {\' is a constant and will be removed. \(OPT-1206\)} $line "" line

	    if {[regexp {/} $line]} {
		puts $temp2 "$line"
		regsub {\w+_reg(.*)} ${line} "" new_name
		incr banks($new_name) 1
		incr total_count 1
		set fname ""
	    } else {
		puts $temp2 "${fname}/${line}"
		incr banks($fname) 1
		incr total_count 1
	    }
	    
	} elseif {[regexp {OPT-1207} $line]} {
	    regsub -all {Information: The register '} $line "" line
	    regsub -all {\' will be removed. \(OPT-1207\)} $line "" line

	    if {[regexp {/} $line]} {
		puts $temp2 "$line"
		regsub {\w+_reg(.*)} ${line} "" new_name
		incr banks($new_name) 1
		incr total_count 1
		set fname ""
	    } else {
		puts $temp2 "${fname}/${line}"
		incr banks($fname) 1
		incr total_count 1
	    }
 
	}
	
    }

    puts $temp "################################################################"
    puts $temp "# All together $total_count FFs were optimized away during synthesis"
    puts $temp "# All removed FFs are reported in synthesis log file by OPT-1206 & OPT-1207"
    puts $temp "# messages. All hierarchies, from which more than 100 FFs were removed"
    puts $temp "# Are listed below:"
    puts $temp "###############################################################"
    
    
    foreach key [lsort [array names banks]] {
	if { [lindex $banks($key) 0]  > 100 } {
	    set count [lindex $banks($key) 0]
	    puts $temp "\t $count \t removed registers were at this hierarchy level: ${DESIGN_NAME}/${key} "
	}	
    }


    # Close opened log file
    close $f_id
    close $temp
    close $temp2
    
}


###################################################################################################
# Procedure that checks design for unconstrained timing endpoints (ffs, IOs, etc)
###################################################################################################
proc check_unconstrained_endpoints { args } {

    global input_clock_ports_list
    global output_clock_ports_list
    global reset_ports_list

    parse_proc_arguments -args $args arguments

    set ios [sort_collection [get_ports *] full_name]
    if {[info exists input_clock_ports_list]} {
	set ios [remove_from_collection $ios $input_clock_ports_list]
    }
    if {[info exists reset_ports_list]} {
	set ios [remove_from_collection $ios $reset_ports_list]
    }
    if {[info exists output_clock_ports_list]} {
	set ios [remove_from_collection $ios $output_clock_ports_list]
    }

    set uio ""
    foreach_in_collection p $ios {
	if {[get_attribute $p max_slack] == "INFINITY"} {
	    if { [sizeof_collection [get_nets -quiet -of [get_ports $p]]] && [sizeof_collection [all_connected -leaf [get_nets -quiet -of [get_ports $p]]]] > 1 } {
		#echo "[get_attribute $p full_name]"
		lappend uio [get_attribute $p full_name]
	    }
	}
    }
    echo "Unconstrained IOs: [llength $uio]"
    foreach c $uio { echo "$c" }

    set uio ""
    set regs [sort_collection [filter_collection [all_registers -edge_triggered] "is_black_box==false && is_positive_level_sensitive==false && is_negative_level_sensitive==false"] full_name]
    foreach_in_collection ff $regs {
	set ff_d_pins [get_pins "[get_object_name $ff]/d"]
	# If ff has an enable-pin, add it!
	if {[sizeof_collection [get_pins -quiet "[get_object_name $ff]/den"]] == 1} {
	    append_to_collection ff_d_pins [get_pins "[get_object_name $ff]/den"]
	}
	foreach_in_collection ff_d_pin $ff_d_pins {
	    if {[get_attribute $ff_d_pin max_slack] == "INFINITY"} {
		if {[get_attribute -quiet $ff_d_pin constant_value] != "0" && [get_attribute -quiet $ff_d_pin constant_value] != "1"} {
		    #echo "[get_attribute $ff_d_pin full_name]"
		    lappend uio [get_attribute $ff_d_pin full_name]
		}
	    }
	}
    }   
    echo "Unconstrained datapins on flipflops: [llength $uio]"
    foreach c $uio { echo "$c" }

    set uio ""
    set clockgates [sort_collection [get_cells * -quiet -hier -filter "@ref_name =~ ec0cilb*"] full_name]
    foreach_in_collection cg $clockgates {
	set cg_en_pins [get_pins "[get_object_name $cg]/en"]
	foreach_in_collection cg_en_pin $cg_en_pins {
	    if {[get_attribute $cg_en_pin max_slack] == "INFINITY"} {
		if {[get_attribute -quiet $cg_en_pin constant_value] != "0" && [get_attribute -quiet $cg_en_pin constant_value] != "1"} {
		    #echo "[get_attribute $cg_en_pin full_name]"
		    lappend uio [get_attribute $cg_en_pin full_name]
		}
	    }
	}
    }   
    echo "Unconstrained enables on clockgates: [llength $uio]"
    foreach c $uio { echo "$c" }


    set uio ""
    set latches [sort_collection [get_cells * -quiet -hier -filter "@ref_name =~ ec0lsw*"] full_name]
    foreach_in_collection ll $latches {
	set ll_d_pins [get_pins "[get_object_name $ll]/d"]
	foreach_in_collection ll_d_pin $ll_d_pins {
	    if {[get_attribute $ll_d_pin max_slack] == "INFINITY"} {
		if {[get_attribute -quiet $ll_d_pin constant_value] != "0" && [get_attribute -quiet $ll_d_pin constant_value] != "1"} {
		    #echo "[get_attribute $ll_d_pin full_name]"
		    lappend uio [get_attribute $ll_d_pin full_name]
		}
	    }
	}
    }   
    echo "Unconstrained datapins on latches: [llength $uio]"
    foreach c $uio { echo "$c" }


    set uio ""
    set memories [sort_collection [get_cells * -quiet -hierarchical -filter "ref_name=~ip7431* && is_hierarchical==false"] full_name]
    foreach_in_collection mem $memories {
	# do not include always-on pins which are driven by latches in wrappers
	set mem_d_pins [get_pins "[get_attribute $mem full_name]/*" -filter "direction==in && @is_data_pin && \
            full_name!~*/fusedatsa_mc00b[0] && \
	    full_name!~*/fusedatsa_mc00b[*] && \
	    full_name!~*/slppgm_mc00h[*] && \
	    full_name!~*/sramvccbias[*] && \
	    full_name!~*/sramvccbiasen && \
	    full_name!~*/sramvccpwmod[*] && \
	    full_name!~*/sramwlbiasloc[*]"]
	
	foreach_in_collection mem_d_pin $mem_d_pins {
	    if {[get_attribute $mem_d_pin max_slack] == "INFINITY"} {
		if {[get_attribute -quiet $mem_d_pin constant_value] != "0" && [get_attribute -quiet $mem_d_pin constant_value] != "1"} {
		    #echo "[get_attribute $mem_d_pin full_name]"
		    lappend uio [get_attribute $mem_d_pin full_name]
		}
	    }
	}
    }   
    echo "Unconstrained pins on memories: [llength $uio]"
    foreach c $uio { echo "$c" }
    
    set uio ""
    set macros [sort_collection [get_cells * -quiet -hierarchical -filter "ref_name!~ip7431* && is_hierarchical==false && is_black_box==true && ref_name!~ec0fmw*"] full_name]
    foreach_in_collection macro $macros {
	set macro_d_pins [get_pins "[get_attribute $macro full_name]/*" -filter "direction==in && @is_data_pin"]

	foreach_in_collection macro_d_pin $macro_d_pins {
	    if {[get_attribute $macro_d_pin max_slack] == "INFINITY"} {
		if {[get_attribute -quiet $macro_d_pin constant_value] != "0" && [get_attribute -quiet $macro_d_pin constant_value] != "1"} {
		    #echo "[get_attribute $macro_d_pin full_name]"
		    lappend uio [get_attribute $macro_d_pin full_name]
		}
	    }
	}
    }   
    echo "Unconstrained pins on macros: [llength $uio]"
    foreach c $uio { echo "$c" }
}

define_proc_attributes check_unconstrained_endpoints  \
	-define_args {
	}

######################################################################################################################
## Print register fanins
######################################################################################################################
proc dc_print_register_fanins { args } {

    # Parse arguments
    parse_proc_arguments -args $args results

    set MIN_LIMIT 32
    if {[info exists results(-min_limit)]} {
	set MIN_LIMIT $results(-min_limit)
    }

    set MAX_LIMIT 31
    if {[info exists results(-max_limit)]} {
	set MAX_LIMIT $results(-max_limit)
    }

    echo "#########################"
    echo "# Format:"
    echo "#########################"
    echo "# register_input_pin: (fanin number)"
    echo "#     =: fanin_register_clkpin"
    echo "#########################"
    
    set TECH_CLKGATE_CELL "ec0cilb*"
    set TECH_D_PIN "d"
    set TECH_ENABLE_PIN "en"
    set TECH_DENABLE_PIN "den"
    
    set i 0
    set regs [filter_collection [all_registers -edge_triggered] "is_black_box==false"]
    append_to_collection regs [get_cells * -quiet -hier -filter "@ref_name =~ $TECH_CLKGATE_CELL"]
    set num_regs [sizeof_collection $regs]
    
    array unset reg_fanin_reg_array
    array unset reg_fanin_nmbr_array

    foreach_in_collection ff $regs {

	# TECH DEPENDENT PIN NAMES!
	if {[sizeof_collection [get_pins -quiet "[get_object_name $ff]/$TECH_D_PIN"]] == 1} {
	    set ff_d_pins [get_pins "[get_object_name $ff]/$TECH_D_PIN"]
	} else {
	    set ff_d_pins [get_pins "[get_object_name $ff]/$TECH_ENABLE_PIN"]
	}
	# If ff has an enable-pin, add it!
	if {[sizeof_collection [get_pins -quiet "[get_object_name $ff]/$TECH_DENABLE_PIN"]] == 1} {
	    append_to_collection ff_d_pins [get_pins "[get_object_name $ff]/$TECH_DENABLE_PIN"]
	}
	
	set ff_d_pins_tie [get_attribute $ff_d_pins constant_value -quiet]
	
	if { ![sizeof_collection $ff_d_pins] || ![string match $ff_d_pins_tie ""] } {
	    continue
	}
	
	foreach_in_collection ff_d_pin $ff_d_pins {
	    set fanin_nmbr [sizeof_collection [all_fanin -flat -to $ff_d_pin -startpoints_only]]

	    set reg_fanin_nmbr_array([get_attribute $ff_d_pin full_name]) $fanin_nmbr
	    set reg_fanin_reg_array([get_attribute $ff_d_pin full_name]) [sort_collection -dictionary [all_fanin -flat -to $ff_d_pin -startpoints_only] full_name]
	}
    }

    # sort arrays
    set l [array get reg_fanin_nmbr_array]
    set lsorted [lsort -stride 2 -integer -decreasing -index 1 $l]
    foreach {reg fnmbr} $lsorted {
	echo "${reg}: (${fnmbr})"
    }

    echo ""
    echo "VERBOSE REPORT LIMITS: MAX=${MAX_LIMIT}, MIN=${MIN_LIMIT}"
    echo ""

    foreach {reg fnmbr} $lsorted {
	if {$fnmbr >= $MIN_LIMIT && $fnmbr <= $MAX_LIMIT} {
	    echo "${reg}: (${fnmbr})"
	    if {[info exists reg_fanin_reg_array($reg)]} {
		set fanins $reg_fanin_reg_array($reg)
		foreach_in_collection freg $fanins {
		    echo "     =: [get_attribute $freg full_name]"
		}
	    }
	}
    }
}

define_proc_attributes dc_print_register_fanins \
    -info "Procedure for printing register fanins." \
    -define_args {
	{-min_limit "verbose print regs which have more registers than this" "" int optional}
	{-max_limit "verbose print regs which have less registers than this" "" int optional}
    }
