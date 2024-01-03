/*

*/
class psinr_env_cfg extends uvm_object;
`uvm_object_utils(psinr_env_cfg)

    // ------------------------------------------------------------------------
    // Attributes
    // ------------------------------------------------------------------------
    string                                                         env_mp_path_q[$];
    logic [8:0]                                                    env_num_rb_q[$];
    logic [3:0]                                                    env_num_layers_q[$];
    logic [3:0]                                                    env_num_symbs_q[$];
    int                                                            env_num_res;
    bit                                                            env_cpofdm_q[$];
    logic [3:0]                                                    env_processing_type_q[$];
    int                                                            env_num_task;
    //combiner interfce
    virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)        m_combiner_input_vif;
    virtual axi_stream_if#(BETA_CFG_WIDTH)                         m_combiner_cfg_vif;
    virtual axi_stream_if#(BETA_REPC_WIDTH)                        m_combiner_repc_vif;
    virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)        m_combiner_output_vif;
    virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)        m_combiner_gain_vif;
    //psinr interfce
    virtual axi_stream_if#(BETA_CFG_WIDTH)                         m_psinr_cfg_vif;
    virtual axi_stream_if#(PSINR_DEMAP_WIDTH)                      m_psinr_demap_vif;
    virtual axi_stream_if#(PSINR_CALC_WIDTH)                       m_psinr_out_vif;
    virtual axi_stream_if#(PSINR_CALC_WIDTH)                       m_psinr_demod_vif;
    //psinr out interface
    virtual axi_stream_if#(BETA_CFG_WIDTH)                         m_psinr_out_cfg_vif;
    virtual axi_stream_if#(3*PSINR_OUT_UCI_WIDTH)                  m_psinr_out_uci_vif;
    virtual axi_stream_if#(PSINR_OUT_REPORT_WIDTH)                 m_psinr_out_report_vif;

    

    extern function new(string name = "psinr_env_cfg");
endclass : psinr_env_cfg


// ----------------------------------------------------------------------------
function psinr_env_cfg::new(string name = "psinr_env_cfg");
    super.new(name);
endfunction : new