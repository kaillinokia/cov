/*------------------------------------------------------------------------------

*/

`ifndef _AXI_STREAM_SEQUENCER_SVH_
`define _AXI_STREAM_SEQUENCER_SVH_

class axi_stream_sequencer#(int DATA_WIDTH = 32) extends uvm_sequencer#(axi_stream_seq_item#(DATA_WIDTH));
 
    `uvm_component_utils(axi_stream_sequencer#(DATA_WIDTH))
   
    //constructor

    extern function new(string name, uvm_component parent);
endclass

function axi_stream_sequencer::new(string name, uvm_component parent);
  super.new(name,parent);
endfunction

`endif
