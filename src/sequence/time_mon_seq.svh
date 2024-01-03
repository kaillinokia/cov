/*------------------------------------------------------------------------------

*/
`ifndef _TIME_MON_SEQ_SVH_
`define _TIME_MON_SEQ_SVH_

class time_mon_seq extends uvm_sequence #(time_mon_seq_item);

   `uvm_object_utils(time_mon_seq)

  int time_tab[3];
  
   extern function new(string name="time_mon_seq");
   extern virtual task body();

   extern virtual task wait_time(input int wait_tab[3],
                                 input uvm_sequencer_base seqr,
                                 input uvm_sequence_base parent = null);


endclass

function time_mon_seq::new(string name="time_mon_seq");
   super.new(name);
endfunction

task time_mon_seq::body();
   time_mon_seq_item wait_time_trains;

   wait_time_trains = time_mon_seq_item::type_id::create("wait_time_trains");
   
   
    //for (int i=0; i < 3; i++)
        wait_time_trains.time_val_tab = this.time_tab;

    start_item(wait_time_trains);
    finish_item(wait_time_trains);
   
endtask


task time_mon_seq::wait_time(input int wait_tab[3],
                                       input uvm_sequencer_base seqr,
                                       input uvm_sequence_base parent = null);
   //for (int i=0; i < 3; i++)
    this.time_tab = wait_tab;
 
//   `uvm_info (get_type_name(), $sformatf("wait seq set at %0d %0d %0d %0d",d_tab[3],d_tab[2],d_tab[1],d_tab[0]), UVM_LOW);

   this.start(seqr, parent);

endtask


`endif //_TIME_MON_SEQ_SVH_

