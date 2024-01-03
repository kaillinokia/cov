/*------------------------------------------------------------------------------

*/
class time_mon_cfg extends uvm_object;
  `uvm_object_utils(time_mon_cfg)

  int   time_base_tab[3];     
  int   time_start_tab[3];    

  virtual	time_mon_if time_clk_if;

  extern function new(string name = "time_mon_cfg");
  

endclass: time_mon_cfg

function time_mon_cfg::new(string name = "time_mon_cfg");
    super.new(name);
endfunction

