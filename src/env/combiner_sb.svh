/*------------------------------------------------------------------------------

*/
`ifndef _COMBINER_SB_
`define _COMBINER_SB_

`uvm_analysis_imp_decl(_combiner_repc)
`uvm_analysis_imp_decl(_combiner)
`uvm_analysis_imp_decl(_combiner_gain)
class combiner_sb extends uvm_scoreboard;
    `uvm_component_utils(combiner_sb)

	axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)       combiner_out_trans_q[$];
    axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)       combiner_out_tran;
    // beta_mp_trans                                combiner_out_trans_buf[$];

    axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)       combiner_gain_trans_q[$];
    axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH)       combiner_gain_tran;

    // axi_stream_seq_item#(BETA_REPC_WIDTH)                        combiner_repc_trans_q[$];
    // axi_stream_seq_item#(BETA_REPC_WIDTH)                        combiner_repc_tran;

    // event                                        combiner_out_req;
    // event                                        combiner_gain_req;
    // event                                        combiner_repc_req;
    // event                                        combiner_out_arrived;
    // event                                        combiner_gain_arrived;
    // event                                        combiner_repc_arrived;
    
    file_parser#(BETA_OUT_MP_WIDTH)               m_comb_out_mp_parser[][]; 
    file_parser#(BETA_EXP_WIDTH)                  m_comb_out_exp_mp_parser[][]; 
    file_parser#(BETA_OUT_MP_WIDTH)               m_comb_gain_mp_parser[][];
    file_parser#(BETA_EXP_WIDTH)                  m_comb_gain_exp_mp_parser[][]; 
    // file_parser#(BETA_REPC_WIDTH)                  m_comb_repc_mp_parser[];

    tr_mp_q                                      mp_comb_out_vec[][];
    tr_exp_q                                     mp_comb_out_exp_vec[][];
    tr_mp_q                                      mp_comb_gain_vec[][];
    tr_exp_q                                     mp_comb_gain_exp_vec[][];
    tr_int_q                                     mp_comb_repc_vec[][];
    bit [BETA_OUT_MP_WIDTH-1:0]                  mp_comb_out_all_symb[$];
    bit [BETA_EXP_WIDTH-1:0]                     mp_comb_out_exp_all_symb[$];
    bit [BETA_OUT_MP_WIDTH-1:0]                  mp_comb_gain_all_symb[$];
    bit [BETA_EXP_WIDTH-1:0]                     mp_comb_gain_exp_all_symb[$];
    
    string                                       mp_path_q[$];
    logic [3:0]                                  symb_num;
    logic [8:0]                                  rb_num_q[$];
    logic [3:0]                                  layer_num_q[$];
    logic [3:0]                                  symb_num_q[$];

    int                                          num_res;
    bit                                          cpofdm_q[$];
    int                                          taskNum;
    int                                          combiner_out_lth;
    int                                          task_lth;
    int                                          task_lth_q[$];
    int                                          task_idx=0;
    int                                          lines_perlayer;
  
    // virtual top_test_if sb_top_test_vif;

    // Ports
    // uvm_analysis_imp_combiner_repc#(axi_stream_seq_item#(BETA_REPC_WIDTH),combiner_sb)                     combiner_repc_imp;
    uvm_analysis_imp_combiner#(axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH),combiner_sb)          combiner_imp;
    uvm_analysis_imp_combiner_gain#(axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH),combiner_sb)     combiner_gain_imp;

    // ------------------------------------------------------------------------
    // Methods
    // ------------------------------------------------------------------------
    extern function                     new             (string name="combiner_sb", uvm_component parent=null);
    extern virtual function void        build_phase     (uvm_phase phase);
    extern task                         configure_phase (uvm_phase phase);
    extern virtual function void        write_combiner    (axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH) t);
    // extern virtual function void        write_combiner_repc    (axi_stream_seq_item#(BETA_REPC_WIDTH) t);
    extern virtual function void        write_combiner_gain    (axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH) t);
    extern task                         main_phase      (uvm_phase phase);
    extern virtual function void        init_file_parser();
endclass: combiner_sb


function combiner_sb::new(string name="combiner_sb", uvm_component parent=null);
    super.new(name, parent);
endfunction: new

// ----------------------------------------------------------------------------
function void combiner_sb::build_phase(uvm_phase phase);
    // Use parent method
    super.build_phase(phase);

    // Create instance for ports
    combiner_imp = new("combiner_imp", this);
    combiner_gain_imp = new("combiner_gain_imp", this);
    // combiner_repc_imp = new("combiner_repc_imp", this);

    init_file_parser();

endfunction: build_phase

// ----------------------------------------------------------------------------
task combiner_sb::configure_phase(uvm_phase phase);
    phase.raise_objection(this);
    phase.drop_objection(this);
endtask: configure_phase

// ----------------------------------------------------------------------------
function void combiner_sb::write_combiner (axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH) t);
    
	// combiner_trans.init(t.data.size());
    combiner_out_trans_q.push_back(t);
    // `uvm_info(get_full_name(), $sformatf("receive combiner out size is %d",t.data.size()), UVM_LOW);

    // -> combiner_out_req;
endfunction

// ----------------------------------------------------------------------------
// function void combiner_sb::write_combiner_repc (axi_stream_seq_item#(BETA_REPC_WIDTH) t);
    
// 	// combiner_status_trans.init(t.data.size());
//     combiner_repc_trans_q.push_back(t);
//     // `uvm_info(get_full_name(), $sformatf("receive combiner repc size is %d",t.data.size()), UVM_LOW);

//     // -> combiner_repc_req;
// endfunction

// ----------------------------------------------------------------------------
function void combiner_sb::write_combiner_gain (axi_stream_seq_item#(BETA_INOUT_WIDTH+BETA_EXP_WIDTH) t);
    
	// combiner_status_trans.init(t.data.size());
    combiner_gain_trans_q.push_back(t);
    // `uvm_info(get_full_name(), $sformatf("receive combiner gain size is %d",t.data.size()), UVM_LOW);

    // -> combiner_gain_req;
endfunction



// ----------------------------------------------------------------------------
task combiner_sb::main_phase(uvm_phase phase);
    bit [BETA_OUT_MP_WIDTH-1:0] comb_out_ref_word;
    bit [BETA_OUT_MP_WIDTH-1:0] comb_out_rtl_word;
    bit [BETA_OUT_MP_WIDTH-1:0] comb_out_ref_word_q[$];
    bit [BETA_OUT_MP_WIDTH-1:0] comb_out_rtl_word_q[$];
    string                      comb_out_status_q[$];
    bit [BETA_EXP_WIDTH-1:0]    comb_out_exp_ref_word;
    bit [BETA_EXP_WIDTH-1:0]    comb_out_exp_rtl_word;
    bit [BETA_EXP_WIDTH-1:0]    comb_out_exp_ref_word_q[$];
    bit [BETA_EXP_WIDTH-1:0]    comb_out_exp_rtl_word_q[$];
    string                      comb_out_exp_status_q[$];

    bit [BETA_OUT_MP_WIDTH-1:0] comb_gain_ref_word;
    bit [BETA_OUT_MP_WIDTH-1:0] comb_gain_rtl_word;
    bit [BETA_OUT_MP_WIDTH-1:0] comb_gain_ref_word_q[$];
    bit [BETA_OUT_MP_WIDTH-1:0] comb_gain_rtl_word_q[$];
    string                      comb_gain_status_q[$];
    bit [BETA_EXP_WIDTH-1:0]    comb_gain_exp_ref_word;
    bit [BETA_EXP_WIDTH-1:0]    comb_gain_exp_rtl_word;
    bit [BETA_EXP_WIDTH-1:0]    comb_gain_exp_ref_word_q[$];
    bit [BETA_EXP_WIDTH-1:0]    comb_gain_exp_rtl_word_q[$];
    string                      comb_gain_exp_status_q[$];

    bit [BETA_INOUT_WIDTH-1:0]                 tmp_data;
    bit [BETA_EXP_WIDTH-1:0]                   tmp_exp_data;
    bit [BETA_INOUT_WIDTH-1:0]                 tmp_gain_data;
    bit [BETA_EXP_WIDTH-1:0]                   tmp_gain_exp_data;
    

    phase.raise_objection(this);
    super.run_phase (phase);

    // Execute several child processes in parallel

    fork
        combiner_output_check:begin
            //for (int tt=0; tt<taskNum; tt++) begin
            `uvm_info(get_full_name(), "waitting for combiner output data", UVM_LOW);
                //for (int nn=0; nn < symb_num_q[tt]; nn++) begin
                    while (mp_comb_out_all_symb.size() != 0) begin
                        // @(combiner_out_req);
                        #10ns;
                        if (combiner_out_trans_q.size()!=0) begin
                            combiner_out_tran   = combiner_out_trans_q.pop_front();
                             //`uvm_info(get_full_name(), $sformatf("mp_comb_out_vec[%d] size is : %d",nn,mp_comb_out_vec[nn].size()), UVM_LOW);
                             `uvm_info(get_full_name(), $sformatf("combiner out_tran size is : %d",combiner_out_tran.data.size()), UVM_LOW);
                            for (int ii=0; ii < combiner_out_tran.data.size(); ii++) begin
                                comb_out_ref_word = mp_comb_out_all_symb.pop_front();
                                comb_out_exp_ref_word = mp_comb_out_exp_all_symb.pop_front();
                                tmp_data = combiner_out_tran.data[ii][BETA_INOUT_WIDTH-1:0];
                                tmp_exp_data = combiner_out_tran.data[ii][BETA_INOUT_WIDTH+BETA_EXP_WIDTH-1:BETA_INOUT_WIDTH];
                                combiner_out_lth = combiner_out_lth + 1; 
                                if (combiner_out_lth > task_lth_q[task_idx]) begin
                                    task_idx = task_idx + 1;
                                    `uvm_info(get_full_name(), $sformatf("combiner out_lth is : %d",combiner_out_lth), UVM_LOW);
                                    combiner_out_lth = 1;
                                end
                                if (cpofdm_q[task_idx] == 1) begin
                                    case (num_res)
                                        2: begin 
                                            comb_out_rtl_word = {{1'b0,tmp_data[14:0]},{1'b0,tmp_data[29:15]}};
                                            comb_out_exp_rtl_word = {tmp_exp_data[7:0],tmp_exp_data[15:8]};
                                            // `uvm_info(get_full_name(), "num_res is 2", UVM_LOW);
                                        end
                                        4: begin 
                                            comb_out_rtl_word = {{1'b0,tmp_data[14:0]},{1'b0,tmp_data[29:15]},{1'b0,tmp_data[44:30]},{1'b0,tmp_data[59:45]}};
                                            comb_out_exp_rtl_word = {tmp_exp_data[7:0],tmp_exp_data[15:8],tmp_exp_data[23:16],tmp_exp_data[31:24]};
                                            // `uvm_info(get_full_name(), "num_res is 4", UVM_LOW);
                                        end
                                        8: begin
                                            comb_out_rtl_word = {{1'b0,tmp_data[14:0]},{1'b0,tmp_data[29:15]},{1'b0,tmp_data[44:30]},{1'b0,tmp_data[59:45]},
                                                                 {1'b0,tmp_data[74:60]},{1'b0,tmp_data[89:75]},{1'b0,tmp_data[104:90]},{1'b0,tmp_data[119:105]}}; 
                                            comb_out_exp_rtl_word = {tmp_exp_data[7:0],tmp_exp_data[15:8],tmp_exp_data[23:16],tmp_exp_data[31:24],
                                                                     tmp_exp_data[39:32],tmp_exp_data[47:40],tmp_exp_data[55:48],tmp_exp_data[63:56]}; 
                                            // `uvm_info(get_full_name(), "num_res is 8", UVM_LOW);
                                        end
                                        16: begin 
                                            comb_out_rtl_word = {{1'b0,tmp_data[14:0]},{1'b0,tmp_data[29:15]},{1'b0,tmp_data[44:30]},{1'b0,tmp_data[59:45]},
                                                                 {1'b0,tmp_data[74:60]},{1'b0,tmp_data[89:75]},{1'b0,tmp_data[104:90]},{1'b0,tmp_data[119:105]},
                                                                 {1'b0,tmp_data[134:120]},{1'b0,tmp_data[149:135]},{1'b0,tmp_data[164:150]},{1'b0,tmp_data[179:165]},
                                                                 {1'b0,tmp_data[194:180]},{1'b0,tmp_data[209:195]},{1'b0,tmp_data[224:210]},{1'b0,tmp_data[239:225]}}; 
                                            comb_out_exp_rtl_word = {tmp_exp_data[7:0],tmp_exp_data[15:8],tmp_exp_data[23:16],tmp_exp_data[31:24],
                                                                     tmp_exp_data[39:32],tmp_exp_data[47:40],tmp_exp_data[55:48],tmp_exp_data[63:56],
                                                                     tmp_exp_data[71:64],tmp_exp_data[79:72],tmp_exp_data[87:80],tmp_exp_data[95:88],
                                                                     tmp_exp_data[103:96],tmp_exp_data[111:104],tmp_exp_data[119:112],tmp_exp_data[127:120]};  
                                            // `uvm_info(get_full_name(), "num_res is 16", UVM_LOW);
                                        end
                                    endcase
                                end
                                else begin
                                    comb_out_rtl_word = {0,tmp_data[14:0]};
                                    case (num_res)
                                        2: comb_out_exp_rtl_word = {tmp_exp_data[7:0],tmp_exp_data[15:8]};
                                        4: comb_out_exp_rtl_word = {tmp_exp_data[7:0],tmp_exp_data[15:8],tmp_exp_data[23:16],tmp_exp_data[31:24]};
                                        8: comb_out_exp_rtl_word = {tmp_exp_data[7:0],tmp_exp_data[15:8],tmp_exp_data[23:16],tmp_exp_data[31:24],
                                                                    tmp_exp_data[39:32],tmp_exp_data[47:40],tmp_exp_data[55:48],tmp_exp_data[63:56]}; 
                                        16: comb_out_exp_rtl_word = {tmp_exp_data[7:0],tmp_exp_data[15:8],tmp_exp_data[23:16],tmp_exp_data[31:24],
                                                                     tmp_exp_data[39:32],tmp_exp_data[47:40],tmp_exp_data[55:48],tmp_exp_data[63:56],
                                                                     tmp_exp_data[71:64],tmp_exp_data[79:72],tmp_exp_data[87:80],tmp_exp_data[95:88],
                                                                     tmp_exp_data[103:96],tmp_exp_data[111:104],tmp_exp_data[119:112],tmp_exp_data[127:120]}; 
                                    endcase
                                end
                                //compare combiner psinr output
                                if (comb_out_ref_word != comb_out_rtl_word )begin
                                    comb_out_status_q.push_back("KO");
                                `uvm_error(get_full_name(), $sformatf("MP(combnier out): rtl data %h /= reference data %h rtl ori out=%h ",comb_out_rtl_word, comb_out_ref_word,tmp_data));
                                end
                                else begin
                                    comb_out_status_q.push_back("OK");
                                end
                                comb_out_ref_word_q.push_back(comb_out_ref_word);
                                comb_out_rtl_word_q.push_back(comb_out_rtl_word);
                                //compare combiner psinr exp output
                                if (comb_out_exp_ref_word != comb_out_exp_rtl_word )begin
                                    comb_out_exp_status_q.push_back("KO");
                                `uvm_error(get_full_name(), $sformatf("MP(combiner exp out): rtl data %h /= reference data %h ",comb_out_exp_rtl_word, comb_out_exp_ref_word));
                                end
                                else begin
                                    comb_out_exp_status_q.push_back("OK");
                                end
                                comb_out_exp_ref_word_q.push_back(comb_out_exp_ref_word);
                                comb_out_exp_rtl_word_q.push_back(comb_out_exp_rtl_word);
                            end
                            m_comb_out_mp_parser[0][0].log_mp_info(comb_out_ref_word_q, comb_out_rtl_word_q, comb_out_status_q);
                            comb_out_ref_word_q.delete();
                            comb_out_rtl_word_q.delete();
                            comb_out_status_q.delete();
                            m_comb_out_exp_mp_parser[0][0].log_mp_info(comb_out_exp_ref_word_q, comb_out_exp_rtl_word_q, comb_out_exp_status_q);
                            comb_out_exp_ref_word_q.delete();
                            comb_out_exp_rtl_word_q.delete();
                            comb_out_exp_status_q.delete();
                        end
                    end
		            `uvm_info(get_full_name(), "combiner out check done", UVM_LOW);
                //end
                //`uvm_info(get_full_name(), $sformatf("task%0d combiner out data check done",tt), UVM_LOW);
            //end
            
        end
        combiner_gain_check:begin
            //for (int tt=0; tt<taskNum; tt++) begin
            `uvm_info(get_full_name(), "waitting for combiner gain data", UVM_LOW);
                //for (int nn=0; nn < symb_num_q[tt]; nn++) begin
                    while (mp_comb_gain_all_symb.size() != 0) begin
                        // @(combiner_gain_arrived);
                        #10ns;
                        if (combiner_gain_trans_q.size()!=0) begin
                            combiner_gain_tran   = combiner_gain_trans_q.pop_front();
                            // `uvm_info(get_full_name(), $sformatf("mp_comb_gain_vec[%d] size is : %d",nn,mp_comb_gain_vec[nn].size()), UVM_LOW);
                             `uvm_info(get_full_name(), $sformatf("combiner gain_tran size is : %d",combiner_gain_tran.data.size()), UVM_LOW);
                            for (int ii=0; ii < combiner_gain_tran.data.size(); ii++) begin
                                comb_gain_ref_word = mp_comb_gain_all_symb.pop_front();
                                comb_gain_exp_ref_word = mp_comb_gain_exp_all_symb.pop_front();
                                tmp_gain_data = combiner_gain_tran.data[ii][BETA_INOUT_WIDTH-1:0];
                                tmp_gain_exp_data = combiner_gain_tran.data[ii][BETA_INOUT_WIDTH+BETA_EXP_WIDTH-1:BETA_INOUT_WIDTH];
                                case (num_res)
                                    2: begin 
                                        comb_gain_rtl_word = {{1'b0,tmp_gain_data[14:0]},{1'b0,tmp_gain_data[29:15]}};
                                        comb_gain_exp_rtl_word = {tmp_gain_exp_data[7:0],tmp_gain_exp_data[15:8]};
                                        // `uvm_info(get_full_name(), "num_res is 2", UVM_LOW);
                                    end
                                    4: begin 
                                        comb_gain_rtl_word = {{1'b0,tmp_gain_data[14:0]},{1'b0,tmp_gain_data[29:15]},{1'b0,tmp_gain_data[44:30]},{1'b0,tmp_gain_data[59:45]}};
                                        comb_gain_exp_rtl_word = {tmp_gain_exp_data[7:0],tmp_gain_exp_data[15:8],tmp_gain_exp_data[23:16],tmp_gain_exp_data[31:24]};
                                        // `uvm_info(get_full_name(), "num_res is 4", UVM_LOW);
                                    end
                                    8: begin
                                        comb_gain_rtl_word = {{1'b0,tmp_gain_data[14:0]},{1'b0,tmp_gain_data[29:15]},{1'b0,tmp_gain_data[44:30]},{1'b0,tmp_gain_data[59:45]},
                                                              {1'b0,tmp_gain_data[74:60]},{1'b0,tmp_gain_data[89:75]},{1'b0,tmp_gain_data[104:90]},{1'b0,tmp_gain_data[119:105]}};
                                        comb_gain_exp_rtl_word = {tmp_gain_exp_data[7:0],tmp_gain_exp_data[15:8],tmp_gain_exp_data[23:16],tmp_gain_exp_data[31:24],
                                                                  tmp_gain_exp_data[39:32],tmp_gain_exp_data[47:40],tmp_gain_exp_data[55:48],tmp_gain_exp_data[63:56]};  
                                        // `uvm_info(get_full_name(), "num_res is 8", UVM_LOW);
                                    end
                                    16: begin 
                                        comb_gain_rtl_word = {{1'b0,tmp_gain_data[14:0]},{1'b0,tmp_gain_data[29:15]},{1'b0,tmp_gain_data[44:30]},{1'b0,tmp_gain_data[59:45]},
                                                                             {1'b0,tmp_gain_data[74:60]},{1'b0,tmp_gain_data[89:75]},{1'b0,tmp_gain_data[104:90]},{1'b0,tmp_gain_data[119:105]},
                                                                             {1'b0,tmp_gain_data[134:120]},{1'b0,tmp_gain_data[149:135]},{1'b0,tmp_gain_data[164:150]},{1'b0,tmp_gain_data[179:165]},
                                                                             {1'b0,tmp_gain_data[194:180]},{1'b0,tmp_gain_data[209:195]},{1'b0,tmp_gain_data[224:210]},{1'b0,tmp_gain_data[239:225]}};  
                                        comb_gain_exp_rtl_word = {tmp_gain_exp_data[7:0],tmp_gain_exp_data[15:8],tmp_gain_exp_data[23:16],tmp_gain_exp_data[31:24],
                                                                  tmp_gain_exp_data[39:32],tmp_gain_exp_data[47:40],tmp_gain_exp_data[55:48],tmp_gain_exp_data[63:56],
                                                                  tmp_gain_exp_data[71:64],tmp_gain_exp_data[79:72],tmp_gain_exp_data[87:80],tmp_gain_exp_data[95:88],
                                                                  tmp_gain_exp_data[103:96],tmp_gain_exp_data[111:104],tmp_gain_exp_data[119:112],tmp_gain_exp_data[127:120]};
                                        // `uvm_info(get_full_name(), "num_res is 16", UVM_LOW);
                                    end
                                endcase
                                //compare combiner gain output
                                if (comb_gain_ref_word != comb_gain_rtl_word )begin
                                    comb_gain_status_q.push_back("KO");
                                    `uvm_error(get_full_name(), $sformatf("MP(combiner gain out) : rtl data %h /= reference data %h rtl ori out=%h ",comb_gain_rtl_word, comb_gain_ref_word,tmp_gain_data));
                                end
                                else begin
                                    comb_gain_status_q.push_back("OK");
                                end
                                comb_gain_ref_word_q.push_back(comb_gain_ref_word);
                                comb_gain_rtl_word_q.push_back(comb_gain_rtl_word);
                                //compare combiner gain exp output
                                if (comb_gain_exp_ref_word != comb_gain_exp_rtl_word )begin
                                    comb_gain_exp_status_q.push_back("KO");
                                    `uvm_error(get_full_name(), $sformatf("MP(comb gain exp out): rtl data %h /= reference data %h ",comb_gain_exp_rtl_word, comb_gain_exp_ref_word));
                                end
                                else begin
                                    comb_gain_exp_status_q.push_back("OK");
                                end
                                comb_gain_exp_ref_word_q.push_back(comb_gain_exp_ref_word);
                                comb_gain_exp_rtl_word_q.push_back(comb_gain_exp_rtl_word);
                            end
                            m_comb_gain_mp_parser[0][0].log_mp_info(comb_gain_ref_word_q, comb_gain_rtl_word_q, comb_gain_status_q);
                            comb_gain_ref_word_q.delete();
                            comb_gain_rtl_word_q.delete();
                            comb_gain_status_q.delete();
                            m_comb_gain_exp_mp_parser[0][0].log_mp_info(comb_gain_exp_ref_word_q, comb_gain_exp_rtl_word_q, comb_gain_exp_status_q);
                            comb_gain_exp_ref_word_q.delete();
                            comb_gain_exp_rtl_word_q.delete();
                            comb_gain_exp_status_q.delete();
                        end
                    end
                    `uvm_info(get_full_name(), "combiner gain data check done", UVM_LOW);
                //end
                //`uvm_info(get_full_name(), $sformatf("task%0d combiner gain data check done",tt), UVM_LOW);
            //end
        end
    join
	`uvm_info(get_full_name(), "*********all combiner MP check done*********", UVM_LOW);


    phase.drop_objection(this);
endtask: main_phase

// ----------------------------------------------------------------------------
function void combiner_sb::init_file_parser();

    // `uvm_info(get_full_name(), $sformatf("psinr scoreboard symb_num is %d", symb_num), UVM_LOW);
    // `uvm_info(get_full_name(), $sformatf("psinr scoreboard tv_path is %s", mp_path), UVM_LOW);
    m_comb_out_mp_parser = new[taskNum];  
    mp_comb_out_vec = new[taskNum]; 
    m_comb_out_exp_mp_parser = new[taskNum]; 
    mp_comb_out_exp_vec = new[taskNum]; 
    m_comb_gain_mp_parser = new[taskNum];
    mp_comb_gain_vec          = new[taskNum];               
    m_comb_gain_exp_mp_parser = new[taskNum];              
    mp_comb_gain_exp_vec      = new[taskNum];         

    for (int tt=0; tt<taskNum; tt++) begin
        symb_num = symb_num_q[tt];
        if (cpofdm_q[tt] == 1) begin
            lines_perlayer = (rb_num_q[tt]*12)/num_res; 
            if ((rb_num_q[tt]*12)%num_res != 0)
                lines_perlayer = lines_perlayer + 1;
            task_lth = lines_perlayer*layer_num_q[tt]*symb_num;
        end
        else begin
            task_lth = layer_num_q[tt]*symb_num;
        end
        task_lth_q.push_back(task_lth); 
        `uvm_info(get_full_name(), $sformatf("combiner task_lth ... is %d", task_lth), UVM_LOW);
        
        m_comb_out_mp_parser[tt] = new[symb_num];
        mp_comb_out_vec[tt] = new[symb_num];
        m_comb_out_exp_mp_parser[tt] = new[symb_num];
        mp_comb_out_exp_vec[tt] = new[symb_num];

        m_comb_gain_mp_parser[tt] = new[symb_num];
        mp_comb_gain_vec[tt] = new[symb_num];
        m_comb_gain_exp_mp_parser[tt] = new[symb_num];
        mp_comb_gain_exp_vec[tt] = new[symb_num];


        for (int nn=0; nn<symb_num; nn++) begin
            //beta psinr mp
            m_comb_out_mp_parser[tt][nn] = file_parser#(BETA_OUT_MP_WIDTH)::type_id::create($sformatf("m_comb_out_mp_parser[%d][%d]", tt,nn));
            m_comb_out_mp_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Calc_C_Rhh_out_psinr_symb%0d.txt",mp_path_q[tt],nn));
            m_comb_out_mp_parser[tt][nn].set_log_path("matchpoints_logs/PSinr_Calc_C_Rhh_out_psinr.log");
            m_comb_out_mp_parser[tt][nn].parse_file(mp_comb_out_vec[tt][nn]);

            m_comb_out_exp_mp_parser[tt][nn] = file_parser#(BETA_EXP_WIDTH)::type_id::create($sformatf("m_comb_out_exp_mp_parser[%d]", nn));
            m_comb_out_exp_mp_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Calc_E_out_psinr_symb%0d.txt",mp_path_q[tt],nn));
            m_comb_out_exp_mp_parser[tt][nn].set_log_path("matchpoints_logs/PSinr_Calc_E_out_psinr.log");
            m_comb_out_exp_mp_parser[tt][nn].parse_file(mp_comb_out_exp_vec[tt][nn]);

            for (int ii=0; ii<mp_comb_out_vec[tt][nn].size(); ii++) begin
                mp_comb_out_all_symb.push_back(mp_comb_out_vec[tt][nn][ii]);
                mp_comb_out_exp_all_symb.push_back(mp_comb_out_exp_vec[tt][nn][ii]);
            end
            // beta gain mp 
            m_comb_gain_mp_parser[tt][nn] = file_parser#(BETA_OUT_MP_WIDTH)::type_id::create($sformatf("m_comb_gain_mp_parser[%d]", nn));
            m_comb_gain_mp_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Calc_C_Rhh_out_gainnorm_symb%0d.txt",mp_path_q[tt],nn));
            m_comb_gain_mp_parser[tt][nn].set_log_path("matchpoints_logs/PSinr_Calc_C_Rhh_out_gainnorm.log");
            m_comb_gain_mp_parser[tt][nn].parse_file(mp_comb_gain_vec[tt][nn]);

            m_comb_gain_exp_mp_parser[tt][nn] = file_parser#(BETA_EXP_WIDTH)::type_id::create($sformatf("m_comb_gain_exp_mp_parser[%d]", nn));
            m_comb_gain_exp_mp_parser[tt][nn].set_file_path($sformatf("%s/PSinr_Calc_E_out_gainnorm_symb%0d.txt",mp_path_q[tt],nn));
            m_comb_gain_exp_mp_parser[tt][nn].set_log_path("matchpoints_logs/PSinr_Calc_E_out_gainnorm.log");
            m_comb_gain_exp_mp_parser[tt][nn].parse_file(mp_comb_gain_exp_vec[tt][nn]);

            for (int ii=0; ii<mp_comb_gain_vec[tt][nn].size(); ii++) begin
                mp_comb_gain_all_symb.push_back(mp_comb_gain_vec[tt][nn][ii]);
                mp_comb_gain_exp_all_symb.push_back(mp_comb_gain_exp_vec[tt][nn][ii]);
            end
        end
    end

    `uvm_info(get_full_name(), $sformatf("mp_comb_out_all_symb size is %d", mp_comb_out_all_symb.size()), UVM_LOW);
    `uvm_info(get_full_name(), $sformatf("mp_comb_gain_all_symb size is %d", mp_comb_gain_all_symb.size()), UVM_LOW);

    

endfunction:init_file_parser

`endif
