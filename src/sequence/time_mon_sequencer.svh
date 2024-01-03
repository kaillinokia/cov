/*------------------------------------------------------------------------------

*/
`ifndef _TIME_MON_SEQUENCER_SVH_
`define _TIME_MON_SEQUENCER_SVH_
class time_mon_sequencer extends uvm_sequencer #(time_mon_seq_item);

   `uvm_component_utils(time_mon_sequencer)
   
   extern function new (string name="", uvm_component parent = null);
   
   
endclass : time_mon_sequencer


function time_mon_sequencer::new (string name="", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

`endif //_TIME_MON_SEQUENCER_SVH_
