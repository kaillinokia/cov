/*------------------------------------------------------------------------------
*/

`ifndef _PARAMS_SHARE_PKG_
`define _PARAMS_SHARE_PKG_


// ----------------------------------------------------------------------------
// Package Definition
// ----------------------------------------------------------------------------
package params_share_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    parameter CLK_CYCLE   = 3ns;  //300MHz

    parameter RE_NUM = `NUM_PARA_RE;
    parameter REIAMG_WIDTH      = 15;
    parameter EXP_WIDTH         = 8;
    parameter BETA_INOUT_WIDTH  = RE_NUM*REIAMG_WIDTH;
    parameter BETA_EXP_WIDTH    = RE_NUM*EXP_WIDTH;
    parameter BETA_OUT_MP_WIDTH = RE_NUM*16;
    parameter BETA_FILE_WIDTH   = RE_NUM*(REIAMG_WIDTH+1);
    parameter BETA_CFG_WIDTH    = 32;
    parameter PSINR_UCI_WIDTH   = 256;
    parameter BETA_REPC_WIDTH   = 32;
    parameter PSINR_CALC_WIDTH  = 16;
    parameter PSINR_DEMAP_WIDTH  = 16*RE_NUM;
    parameter BETA_INT_WIDTH    = 32;
    // parameter PSINR_OUT_REPORT_WIDTH = RE_NUM*16;
    parameter PSINR_OUT_REPORT_WIDTH = RE_NUM*32;
    parameter PSINR_OUT_UCI_WIDTH = 256;

    parameter COMB_STATUS_WIDTH  = 12;
    parameter PSINR_CALC_STATUS_WIDTH  = 10;
    parameter PSINR_OUT_STATUS_WIDTH  = 7;
    

    typedef int tr_cfg_t[string];           // associative array [string] = int
    typedef bit [BETA_FILE_WIDTH-1:0]       tr_data_q[$];
    typedef bit [32-1:0]                    tr_int_q[$];
    typedef bit [PSINR_OUT_UCI_WIDTH-1:0]   tr_uci_q[$];

    typedef bit [BETA_OUT_MP_WIDTH-1:0] tr_mp_q[$];
    typedef bit [PSINR_OUT_REPORT_WIDTH-1:0] tr_report_q[$];
    typedef bit [BETA_EXP_WIDTH-1:0]    tr_exp_q[$];

    typedef bit [REIAMG_WIDTH:0]        tr_reMp_q[$];


    // typedef axi_stream_seq_item#(BETA_INOUT_WIDTH)       beta_mp_trans[$];

    // typedef struct {
    //   logic                     beta_bypass;
    //   logic [1:0]               du_ru_mode;
    //   logic [3:0]               processing_type;
    //   logic [8:0]               beta_num_rb;
    //   logic [3:0]               beta_num_symb;
    //   logic [2:0]               beta_spread_seq_id;
    // } beta_cfg_type;


    `include "psinr_report_server.svh"
    `include "file_parser.svh"


endpackage: params_share_pkg

`endif // _PARAMS_SHARE_PKG_