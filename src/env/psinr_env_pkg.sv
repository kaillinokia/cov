/*------------------------------------------------------------------------------

*/
`ifndef _PSINR_ENV_PKG_
`define _PSINR_ENV_PKG_

// ----------------------------------------------------------------------------
// Package Definition
// ----------------------------------------------------------------------------
package psinr_env_pkg;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import params_share_pkg::*;
    import psinr_seq_pkg::*;

    `include "function_cov.svh"
    `include "psinr_env_cfg.svh"
    `include "axi_stream_driver.svh"
    `include "axi_stream_monitor.svh"
    `include "time_mon_cfg.svh"
    `include "time_mon_driver.svh"
    `include "combiner_sb.svh"
    `include "psinr_sb.svh"
    `include "psinr_env.svh" 
    
endpackage : psinr_env_pkg

`endif // _PSINR_ENV_PKG_
