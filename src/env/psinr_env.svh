/*

*/
class psinr_env extends uvm_env;
    `uvm_component_utils(psinr_env)

    psinr_env_cfg                                                  m_psinr_env_cfg;
    //combiner 
    virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)        m_combiner_input_vif;
    virtual axi_stream_if#(BETA_CFG_WIDTH)                         m_combiner_cfg_vif;
    virtual axi_stream_if#(BETA_REPC_WIDTH)                        m_combiner_repc_vif;
    virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)        m_combiner_output_vif;
    virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)        m_combiner_gain_vif;
            
    axi_stream_driver#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)            m_combiner_driver;
    axi_stream_driver#(BETA_CFG_WIDTH)                             m_combiner_cfg_driver;
    // axi_stream_monitor#(BETA_REPC_WIDTH)                           m_combiner_repc_monitor;
    axi_stream_monitor#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)           m_combiner_monitor;
    axi_stream_monitor#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)           m_combiner_gain_monitor;
    combiner_sb                                                    m_combiner_sb;

    axi_stream_sequencer#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)         m_combiner_sqr;
    axi_stream_sequencer#(BETA_CFG_WIDTH)                          m_combiner_cfg_sqr;

    //psinr
    virtual axi_stream_if#(BETA_CFG_WIDTH)                         m_psinr_cfg_vif;
    virtual axi_stream_if#(PSINR_DEMAP_WIDTH)                      m_psinr_demap_vif;
    virtual axi_stream_if#(PSINR_CALC_WIDTH)                       m_psinr_out_vif;
    virtual axi_stream_if#(PSINR_CALC_WIDTH)                       m_psinr_demod_vif;

    virtual axi_stream_if#(BETA_CFG_WIDTH)                         m_psinr_out_cfg_vif;
    virtual axi_stream_if#(3*PSINR_OUT_UCI_WIDTH)                  m_psinr_out_uci_vif;
    virtual axi_stream_if#(PSINR_OUT_REPORT_WIDTH)                 m_psinr_out_report_vif;

    axi_stream_driver#(BETA_CFG_WIDTH)                             m_psinr_calc_cfg_driver;
    axi_stream_monitor#(PSINR_DEMAP_WIDTH)                         m_psinr_demap_monitor;
    axi_stream_monitor#(PSINR_CALC_WIDTH)                          m_psinr_out_monitor;
    axi_stream_monitor#(PSINR_CALC_WIDTH)                          m_psinr_demod_monitor;

    axi_stream_driver#(BETA_CFG_WIDTH)                             m_psinr_out_cfg_driver;
    axi_stream_driver#(3*PSINR_OUT_UCI_WIDTH)                      m_psinr_out_uci_driver;
    axi_stream_monitor#(PSINR_OUT_REPORT_WIDTH)                    m_psinr_out_report_monitor;


    psinr_sb                                                       m_psinr_sb;
    axi_stream_sequencer#(BETA_CFG_WIDTH)                          m_psinr_calc_cfg_sqr;
    axi_stream_sequencer#(BETA_CFG_WIDTH)                          m_psinr_out_cfg_sqr;
    axi_stream_sequencer#(3*PSINR_OUT_UCI_WIDTH)                   m_psinr_out_uci_sqr;

    //timer        
    time_mon_driver                                                m_time_mon_driver;
    time_mon_sequencer                                             m_time_mon_sqr;

    function_cov                                                   psinr_func_cov;

    bit                                                            scb_enable;

    extern function                         new                                     (string name = "psinr_env",uvm_component parent = null);

    // Group: UVM Phasing Interface.
    extern virtual function void            build_phase                             (uvm_phase phase);
    extern virtual function void            connect_phase                           (uvm_phase phase);

    extern virtual function void            set_virtual_interface_handles();

    extern virtual function void            init_env_component();
    extern virtual function void            init_env_cfg_para();
    
    
endclass : psinr_env

// ----------------------------------------------------------------------------
// Class Methods Implementation
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
function psinr_env::new(string name = "psinr_env", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// ----------------------------------------------------------------------------
function void psinr_env::build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(psinr_env_cfg)::get(null, "psinr_env_cfg::", "m_psinr_env_cfg", m_psinr_env_cfg)) 
    begin
        `uvm_fatal({"ENV [", get_full_name(), "]"}, {"'m_psinr_env_cfg' must be set for: ", get_full_name()})
    end
    
    init_env_component();

    set_virtual_interface_handles();

    if (scb_enable == 1) begin
        init_env_cfg_para();
    end

endfunction : build_phase

// ----------------------------------------------------------------------------
function void psinr_env::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    //combiner
    m_combiner_driver.seq_item_port.connect(m_combiner_sqr.seq_item_export);
    m_combiner_cfg_driver.seq_item_port.connect(m_combiner_cfg_sqr.seq_item_export);

    //pisnr calc
    m_psinr_calc_cfg_driver.seq_item_port.connect(m_psinr_calc_cfg_sqr.seq_item_export);
    
    //psinr out
    m_psinr_out_cfg_driver.seq_item_port.connect(m_psinr_out_cfg_sqr.seq_item_export);
    m_psinr_out_uci_driver.seq_item_port.connect(m_psinr_out_uci_sqr.seq_item_export);

    if (scb_enable == 1) begin
        m_combiner_monitor.axi_analysis_port.connect(m_combiner_sb.combiner_imp);
        m_combiner_gain_monitor.axi_analysis_port.connect(m_combiner_sb.combiner_gain_imp);
        m_psinr_out_monitor.axi_analysis_port.connect(m_psinr_sb.psinr_out_imp);
        m_psinr_demap_monitor.axi_analysis_port.connect(m_psinr_sb.psinr_demap_imp);
        m_psinr_demod_monitor.axi_analysis_port.connect(m_psinr_sb.psinr_demod_imp);
        m_psinr_out_report_monitor.axi_analysis_port.connect(m_psinr_sb.psinr_out_report_imp);
    end
    //timer
    m_time_mon_driver.seq_item_port.connect(m_time_mon_sqr.seq_item_export);

endfunction : connect_phase

//-----------------------------------------------------------------------------
function void psinr_env::set_virtual_interface_handles();
    //combiner
    m_combiner_input_vif = m_psinr_env_cfg.m_combiner_input_vif;
    uvm_config_db#(virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH) )::set(this.m_combiner_driver, "", "drv_if", m_combiner_input_vif);

    m_combiner_cfg_vif = m_psinr_env_cfg.m_combiner_cfg_vif;
    uvm_config_db#(virtual axi_stream_if#(BETA_CFG_WIDTH) )::set(this.m_combiner_cfg_driver, "", "drv_if", m_combiner_cfg_vif);

    // m_combiner_repc_vif = m_psinr_env_cfg.m_combiner_repc_vif;
    // uvm_config_db#(virtual axi_stream_if#(BETA_REPC_WIDTH) )::set(this.m_combiner_repc_monitor, "", "mot_if", m_combiner_repc_vif);

    m_combiner_output_vif = m_psinr_env_cfg.m_combiner_output_vif;
    uvm_config_db#(virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH) )::set(this.m_combiner_monitor, "", "mot_if", m_combiner_output_vif);

    m_combiner_gain_vif = m_psinr_env_cfg.m_combiner_gain_vif;
    uvm_config_db#(virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH) )::set(this.m_combiner_gain_monitor, "", "mot_if", m_combiner_gain_vif);

    //psinr
    m_psinr_cfg_vif = m_psinr_env_cfg.m_psinr_cfg_vif;
    uvm_config_db#(virtual axi_stream_if#(BETA_CFG_WIDTH) )::set(this.m_psinr_calc_cfg_driver, "", "drv_if", m_psinr_cfg_vif);

    m_psinr_demap_vif = m_psinr_env_cfg.m_psinr_demap_vif;
    uvm_config_db#(virtual axi_stream_if#(PSINR_DEMAP_WIDTH) )::set(this.m_psinr_demap_monitor, "", "mot_if", m_psinr_demap_vif);

    m_psinr_out_vif = m_psinr_env_cfg.m_psinr_out_vif;
    uvm_config_db#(virtual axi_stream_if#(PSINR_CALC_WIDTH) )::set(this.m_psinr_out_monitor, "", "mot_if", m_psinr_out_vif);

    m_psinr_demod_vif = m_psinr_env_cfg.m_psinr_demod_vif;
    uvm_config_db#(virtual axi_stream_if#(PSINR_CALC_WIDTH) )::set(this.m_psinr_demod_monitor, "", "mot_if", m_psinr_demod_vif);

    //psinr out
    m_psinr_out_cfg_vif = m_psinr_env_cfg.m_psinr_out_cfg_vif;
    uvm_config_db#(virtual axi_stream_if#(BETA_CFG_WIDTH) )::set(this.m_psinr_out_cfg_driver, "", "drv_if", m_psinr_out_cfg_vif);

    m_psinr_out_uci_vif = m_psinr_env_cfg.m_psinr_out_uci_vif;
    uvm_config_db#(virtual axi_stream_if#(3*PSINR_OUT_UCI_WIDTH) )::set(this.m_psinr_out_uci_driver, "", "drv_if", m_psinr_out_uci_vif);

    m_psinr_out_report_vif = m_psinr_env_cfg.m_psinr_out_report_vif;
    uvm_config_db#(virtual axi_stream_if#(PSINR_OUT_REPORT_WIDTH) )::set(this.m_psinr_out_report_monitor, "", "mot_if", m_psinr_out_report_vif);

endfunction : set_virtual_interface_handles

//-----------------------------------------------------------------------------
function void psinr_env::init_env_component();

    //combiner
    m_combiner_sqr = axi_stream_sequencer#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)::type_id::create("m_combiner_sqr", this);
    m_combiner_driver = axi_stream_driver#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)::type_id::create("m_combiner_driver", this);
    m_combiner_cfg_sqr = axi_stream_sequencer#(BETA_CFG_WIDTH)::type_id::create("m_combiner_cfg_sqr", this);
    m_combiner_cfg_driver = axi_stream_driver#(BETA_CFG_WIDTH)::type_id::create("m_combiner_cfg_driver", this);

    //psinr
    m_psinr_calc_cfg_sqr = axi_stream_sequencer#(BETA_CFG_WIDTH)::type_id::create("m_psinr_calc_cfg_sqr", this);
    m_psinr_calc_cfg_driver = axi_stream_driver#(BETA_CFG_WIDTH)::type_id::create("m_psinr_calc_cfg_driver", this);

    m_psinr_out_cfg_sqr = axi_stream_sequencer#(BETA_CFG_WIDTH)::type_id::create("m_psinr_out_cfg_sqr", this);
    m_psinr_out_cfg_driver = axi_stream_driver#(BETA_CFG_WIDTH)::type_id::create("m_psinr_out_cfg_driver", this);
    m_psinr_out_uci_sqr = axi_stream_sequencer#(3*PSINR_OUT_UCI_WIDTH)::type_id::create("m_psinr_out_uci_sqr", this);
    m_psinr_out_uci_driver = axi_stream_driver#(3*PSINR_OUT_UCI_WIDTH)::type_id::create("m_psinr_out_uci_driver", this);
    

    if (scb_enable == 1) begin
        m_combiner_monitor = axi_stream_monitor#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)::type_id::create("m_combiner_monitor", this);
        m_combiner_gain_monitor = axi_stream_monitor#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)::type_id::create("m_combiner_gain_monitor", this);
        m_combiner_sb = combiner_sb::type_id::create("m_combiner_sb", this);

        m_psinr_demap_monitor = axi_stream_monitor#(PSINR_DEMAP_WIDTH)::type_id::create("m_psinr_demap_monitor", this);
        m_psinr_out_monitor = axi_stream_monitor#(PSINR_CALC_WIDTH)::type_id::create("m_psinr_out_monitor", this);
        m_psinr_demod_monitor = axi_stream_monitor#(PSINR_CALC_WIDTH)::type_id::create("m_psinr_demod_monitor", this);
        m_psinr_out_report_monitor = axi_stream_monitor#(PSINR_OUT_REPORT_WIDTH)::type_id::create("m_psinr_out_report_monitor", this);

        m_psinr_sb = psinr_sb::type_id::create("m_psinr_sb", this);
    end

    // function coverage
    psinr_func_cov = function_cov::type_id::create("psinr_func_cov",this);

    //timer
    m_time_mon_sqr = time_mon_sequencer::type_id::create("m_time_mon_sqr", this);
    m_time_mon_driver = time_mon_driver::type_id::create("m_time_mon_driver", this);

endfunction : init_env_component

//-----------------------------------------------------------------------------
function void psinr_env::init_env_cfg_para();

    m_combiner_sb.mp_path_q = m_psinr_env_cfg.env_mp_path_q;
    m_combiner_sb.layer_num_q = m_psinr_env_cfg.env_num_layers_q;
    m_combiner_sb.rb_num_q = m_psinr_env_cfg.env_num_rb_q;
    m_combiner_sb.symb_num_q = m_psinr_env_cfg.env_num_symbs_q;
    m_combiner_sb.num_res = m_psinr_env_cfg.env_num_res;
    m_combiner_sb.cpofdm_q = m_psinr_env_cfg.env_cpofdm_q;
    m_combiner_sb.taskNum = m_psinr_env_cfg.env_num_task;

    m_psinr_sb.mp_path_q = m_psinr_env_cfg.env_mp_path_q;
    m_psinr_sb.symb_num_q = m_psinr_env_cfg.env_num_symbs_q;
    m_psinr_sb.num_res = m_psinr_env_cfg.env_num_res;
    m_psinr_sb.cpofdm_q = m_psinr_env_cfg.env_cpofdm_q;
    m_psinr_sb.processType_q = m_psinr_env_cfg.env_processing_type_q;
    m_psinr_sb.taskNum = m_psinr_env_cfg.env_num_task;

endfunction : init_env_cfg_para