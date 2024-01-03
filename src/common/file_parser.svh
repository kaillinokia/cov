/*------------------------------------------------------------------------------
*/
`ifndef _FILE_PARSER_SVH_
`define _FILE_PARSER_SVH_

class file_parser#(int DATA_WIDTH=128) extends uvm_object;

  `uvm_object_utils(file_parser#(DATA_WIDTH))

  string     file_path;
  string     log_path;
  string     mp_file_path;
  // int        data_width;

  //tasks and functions
  extern function      new(string name = "file_parser");
  extern function void set_file_path(string tv_path);
  extern function void parse_file(output bit [DATA_WIDTH-1:0]   trans_data_q[$]); // read all content in file
  extern function void parse_cfg_file(output tr_cfg_t   tr_cfg_info); 
  extern function void set_log_path(string log_path);
  extern function void set_mp_file_path(string mp_file_path);
  // extern function void set_data_width(int data_width);

  extern function void log_mp_info(input bit [DATA_WIDTH-1:0] ref_words[$] , input bit [DATA_WIDTH-1:0] rtl_words[$] , input string tr_status[$]);


endclass : file_parser


function file_parser::new(string name = "file_parser");
  super.new(name);
endfunction : new

function void  file_parser::set_file_path(string tv_path);
  this.file_path = tv_path;
  `uvm_info(get_full_name(), $sformatf("input tv file path is %s",tv_path), UVM_LOW);
endfunction: set_file_path

function void  file_parser::set_log_path(string log_path);
  this.log_path = log_path;
  `uvm_info(get_full_name(), $sformatf("matchpoint log file path is %s",log_path), UVM_LOW);
endfunction: set_log_path

// function void  file_parser::set_data_width(int data_width);
//   this.data_width = data_width;
// endfunction: set_data_width

function void  file_parser::set_mp_file_path(string mp_file_path);
  this.mp_file_path = mp_file_path;
  `uvm_info(get_full_name(), $sformatf("matchpoint file path is %s",mp_file_path), UVM_LOW);
endfunction: set_mp_file_path


function void file_parser::parse_file(output bit [DATA_WIDTH-1:0]   trans_data_q[$]);

  string line;
  integer fileid;
  string error_string;
  integer error;
  int match_string=0;
  logic [DATA_WIDTH-1:0] tmp_data;


  fileid = $fopen(file_path, "r");
  if (fileid == 0) begin
    error = $ferror(fileid,error_string);
    // `uvm_fatal(get_full_name(),$sformatf("error find during parsing %s file, error_string is %s",file_path,error_string))
    `uvm_info(get_full_name(), $sformatf("error find during parsing %s file, error_string is %s",file_path,error_string), UVM_LOW);
  end

  while(!$feof(fileid)) begin
    if ($fgets(line,fileid)) begin
        match_string = $sscanf(line, "%h",tmp_data);
        //`uvm_info(get_full_name(), $sformatf("line is : %h",tmp_data), UVM_LOW);
        trans_data_q.push_back(tmp_data);
    end
  end

  $fclose(fileid);

  // return parsing_content;
endfunction : parse_file

function void file_parser::parse_cfg_file(output tr_cfg_t   tr_cfg_info);

  string line;
  integer fileid;
  string error_string;
  integer error;
  int match_string=0;
  // int bypass,du_ru_mode,processing_type,num_prbs,num_symbs,num_layers,puc_sprd_id,puc_f2_flag,sinr_calc_bypass;

  logic                             bypass;
  logic [2:0]                       du_ru_mode;
  logic [3:0]                       processing_type;
  logic [8:0]                       num_prbs;
  logic [3:0]                       num_symbs;
  logic [2:0]                       puc_sprd_id;
  logic [3:0]                       num_layers;
  logic [2:0]                       puc_f2_flag;
  logic [1:0]                       puc_sprd_type;
  logic                             psinr_calc_bypass;
  logic                             musu_mode;
  logic [27:0]                      sinr_cfg;

  fileid = $fopen(file_path, "r");
  if (fileid == 0) begin
    error = $ferror(fileid,error_string);
    `uvm_fatal(get_full_name(),$sformatf("error find during parsing %s file, error_string is %s",file_path,error_string))
  end

  while(!$feof(fileid)) begin
    if ($fgets(line,fileid)) begin
          //`uvm_info(get_full_name(), $sformatf("line is : %s",line), UVM_LOW);
          match_string = $sscanf(line, "#du_ru_mode=%d, processing_type=%d, nb_layer=%d, nb_sym=%d, nb_rb=%d, pucch_spread_seq_id=%d, pucch_spread_type=%d, sinr_calculation_bypass=%d, su_mu_mode=%d, configured_sinr=%d, puc_f2_flag=%d",
                                du_ru_mode,processing_type,num_layers,num_symbs,num_prbs,puc_sprd_id,puc_sprd_type,psinr_calc_bypass,musu_mode,sinr_cfg,puc_f2_flag);
          `uvm_info(get_full_name(), $sformatf("match_string is : %d",match_string), UVM_LOW);

          tr_cfg_info["du_ru_mode"] = du_ru_mode;
          tr_cfg_info["processing_type"] = processing_type;
          tr_cfg_info["num_prbs"] = num_prbs;
          tr_cfg_info["num_symbs"] = num_symbs;
          tr_cfg_info["num_layers"] = num_layers;
          tr_cfg_info["puc_sprd_id"] = puc_sprd_id;
          tr_cfg_info["puc_f2_flag"] = puc_f2_flag;
          tr_cfg_info["puc_sprd_type"] = puc_sprd_type;
          tr_cfg_info["psinr_calc_bypass"] = psinr_calc_bypass;
          tr_cfg_info["musu_mode"] = musu_mode;
          tr_cfg_info["sinr_cfg"] = sinr_cfg;

      end
  end

  $fclose(fileid);

endfunction : parse_cfg_file

function void file_parser::log_mp_info(input bit [DATA_WIDTH-1:0] ref_words[$] , input bit [DATA_WIDTH-1:0] rtl_words[$] , input string tr_status[$]);
  integer mp_fileid;

  mp_fileid = $fopen(log_path, "a");

  if (ref_words.size() != rtl_words.size()) begin
    `uvm_fatal(get_full_name(),$sformatf("ERROR: size mismatch when writing file %s: ref_words size = %0d , rtl_words size = %d",log_path,ref_words.size(),rtl_words.size()))
  end

  for(int i=0; i < rtl_words.size(); i++) begin
    if (tr_status[i] == "OK")
      $fwrite(mp_fileid,"%h %s\n",rtl_words[i],tr_status[i]);
    else
      $fwrite(mp_fileid,"rtl word = %h, ref word = %h  %s\n",rtl_words[i],ref_words[i],tr_status[i]);
  end

  $fclose(mp_fileid);

endfunction : log_mp_info

`endif //_FILE_PARSER_SVH_
