/*------------------------------------------------------------------------------

*/
`ifndef _AXI_STREAM_MONITOR_SVH_
`define _AXI_STREAM_MONITOR_SVH_

class axi_stream_monitor#(int DATA_WIDTH=32) extends uvm_monitor;

    `uvm_component_utils(axi_stream_monitor#(DATA_WIDTH))

    
    virtual axi_stream_if#(DATA_WIDTH) mot_vif;

    uvm_analysis_port #(axi_stream_seq_item#(DATA_WIDTH))  axi_analysis_port;

    extern function new(string name, uvm_component parent);
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual task main_phase(uvm_phase phase);
    extern virtual task monitor_output(axi_stream_seq_item#(DATA_WIDTH) tr);


endclass

function axi_stream_monitor::new(string name, uvm_component parent);
    super.new(name,parent); 
endfunction //new()

function void axi_stream_monitor::build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual axi_stream_if#(DATA_WIDTH) )::get(this, "", "mot_if", mot_vif))
       `uvm_fatal(get_full_name(), "cannot get monitor if");

    axi_analysis_port = new ("axi_analysis_port",this);
endfunction:build_phase

task axi_stream_monitor::main_phase(uvm_phase phase);
    axi_stream_seq_item#(DATA_WIDTH) tr;

    forever begin
        tr = axi_stream_seq_item#(DATA_WIDTH)::type_id::create("tr");
        monitor_output(tr);
        axi_analysis_port.write(tr);
        // `uvm_info(get_full_name(), $sformatf("tr.data.size() is : %d",tr.data.size()), UVM_LOW);

    end
endtask:main_phase 

task axi_stream_monitor::monitor_output(axi_stream_seq_item#(DATA_WIDTH) tr);
    logic  [DATA_WIDTH-1:0] data_q[$];
    logic                   valid_q[$];
    logic  [3:0]            last_q[$];

    while  (~(mot_vif.tvalid === 1'b1 && mot_vif.tready === 1'b1)) begin
       @(posedge mot_vif.aclk);
    end;
    while  (mot_vif.tvalid === 1'b1 && mot_vif.tready === 1'b1) begin
        data_q.push_back(mot_vif.tdata);
        valid_q.push_back(mot_vif.tvalid);
        last_q.push_back(mot_vif.tlast);
        // tr.data.push_back(mot_vif.tdata);
        // tr.valid.push_back(mot_vif.tvalid);
        // tr.last.push_back(mot_vif.tlast);
       @(posedge mot_vif.aclk);
    end;

    tr.init(data_q.size());

    for (int ii = 0 ; data_q.size() != 0; ii++) begin
        tr.data[ii] = data_q.pop_front();
        tr.valid[ii] = valid_q.pop_front();
        tr.last[ii] = last_q.pop_front();

        //`uvm_info(get_full_name(), $sformatf("tr.data is : %d",tr.data[ii]), UVM_LOW);
    end
    // `uvm_info(get_full_name(),"one output pkt receive done",UVM_LOW);
 
endtask:monitor_output


`endif  //_AXI_STREAM_MONITOR_SVH_

