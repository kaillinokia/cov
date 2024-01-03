/*

*/
class function_cov extends uvm_component;
    `uvm_component_utils(function_cov)

    virtual dut_cov_if cov_vif;
    //cfg parameters
    bit [2:0]  duru_mode;
    bit [3:0]  processing_type;
    bit [8:0]  num_rb;
    bit [3:0]  num_symbol;
    bit [3:0]  num_layer;
    bit [2:0]  pucch_spread_seq_id;
    bit [1:0]  pucch_spread_type;
    bit        pucch_f2_flag;
    bit        su_mu_mode;
    bit        sinr_calculation_bypass;
    bit [4:0]  configured_sinr;

    //debug status
    bit [2:0]     comb_mis_status;
    bit [4:0]     comb_err_status;
    bit [2:0]     psinr_calc_mis_status;
    bit [4:0]     psinr_calc_err_status;
    bit [2:0]     psinr_out_mis_status;
    bit [3:0]     psinr_out_err_status;

 

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task          main_phase(uvm_phase phase);
    extern function new(string name = "function_cov", uvm_component parent = null);
    extern virtual task collect_comb_cfg_cov();
    extern virtual task collect_psinr_cfg_cov();
    extern virtual task collect_comb_debug_cov();
    extern virtual task collect_psinr_calc_debug_cov();
    extern virtual task collect_psinr_out_debug_cov();
    extern function void get_coverage();

    covergroup cov_comb_cfg_parms;
        reg_du_ru_mode: coverpoint duru_mode {
          bins mode_0 = {0};   //DU mode, option 7-2 
          // bins mode_1 = {1};//DU mode, option 7-3 
          // bins mode_2 = {2};//RU mode, option 7-3
          // bins mode_3 = {3};
          // bins mode_4 = {4};
          // bins mode_5 = {5};
          // bins mode_6 = {6};
          // bins mode_7 = {7};//DFT-IDFT only mode
        }
        reg_processing_type: coverpoint processing_type {
          // bins type_0 = {0};//LTE 1ms TTI
          // bins type_1 = {1};//LTE 7-os sTTI
          // bins type_2 = {2};//LTE 2/3 OS sTTI
          // bins type_3 = {3};//LTE subPrb
          // bins type_4 = {4};//LTE special subframe 
          bins type_5 = {5};//NR DFT-s-OFDM (PUC F3, PUS DFT-s-OFDM)
          bins type_6 = {6};//NR CP-OFDM    (PUC F2,    PUS CP-OFDM)
          // bins type_7 = {7};//PUC F4
        }
        reg_num_rb: coverpoint num_rb {
          bins num_rb_low1 ={[1:50]};
          bins num_rb_low2 ={[51:100]};
          bins num_rb_mid1 ={[101:150]};
          bins num_rb_mid2 ={[151:200]};
          bins num_rb_high ={[201:273]};
        }

        reg_num_sym: coverpoint num_symbol {
          bins num_symb_low ={[1:3]};
          bins num_symb_mid1 ={[4:6]};
          bins num_symb_mid2 ={[7:9]};
          bins num_symb_high1 ={[10:12]};
          bins num_symb_high2 ={[12:14]};
        }
        reg_num_layer: coverpoint num_layer {
          bins num_layer_1 ={1};
          bins num_layer_2 ={2};
          bins num_layer_3 ={3};
          bins num_layer_4 ={4};
        }
        reg_pucch_spread_seq_id: coverpoint pucch_spread_seq_id {
          bins pucch_spread_seq_id_0 ={0};
        }
        reg_pucch_spread_type: coverpoint pucch_spread_type {
          bins pucch_spread_type_0 ={0};
        }

    endgroup : cov_comb_cfg_parms

    covergroup cov_psinr_cfg_parms;
        reg_pucch_f2_flag: coverpoint pucch_f2_flag {
          bins pucch_f2_flag_0 ={0};
        }
        reg_su_mu_mode: coverpoint su_mu_mode {
          bins su_mu_mode_0 ={0};
          bins su_mu_mode_1 ={1};
        }
        reg_sinr_calculation_bypass: coverpoint sinr_calculation_bypass {
          bins sinr_calculation_bypass_0 ={0};
          bins sinr_calculation_bypass_1 ={1};
        }
        reg_configured_sinr: coverpoint configured_sinr {
          bins configured_sinr_0 ={[0:15]};
        }
    endgroup : cov_psinr_cfg_parms

    covergroup cov_comb_debug_status;
        comb_mismatch_status: coverpoint comb_mis_status {
          bins comb_mis_status_0 ={0};
          bins comb_mis_status_1 ={7};
        }
        comb_error_status: coverpoint comb_err_status {
          bins comb_err_status_0 ={0};
          bins comb_err_status_1 ={31};
        }
    endgroup : cov_comb_debug_status

    covergroup cov_psinr_calc_debug_status;
        psinr_calc_mismatch_status: coverpoint psinr_calc_mis_status {
          bins psinr_calc_mis_status_0 ={0};
          bins psinr_calc_mis_status_1 ={7};
        }
        psinr_calc_error_status: coverpoint psinr_calc_err_status {
          bins psinr_calc_err_status_0 ={0};
          bins psinr_calc_err_status_1 ={31};
        }
    endgroup : cov_psinr_calc_debug_status

    covergroup cov_psinr_out_debug_status;
        psinr_out_mismatch_status: coverpoint psinr_out_mis_status {
          bins psinr_out_mis_status_0 ={0};
          bins psinr_out_mis_status_1 ={7};
        }
        psinr_out_error_status: coverpoint psinr_out_err_status {
          bins psinr_out_err_status_0 ={0};
          bins psinr_out_err_status_1 ={15};
        }
    endgroup : cov_psinr_out_debug_status


endclass : function_cov

function void function_cov::get_coverage();
  $display(" Parms Coverage:%0.8f %%", cov_comb_cfg_parms.get_coverage());
  $display(" Parms Coverage:%0.8f %%", cov_psinr_cfg_parms.get_coverage());
  $display(" Parms Coverage:%0.8f %%", cov_comb_debug_status.get_coverage());
  $display(" Parms Coverage:%0.8f %%", cov_psinr_calc_debug_status.get_coverage());
  $display(" Parms Coverage:%0.8f %%", cov_psinr_out_debug_status.get_coverage());
  // `uvm_info("psinr function coverage","ttttt.",UVM_LOW);

endfunction : get_coverage

function function_cov::new(string name = "function_cov", uvm_component parent = null);
  super.new(name,parent);
  cov_comb_cfg_parms = new();
  cov_psinr_cfg_parms = new();
  cov_comb_debug_status = new();
  cov_psinr_calc_debug_status = new();
  cov_psinr_out_debug_status = new();
endfunction : new

function void function_cov::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if(!uvm_config_db#(virtual dut_cov_if)::get(this, "", "m_dut_cov_vif", cov_vif))
    `uvm_fatal("dut coverage interface error", "virtual interface must be set for dut_cov_if");

  if(cov_vif == null)
    `uvm_fatal(get_full_name(), "get wrong coverage vif");

endfunction : build_phase 

task function_cov::main_phase(uvm_phase phase);

  
  fork
    begin
      `uvm_info("function_coverage","Start to Collect Combiner Cfg Coverage.",UVM_LOW);
      forever collect_comb_cfg_cov;
    end
    begin
      `uvm_info("function_coverage","Start to Collect Psinr Cfg Coverage.",UVM_LOW);
      forever collect_psinr_cfg_cov;
    end
    begin
      `uvm_info("function_coverage","Start to Collect Combiner debug Status Coverage.",UVM_LOW);
      forever collect_comb_debug_cov;
    end
    begin
      `uvm_info("function_coverage","Start to Collect Psinr Calc debug Status Coverage.",UVM_LOW);
      forever collect_psinr_calc_debug_cov;
    end
    begin
      `uvm_info("function_coverage","Start to Collect Psinr Out debug Status Coverage.",UVM_LOW);
      forever collect_psinr_out_debug_cov;
    end

  join
endtask:main_phase 

task function_cov::collect_comb_cfg_cov();
  @(posedge cov_vif.comb_cfg_valid);
  duru_mode = cov_vif.comb_cfg[29:27];
  processing_type = cov_vif.comb_cfg[26:23];
  num_rb  = cov_vif.comb_cfg[22:14];
  num_symbol  = cov_vif.comb_cfg[13:10];
  num_layer  = cov_vif.comb_cfg[9:6];
  pucch_spread_seq_id = cov_vif.comb_cfg[5:3];
  pucch_spread_type = cov_vif.comb_cfg[2:1];
  // `uvm_info("function_coverage",$sformatf(" duru_mode=%d, processing_type=%d,num_rb=%d,num_symbol=%d",duru_mode,processing_type,num_rb,num_symbol),UVM_LOW);
  cov_comb_cfg_parms.sample();
endtask : collect_comb_cfg_cov

task function_cov::collect_psinr_cfg_cov();
  @(posedge cov_vif.psinr_cfg_valid);
  pucch_f2_flag = cov_vif.psinr_cfg[7];
  su_mu_mode = cov_vif.psinr_cfg[6];
  sinr_calculation_bypass = cov_vif.psinr_cfg[5];
  configured_sinr = cov_vif.psinr_cfg[4:0];
  cov_psinr_cfg_parms.sample();
endtask : collect_psinr_cfg_cov

task function_cov::collect_comb_debug_cov();
  @(posedge cov_vif.comb_status_tvalid);
  comb_mis_status = cov_vif.comb_status_tdata[11:9];
  comb_err_status = cov_vif.comb_status_tdata[6:2];
  cov_comb_debug_status.sample();
endtask : collect_comb_debug_cov

task function_cov::collect_psinr_calc_debug_cov();
  @(posedge cov_vif.psinr_calc_status_tvalid);
  psinr_calc_mis_status = cov_vif.psinr_calc_status_tdata[9:7];
  psinr_calc_err_status = cov_vif.psinr_calc_status_tdata[4:0];
  cov_psinr_calc_debug_status.sample();
endtask : collect_psinr_calc_debug_cov

task function_cov::collect_psinr_out_debug_cov();
  @(posedge cov_vif.psinr_out_status_tvalid);
  psinr_out_mis_status = cov_vif.psinr_out_status_tdata[6:4];
  psinr_out_err_status = cov_vif.psinr_out_status_tdata[3:0];
  cov_psinr_out_debug_status.sample();
endtask : collect_psinr_out_debug_cov