set DONT_USE_CELLS [list */*D1BWP* */*D24BWP* */*D28BWP* */*AO*D2BWP* */*OA*D2BWP* */CKBD* */CKND* */*CKL*QD*DLVTLL */*DEL* */*ANTENNA* */*CAP*]
if {[info exists DONT_USE_CELLS]} {
    set_dont_use [get_lib_cells $DONT_USE_CELLS]
}
