/*------------------------------------------------------------------------------

*/

`ifndef _PSINR_TEST_BASE_SVH_
`define _PSINR_TEST_BASE_SVH_

// ----------------------------------------------------------------------------
// Class Definition 
// ----------------------------------------------------------------------------
class psinr_test_base extends uvm_test;
    `uvm_component_utils(psinr_test_base)

    string     tv_path_vec[$];
    int        chunkSize=1;
    int        num_parallel_re=8;
    bit        cpofdm=0;
    bit        cpofdm_q[$];
    int        chunks_perlayer;
    int        chunks_perlayer_q[$];
    int        lines_persymb=0;
    int        lines_persymb_q[$];
    int        lines_lastchunk=0;
    int        lines_lastchunk_q[$];
    int        num_task=1;
    
    logic [8:0]        num_rb;  
    logic [8:0]        num_rb_q[$];   
    logic [3:0]        num_symbs;     
    logic [3:0]        num_symbs_q[$];
    logic [3:0]        num_layers; 
    logic [3:0]        num_layers_q[$];
    logic [2:0]        du_ru_mode=0;
    logic [2:0]        du_ru_mode_q[$];
    logic [3:0]        processing_type;
    logic [3:0]        processing_type_q[$];
    logic [2:0]        puc_sprd_seqid_q[$];
    logic [1:0]        puc_sprd_type_q[$];
    logic              puc_f2_flag_q[$];
    logic              musu_mode_q[$];
    logic              psinr_calc_bypass_q[$];
    logic [4:0]        psinr_cfg_para_q[$];

    bit                fpga_opt=1;



    logic [PSINR_OUT_UCI_WIDTH-1:0]   uci_ack;
    logic [PSINR_OUT_UCI_WIDTH-1:0]   uci_csi1;
    logic [PSINR_OUT_UCI_WIDTH-1:0]   uci_csi2;
    

    virtual dut_top_if                    m_dut_top_vif;
    virtual back_pressure_if              m_psinr_bp_vif;

    virtual axi_stream_if#(COMB_STATUS_WIDTH)        m_combiner_status_vif;
    virtual axi_stream_if#(PSINR_CALC_STATUS_WIDTH)  m_psinr_calc_status_vif;
    virtual axi_stream_if#(PSINR_OUT_STATUS_WIDTH)   m_psinr_out_status_vif;



    psinr_report_server                   psinr_report_server_inst;

    psinr_env                             m_psinr_env;
    psinr_env_cfg                         m_psinr_env_cfg; 

    time_mon_cfg                          m_time_mon_cfg;    

    file_parser#(BETA_FILE_WIDTH)         m_comb_data_parser[][];
    file_parser#(BETA_EXP_WIDTH)          m_comb_exp_parser[][]; 
    file_parser#(BETA_CFG_WIDTH)          m_comb_cfg_parser[];  
    file_parser#(PSINR_OUT_UCI_WIDTH)     m_psinr_out_uci_parser[][];

    tr_cfg_t                              tr_combiner_cfg[];

    tr_data_q                             tr_combiner_vec[][];
    tr_exp_q                              tr_combiner_exp_vec[][];
    tr_uci_q                              tr_psinr_out_uci_vec[][];

    bit                                   psinr_symb_last_req[$];
    event                                 combiner_data_input_req;

    
    extern function new(string name = "psinr_test_base",uvm_component parent = null);

    // Group: UVM Phasing.
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern virtual function void end_of_elaboration_phase(uvm_phase phase);
    extern virtual function void start_of_simulation_phase(uvm_phase phase);
    extern         task          reset_phase(uvm_phase phase);
    extern         task          configure_phase(uvm_phase phase);
    extern         task          pre_main_phase(uvm_phase phase);
    extern         task          main_phase(uvm_phase phase);
    extern         task          delay_us(int val); 
    extern virtual function void report_phase(uvm_phase phase);

    extern virtual function void parse_cmdline_arguments();
    extern virtual function void get_virtual_interface_handles();
    extern virtual function void init_psinr_env_config();
    extern virtual function void init_time_mon_config();
    extern virtual function void do_build_file_parser();

    extern virtual task          combiner_data_input(bit status);
    extern virtual task          combiner_cfg_input(bit status);
    extern virtual task          psinr_calc_cfg_input(bit status);
    extern virtual task          psinr_out_cfg_input(bit status);
    extern virtual task          psinr_out_uci_input(bit status);
    extern virtual task          reset_dut(bit status);

    rand int ready_wait; //us
    constraint c_ready_wait  { ready_wait  >= 1; ready_wait <= 10; }
endclass : psinr_test_base


function psinr_test_base::new(string name = "psinr_test_base", uvm_component parent = null);
    super.new(name,parent);
endfunction : new

// ----------------------------------------------------------------------------
function void psinr_test_base::build_phase(uvm_phase phase);
    parse_cmdline_arguments();
    
    super.build_phase(phase);

    //create env and config
    m_psinr_env = psinr_env::type_id::create("m_psinr_env", this);
    m_psinr_env_cfg = psinr_env_cfg::type_id::create("m_psinr_env_cfg");

    m_time_mon_cfg = time_mon_cfg::type_id::create("m_time_mon_cfg");

    do_build_file_parser();

    get_virtual_interface_handles();

    init_time_mon_config();
    init_psinr_env_config();

    uvm_config_db#(psinr_env_cfg)::set(null, "psinr_env_cfg::", "m_psinr_env_cfg", m_psinr_env_cfg);
    uvm_config_db #(time_mon_cfg)::set(this.m_psinr_env.m_time_mon_driver,"","time_mon_cfg", m_time_mon_cfg);

    //reset report format
    psinr_report_server_inst = psinr_report_server::type_id::create("psinr_report_server_inst", this);
    uvm_report_server::set_server(psinr_report_server_inst);
    

endfunction : build_phase

// ----------------------------------------------------------------------------
function void psinr_test_base::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
endfunction : connect_phase

// ----------------------------------------------------------------------------
function void psinr_test_base::end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
endfunction : end_of_elaboration_phase

// ----------------------------------------------------------------------------
function void psinr_test_base::start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
endfunction : start_of_simulation_phase

task psinr_test_base::reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.drop_objection(this);
endtask 

task psinr_test_base::configure_phase(uvm_phase phase);
    phase.raise_objection(this);
    super.configure_phase(phase);
    phase.drop_objection(this);
endtask 

task psinr_test_base::pre_main_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.drop_objection(this); 
endtask 

// ----------------------------------------------------------------------------
task psinr_test_base::main_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.drop_objection(this);
endtask: main_phase


// ----------------------------------------------------------------------------
function void psinr_test_base::report_phase(uvm_phase phase);
    uvm_report_server uvm_report_server_h = uvm_report_server::get_server();
    super.report_phase(phase);
    
    if (uvm_report_enabled(UVM_LOW)) begin
        if (uvm_report_server_h.get_severity_count(UVM_FATAL) + uvm_report_server_h.get_severity_count(UVM_ERROR) == 0) 
        begin
            uvm_report_info({"TEST [", get_type_name(), "]"}, "*************************", UVM_LOW, "", 0, "", 1);
            uvm_report_info({"TEST [", get_type_name(), "]"}, "*** SIMULATION PASSED ***", UVM_LOW, "", 0, "", 1);
            uvm_report_info({"TEST [", get_type_name(), "]"}, "*************************", UVM_LOW, "", 0, "", 1);
        end 
        else 
        begin
            uvm_report_info({"TEST [", get_type_name(), "]"}, "*************************", UVM_LOW, "", 0, "", 1);
            uvm_report_info({"TEST [", get_type_name(), "]"}, "*** SIMULATION FAILED ***", UVM_LOW, "", 0, "", 1);
            uvm_report_info({"TEST [", get_type_name(), "]"}, "*************************", UVM_LOW, "", 0, "", 1);
        end
    end
endfunction : report_phase

// ----------------------------------------------------------------------------
function void psinr_test_base::parse_cmdline_arguments();
    uvm_cmdline_processor   cmdline_processor;
    string                  cmd_input;
    int                     tmp;

    cmdline_processor = uvm_cmdline_processor::get_inst();

    if (cmdline_processor.get_arg_value("+task0_path=", cmd_input)) begin
        tv_path_vec.push_back(cmd_input);
        `uvm_info(get_full_name(), $sformatf("task0_path is : %s",cmd_input), UVM_LOW);
    end
    if (cmdline_processor.get_arg_value("+task1_path=", cmd_input)) begin
        tv_path_vec.push_back(cmd_input);
        `uvm_info(get_full_name(), $sformatf("task1_path is : %s",cmd_input), UVM_LOW);
    end
    if (cmdline_processor.get_arg_value("+task2_path=", cmd_input)) begin
        tv_path_vec.push_back(cmd_input);
        `uvm_info(get_full_name(), $sformatf("task2_path is : %s",cmd_input), UVM_LOW);
    end
    if (cmdline_processor.get_arg_value("+task3_path=", cmd_input)) begin
        tv_path_vec.push_back(cmd_input);
        `uvm_info(get_full_name(), $sformatf("task3_path is : %s",cmd_input), UVM_LOW);
    end
    if (cmdline_processor.get_arg_value("+task4_path=", cmd_input)) begin
        tv_path_vec.push_back(cmd_input);
        `uvm_info(get_full_name(), $sformatf("task4_path is : %s",cmd_input), UVM_LOW);
    end
    if (cmdline_processor.get_arg_value("+chunk_size=", cmd_input)) begin
        chunkSize = cmd_input.atoi();
        `uvm_info(get_full_name(), $sformatf("chunkSize  is : %d",chunkSize), UVM_LOW);
    end
    if (cmdline_processor.get_arg_value("+num_parallel_re=", cmd_input)) begin
        num_parallel_re = cmd_input.atoi();
        `uvm_info(get_full_name(), $sformatf("num_parallel_re  is : %d",num_parallel_re), UVM_LOW);
    end
    if (cmdline_processor.get_arg_value("+fpga_opt=", cmd_input)) begin
        fpga_opt = cmd_input.atoi();
        `uvm_info(get_full_name(), $sformatf("fpga_opt  is : %d",fpga_opt), UVM_LOW);
    end
    // if (cmdline_processor.get_arg_value("+task_num=", cmd_input)) begin
    //     num_task = cmd_input.atoi();
    //     `uvm_info(get_full_name(), $sformatf("num_task  is : %d",num_task), UVM_LOW);
    // end
    num_task = tv_path_vec.size();
    `uvm_info(get_full_name(), $sformatf("num_task  is : %d",num_task), UVM_LOW);

endfunction : parse_cmdline_arguments

//-----------------------------------------------------------------------------
function void psinr_test_base::get_virtual_interface_handles();
    //top interface
    if (!uvm_config_db#(virtual dut_top_if)::get(null, "", "m_dut_top_vif", m_dut_top_vif)) begin
        `uvm_fatal("Top test interface error", "virtual interface must be set for dut_top_if");
    end

    if (!uvm_config_db#(virtual time_mon_if)::get(this, "", "m_time_mon_vif",m_time_mon_cfg.time_clk_if)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_time_mon_vif from uvm_config_db.")
    end
    //combiner interface
    if (!uvm_config_db#(virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH))::get(this, "", "m_combiner_input_vif",m_psinr_env_cfg.m_combiner_input_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_combiner_input_vif from uvm_config_db.")
    end

    if (!uvm_config_db#(virtual axi_stream_if#(BETA_CFG_WIDTH))::get(this, "", "m_combiner_cfg_vif",m_psinr_env_cfg.m_combiner_cfg_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_combiner_cfg_vif from uvm_config_db.")
    end

    // if (!uvm_config_db#(virtual axi_stream_if#(BETA_REPC_WIDTH))::get(this, "", "m_combiner_repc_vif",m_psinr_env_cfg.m_combiner_repc_vif)) 
    // begin
    //     `uvm_fatal(get_name(), "Cannot get() interface m_combiner_repc_vif from uvm_config_db.")
    // end

    if (!uvm_config_db#(virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH))::get(this, "", "m_combiner_output_vif",m_psinr_env_cfg.m_combiner_output_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_combiner_output_vif from uvm_config_db.")
    end

    if (!uvm_config_db#(virtual axi_stream_if#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH))::get(this, "", "m_combiner_gain_vif",m_psinr_env_cfg.m_combiner_gain_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_combiner_gain_vif from uvm_config_db")
    end
    if (!uvm_config_db#(virtual axi_stream_if#(COMB_STATUS_WIDTH))::get(this, "", "m_combiner_status_vif",m_combiner_status_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_combiner_status_vif from uvm_config_db")
    end
    //psinr interface
    if (!uvm_config_db#(virtual axi_stream_if#(BETA_CFG_WIDTH))::get(this, "", "m_psinr_cfg_vif",m_psinr_env_cfg.m_psinr_cfg_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_cfg_vif from uvm_config_db.")
    end
    if (!uvm_config_db#(virtual axi_stream_if#(PSINR_DEMAP_WIDTH))::get(this, "", "m_psinr_demap_vif",m_psinr_env_cfg.m_psinr_demap_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_demap_vif from uvm_config_db.")
    end
    if (!uvm_config_db#(virtual axi_stream_if#(PSINR_CALC_WIDTH))::get(this, "", "m_psinr_out_vif",m_psinr_env_cfg.m_psinr_out_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_out_vif from uvm_config_db.")
    end
    if (!uvm_config_db#(virtual axi_stream_if#(PSINR_CALC_WIDTH))::get(this, "", "m_psinr_demod_vif",m_psinr_env_cfg.m_psinr_demod_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_demod_vif from uvm_config_db.")
    end
    if (!uvm_config_db#(virtual axi_stream_if#(PSINR_CALC_STATUS_WIDTH))::get(this, "", "m_psinr_calc_status_vif",m_psinr_calc_status_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_calc_status_vif from uvm_config_db.")
    end
    //psinr out interface
     //psinr interface
    if (!uvm_config_db#(virtual axi_stream_if#(BETA_CFG_WIDTH))::get(this, "", "m_psinr_out_cfg_vif",m_psinr_env_cfg.m_psinr_out_cfg_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_out_cfg_vif from uvm_config_db.")
    end
    if (!uvm_config_db#(virtual axi_stream_if#(3*PSINR_OUT_UCI_WIDTH))::get(this, "", "m_psinr_out_uci_vif",m_psinr_env_cfg.m_psinr_out_uci_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_out_uci_vif from uvm_config_db.")
    end
    if (!uvm_config_db#(virtual axi_stream_if#(PSINR_OUT_REPORT_WIDTH))::get(this, "", "m_psinr_out_report_vif",m_psinr_env_cfg.m_psinr_out_report_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_out_report_vif from uvm_config_db.")
    end
    if (!uvm_config_db#(virtual axi_stream_if#(PSINR_OUT_STATUS_WIDTH))::get(this, "", "m_psinr_out_status_vif",m_psinr_out_status_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_out_status_vif from uvm_config_db.")
    end
    //psinr out back pressure signal
    if (!uvm_config_db#(virtual back_pressure_if)::get(this, "", "m_psinr_bp_vif",m_psinr_bp_vif)) 
    begin
        `uvm_fatal(get_name(), "Cannot get() interface m_psinr_bp_vif from uvm_config_db.")
    end

endfunction : get_virtual_interface_handles

// ----------------------------------------------------------------------------
function void psinr_test_base::init_psinr_env_config();
    
    m_psinr_env_cfg.env_mp_path_q = tv_path_vec;
    m_psinr_env_cfg.env_num_layers_q = num_layers_q;
    m_psinr_env_cfg.env_num_rb_q = num_rb_q;
    m_psinr_env_cfg.env_num_symbs_q = num_symbs_q;
    m_psinr_env_cfg.env_num_res = num_parallel_re;
    m_psinr_env_cfg.env_cpofdm_q = cpofdm_q; 
    m_psinr_env_cfg.env_processing_type_q = processing_type_q;
    m_psinr_env_cfg.env_num_task = num_task;

endfunction:init_psinr_env_config

// ----------------------------------------------------------------------------
function void psinr_test_base::init_time_mon_config();
    
    m_time_mon_cfg.time_start_tab[2] = 0;      // start slot
    m_time_mon_cfg.time_start_tab[1] = 0;      // start symbol
    m_time_mon_cfg.time_start_tab[0] = 0;      // start clk

    m_time_mon_cfg.time_base_tab[1] = 14;      // total symbol per slot
    m_time_mon_cfg.time_base_tab[0] = 23806;      // total clk per symbol (FDD),300Mhz，1000us/14=71.42us = 71420ns; 71420ns/3=23806;

endfunction:init_time_mon_config

// ----------------------------------------------------------------------------
function void psinr_test_base::do_build_file_parser();

    m_comb_cfg_parser = new[num_task];
    tr_combiner_cfg = new[num_task];

    m_comb_data_parser = new[num_task];
    tr_combiner_vec = new[num_task];
    m_comb_exp_parser = new[num_task];
    tr_combiner_exp_vec = new[num_task];

    m_psinr_out_uci_parser = new[num_task];
    tr_psinr_out_uci_vec = new[num_task];

    for (int tt=0; tt<num_task; tt++) begin 
        //build cfg file parser
        m_comb_cfg_parser[tt] = file_parser#(BETA_CFG_WIDTH)::type_id::create($sformatf("m_comb_cfg_parser[%d]", tt));
        m_comb_cfg_parser[tt].set_file_path($sformatf("%s/PSinr_Calc_Comb_cfg.txt",tv_path_vec[tt]));
        m_comb_cfg_parser[tt].parse_cfg_file(tr_combiner_cfg[tt]);

        du_ru_mode = tr_combiner_cfg[tt]["du_ru_mode"];
        du_ru_mode_q.push_back(du_ru_mode);
        processing_type = tr_combiner_cfg[tt]["processing_type"];
        processing_type_q.push_back(processing_type);
        num_rb = tr_combiner_cfg[tt]["num_prbs"];
        num_rb_q.push_back(num_rb);
        num_symbs = tr_combiner_cfg[tt]["num_symbs"];
        num_symbs_q.push_back(num_symbs);
        num_layers = tr_combiner_cfg[tt]["num_layers"];
        num_layers_q.push_back(num_layers);
        puc_sprd_seqid_q.push_back(tr_combiner_cfg[tt]["puc_sprd_id"]);
        puc_f2_flag_q.push_back(tr_combiner_cfg[tt]["puc_f2_flag"]);
        puc_sprd_type_q.push_back(tr_combiner_cfg[tt]["puc_sprd_type"]);
        musu_mode_q.push_back(tr_combiner_cfg[tt]["musu_mode"]);
        psinr_calc_bypass_q.push_back(tr_combiner_cfg[tt]["psinr_calc_bypass"]);
        psinr_cfg_para_q.push_back(tr_combiner_cfg[tt]["sinr_cfg"]);

        // calculate file size parameters
        lines_persymb = (num_rb*12)/num_parallel_re; 
        if ((num_rb*12)%num_parallel_re != 0)
            lines_persymb = lines_persymb + 1;
        lines_persymb_q.push_back(lines_persymb);
        chunks_perlayer = lines_persymb/chunkSize;
        if (lines_persymb%chunkSize != 0) begin
            lines_lastchunk = lines_persymb - chunks_perlayer*chunkSize;
            chunks_perlayer = chunks_perlayer + 1;
        end
        else begin
            lines_lastchunk = chunkSize;
        end 
        chunks_perlayer_q.push_back(chunks_perlayer);
        lines_lastchunk_q.push_back(lines_lastchunk);
        if (du_ru_mode== 0 && processing_type==6)
            cpofdm = 1;
        else
            cpofdm = 0;
        cpofdm_q.push_back(cpofdm);

        `uvm_info(get_full_name(), $sformatf("task%d :lines_persymb is %d, chunks_perlayer is %d,lines_lastchunk is %d",tt,lines_persymb,chunks_perlayer,lines_lastchunk), UVM_LOW);
        

        m_comb_data_parser[tt] = new[num_symbs];
        tr_combiner_vec[tt] = new[num_symbs];
        m_comb_exp_parser[tt] = new[num_symbs];
        tr_combiner_exp_vec[tt] = new[num_symbs];

        m_psinr_out_uci_parser[tt] = new[num_symbs];
        tr_psinr_out_uci_vec[tt] = new[num_symbs];
        //build other file parser
        for (int nn=0; nn<num_symbs; nn++) begin
            m_comb_data_parser[tt][nn] = file_parser#(BETA_FILE_WIDTH)::type_id::create($sformatf("m_comb_data_parser[%d][%d]",tt,nn));
            m_comb_data_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Calc_C_Rhh_in_symb%0d.txt",tv_path_vec[tt],nn));
            m_comb_data_parser[tt][nn].parse_file(tr_combiner_vec[tt][nn]);

            m_comb_exp_parser[tt][nn] = file_parser#(BETA_EXP_WIDTH)::type_id::create($sformatf("m_comb_exp_parser[%d][%d]",tt,nn));
            m_comb_exp_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Calc_E_in_symb%0d.txt",tv_path_vec[tt],nn));
            m_comb_exp_parser[tt][nn].parse_file(tr_combiner_exp_vec[tt][nn]);
        end

        if (cpofdm == 1) begin
            for (int nn=0; nn<num_symbs; nn++) begin
                m_psinr_out_uci_parser[tt][nn] = file_parser#(PSINR_OUT_UCI_WIDTH)::type_id::create($sformatf("m_psinr_out_uci_parser[%d][%d]",tt,nn));
                m_psinr_out_uci_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Out_C_Uci_in_symb%0d.txt",tv_path_vec[tt],nn));
                m_psinr_out_uci_parser[tt][nn].parse_file(tr_psinr_out_uci_vec[tt][nn]);
            end
        end
    end
    

endfunction:do_build_file_parser
//---------------------------------------------------------------------------------------------------------------------------------------------
task psinr_test_base::combiner_data_input (bit status);
    bit                               task_last=0;
    bit                               symb_last=0;
    bit                               layer_last=0;
    bit                               chunk_last=1;
    int                               lines=0;

    logic [BETA_FILE_WIDTH-1:0]       res_group;
    logic [BETA_EXP_WIDTH-1:0]        reExp_group;
    logic [BETA_INOUT_WIDTH-1:0]      word_perclk=0;
    logic [BETA_EXP_WIDTH-1:0]        exp_perclk=0;

    logic [BETA_INOUT_WIDTH+BETA_EXP_WIDTH-1:0]           combiner_data_q[$];
    logic [3:0]                       combiner_last;

    axi_stream_seq #(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)     m_combiner_seq;
    m_combiner_seq   = axi_stream_seq#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)::type_id::create("m_combiner_seq");
    status = 0;
    for (int tt=0; tt<num_task; tt++) begin
		#10ns;
        if (cpofdm_q[tt] == 1) begin   //CP-OFDM
            for (int nn=0; nn<num_symbs_q[tt]; nn++) begin //read all symbs in one task
                for (int ll=0; ll<num_layers_q[tt]; ll++) begin //read all layers in one symb
                    for (int cc=0; cc<chunks_perlayer_q[tt]; cc++) begin //read all chunks in one layer
                        lines = 0;
                        for (int ii=0; ii<chunkSize; ii++) begin //read all words in one chunk
                            lines = lines + 1;
                            res_group = tr_combiner_vec[tt][nn].pop_front();
                            reExp_group = tr_combiner_exp_vec[tt][nn].pop_front();
                            case (num_parallel_re)
                                2: begin 
                                    word_perclk = {res_group[14:0],res_group[30:16]};
                                    exp_perclk = {reExp_group[7:0],reExp_group[15:8]};
                                    // `uvm_info(get_full_name(), "num_res is 4", UVM_LOW);
                                end
                                4: begin 
                                    word_perclk = {res_group[14:0],res_group[30:16],res_group[46:32],res_group[62:48]};
                                    exp_perclk = {reExp_group[7:0],reExp_group[15:8],reExp_group[23:16],reExp_group[31:24]};
                                    // `uvm_info(get_full_name(), "num_res is 4", UVM_LOW);
                                end
                                8: begin
                                    word_perclk = {res_group[14:0],res_group[30:16],res_group[46:32],res_group[62:48],
                                                   res_group[78:64],res_group[94:80],res_group[110:96],res_group[126:112]};
                                    exp_perclk = {reExp_group[7:0],reExp_group[15:8],reExp_group[23:16],reExp_group[31:24],
                                                  reExp_group[39:32],reExp_group[47:40],reExp_group[55:48],reExp_group[63:56]};
                                    // `uvm_info(get_full_name(), "num_res is 8", UVM_LOW);
                                end
                                16: begin 
                                    word_perclk = {res_group[14:0],res_group[30:16],res_group[46:32],res_group[62:48],
                                                   res_group[78:64],res_group[94:80],res_group[110:96],res_group[126:112],
                                                   res_group[142:128],res_group[158:144],res_group[174:160],res_group[190:176],
                                                   res_group[206:192],res_group[222:208],res_group[238:224],res_group[254:240]};  
                                    exp_perclk = {reExp_group[7:0],reExp_group[15:8],reExp_group[23:16],reExp_group[31:24],
                                                  reExp_group[39:32],reExp_group[47:40],reExp_group[55:48],reExp_group[63:56],
                                                  reExp_group[71:64],reExp_group[79:72],reExp_group[87:80],reExp_group[95:88],
                                                  reExp_group[103:96],reExp_group[111:104],reExp_group[119:112],reExp_group[127:120]};
                                    // `uvm_info(get_full_name(), "num_res is 16", UVM_LOW);
                                end
                            endcase
                            if (lines_lastchunk_q[tt] != 0) begin
                                if (lines == lines_lastchunk_q[tt] && cc == chunks_perlayer_q[tt]-1)
                                    ii = chunkSize;
                            end
                            // `uvm_info(get_full_name(), $sformatf("word_perclk is %h,exp_perclk is %h",word_perclk,exp_perclk), UVM_LOW);
                            combiner_data_q.push_back({exp_perclk,word_perclk});
                        end
                        if (cc == chunks_perlayer_q[tt]-1) 
                            layer_last = 1'b1;
                        else
                            layer_last = 1'b0;
                        if (ll == num_layers_q[tt]-1 && layer_last == 1) begin
                            symb_last = 1'b1;
                            psinr_symb_last_req.push_back(1);
                        end
                        else
                            symb_last = 1'b0;
                        if (nn == num_symbs_q[tt]-1 && symb_last == 1) 
                            task_last = 1'b1;
                        else
                            task_last = 1'b0;
                        combiner_last = {task_last,symb_last,layer_last,chunk_last};
                        -> combiner_data_input_req;
                        m_combiner_seq.send(combiner_data_q,combiner_last,m_psinr_env.m_combiner_sqr);
                        combiner_data_q.delete();
                        `uvm_info(get_full_name(), $sformatf("task%0d symbol%0d layer%0d chunk%0d data transfer finished",tt,nn,ll,cc), UVM_LOW);
                    end
                end
            end
        end
        else begin   //DFTs-OFDM
            for (int nn=0; nn<num_symbs_q[tt]; nn++) begin  //read all symbs in one task
                for (int ll=0; ll<num_layers_q[tt]; ll++) begin //read all layers in one symb 
                    for (int ii=0; ii<lines_persymb_q[tt]; ii++) begin  //read all words in one symb
                        // `uvm_info(get_full_name(), $sformatf("tt is %d, nn is %d",tt,nn), UVM_LOW);
                        res_group = tr_combiner_vec[tt][nn].pop_front();
                        reExp_group = tr_combiner_exp_vec[tt][nn].pop_front();
                        case (num_parallel_re)
                            2: begin 
                                word_perclk = {res_group[14:0],res_group[30:16]};
                                exp_perclk = {reExp_group[7:0],reExp_group[15:8]};
                                // `uvm_info(get_full_name(), "num_res is 2", UVM_LOW);
                            end
                            4: begin 
                                word_perclk = {res_group[14:0],res_group[30:16],res_group[46:32],res_group[62:48]};
                                exp_perclk = {reExp_group[7:0],reExp_group[15:8],reExp_group[23:16],reExp_group[31:24]};
                                // `uvm_info(get_full_name(), "num_res is 4", UVM_LOW);
                            end
                            8: begin
                                word_perclk = {res_group[14:0],res_group[30:16],res_group[46:32],res_group[62:48],
                                               res_group[78:64],res_group[94:80],res_group[110:96],res_group[126:112]};
                                exp_perclk = {reExp_group[7:0],reExp_group[15:8],reExp_group[23:16],reExp_group[31:24],
                                              reExp_group[39:32],reExp_group[47:40],reExp_group[55:48],reExp_group[63:56]};
                                // `uvm_info(get_full_name(), "num_res is 8", UVM_LOW);
                            end
                            16: begin 
                                word_perclk = {res_group[14:0],res_group[30:16],res_group[46:32],res_group[62:48],
                                               res_group[78:64],res_group[94:80],res_group[110:96],res_group[126:112],
                                               res_group[142:128],res_group[158:144],res_group[174:160],res_group[190:176],
                                               res_group[206:192],res_group[222:208],res_group[238:224],res_group[254:240]};  
                                exp_perclk = {reExp_group[7:0],reExp_group[15:8],reExp_group[23:16],reExp_group[31:24],
                                              reExp_group[39:32],reExp_group[47:40],reExp_group[55:48],reExp_group[63:56],
                                              reExp_group[71:64],reExp_group[79:72],reExp_group[87:80],reExp_group[95:88],
                                              reExp_group[103:96],reExp_group[111:104],reExp_group[119:112],reExp_group[127:120]};
                                // `uvm_info(get_full_name(), "num_res is 16", UVM_LOW);
                            end
                        endcase 
                        combiner_data_q.push_back({exp_perclk,word_perclk});
                    end
                    if (ll == num_layers_q[tt]-1)
                        symb_last = 1'b1;
                    else
                        symb_last = 1'b0;
                    if (nn == num_symbs_q[tt]-1 && symb_last == 1)
                        task_last = 1'b1;
                    else
                        task_last = 1'b0; 
                    combiner_last = {task_last,symb_last,1'b1,1'b0};
                    -> combiner_data_input_req;
                    m_combiner_seq.send(combiner_data_q,combiner_last,m_psinr_env.m_combiner_sqr);
                    combiner_data_q.delete();
                    `uvm_info(get_full_name(), $sformatf("task%0d symbol%0d layer%0d combiner data transfer finished",tt,nn,ll), UVM_LOW);
                end
            end
        end 
    end
    status = 1;
endtask : combiner_data_input
//---------------------------------------------------------------------------------------------------------------------------------------------
task psinr_test_base::combiner_cfg_input (bit status);
    axi_stream_seq #(BETA_CFG_WIDTH)        m_combiner_cfg_seq;
    logic [BETA_CFG_WIDTH-1:0]              combiner_cfg;
    logic [BETA_CFG_WIDTH-1:0]              combiner_cfg_q[$];

    m_combiner_cfg_seq   = axi_stream_seq#(BETA_CFG_WIDTH)::type_id::create("m_combiner_cfg_seq");
    status = 0;
    for (int tt=0; tt<num_task; tt++) begin
        combiner_cfg = {du_ru_mode_q[tt],processing_type_q[tt],num_rb_q[tt],num_symbs_q[tt],num_layers_q[tt],puc_sprd_seqid_q[tt],puc_sprd_type_q[tt],puc_f2_flag_q[tt]};
        combiner_cfg_q.push_back(combiner_cfg);
        m_combiner_cfg_seq.send(combiner_cfg_q,0,m_psinr_env.m_combiner_cfg_sqr);
        combiner_cfg_q.delete();
        `uvm_info(get_full_name(), $sformatf("task%0d combiner cfg send done, combiner_cfg is %h",tt,combiner_cfg), UVM_LOW);
    end
    status = 1;
endtask : combiner_cfg_input
//---------------------------------------------------------------------------------------------------------------------------------------------
task psinr_test_base::psinr_calc_cfg_input (bit status);
    axi_stream_seq #(BETA_CFG_WIDTH)        m_psinr_calc_cfg_seq;
    logic [BETA_CFG_WIDTH-1:0]              psinr_calc_cfg;
    logic [BETA_CFG_WIDTH-1:0]              psinr_calc_cfg_q[$];

    m_psinr_calc_cfg_seq   = axi_stream_seq#(BETA_CFG_WIDTH)::type_id::create("m_psinr_calc_cfg_seq");
    status = 0;
    for (int tt=0; tt<num_task; tt++) begin
        psinr_calc_cfg = {du_ru_mode_q[tt],processing_type_q[tt],num_rb_q[tt],num_symbs_q[tt],num_layers_q[tt],puc_f2_flag_q[tt],musu_mode_q[tt],psinr_calc_bypass_q[tt],psinr_cfg_para_q[tt]};
        psinr_calc_cfg_q.push_back(psinr_calc_cfg);
        m_psinr_calc_cfg_seq.send(psinr_calc_cfg_q,0,m_psinr_env.m_psinr_calc_cfg_sqr);
        psinr_calc_cfg_q.delete();
        `uvm_info(get_full_name(), $sformatf("task%0d psinr_calc cfg send done, psinr_calc cfg is %h",tt,psinr_calc_cfg), UVM_LOW);
    end
    status = 1;
endtask : psinr_calc_cfg_input
//---------------------------------------------------------------------------------------------------------------------------------------------
task psinr_test_base::psinr_out_cfg_input (bit status);
    axi_stream_seq #(BETA_CFG_WIDTH)        m_psinr_out_cfg_seq;
    logic [BETA_CFG_WIDTH-1:0]              psinr_out_cfg;
    logic [BETA_CFG_WIDTH-1:0]              psinr_out_cfg_q[$];

    m_psinr_out_cfg_seq  = axi_stream_seq#(BETA_CFG_WIDTH)::type_id::create("m_psinr_out_cfg_seq");
    status = 0;
    for (int tt=0; tt<num_task; tt++) begin
        psinr_out_cfg = {du_ru_mode_q[tt],processing_type_q[tt],num_layers_q[tt],num_symbs_q[tt]};
        psinr_out_cfg_q.push_back(psinr_out_cfg);
        m_psinr_out_cfg_seq.send(psinr_out_cfg_q,0,m_psinr_env.m_psinr_out_cfg_sqr);
        psinr_out_cfg_q.delete();
        `uvm_info(get_full_name(), $sformatf("task%0d psinr_out cfg send done, psinr_out cfg is %h",tt,psinr_out_cfg), UVM_LOW);
    end
    status = 1;
endtask : psinr_out_cfg_input
//---------------------------------------------------------------------------------------------------------------------------------------------
task psinr_test_base::psinr_out_uci_input (bit status);
    axi_stream_seq #(3*PSINR_OUT_UCI_WIDTH)     m_psinr_out_uci_seq;
    logic [3*PSINR_OUT_UCI_WIDTH-1:0]           psinr_out_uci_input_q[$];

    m_psinr_out_uci_seq  = axi_stream_seq#(3*PSINR_OUT_UCI_WIDTH)::type_id::create("m_psinr_out_uci_seq");
    status = 0;
    for (int tt=0; tt<num_task; tt++) begin
        if (cpofdm_q[tt] == 1) begin
            for (int nn=0; nn<num_symbs_q[tt]; nn++) begin
                uci_csi2 = tr_psinr_out_uci_vec[tt][nn].pop_front();
                uci_ack = tr_psinr_out_uci_vec[tt][nn].pop_front();
                uci_csi1 = tr_psinr_out_uci_vec[tt][nn].pop_front();
                psinr_out_uci_input_q.push_back({uci_csi2,uci_csi1,uci_ack});
                wait (psinr_symb_last_req.size() != 0) begin
                    m_psinr_out_uci_seq.send(psinr_out_uci_input_q,0,m_psinr_env.m_psinr_out_uci_sqr);
                    psinr_symb_last_req.pop_front();
                end
                psinr_out_uci_input_q.delete();
            end
            `uvm_info(get_full_name(), $sformatf("task%0d psinr_out uci send done",tt), UVM_LOW);
        end
    end
    status = 1;
endtask : psinr_out_uci_input
//---------------------------------------------------------------------------------------------------------------------------------------------
task psinr_test_base::reset_dut (bit status);
    status = 0;
    if (fpga_opt == 1) begin
        `uvm_info("psinr_test_base", "fpga reset mode", UVM_LOW);
        @(posedge m_dut_top_vif.clk);
        m_dut_top_vif.fpga_reset();
        m_dut_top_vif.asic_start();
        repeat (1000) @(posedge m_dut_top_vif.clk);
        m_dut_top_vif.fpga_start();
        repeat (50) @(posedge m_dut_top_vif.clk);
    end
    else begin
        `uvm_info("psinr_test_base", "asic reset mode", UVM_LOW);
        @(posedge m_dut_top_vif.clk);
        m_dut_top_vif.asic_resetn();
        m_dut_top_vif.fpga_start();
        repeat (1000) @(posedge m_dut_top_vif.clk);
        m_dut_top_vif.asic_start();
        repeat (50) @(posedge m_dut_top_vif.clk);
    end
    status = 1;
endtask : reset_dut


task psinr_test_base::delay_us(int val);
  repeat (val) begin
    for (int m=0; m<333; m++) //300MHz 
        @(posedge m_psinr_bp_vif.aclk);
  end
endtask 



`endif //PSINR_TEST_BASE_SVH_