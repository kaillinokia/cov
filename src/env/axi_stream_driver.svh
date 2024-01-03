/*------------------------------------------------------------------------------
*/
`ifndef AXI_STREAM_DRIVER_SVH_
`define AXI_STREAM_DRIVER_SVH_

class axi_stream_driver#(int DATA_WIDTH=32) extends uvm_driver #(axi_stream_seq_item#(DATA_WIDTH));
  `uvm_component_utils(axi_stream_driver#(DATA_WIDTH))

  virtual axi_stream_if#(DATA_WIDTH) drv_vif;


  function new(string name, uvm_component parent);
    super.new(name, parent);

  endfunction: new

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task run_phase(uvm_phase phase);
  extern virtual task drive_one_pkt(REQ tr);

endclass: axi_stream_driver

function void axi_stream_driver::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db#(virtual axi_stream_if#(DATA_WIDTH) )::get(this, "", "drv_if", drv_vif))
    `uvm_fatal(get_full_name(), "cannot get driver vif");

  if(drv_vif == null)
    `uvm_fatal(get_full_name(), "get wrong driver vif");

  
endfunction: build_phase

task axi_stream_driver::run_phase(uvm_phase phase);
    @(posedge drv_vif.aclk);
    // drv_vif.reset();
    drv_vif.tdata <= 0;
    drv_vif.tvalid <= 0;
    drv_vif.tlast <= 0;

    forever begin
        seq_item_port.get_next_item(req);
        drive_one_pkt(req);
        seq_item_port.item_done();
    end
    
endtask: run_phase

task axi_stream_driver::drive_one_pkt(REQ tr);

    for (int ll = 0 ; ll<10; ll++)
      @(posedge drv_vif.aclk);
    drv_vif.tdata <= 0;
    drv_vif.tvalid <= 0;
    drv_vif.tlast <= 0;
    // drv_vif.reset();

    for (int ii = 0 ; ii<tr.data.size(); ii++) begin
      drv_vif.tdata <= tr.data[ii];
      drv_vif.tvalid <= tr.valid[ii];
      drv_vif.tlast <= tr.last[ii];

      do begin
        @(posedge drv_vif.aclk);
      end while(drv_vif.tready !== 1);
    end
    
    // drv_vif.reset();
    drv_vif.tdata <= 0;
    drv_vif.tvalid <= 0;
    drv_vif.tlast <= 0;
    
    // `uvm_info(get_full_name(), "drive_one_pkt transfer done", UVM_LOW);
    // `uvm_info(get_full_name(), $sformatf("drive_one_pkt size is : %d ",tr.data.size()), UVM_LOW);
endtask: drive_one_pkt


`endif  // AXI_STREAM_DRIVER_SVH_
