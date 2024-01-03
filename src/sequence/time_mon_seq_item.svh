/*------------------------------------------------------------------------------

*/

`ifndef _TIME_MON_SEQ_ITEM_SV_
`define _TIME_MON_SEQ_ITEM_SV_

class time_mon_seq_item extends uvm_sequence_item;

  int   time_val_tab[3];


  `uvm_object_utils (time_mon_seq_item)

   function new(string name = "time_mon_seq_item");
      super.new(name);
   endfunction: new

endclass: time_mon_seq_item


`endif // _TIME_MON_SEQ_ITEM_SV_


