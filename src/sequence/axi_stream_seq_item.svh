/*------------------------------------------------------------------------------

*/

`ifndef _AXI_ATREAM_SEQ_ITEM_SVH_
`define _AXI_ATREAM_SEQ_ITEM_SVH_
class axi_stream_seq_item #(int DATA_WIDTH = 128) extends uvm_sequence_item;

    rand logic  [DATA_WIDTH-1:0] data[];
    rand bit                     valid[];
    rand logic  [3:0]            last[];

    `uvm_object_utils_begin(axi_stream_seq_item#(DATA_WIDTH))
        `uvm_field_array_int(data,UVM_ALL_ON)
        `uvm_field_array_int(last,UVM_ALL_ON)
        `uvm_field_array_int(valid,UVM_ALL_ON)
    `uvm_object_utils_end

    //   `uvm_object_utils_begin(axi_stream_seq_item#(DATA_WIDTH))
    //     `uvm_field_queue_int(data,UVM_ALL_ON)
    //     `uvm_field_queue_int(last,UVM_ALL_ON)
    //     `uvm_field_queue_int(valid,UVM_ALL_ON)
    // `uvm_object_utils_end



    function new(string name = "axi_stream_seq_item");
        super.new(name);
    endfunction: new

    // // ------------------------------------------------------------------------
    function void init(int size);
        // data.delete();
        // valid.delete();
        // last.delete();

        data  = new[size];
        valid = new[size];
        last  = new[size];
    endfunction

endclass //_AXI_ATREAM_SEQ_ITEM_SVH_

`endif