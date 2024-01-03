/*------------------------------------------------------------------------------

*/

`ifndef _PSINR_MIS_TC_SVH_
`define _PSINR_MIS_TC_SVH_

// ----------------------------------------------------------------------------
// Class Definition 
// ----------------------------------------------------------------------------
class psinr_mis_tc extends psinr_test_base;
    `uvm_component_utils(psinr_mis_tc)


    extern function new(string name = "psinr_mis_tc",uvm_component parent = null);

    // Group: UVM Phasing.
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern         task          main_phase(uvm_phase phase);
    extern virtual task          combiner_abnormalData_input();

endclass : psinr_mis_tc


function psinr_mis_tc::new(string name = "psinr_mis_tc", uvm_component parent = null);
    super.new(name,parent);
endfunction : new

// ----------------------------------------------------------------------------
function void psinr_mis_tc::build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_psinr_env.scb_enable = 0;
endfunction : build_phase

// ----------------------------------------------------------------------------
function void psinr_mis_tc::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
endfunction : connect_phase


// ----------------------------------------------------------------------------
task psinr_mis_tc::main_phase(uvm_phase phase);
    
    axi_stream_seq #(BETA_CFG_WIDTH)        m_combiner_cfg_seq;
    logic [BETA_CFG_WIDTH-1:0]              combiner_cfg;
    logic [BETA_CFG_WIDTH-1:0]              combiner_cfg_q[$];

    axi_stream_seq #(BETA_CFG_WIDTH)        m_psinr_calc_cfg_seq;
    logic [BETA_CFG_WIDTH-1:0]              psinr_calc_cfg;
    logic [BETA_CFG_WIDTH-1:0]              psinr_calc_cfg_q[$];

    axi_stream_seq #(BETA_CFG_WIDTH)        m_psinr_out_cfg_seq;
    logic [BETA_CFG_WIDTH-1:0]              psinr_out_cfg;
    logic [BETA_CFG_WIDTH-1:0]              psinr_out_cfg_q[$];

    bit [2:0]                               puc_sprd_seqid;
    bit [1:0]                               puc_sprd_type;
    bit                                     puc_f2_flag;
    bit                                     psinr_calc_bypass;
    bit                                     musu_mode =0;
    bit [4:0]                               sinr_cfg = 5'd0;
    phase.raise_objection(this);
    
    m_combiner_cfg_seq   = axi_stream_seq#(BETA_CFG_WIDTH)::type_id::create("m_combiner_cfg_seq");
    m_psinr_calc_cfg_seq   = axi_stream_seq#(BETA_CFG_WIDTH)::type_id::create("m_psinr_calc_cfg_seq");
    m_psinr_out_cfg_seq  = axi_stream_seq#(BETA_CFG_WIDTH)::type_id::create("m_psinr_out_cfg_seq");

    du_ru_mode = 0;
    processing_type = 5;
    num_rb = 4;
    num_symbs = 3;
    num_layers = 4;
    puc_sprd_seqid = 0;
    puc_sprd_type = 0;
    puc_f2_flag = 0;
    psinr_calc_bypass = 0;

    reset_dut(1);

    `uvm_info("psinr_err_tc", "*************psinr mismatch status test case *************", UVM_LOW);

    fork
        combiner_cfg_input_flow:begin
            `uvm_info(get_full_name(), "combiner cfg start to transfer", UVM_LOW);
            combiner_cfg = {du_ru_mode,processing_type,num_rb,num_symbs,num_layers,puc_sprd_seqid,puc_sprd_type,puc_f2_flag};
            combiner_cfg_q.push_back(combiner_cfg);
            m_combiner_cfg_seq.send(combiner_cfg_q,0,m_psinr_env.m_combiner_cfg_sqr);
            `uvm_info(get_full_name(), "all combiner cfg transfer done", UVM_LOW);
        end
        combiner_data_input_flow:begin
            `uvm_info(get_full_name(), "combiner data start to transfer", UVM_LOW);
            combiner_abnormalData_input();
            `uvm_info(get_full_name(), "all symbol combiner data transfer done", UVM_LOW);
        end
        psinr_calc_cfg_input_flow:begin
            `uvm_info(get_full_name(), "psinr_calc cfg start to transfer", UVM_LOW);
            psinr_calc_cfg = {du_ru_mode,processing_type,num_rb,num_symbs,num_layers,puc_f2_flag,musu_mode,psinr_calc_bypass,sinr_cfg};
            psinr_calc_cfg_q.push_back(psinr_calc_cfg);
            m_psinr_calc_cfg_seq.send(psinr_calc_cfg_q,0,m_psinr_env.m_psinr_calc_cfg_sqr);
            `uvm_info(get_full_name(), "all psinr_calc cfg transfer done", UVM_LOW);
        end
        psinr_out_cfg_input_flow:begin
            `uvm_info(get_full_name(), "psinr_out cfg start to transfer", UVM_LOW);
            psinr_out_cfg = {du_ru_mode,processing_type,num_layers,num_symbs};
            psinr_out_cfg_q.push_back(psinr_out_cfg);
            m_psinr_out_cfg_seq.send(psinr_out_cfg_q,0,m_psinr_env.m_psinr_out_cfg_sqr);
            `uvm_info(get_full_name(), "all psinr_out cfg transfer done", UVM_LOW);
        end

        psinr_back_pressure:begin
            @(posedge m_psinr_bp_vif.aclk);
            m_psinr_bp_vif.tready = 4'b1111;
            `uvm_info(get_full_name(), "psinr back pressure is disable", UVM_LOW);
        end

        check_combiner_status_output:begin
           wait(m_combiner_status_vif.tvalid == 1);
           if (m_combiner_status_vif.tdata[11:9] == 3'b111) begin
               `uvm_info(get_full_name(), "combiner mismatch status is normal", UVM_LOW); 
           end
           else begin
                `uvm_info(get_full_name(), "combiner mismatch status is abnormal", UVM_LOW); 
           end
        end

        check_psinr_calc_status_output:begin
           wait(m_psinr_calc_status_vif.tvalid == 1);
           if (m_psinr_calc_status_vif.tdata[9:7] == 3'b111) begin
               `uvm_info(get_full_name(), "psinr_calc mismatch status is normal", UVM_LOW); 
           end
           else begin
                `uvm_info(get_full_name(), "psinr_calc mismatch status is abnormal", UVM_LOW); 
           end
        end

        // check_psinr_out_status_output:begin
        //    wait(m_psinr_out_status_vif.tvalid == 1);
        //    if (m_psinr_out_status_vif.tdata[6:4] == 3'b111) begin
        //        `uvm_info(get_full_name(), "psinr_out mismatch status is normal", UVM_LOW); 
        //    end
        //    else begin
        //         `uvm_info(get_full_name(), "psinr_out mismatch status is abnormal", UVM_LOW); 
        //    end
        // end

    join
    #500us; 
    `uvm_info("psinr_mis_tc", "*************all dut cfg & data send done  *************", UVM_LOW);
    // $finish;

    phase.drop_objection(this);
endtask: main_phase

//-----------------------------------------------------------------------------------------------------------
task psinr_mis_tc::combiner_abnormalData_input ();
    bit                               task_last=0;
    bit                               symb_last=0;

    logic [BETA_INOUT_WIDTH-1:0]      word_perclk=0;
    logic [BETA_EXP_WIDTH-1:0]        exp_perclk=0;

    logic [BETA_INOUT_WIDTH+BETA_EXP_WIDTH-1:0]           combiner_data_q[$];
    logic [3:0]                       combiner_last;

    int                               mis_num_symbs = 2;
    int                               mis_num_layers = 2;
    int                               mis_num_rbs = 2;

    axi_stream_seq #(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)     m_combiner_seq;
    m_combiner_seq   = axi_stream_seq#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)::type_id::create("m_combiner_seq");
    
    for (int nn=0; nn<mis_num_symbs; nn++) begin     
        for (int ll=0; ll<mis_num_layers; ll++) begin //read all layers in one symb 
            for (int ii=0; ii<mis_num_rbs*3; ii++) begin  //read all words in one symb, mis_num_rbs*12/4
                word_perclk = word_perclk + 1;
                exp_perclk = 32'd0;
                combiner_data_q.push_back({exp_perclk,word_perclk});
            end       
            if (ll == mis_num_layers-1)
                symb_last = 1'b1;
            else
                symb_last = 1'b0;
            if (nn == mis_num_symbs-1 && symb_last == 1)
                task_last = 1'b1;
            else
                task_last = 1'b0; 
            combiner_last = {task_last,symb_last,1'b1,1'b0};
                        
            m_combiner_seq.send(combiner_data_q,combiner_last,m_psinr_env.m_combiner_sqr);
            combiner_data_q.delete();
            `uvm_info(get_full_name(), $sformatf("task0 symbol%0d layer%0d combiner data transfer finished",nn,ll), UVM_LOW);
        end
    end

endtask : combiner_abnormalData_input


`endif //_PSINR_MIS_TC_SVH_