/*------------------------------------------------------------------------------

*/
`ifndef _TB_TOP_
`define _TB_TOP_


// ----------------------------------------------------------------------------
// Module Definition
// ----------------------------------------------------------------------------
module tb_top;

    // ------------------------------------------------------------------------
    // Package Imports
    // ------------------------------------------------------------------------
    import uvm_pkg::*;
    import params_share_pkg::*;
    import psinr_tc_pkg::*;

    initial 
    begin
 
        uvm_config_db#(virtual dut_top_if            )::set(null, "", "m_dut_top_vif",        dut_top.m_dut_top_if);
        uvm_config_db#(virtual time_mon_if           )::set(null, "", "m_time_mon_vif",       dut_top.m_time_mon_if);
        //combiner interface
        uvm_config_db#(virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH))::set(null, "", "m_combiner_input_vif", dut_top.m_comb_input_if);
        uvm_config_db#(virtual axi_stream_if#(BETA_CFG_WIDTH ))::set(null, "", "m_combiner_cfg_vif", dut_top.m_comb_cfg_if);
        // uvm_config_db#(virtual axi_stream_if#(BETA_REPC_WIDTH))::set(null, "", "m_combiner_repc_vif", dut_top.m_comb_repc_if);
        uvm_config_db#(virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH))::set(null, "", "m_combiner_output_vif", dut_top.m_comb_output_if);
        uvm_config_db#(virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH))::set(null, "", "m_combiner_gain_vif", dut_top.m_comb_gain_if);
        uvm_config_db#(virtual axi_stream_if#(COMB_STATUS_WIDTH))::set(null, "", "m_combiner_status_vif", dut_top.m_comb_status_if);
        //psinr interface
        uvm_config_db#(virtual axi_stream_if#(BETA_CFG_WIDTH ))::set(null, "", "m_psinr_cfg_vif", dut_top.m_psinr_cfg_if);
        uvm_config_db#(virtual axi_stream_if#(PSINR_DEMAP_WIDTH))::set(null, "", "m_psinr_demap_vif", dut_top.m_psinr_demap_if);
        uvm_config_db#(virtual axi_stream_if#(PSINR_CALC_WIDTH))::set(null, "", "m_psinr_out_vif", dut_top.m_psinr_out_if);
        uvm_config_db#(virtual axi_stream_if#(PSINR_CALC_WIDTH))::set(null, "", "m_psinr_demod_vif", dut_top.m_psinr_demod_if);
        uvm_config_db#(virtual axi_stream_if#(PSINR_CALC_STATUS_WIDTH))::set(null, "", "m_psinr_calc_status_vif", dut_top.m_psinr_calc_status_if);
        //psinr out interface
        uvm_config_db#(virtual axi_stream_if#(BETA_CFG_WIDTH ))::set(null, "", "m_psinr_out_cfg_vif", dut_top.m_psinr_out_cfg_if);
        uvm_config_db#(virtual axi_stream_if#(3*PSINR_OUT_UCI_WIDTH))::set(null, "", "m_psinr_out_uci_vif", dut_top.m_psinr_out_uci_if);
        uvm_config_db#(virtual axi_stream_if#(PSINR_OUT_REPORT_WIDTH))::set(null, "", "m_psinr_out_report_vif", dut_top.m_psinr_out_report_if);
        uvm_config_db#(virtual axi_stream_if#(PSINR_OUT_STATUS_WIDTH))::set(null, "", "m_psinr_out_status_vif", dut_top.m_psinr_out_status_if);
        //psinr out back pressure
        uvm_config_db#(virtual back_pressure_if )::set(null, "", "m_psinr_bp_vif", dut_top.m_psinr_bp_if);
        //dut coverage interface
        uvm_config_db#(virtual dut_cov_if )::set(null, "uvm_test_top.m_psinr_env.psinr_func_cov", "m_dut_cov_vif", dut_top.m_dut_cov_if);
        run_test();
    end

endmodule:tb_top
`endif