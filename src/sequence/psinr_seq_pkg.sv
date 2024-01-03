/*------------------------------------------------------------------------------

*/
`ifndef _PSINR_SEQ_PKG_
`define _PSINR_SEQ_PKG_

// ----------------------------------------------------------------------------
// Package Definition
// ----------------------------------------------------------------------------
package psinr_seq_pkg;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import params_share_pkg::*;

    `include "axi_stream_seq_item.svh"
    `include "axi_stream_sequencer.svh"
    `include "axi_stream_seq.svh"
    `include "time_mon_seq_item.svh"
    `include "time_mon_sequencer.svh"
    `include "time_mon_seq.svh"
    
endpackage : psinr_seq_pkg

`endif // _PSINR_SEQ_PKG_
