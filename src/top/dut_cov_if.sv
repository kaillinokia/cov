/*------------------------------------------------------------------------------

*/

`ifndef _DUT_COV_IF_
`define _DUT_COV_IF_

// ----------------------------------------------------------------------------
// Interface Definition
// ----------------------------------------------------------------------------
interface dut_cov_if;

    bit           clk;
    bit           rst;
    bit           arst_n;
    
    bit [31:0]    comb_cfg;
    bit           comb_cfg_valid;
    bit           comb_cfg_ready;
    bit [31:0]    psinr_cfg;
    bit           psinr_cfg_valid;
    bit           psinr_cfg_ready;
    bit           comb_status_tvalid;
    bit [11:0]    comb_status_tdata ;
    bit           comb_status_tready;
    bit           psinr_calc_status_tvalid;
    bit [9:0]     psinr_calc_status_tdata ;
    bit           psinr_calc_status_tready;
    bit           psinr_out_status_tvalid;
    bit [6:0]     psinr_out_status_tdata ;
    bit           psinr_out_status_tready;


    
endinterface

`endif //_DUT_COV_IF_
