/*------------------------------------------------------------------------------

*/
`ifndef _AXI_STREAM_SEQ_SVH_
`define _AXI_STREAM_SEQ_SVH_

// ----------------------------------------------------------------------------
// Class Definition 
// ----------------------------------------------------------------------------
class axi_stream_seq #(int DATA_WIDTH = 32) extends uvm_sequence #(axi_stream_seq_item#(DATA_WIDTH));
    `uvm_object_param_utils(axi_stream_seq#(DATA_WIDTH))

    // ------------------------------------------------------------------------
    // Attributes
    // ------------------------------------------------------------------------
    logic [DATA_WIDTH-1:0]  seq_data_q[$];
    logic [3:0]             seq_last;

    // ------------------------------------------------------------------------
    // Methods
    // ------------------------------------------------------------------------
    extern function     new (string name="axi_stream_seq");
    extern virtual task body();
    extern virtual task send( logic [DATA_WIDTH-1:0] data_q[$],logic [3:0] last,
                              uvm_sequencer_base    seqr,
                              uvm_sequence_base     parent = null);
  
endclass: axi_stream_seq

// ----------------------------------------------------------------------------
// Class Methods Implementation
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
function axi_stream_seq::new(string name="axi_stream_seq");
    super.new(name);
endfunction

// ----------------------------------------------------------------------------
task axi_stream_seq::body();
    axi_stream_seq_item#(DATA_WIDTH) tr;

    tr = axi_stream_seq_item#(DATA_WIDTH)::type_id::create("tr");

    if (this.seq_data_q.size() == 0) 
    begin
        `uvm_fatal(get_type_name(),"input data queue is empty");
    end

    tr.init(this.seq_data_q.size());

    // `uvm_info(get_full_name(), $sformatf(" init tr.data size is : %d  tr.last size is %d",tr.data.size(),tr.last.size()), UVM_LOW);

    for (int ii = 0 ; this.seq_data_q.size() != 0; ii++) 
    begin
        tr.data[ii]   = this.seq_data_q.pop_front();
        tr.valid[ii]  = 1;
        tr.last[ii]   = 0;
    end
    tr.last[tr.data.size()-1]  = this.seq_last; 
    
    start_item(tr);
    finish_item(tr); 
endtask

// ----------------------------------------------------------------------------
task axi_stream_seq::send( logic [DATA_WIDTH-1:0] data_q[$], logic [3:0] last,
                                       uvm_sequencer_base seqr,
                                       uvm_sequence_base parent = null);
    this.seq_data_q = data_q;
    this.seq_last = last;
    this.start(seqr, parent);
endtask

`endif  // AXI_STREAM_SEQ_SVH
