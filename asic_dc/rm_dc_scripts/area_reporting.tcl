########################################################################################################################
# Generate hierarchical report for design that contains following info:
#
# Total area (0), Gate count (1), combinational area (2), sequential area (3), hardmacro area (4), memory area (5), instance count (6), sequential cell count (7), flip flop count (8), leakage (9), reference name (10), 1RW memory count (11), 1R1W memory count (12), 2RW memory count (13), Total memory count (14), 1RW bit count (15), 1R1W bit count (16), 2RW bit count (17), Total bit count (18)
#
# USAGE:
# source /path/to/your/location/tech_bm_repository/tcl/procedures.tcl
# source /path/to/your/location/tech_bm_repository/tcl/area_reporting.tcl
#
# unset dataArray
# create_design_data dataArray 200 1  // 200 = max std cell area, 1/0 = enable/disable leakage power calculation  
#
# report_design_data dataArray 200 2 > hier_report.csv // report 2 top hier levels to 'hier_report.csv', 200 is max std area
# report_design_data dataArray 200 3 > hier_report.csv // report 3 top hier levels to 'hier_report.csv', 200 is max std area
#
########################################################################################################################

proc get_upcells {c_in} {

    # Find upper level hierarchical cells
    set c [get_cells $c_in]
    set c_fn [get_attribute $c full_name]
    set c_out ""
    while { [regexp {(.*)/(.*)} $c_fn f1 c_fn f3] } {
	lappend c_out $c_fn
    }
    return $c_out
}

set m_1rw_cnt 0
set m_1r1w_cnt 0
set m_2rw_cnt 0
set m_total_cnt 0
set m_1rw_bit_cnt 0
set m_1r1w_bit_cnt 0
set m_2rw_bit_cnt 0
set m_total_bit_cnt 0

proc extract_memory_info {c_rn} {
    
    global m_1rw_cnt
    global m_1r1w_cnt
    global m_2rw_cnt
    global m_total_cnt
    global m_1rw_bit_cnt
    global m_1r1w_bit_cnt
    global m_2rw_bit_cnt
    global m_total_bit_cnt
    
    # 10nm & tsmc 5nm Memories
    if { [regexp {TS6N05} $c_rn] } {
	set m_1rw_cnt  0
	set m_1r1w_cnt 1
	set m_2rw_cnt  0
	set m_total_cnt 1
#	regexp {ip743(1|)rfshpm1r1w(\D*)(\d*)x(\d*)(.*)} $c_rn full_string f0 f1 width depth f4
	regexp {TS6N05(\D*)VT(\D)(\d*)X(\d*)(.*)}  $c_rn full_string f0 f1  depth width f4
	set m_1rw_bit_cnt 0
	set m_1r1w_bit_cnt [expr $width * $depth]
	set m_2rw_bit_cnt 0
	set m_total_bit_cnt [expr $width * $depth]
    } elseif { [regexp {ip743(1|)rfsstl2r2w} $c_rn] } {
	set m_1rw_cnt  0
	set m_1r1w_cnt 0
	set m_2rw_cnt  1
	set m_total_cnt 1
	regexp {ip743(1|)rfsstl2r2w(\D*)(\d*)x(\d*)(.*)} $c_rn full_string f0 f1 width depth f4
	set m_1rw_bit_cnt 0
	set m_1r1w_bit_cnt 0
	set m_2rw_bit_cnt [expr $width * $depth]
	set m_total_bit_cnt [expr $width * $depth]
    } elseif { [regexp {TS1N05} $c_rn] } {
	set m_1rw_cnt  1
	set m_1r1w_cnt 0
	set m_2rw_cnt  0
	set m_total_cnt 1
	#regexp {ip743(1|)srmbdlv(\D*)(\d*)x(\d*)(.*)} $c_rn full_string f0 f1 width depth f4
	regexp {TS1N05(\D*)VT(\D)(\d*)X(\d*)(.*)}  $c_rn full_string f0 f1  depth width f4
	set m_1rw_bit_cnt [expr $width * $depth]
	set m_1r1w_bit_cnt 0
	set m_2rw_bit_cnt 0
	set m_total_bit_cnt [expr $width * $depth]
    } elseif { [regexp {ip743(1|)srmbslv} $c_rn] } {
	set m_1rw_cnt  1
	set m_1r1w_cnt 0
	set m_2rw_cnt  0
	set m_total_cnt 1
	regexp {ip743(1|)srmbslv(\D*)(\d*)x(\d*)(.*)} $c_rn full_string f0 f1 width depth f4
	set m_1rw_bit_cnt [expr $width * $depth]
	set m_1r1w_bit_cnt 0
	set m_2rw_bit_cnt 0
	set m_total_bit_cnt [expr $width * $depth]
    } elseif { [regexp {ip743(1|)srhsshp} $c_rn] } {
	set m_1rw_cnt  1
	set m_1r1w_cnt 0
	set m_2rw_cnt  0
	set m_total_cnt 1
        regexp {ip743(1|)srhsshp(\D*)(\d*)x(\d*)(.*)} $c_rn full_string f0 f1 width depth f4
	set m_1rw_bit_cnt [expr $width * $depth]
	set m_1r1w_bit_cnt 0
	set m_2rw_bit_cnt 0
	set m_total_bit_cnt [expr $width * $depth]
    } else {
	# Hardmacro
	set m_1rw_cnt  0
	set m_1r1w_cnt 0
	set m_2rw_cnt  0
	set m_total_cnt 0
	set m_1rw_bit_cnt 0
	set m_1r1w_bit_cnt 0
	set m_2rw_bit_cnt 0
	set m_total_bit_cnt 0
    }

}


proc create_design_data {dataArray_in max_std_cell_area power} {
    
    global m_1rw_cnt
    global m_1r1w_cnt
    global m_2rw_cnt
    global m_total_cnt
    global m_1rw_bit_cnt
    global m_1r1w_bit_cnt
    global m_2rw_bit_cnt
    global m_total_bit_cnt

    if {$power} {
	set power_enable_analysis true
	set_app_var power_analysis_mode averaged
	set_power_analysis_options -static_leakage_only
    }

    # Use smallest nand2 area for technology gate count calculation
    set nand2_area [get_attribute [get_lib_cells tcbn05_bwph210l6p51cnod_base_lvtllssgnp_0p675v_m40c_cworst_CCworst_T_ccs/ND2D2BWP210H6P51CNODLVTLL] area]

    # Create array for design data
    # Fields : Total area (0), Gate count (1), combinational area (2), sequential area (3), hardmacro area (4), memory area (5), instance count (6), sequential cell count (7), flip flop count (8), leakage (9), reference name (10), 1RW memory count (11), 1R1W memory count (12), 2RW memory count (13), Total memory count (14), 1RW bit count (15), 1R1W bit count (16), 2RW bit count (17), Total bit count (18)
    upvar $dataArray_in dataArray
    
    foreach_in_collection c [get_cells -hierarchical -filter "is_hierarchical == true"] {
	set c_fn [get_attribute $c full_name]
	set c_rn [get_attribute $c ref_name]
	set dataArray($c_fn) [list 0 0 0 0 0 0 0 0 0 0 $c_rn 0 0 0 0 0 0 0 0]
    }

    # Memory & hard macro info gathering
    foreach_in_collection c [get_cells -hierarchical -filter "area > $max_std_cell_area && is_hierarchical == false"] {
	set c_fn [get_attribute $c full_name]
	set c_rn [get_attribute $c ref_name]
	set c_area [get_attribute $c area]
	set c_leakage [get_attribute -quiet $c leakage_power]
	
	if {$c_area == ""} {set c_area 0}
	if {$c_leakage == ""} {set c_leakage 0}

	extract_memory_info $c_rn
	
	if {[regexp {^ip743(1|)\S+\d+x\d+} $c_rn]} {
	    # memory
	    set dataArray($c_fn) [list $c_area 0 0 0 0 $c_area 1 0 0 $c_leakage $c_rn $m_1rw_cnt $m_1r1w_cnt $m_2rw_cnt $m_total_cnt $m_1rw_bit_cnt $m_1r1w_bit_cnt $m_2rw_bit_cnt $m_total_bit_cnt]
	} else {
	    # else it's a hard macro
	    set dataArray($c_fn) [list $c_area 0 0 0 $c_area 0 1 0 0 $c_leakage $c_rn $m_1rw_cnt $m_1r1w_cnt $m_2rw_cnt $m_total_cnt $m_1rw_bit_cnt $m_1r1w_bit_cnt $m_2rw_bit_cnt $m_total_bit_cnt]
	}
    }
    
    set leaf_count [sizeof_collection [get_cells -hierarchical -filter "is_hierarchical == false && ref_name != **logic_0** && ref_name != **logic_1**"]]
    set i 0
    set j 0.01
    
    echo "NSN-INFO: Generating design data for leaf cells..."
    # Hierarchical cells info gathering
    foreach_in_collection c [get_cells -hierarchical -filter "is_hierarchical == false && ref_name != **logic_0** && ref_name != **logic_1**"] {
	incr i

	if {$i > [expr $j * $leaf_count]} {
	    set percentage [expr $j * 100]
	    echo "NSN-INFO: $percentage % of leaf cells processed ($i / $leaf_count cells)"
	    set j [expr $j + 0.01]
	}
	
	set c_rn [get_attribute -quiet $c ref_name]
	set c_area [get_attribute -quiet $c area]
	set c_seq [get_attribute -quiet $c is_sequential]
	set c_leakage [get_attribute -quiet $c leakage_power]

#	set c_gcount [expr $c_area / $nand2_area]

	if {$c_area == ""} {set c_area 0}
	if {$c_leakage == ""} {set c_leakage 0}

	set c_gcount [expr $c_area / $nand2_area]

	foreach c_upcell [get_upcells $c] {

	    # This if is needed, since all upcells doesn't necessarily exist (e.g. if ILM models are used for some component)
	    if {[sizeof_collection [get_cells -quiet $c_upcell]]} {

		set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 6 6 [expr [lindex $dataArray($c_upcell) 6] + 1]]
		set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 9 9 [expr [lindex $dataArray($c_upcell) 9] + $c_leakage]]
		if { $c_area > $max_std_cell_area } {

		    extract_memory_info $c_rn
		    
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 0 0   [expr [lindex $dataArray($c_upcell) 0]  + $c_area]]
		    if {[regexp {^ip743(1|)\S+\d+x\d+} $c_rn]} {
			# memory
			set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 5 5   [expr [lindex $dataArray($c_upcell) 5]  + $c_area]]
		    } else {
			# hard macro
			set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 4 4   [expr [lindex $dataArray($c_upcell) 4]  + $c_area]]
		    }
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 11 11 [expr [lindex $dataArray($c_upcell) 11] + $m_1rw_cnt]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 12 12 [expr [lindex $dataArray($c_upcell) 12] + $m_1r1w_cnt]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 13 13 [expr [lindex $dataArray($c_upcell) 13] + $m_2rw_cnt]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 14 14 [expr [lindex $dataArray($c_upcell) 14] + $m_total_cnt]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 15 15 [expr [lindex $dataArray($c_upcell) 15] + $m_1rw_bit_cnt]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 16 16 [expr [lindex $dataArray($c_upcell) 16] + $m_1r1w_bit_cnt]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 17 17 [expr [lindex $dataArray($c_upcell) 17] + $m_2rw_bit_cnt]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 18 18 [expr [lindex $dataArray($c_upcell) 18] + $m_total_bit_cnt]]
		    
		} elseif { [string match $c_seq "true"] } {
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 0 0 [expr [lindex $dataArray($c_upcell) 0] + $c_area]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 1 1 [expr [lindex $dataArray($c_upcell) 1] + $c_gcount]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 3 3 [expr [lindex $dataArray($c_upcell) 3] + $c_area]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 7 7 [expr [lindex $dataArray($c_upcell) 7] + 1]]
		} else {
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 0 0 [expr [lindex $dataArray($c_upcell) 0] + $c_area]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 1 1 [expr [lindex $dataArray($c_upcell) 1] + $c_gcount]]
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 2 2 [expr [lindex $dataArray($c_upcell) 2] + $c_area]]		
		}
		if { [string match $c_seq "true"] && (! [regexp {CLKSG} $c_rn]) } {
		    set dataArray($c_upcell) [lreplace $dataArray($c_upcell) 8 8 [expr [lindex $dataArray($c_upcell) 8] + 1]]		    
		}
	    }
	}
    }
    # TOP level cells
    set TOP_rn [get_attribute [current_design] full_name]
    set dataArray(TOP) [list 0 0 0 0 0 0 0 0 0 0 $TOP_rn 0 0 0 0 0 0 0 0]

    # Pure TOP level cells
    foreach_in_collection c [get_cells -filter "is_hierarchical == false && ref_name != **logic_0** && ref_name != **logic_1**"] {
	set c_area [get_attribute -quiet $c area]
	set c_seq [get_attribute -quiet $c is_sequential]
	set c_leakage [get_attribute -quiet $c leakage_power]

	set c_gcount [expr $c_area / $nand2_area]

	if {$c_area == ""} {set c_area 0}
	if {$c_leakage == ""} {set c_leakage 0}
	
	set dataArray(TOP) [lreplace $dataArray(TOP) 6 6 [expr [lindex $dataArray(TOP) 6] + 1]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 9 9 [expr [lindex $dataArray(TOP) 9] + $c_leakage]]
	
	if { $c_area > $max_std_cell_area && ![regexp {^ip743(1|)\S+\d+x\d+} $c_rn] } {
	    
	    extract_memory_info $c_rn
	    
	    set dataArray(TOP) [lreplace $dataArray(TOP) 0 0   [expr [lindex $dataArray(TOP) 0]  + $c_area]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 4 4   [expr [lindex $dataArray(TOP) 4]  + $c_area]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 11 11 [expr [lindex $dataArray(TOP) 11] + $m_1rw_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 12 12 [expr [lindex $dataArray(TOP) 12] + $m_1r1w_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 13 13 [expr [lindex $dataArray(TOP) 13] + $m_2rw_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 14 14 [expr [lindex $dataArray(TOP) 14] + $m_total_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 15 15 [expr [lindex $dataArray(TOP) 15] + $m_1rw_bit_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 16 16 [expr [lindex $dataArray(TOP) 16] + $m_1r1w_bit_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 17 17 [expr [lindex $dataArray(TOP) 17] + $m_2rw_bit_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 18 18 [expr [lindex $dataArray(TOP) 18] + $m_total_bit_cnt]]
	    
	} elseif { $c_area > $max_std_cell_area && [regexp {^ip743(1|)\S+\d+x\d+} $c_rn] } {
	    
	    extract_memory_info $c_rn
	    
	    set dataArray(TOP) [lreplace $dataArray(TOP) 0 0   [expr [lindex $dataArray(TOP) 0]  + $c_area]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 5 5   [expr [lindex $dataArray(TOP) 5]  + $c_area]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 11 11 [expr [lindex $dataArray(TOP) 11] + $m_1rw_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 12 12 [expr [lindex $dataArray(TOP) 12] + $m_1r1w_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 13 13 [expr [lindex $dataArray(TOP) 13] + $m_2rw_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 14 14 [expr [lindex $dataArray(TOP) 14] + $m_total_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 15 15 [expr [lindex $dataArray(TOP) 15] + $m_1rw_bit_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 16 16 [expr [lindex $dataArray(TOP) 16] + $m_1r1w_bit_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 17 17 [expr [lindex $dataArray(TOP) 17] + $m_2rw_bit_cnt]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 18 18 [expr [lindex $dataArray(TOP) 18] + $m_total_bit_cnt]]
	    
	} elseif { [string match $c_seq "true"] } {
	    set dataArray(TOP) [lreplace $dataArray(TOP) 0 0 [expr [lindex $dataArray(TOP) 0] + $c_area]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 1 1 [expr [lindex $dataArray(TOP) 1] + $c_gcount]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 3 3 [expr [lindex $dataArray(TOP) 3] + $c_area]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 7 7 [expr [lindex $dataArray(TOP) 7] + 1]]
	} else {
	    set dataArray(TOP) [lreplace $dataArray(TOP) 0 0 [expr [lindex $dataArray(TOP) 0] + $c_area]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 1 1 [expr [lindex $dataArray(TOP) 1] + $c_gcount]]
	    set dataArray(TOP) [lreplace $dataArray(TOP) 2 2 [expr [lindex $dataArray(TOP) 2] + $c_area]]		
	}
	if { [string match $c_seq "true"] && (! [regexp {CLKSG} $c_rn]) } {
	    set dataArray(TOP) [lreplace $dataArray(TOP) 8 8 [expr [lindex $dataArray(TOP) 8] + 1]]		    
	}
	
    }
    
    # Use first level hierarchical cells data
    foreach_in_collection c [get_cells -filter "is_hierarchical == true"] {
	set c_fn [get_attribute $c full_name]
	set dataArray(TOP) [lreplace $dataArray(TOP) 0 0 [expr [lindex $dataArray(TOP) 0] + [lindex $dataArray($c_fn) 0]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 1 1 [expr [lindex $dataArray(TOP) 1] + [lindex $dataArray($c_fn) 1]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 2 2 [expr [lindex $dataArray(TOP) 2] + [lindex $dataArray($c_fn) 2]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 3 3 [expr [lindex $dataArray(TOP) 3] + [lindex $dataArray($c_fn) 3]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 4 4 [expr [lindex $dataArray(TOP) 4] + [lindex $dataArray($c_fn) 4]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 5 5 [expr [lindex $dataArray(TOP) 5] + [lindex $dataArray($c_fn) 5]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 6 6 [expr [lindex $dataArray(TOP) 6] + [lindex $dataArray($c_fn) 6]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 7 7 [expr [lindex $dataArray(TOP) 7] + [lindex $dataArray($c_fn) 7]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 8 8 [expr [lindex $dataArray(TOP) 8] + [lindex $dataArray($c_fn) 8]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 9 9 [expr [lindex $dataArray(TOP) 9] + [lindex $dataArray($c_fn) 9]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 11 11 [expr [lindex $dataArray(TOP) 11] + [lindex $dataArray($c_fn) 11]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 12 12 [expr [lindex $dataArray(TOP) 12] + [lindex $dataArray($c_fn) 12]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 13 13 [expr [lindex $dataArray(TOP) 13] + [lindex $dataArray($c_fn) 13]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 14 14 [expr [lindex $dataArray(TOP) 14] + [lindex $dataArray($c_fn) 14]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 15 15 [expr [lindex $dataArray(TOP) 15] + [lindex $dataArray($c_fn) 15]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 16 16 [expr [lindex $dataArray(TOP) 16] + [lindex $dataArray($c_fn) 16]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 17 17 [expr [lindex $dataArray(TOP) 17] + [lindex $dataArray($c_fn) 17]]]
	set dataArray(TOP) [lreplace $dataArray(TOP) 18 18 [expr [lindex $dataArray(TOP) 18] + [lindex $dataArray($c_fn) 18]]]
    }

}


proc report_design_data { dataArray_in min_total_area hier_levels} {
    upvar $dataArray_in dataArray
    echo "Instance name; Total area; Gate count; Combinational area; Sequential area; Hardmacro area; Memory area; Instance count; Sequential cell count; Flip flop count; Leakage; Reference name; 1RW memory count; 1R1W memory count; 2RW memory count; Total memory count; 1RW bit count; 1R1W bit count; 2RW bit count; Total bit count"
    set key TOP
    echo "$key; [join $dataArray($key) "; "]"
    foreach key [lsort [array names dataArray]] {
	if { [lindex $dataArray($key) 0] > $min_total_area } {
	    set hier_stage [regexp -all {/} $key]
	    if { ( $hier_stage < $hier_levels ) && ( ! [string match $key "TOP"] ) } {
		echo "$key; [join $dataArray($key) "; "]"
	    }
	}
    }
}

###########################################################################################################
#       __  ____ __                 __ __ _ __ 
#      /  |/  (_) /______ ______   / //_/(_) /_
#     / /|_/ / / //_/ __ `/ ___/  / ,<  / / __/
#    / /  / / / ,< / /_/ (__  )  / /| |/ / /_  
#   /_/  /_/_/_/|_|\__,_/____/  /_/ |_/_/\__/  
#                                           
#                  RULES!!!!!!!
###########################################################################################################


