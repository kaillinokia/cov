/*------------------------------------------------------------------------------

*/
`ifndef _PSINR_SB_
`define _PSINR_SB_

`uvm_analysis_imp_decl(_psinr_demap)
`uvm_analysis_imp_decl(_psinr_out)
`uvm_analysis_imp_decl(_psinr_demod)
`uvm_analysis_imp_decl(_psinr_out_report)
class psinr_sb extends uvm_scoreboard;
    `uvm_component_utils(psinr_sb)

	axi_stream_seq_item#(PSINR_CALC_WIDTH)             psinr_out_trans_q[$];
    axi_stream_seq_item#(PSINR_CALC_WIDTH)             psinr_out_tran;
      
    axi_stream_seq_item#(PSINR_DEMAP_WIDTH)             psinr_demap_trans_q[$];
    axi_stream_seq_item#(PSINR_DEMAP_WIDTH)             psinr_demap_tran;
      
    axi_stream_seq_item#(PSINR_CALC_WIDTH)             psinr_demod_trans_q[$];
    axi_stream_seq_item#(PSINR_CALC_WIDTH)             psinr_demod_tran;

    axi_stream_seq_item#(PSINR_OUT_REPORT_WIDTH)       psinr_out_report_trans_q[$];
    axi_stream_seq_item#(PSINR_OUT_REPORT_WIDTH)       psinr_out_report_tran;

    
    file_parser#(PSINR_CALC_WIDTH)               m_psinr_out_mp_parser[][]; 
    file_parser#(PSINR_DEMAP_WIDTH)              m_psinr_demap_mp_parser[][]; 
    file_parser#(PSINR_CALC_WIDTH)               m_psinr_demod_mp_parser[][];
    file_parser#(PSINR_OUT_REPORT_WIDTH)         m_psinr_out_report_mp_parser[][];

    tr_reMp_q                                    mp_psinr_out_vec[][];
    tr_reMp_q                                    mp_psinr_demod_vec[][];
    tr_mp_q                                      mp_psinr_demap_vec[][];
    tr_report_q                                  mp_psinr_out_report_vec[][];
    bit [REIAMG_WIDTH-1:0]                        mp_psinr_out_all_symb[$];
    bit [REIAMG_WIDTH-1:0]                        mp_psinr_demod_all_symb[$];
    bit [BETA_OUT_MP_WIDTH-1:0]                   mp_psinr_demap_all_symb[$];
    bit [PSINR_OUT_REPORT_WIDTH-1:0]              mp_psinr_out_report_all_symb[$];
    
    string                                       mp_path_q[$];
    logic [3:0]                                  symb_num;
    logic [3:0]                                  symb_num_q[$];
    int                                          num_res;
    bit                                          cpofdm_q[$];
    logic [3:0]                                  processType_q[$];
    logic [3:0]                                  report_symbNum_q[$];
    int                                          taskNum;
	
	int                                          report_out_lth;
    int                                          task_lth;
    int                                          task_lth_q[$];
    int                                          task_idx=0;
    int                                          lines_perlayer;

    int                                          demap_index=0;

  
    // Ports
    uvm_analysis_imp_psinr_out#(axi_stream_seq_item#(PSINR_CALC_WIDTH),psinr_sb)         psinr_out_imp;
    uvm_analysis_imp_psinr_demap#(axi_stream_seq_item#(PSINR_DEMAP_WIDTH),psinr_sb)       psinr_demap_imp;
    uvm_analysis_imp_psinr_demod#(axi_stream_seq_item#(PSINR_CALC_WIDTH),psinr_sb)       psinr_demod_imp;
    uvm_analysis_imp_psinr_out_report#(axi_stream_seq_item#(PSINR_OUT_REPORT_WIDTH),psinr_sb) psinr_out_report_imp;

    // ------------------------------------------------------------------------
    // Methods
    // ------------------------------------------------------------------------
    extern function                     new             (string name="psinr_sb", uvm_component parent=null);
    extern virtual function void        build_phase     (uvm_phase phase);
    extern task                         configure_phase (uvm_phase phase);
    extern virtual function void        write_psinr_out    (axi_stream_seq_item#(PSINR_CALC_WIDTH) t);
    extern virtual function void        write_psinr_demap    (axi_stream_seq_item#(PSINR_DEMAP_WIDTH) t);
    extern virtual function void        write_psinr_demod    (axi_stream_seq_item#(PSINR_CALC_WIDTH) t);
    extern virtual function void        write_psinr_out_report    (axi_stream_seq_item#(PSINR_OUT_REPORT_WIDTH) t);
    extern task                         main_phase      (uvm_phase phase);
    // extern function         int         comp_tr(bit[PSINR_CALC_WIDTH-1:0]  ref_words[$], bit[PSINR_CALC_WIDTH-1:0]  rtl_words[$], string mp_point, int symb_idx);
    extern virtual function void        init_file_parser();
endclass: psinr_sb


function psinr_sb::new(string name="psinr_sb", uvm_component parent=null);
    super.new(name, parent);
endfunction: new

// ----------------------------------------------------------------------------
function void psinr_sb::build_phase(uvm_phase phase);
    // Use parent method
    super.build_phase(phase);

    // Create instance for ports
    psinr_out_imp = new("psinr_out_imp", this);
    psinr_demap_imp = new("psinr_demap_imp", this);
    psinr_demod_imp = new("psinr_demod_imp", this);
    psinr_out_report_imp = new("psinr_out_report_imp", this);

    init_file_parser();

endfunction: build_phase

// ----------------------------------------------------------------------------
task psinr_sb::configure_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.drop_objection(this);
endtask: configure_phase

// ----------------------------------------------------------------------------
function void psinr_sb::write_psinr_out (axi_stream_seq_item#(PSINR_CALC_WIDTH) t);
    
    psinr_out_trans_q.push_back(t);
    // `uvm_info(get_full_name(), $sformatf("receive psinr out size is %d",t.data.size()), UVM_LOW);

    // -> psinr_out_req;
endfunction

// ----------------------------------------------------------------------------
function void psinr_sb::write_psinr_demap (axi_stream_seq_item#(PSINR_DEMAP_WIDTH) t);

    psinr_demap_trans_q.push_back(t);
    //  `uvm_info(get_full_name(), $sformatf("receive psinr demap size is %d",t.data.size()), UVM_LOW);

endfunction

// ----------------------------------------------------------------------------
function void psinr_sb::write_psinr_demod (axi_stream_seq_item#(PSINR_CALC_WIDTH) t);
    
    psinr_demod_trans_q.push_back(t);
    // `uvm_info(get_full_name(), $sformatf("receive psinr demod size is %d",t.data.size()), UVM_LOW);

endfunction

// ----------------------------------------------------------------------------
function void psinr_sb::write_psinr_out_report (axi_stream_seq_item#(PSINR_OUT_REPORT_WIDTH) t);
    
    psinr_out_report_trans_q.push_back(t);
    // `uvm_info(get_full_name(), $sformatf("receive psinr out size is %d",t.data.size()), UVM_LOW);

    // -> psinr_out_req;
endfunction



// ----------------------------------------------------------------------------
task psinr_sb::main_phase(uvm_phase phase);
    bit [PSINR_CALC_WIDTH-1:0] psinr_out_ref_word;
    bit [PSINR_CALC_WIDTH-1:0] psinr_out_rtl_word;
    bit [PSINR_CALC_WIDTH-1:0] psinr_out_ref_word_q[$];
    bit [PSINR_CALC_WIDTH-1:0] psinr_out_rtl_word_q[$];
    string                     psinr_out_status_q[$];

    bit [PSINR_DEMAP_WIDTH-1:0] psinr_demap_ref_word;
    bit [PSINR_DEMAP_WIDTH-1:0] psinr_demap_rtl_word;
    bit [PSINR_DEMAP_WIDTH-1:0] psinr_demap_ref_word_q[$];
    bit [PSINR_DEMAP_WIDTH-1:0] psinr_demap_rtl_word_q[$];
    string                     psinr_demap_status_q[$];


    bit [PSINR_CALC_WIDTH-1:0]    psinr_demod_ref_word;
    bit [PSINR_CALC_WIDTH-1:0]    psinr_demod_rtl_word;
    bit [PSINR_CALC_WIDTH-1:0]    psinr_demod_rtl_word_q[$];
    bit [PSINR_CALC_WIDTH-1:0]    psinr_demod_ref_word_q[$];
    string                        psinr_demod_status_q[$];

    bit [PSINR_OUT_REPORT_WIDTH-1:0] psinr_out_report_ref_word;
    bit [PSINR_OUT_REPORT_WIDTH-1:0] psinr_out_report_rtl_word;
    bit [PSINR_OUT_REPORT_WIDTH-1:0] psinr_out_report_ref_word_q[$];
    bit [PSINR_OUT_REPORT_WIDTH-1:0] psinr_out_report_rtl_word_q[$];
    string                           psinr_out_report_status_q[$];

    bit [PSINR_CALC_WIDTH-1:0]    tmp_out_data;
    bit [PSINR_DEMAP_WIDTH-1:0]    tmp_demap_data;
    bit [PSINR_CALC_WIDTH-1:0]    tmp_demod_data;
    bit [PSINR_OUT_REPORT_WIDTH-1:0] tmp_report_rtl_word;
    

    phase.raise_objection(this);
    super.run_phase (phase);

    // Execute several child processes in parallel

    fork
        // for (int tt=0; tt<taskNum; tt++) begin
            // if (cpofdm_q[tt] == 1) begin
                psinr_demap_check:begin
                    `uvm_info(get_full_name(), "waiting for psinr_calc layer_demapper data", UVM_LOW);
                    // for (int nn=0; nn < symb_num_q[tt]; nn++) begin
                        while (mp_psinr_demap_all_symb.size() != 0) begin
                            // @(psinr_gain_arrived);
                            #10ns;
                            if (psinr_demap_trans_q.size()!=0) begin
                                psinr_demap_tran   = psinr_demap_trans_q.pop_front();
                                // `uvm_info(get_full_name(), $sformatf("mp_psinr_demap_vec[%d] size is : %d",nn,mp_psinr_demap_vec[nn].size()), UVM_LOW);
                                `uvm_info(get_full_name(), $sformatf("psinr_calc layer_demap_tran size is : %d",psinr_demap_tran.data.size()), UVM_LOW);
                                for (int ii=0; ii < psinr_demap_tran.data.size(); ii++) begin
                                    psinr_demap_ref_word = mp_psinr_demap_all_symb.pop_front();
                                    tmp_demap_data = psinr_demap_tran.data[ii];
                                    case (num_res)
                                        2: begin 
                                            psinr_demap_rtl_word = {tmp_demap_data[15:0],tmp_demap_data[31:16]};
                                            // `uvm_info(get_full_name(), "num_res is 2", UVM_LOW);
                                        end
                                        4: begin 
                                            psinr_demap_rtl_word = {tmp_demap_data[15:0],tmp_demap_data[31:16],tmp_demap_data[47:32],tmp_demap_data[63:48]};
                                            // `uvm_info(get_full_name(), "num_res is 4", UVM_LOW);
                                        end
                                        8: begin
                                            psinr_demap_rtl_word = {tmp_demap_data[15:0],tmp_demap_data[31:16],tmp_demap_data[47:32],tmp_demap_data[63:48],
                                                                    tmp_demap_data[79:64],tmp_demap_data[95:80],tmp_demap_data[111:96],tmp_demap_data[127:112]};  
                                            // `uvm_info(get_full_name(), "num_res is 8", UVM_LOW);
                                        end
                                        16: begin 
                                            psinr_demap_rtl_word = {tmp_demap_data[15:0],tmp_demap_data[31:16],tmp_demap_data[47:32],tmp_demap_data[63:48],
                                                                    tmp_demap_data[79:64],tmp_demap_data[95:80],tmp_demap_data[111:96],tmp_demap_data[127:112],
                                                                    tmp_demap_data[143:128],tmp_demap_data[159:144],tmp_demap_data[175:160],tmp_demap_data[191:176],
                                                                    tmp_demap_data[207:192],tmp_demap_data[223:208],tmp_demap_data[239:224],tmp_demap_data[255:240]};  
                                            // `uvm_info(get_full_name(), "num_res is 16", UVM_LOW);
                                        end
                                    endcase
                                    //compare psinr demapper output
                                    if (psinr_demap_ref_word != psinr_demap_rtl_word )begin
                                        psinr_demap_status_q.push_back("KO");
                                        `uvm_error(get_full_name(), $sformatf("MP(psinr_calc layer_demap out): rtl data %h /= reference data %h rtl ori out=%h ",psinr_demap_rtl_word, psinr_demap_ref_word,tmp_demap_data));
                                    end
                                    else begin
                                        psinr_demap_status_q.push_back("OK");
                                    end
                                    psinr_demap_ref_word_q.push_back(psinr_demap_ref_word);
                                    psinr_demap_rtl_word_q.push_back(psinr_demap_rtl_word);
                                end
                                m_psinr_demap_mp_parser[0][0].log_mp_info(psinr_demap_ref_word_q, psinr_demap_rtl_word_q, psinr_demap_status_q);
                                psinr_demap_ref_word_q.delete();
                                psinr_demap_rtl_word_q.delete();
                                psinr_demap_status_q.delete();
                            end
                        end
                        `uvm_info(get_full_name(),"psinr_calc layer_demappper check done",UVM_LOW);
                    // end
                    // `uvm_info(get_full_name(), $sformatf("task%0d psinr_layer_demappper_output_check done",tt), UVM_LOW);
                // end
            end
            // else begin
                psinr_output_check:begin
                    `uvm_info(get_full_name(), "waiting for psinr_calc output data", UVM_LOW);
                    // for (int nn=0; nn < symb_num_q[tt]; nn++) begin
                       while (mp_psinr_out_all_symb.size() != 0) begin
                            // @(psinr_out_req);
                            #10ns;
                            if (psinr_out_trans_q.size()!=0) begin
                                psinr_out_tran   = psinr_out_trans_q.pop_front();
                                // `uvm_info(get_full_name(), $sformatf("mp_psinr_out_vec[%d] size is : %d",nn,mp_psinr_out_vec[nn].size()), UVM_LOW);
                                `uvm_info(get_full_name(), $sformatf("psinr_calc out_tran size is : %d",psinr_out_tran.data.size()), UVM_LOW);
                                for (int ii=0; ii < psinr_out_tran.data.size(); ii++) begin
                                    psinr_out_ref_word = mp_psinr_out_all_symb.pop_front();
                                    psinr_out_rtl_word = psinr_out_tran.data[ii];

                                    //compare psinr output
                                    if (psinr_out_ref_word != psinr_out_rtl_word )begin
                                        psinr_out_status_q.push_back("KO");
                                        `uvm_error(get_full_name(), $sformatf("MP(psinr_calc out) : rtl data %h /= reference data %h ",psinr_out_rtl_word, psinr_out_ref_word));
                                    end
                                    else begin
                                        psinr_out_status_q.push_back("OK");
                                    end
                                    psinr_out_ref_word_q.push_back(psinr_out_ref_word);
                                    psinr_out_rtl_word_q.push_back(psinr_out_rtl_word);

                                end
                                m_psinr_out_mp_parser[0][0].log_mp_info(psinr_out_ref_word_q, psinr_out_rtl_word_q, psinr_out_status_q);
                                psinr_out_ref_word_q.delete();
                                psinr_out_rtl_word_q.delete();
                                psinr_out_status_q.delete();
                            end
                        end
                    // end
                    `uvm_info(get_full_name(), "psinr_calc output check done", UVM_LOW);
                end
                psinr_demod_check:begin
                    `uvm_info(get_full_name(), "waitting for psinr_calc demod data", UVM_LOW);
                    // for (int nn=0; nn < symb_num_q[tt]; nn++) begin
                        while (mp_psinr_demod_all_symb.size() != 0) begin
                            #10ns;
                            if (psinr_demod_trans_q.size()!=0) begin
                                psinr_demod_tran   = psinr_demod_trans_q.pop_front();
                                // `uvm_info(get_full_name(), $sformatf("mp_psinr_demod_vec[%d] size is : %d",nn,mp_psinr_demod_vec[nn].size()), UVM_LOW);
                                `uvm_info(get_full_name(), $sformatf("psinr_calc demod_tran size is : %d",psinr_demod_tran.data.size()), UVM_LOW);
                                for(int ii=0; ii < psinr_demod_tran.data.size(); ii++) begin
                                    psinr_demod_ref_word = mp_psinr_demod_all_symb.pop_front();
                                    psinr_demod_rtl_word = psinr_demod_tran.data[ii];
                                    if (psinr_demod_ref_word != psinr_demod_rtl_word )begin
                                        psinr_demod_status_q.push_back("KO");
                                        `uvm_error(get_full_name(), $sformatf("MP(psinr_calc demod output) : rtl data %h /= reference tv data %h ",psinr_demod_rtl_word, psinr_demod_ref_word));
                                    end
                                    else begin
                                        psinr_demod_status_q.push_back("OK");
                                    end
                                    psinr_demod_rtl_word_q.push_back(psinr_demod_rtl_word);
                                    psinr_demod_ref_word_q.push_back(psinr_demod_ref_word);
                                end
                                m_psinr_demod_mp_parser[0][0].log_mp_info(psinr_demod_ref_word_q, psinr_demod_rtl_word_q, psinr_demod_status_q);
                                psinr_demod_ref_word_q.delete();
                                psinr_demod_rtl_word_q.delete();
                                psinr_demod_status_q.delete();
                            end
                        end
                        `uvm_info(get_full_name(), "psinr_calc demod_output check done", UVM_LOW);
                    end
                    // `uvm_info(get_full_name(), $sformatf("task%0d psinr_demod_output_check done",tt), UVM_LOW);
                // end
            // end
        // end
        psinr_out_report_check:begin
            // for (int tt=0; tt<taskNum; tt++) begin
                `uvm_info(get_full_name(), "waitting for psinr_out report data",UVM_LOW);
                // for (int nn=0; nn < report_symbNum_q[tt]; nn++) begin
                    while (mp_psinr_out_report_all_symb.size() != 0) begin
                        #10ns;
                        if (psinr_out_report_trans_q.size()!=0) begin
                            psinr_out_report_tran   = psinr_out_report_trans_q.pop_front();
                            // `uvm_info(get_full_name(), $sformatf("mp_psinr_demod_vec[%d] size is : %d",nn,mp_psinr_demod_vec[nn].size()), UVM_LOW);
                            `uvm_info(get_full_name(), $sformatf("psinr_out_report_tran size is : %d",psinr_out_report_tran.data.size()), UVM_LOW);
                            for(int ii=0; ii < psinr_out_report_tran.data.size(); ii++) begin
                                psinr_out_report_ref_word = mp_psinr_out_report_all_symb.pop_front();
                                tmp_report_rtl_word = psinr_out_report_tran.data[ii];
                                report_out_lth = report_out_lth + 1; 
                                if (report_out_lth > task_lth_q[task_idx]) begin
                                    task_idx = task_idx + 1;
                                    `uvm_info(get_full_name(), $sformatf("report_out_lth is : %d",report_out_lth), UVM_LOW);
                                    report_out_lth = 1;
                                end
                                if (processType_q[task_idx] == 5 || processType_q[task_idx] == 7) begin
                                    case (num_res)
                                        2: begin 
                                            psinr_out_report_rtl_word = {tmp_report_rtl_word[63:0]};
                                            // `uvm_info(get_full_name(), "num_res is 2", UVM_LOW);
                                        end
                                        4: begin 
                                            psinr_out_report_rtl_word = {tmp_report_rtl_word[63:0],tmp_report_rtl_word[127:64]};
                                            // `uvm_info(get_full_name(), "num_res is 4", UVM_LOW);
                                        end
                                        8: begin
                                            psinr_out_report_rtl_word = {tmp_report_rtl_word[63:0],tmp_report_rtl_word[127:64],tmp_report_rtl_word[191:128],tmp_report_rtl_word[255:192]};  
                                            // `uvm_info(get_full_name(), "num_res is 8", UVM_LOW);
                                        end
                                        16: begin 
                                            psinr_out_report_rtl_word = {tmp_report_rtl_word[63:0],tmp_report_rtl_word[127:64],tmp_report_rtl_word[191:128],tmp_report_rtl_word[255:192],
                                                                        tmp_report_rtl_word[319:256],tmp_report_rtl_word[383:320],tmp_report_rtl_word[447:384],tmp_report_rtl_word[511:448]};  
                                            // `uvm_info(get_full_name(), "num_res is 16", UVM_LOW);
                                        end
                                    endcase
                                end
                                else begin
                                    psinr_out_report_rtl_word = tmp_report_rtl_word;
                                end

                                if (psinr_out_report_ref_word != psinr_out_report_rtl_word )begin
                                    psinr_out_report_status_q.push_back("KO");
                                    `uvm_error(get_full_name(), $sformatf("MP(psinr_out report): rtl data %h /= reference tv data %h ",psinr_out_report_rtl_word, psinr_out_report_ref_word));
                                end
                                else begin
                                    psinr_out_report_status_q.push_back("OK");
                                end
                                psinr_out_report_rtl_word_q.push_back(psinr_out_report_rtl_word);
                                psinr_out_report_ref_word_q.push_back(psinr_out_report_ref_word);
                            end
                            m_psinr_out_report_mp_parser[0][0].log_mp_info(psinr_out_report_ref_word_q, psinr_out_report_rtl_word_q, psinr_out_report_status_q);
                            psinr_out_report_ref_word_q.delete();
                            psinr_out_report_rtl_word_q.delete();
                            psinr_out_report_status_q.delete();
                        end
                    end
                // end
                `uvm_info(get_full_name(), "psinr_out report check done",UVM_LOW);
            end
        // end

    join
	
	`uvm_info(get_full_name(), "*********all psinr(calc,out) MP check done*********",UVM_LOW);
	


    phase.drop_objection(this);
endtask: main_phase

// ----------------------------------------------------------------------------
function void psinr_sb::init_file_parser();

    // `uvm_info(get_full_name(), $sformatf("psinr scoreboard symb_num is %d", symb_num), UVM_LOW);
    // `uvm_info(get_full_name(), $sformatf("psinr scoreboard tv_path is %s", mp_path), UVM_LOW);
    m_psinr_demap_mp_parser = new[taskNum];
    mp_psinr_demap_vec = new[taskNum];
    m_psinr_out_mp_parser = new[taskNum];
    mp_psinr_out_vec = new[taskNum];
    m_psinr_demod_mp_parser = new[taskNum];
    mp_psinr_demod_vec = new[taskNum];
    m_psinr_out_report_mp_parser = new[taskNum];
    mp_psinr_out_report_vec = new[taskNum];
    
    for (int tt=0; tt<taskNum; tt++) begin
        symb_num = symb_num_q[tt];
        if (cpofdm_q[tt] == 1) begin
            m_psinr_demap_mp_parser[demap_index] = new[symb_num];
            mp_psinr_demap_vec[demap_index] = new[symb_num];
            for (int nn=0; nn<symb_num; nn++) begin
                //psinr demap
                m_psinr_demap_mp_parser[demap_index][nn] = file_parser#(PSINR_DEMAP_WIDTH)::type_id::create($sformatf("m_psinr_demap_mp_parser[%d][%d]",demap_index,nn));
                m_psinr_demap_mp_parser[demap_index][nn].set_file_path($sformatf("%s/PSinr_Calc_layer_demap_symb%0d.txt",mp_path_q[tt],nn));
                m_psinr_demap_mp_parser[demap_index][nn].set_log_path("matchpoints_logs/PSinr_Calc_layer_demap.log");
                m_psinr_demap_mp_parser[demap_index][nn].parse_file(mp_psinr_demap_vec[demap_index][nn]);
            
				for (int ii=0; ii<mp_psinr_demap_vec[demap_index][nn].size(); ii++) begin
					mp_psinr_demap_all_symb.push_back(mp_psinr_demap_vec[demap_index][nn][ii]);
				end
			end
            `uvm_info(get_full_name(), $sformatf("m_psinr_demap_mp_parser[%d] size is %d",tt, m_psinr_demap_mp_parser[demap_index].size()), UVM_LOW);
            demap_index <= demap_index + 1;
        end
        else begin
            m_psinr_out_mp_parser[tt] = new[symb_num];
            mp_psinr_out_vec[tt] = new[symb_num];
            m_psinr_demod_mp_parser[tt] = new[symb_num];
            mp_psinr_demod_vec[tt] = new[symb_num];

            for (int nn=0; nn<symb_num; nn++) begin
                //psinr out
                m_psinr_out_mp_parser[tt][nn] = file_parser#(PSINR_CALC_WIDTH)::type_id::create($sformatf("m_psinr_out_mp_parser[%d][%d]",tt,nn));
                m_psinr_out_mp_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Calc_out_symb%0d.txt",mp_path_q[tt],nn));
                m_psinr_out_mp_parser[tt][nn].set_log_path("matchpoints_logs/PSinr_Calc_out.log");
                m_psinr_out_mp_parser[tt][nn].parse_file(mp_psinr_out_vec[tt][nn]);
                //psinr demod
                m_psinr_demod_mp_parser[tt][nn] = file_parser#(PSINR_CALC_WIDTH)::type_id::create($sformatf("m_psinr_demod_mp_parser[%d][%d]",tt,nn));
                m_psinr_demod_mp_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Calc_dmod_symb%0d.txt",mp_path_q[tt],nn));
                m_psinr_demod_mp_parser[tt][nn].set_log_path("matchpoints_logs/PSinr_Calc_dmod.log");
                m_psinr_demod_mp_parser[tt][nn].parse_file(mp_psinr_demod_vec[tt][nn]);
           
				for (int ii=0; ii<mp_psinr_out_vec[tt][nn].size(); ii++) begin
					mp_psinr_out_all_symb.push_back(mp_psinr_out_vec[tt][nn][ii]);
				end
				for (int ii=0; ii<mp_psinr_demod_vec[tt][nn].size(); ii++) begin
					mp_psinr_demod_all_symb.push_back(mp_psinr_demod_vec[tt][nn][ii]);
				end
			end
        end
        `uvm_info(get_full_name(), $sformatf("mp_psinr_demap_all_symb size is %d", mp_psinr_demap_all_symb.size()), UVM_LOW);
        `uvm_info(get_full_name(), $sformatf("mp_psinr_demod_all_symb size is %d", mp_psinr_demod_all_symb.size()), UVM_LOW);
        `uvm_info(get_full_name(), $sformatf("mp_psinr_out_all_symb size is %d", mp_psinr_out_all_symb.size()), UVM_LOW);

        m_psinr_out_report_mp_parser[tt] = new[symb_num];
        mp_psinr_out_report_vec[tt] = new[symb_num];
        if (processType_q[tt] == 5 || processType_q[tt] == 7) begin
            report_symbNum_q.push_back(1);
			if (symb_num > 12 ) begin //need 2 768 word
				case(num_res)
                    2: begin 
                       task_lth = 2*12;//2*(768/(2*32))
                    end
					4: begin 
                       task_lth = 2*6;//2*(768/(4*32))
                    end
                    8: begin
                       task_lth = 2*3;//2*(768/(8*32))
                    end
                    16: begin 
                       task_lth = 2*2;//2*(768/(16*32)),向上取整
                    end
                endcase
			end 
			else begin
				case(num_res)
                    2: begin 
                       task_lth = 12;//(768/(2*32))
                    end
					4: begin 
                       task_lth = 6;//(768/(4*32))
                    end
                    8: begin
                       task_lth = 3;//(768/(8*32))
                    end
                    16: begin 
                       task_lth = 2;//(768/(16*32)),向上取整
                    end
                endcase
			end
		end
        else begin
            report_symbNum_q.push_back(symb_num_q[tt]);
			case(num_res)
                2: begin 
                   task_lth = 4*3*symb_num;//4layer*3compont(csi2/1/ack)
                end
				4: begin 
                   task_lth = 2*3*symb_num;//2layer*3compont(csi2/1/ack)
                end
                8: begin
                   task_lth = 3*symb_num;//3compont(csi2/1/ack)
                end
                16: begin 
                   task_lth = 2*symb_num;//2 lines put 3compont
                end
            endcase
		end
		`uvm_info(get_full_name(), $sformatf("report task_lth ... is %d", task_lth), UVM_LOW);
		task_lth_q.push_back(task_lth);

        for (int nn=0; nn<report_symbNum_q[tt]; nn++) begin
            //psinr out report
            m_psinr_out_report_mp_parser[tt][nn] = file_parser#(PSINR_OUT_REPORT_WIDTH)::type_id::create($sformatf("m_psinr_out_report_mp_parser[%d][%d]",tt, nn));
            m_psinr_out_report_mp_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Out_report_symb%0d.txt",mp_path_q[tt],nn));
            m_psinr_out_report_mp_parser[tt][nn].set_log_path("matchpoints_logs/PSinr_Out_report.log");
            m_psinr_out_report_mp_parser[tt][nn].parse_file(mp_psinr_out_report_vec[tt][nn]);
        
			for (int ii=0; ii<mp_psinr_out_report_vec[tt][nn].size(); ii++) begin
				mp_psinr_out_report_all_symb.push_back(mp_psinr_out_report_vec[tt][nn][ii]);
			end
		end
    end    

endfunction:init_file_parser

`endif
