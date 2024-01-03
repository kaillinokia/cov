/*------------------------------------------------------------------------------

*/
`ifndef _TIME_MON_DRIVER_SVH_
`define _TIME_MON_DRIVER_SVH_

class time_mon_driver extends uvm_driver #(time_mon_seq_item);
    `uvm_component_utils(time_mon_driver)

    int       d_cnt_tab[3]; //slot\symbol\clk
    int       d_base_tab[3];
    
    int restart_flag = 0;


    virtual time_mon_if time_clk_if;
    time_mon_cfg time_cfg ;

  extern function new (string name = "time_mon_driver", uvm_component parent = null);
  extern function void build_phase(uvm_phase phase);
  extern task configure_phase(uvm_phase phase);
  extern task run_phase(uvm_phase phase);
  extern task run_timer();
  extern task wait_time(time_mon_seq_item time_mon_req);
  extern function void restart();

endclass : time_mon_driver


function time_mon_driver::new (string name = "time_mon_driver", uvm_component parent = null);
  super.new(name, parent);
endfunction : new


function void time_mon_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if (!uvm_config_db#(time_mon_cfg)::get(this, "", "time_mon_cfg", time_cfg)) begin
    `uvm_fatal(get_type_name(), "Can't get configuration object time_mon_cfg through config_db");
    
  end
      
endfunction : build_phase

task time_mon_driver::run_phase(uvm_phase phase);
  time_mon_seq_item time_mon_req;

  super.run_phase (phase);
  time_mon_req = time_mon_seq_item::type_id::create("time_mon_req");

  time_clk_if = time_cfg.time_clk_if;

  fork
    tb_time_running:begin
        run_timer();
    end

    wait_time_flag:begin
        forever begin
          seq_item_port.get_next_item(time_mon_req);
          wait_time(time_mon_req);
          seq_item_port.item_done();
        end
    end
  join_none
endtask

function void time_mon_driver::restart(); 
  `uvm_info(get_full_name(), "force restart timer", UVM_LOW);
  restart_flag = 1;

endfunction

task time_mon_driver::configure_phase(uvm_phase phase);
  phase.raise_objection(this);

  for (int i=0; i < 3; i++) d_base_tab[i]              = time_cfg.time_base_tab[i];
  for (int i=0; i < 3; i++) d_cnt_tab[i]               = time_cfg.time_start_tab[i];
  phase.drop_objection(this);
endtask: configure_phase

task time_mon_driver::run_timer();
  while(1) begin
    @(posedge time_clk_if.clk);
    if (restart_flag) begin
      for (int i=0; i < 3; i++) d_base_tab[i]              = time_cfg.time_base_tab[i];
      for (int i=0; i < 3; i++) d_cnt_tab[i]               = time_cfg.time_start_tab[i];
      restart_flag = 0;
    end 
    else begin
      d_cnt_tab[0] = d_cnt_tab[0] + 1; 
      for (int i=1; i < 3; i++)
        d_cnt_tab[i] = d_cnt_tab[i] + d_cnt_tab[i-1]/d_base_tab[i-1];

      for (int i=0; i < 3-1; i++)
        d_cnt_tab[i] = d_cnt_tab[i]%d_base_tab[i];
    end

    for (int i=0; i < 3; i++)
      time_clk_if.time_val_tab[i] = d_cnt_tab[i];

  end

endtask


task time_mon_driver::wait_time(time_mon_seq_item time_mon_req);
  int tick_t = 0;
  int current_cnt = 0;

  `uvm_info (get_type_name(), $sformatf("waiting for(slot/symbol): %0d,%0d; current time: %0d,%0d",time_mon_req.time_val_tab[2],time_mon_req.time_val_tab[1], d_cnt_tab[2],d_cnt_tab[1]), UVM_LOW);

  for (int i = 3; i > 0; i--) begin
    current_cnt  = current_cnt*d_base_tab[i-1] + d_cnt_tab[i-1];
  end

  for (int i= 3; i > 0; i--) begin
    tick_t      = tick_t*d_base_tab[i-1] + time_mon_req.time_val_tab[i-1];
  end

  while (tick_t > current_cnt ) begin
    @(posedge time_clk_if.clk);
    current_cnt = 0;
    for (int i= 3; i > 0; i--) begin
      current_cnt  = current_cnt*d_base_tab[i-1] + d_cnt_tab[i-1];
    end
  end
  `uvm_info (get_type_name(), $sformatf("end waiting for(slot/symbol): %0d,%0d; current time: %0d,%0d",time_mon_req.time_val_tab[2], time_mon_req.time_val_tab[1],d_cnt_tab[2],d_cnt_tab[1]), UVM_LOW);
  
endtask

`endif
