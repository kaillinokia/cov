/*------------------------------------------------------------------------------

*/
`ifndef __PSINR_TC_PKG_SV
`define __PSINR_TC_PKG_SV
package psinr_tc_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    import params_share_pkg::*;
    import psinr_seq_pkg::*;
    import psinr_env_pkg::*;
    `include "psinr_test_base.svh"
    `include "psinr_normal_tc.svh"
    `include "psinr_bp_tc.svh"
    `include "psinr_mis_tc.svh"
    `include "psinr_err_tc.svh"

endpackage

`endif