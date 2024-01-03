/*------------------------------------------------------------------------------
*/
`ifndef AXI_STREAM_AGENT_SVH_
`define AXI_STREAM_AGENT_SVH_

class axi_stream_agent extends uvm_agent;
  `uvm_component_utils(axi_stream_agent)

  axi_stream_configuration cfg;
  uvm_analysis_port #(axi_stream_seq_item) ap;
  axi_stream_seq_item_sequencer seqr;
  axi_stream_driver drv;
  axi_stream_monitor mon;
 


  bit    has_driver = 1;
  bit    has_monitor = 1;

         
  real   version_number = `AXI_STREAM_VIP_VERSION;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);
  extern virtual function void reset();
endclass: axi_stream_agent

function void axi_stream_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);
   
  has_driver = cfg.has_driver;    
  has_monitor = cfg.has_monitor;  

  if (master_not_slave) begin
    if (has_driver) begin
      seqr = new("seqr", this);
      drv  = axi_stream_driver::type_id::create("drv", this);
    end
  end else begin
    if (has_driver) begin
      res = axi_stream_responder::type_id::create("res", this);

    end
  end

  if (has_monitor) begin
    mon = axi_stream_monitor::type_id::create("mon", this);

  end

  ap = new("ap", this);

  `uvm_info("AXI stream VIP", $sformatf("## VIP Release v%s.%0d ##", `AXIS_CONVERT_TO_STRING(`AXI_STREAM_VIP_VERSION), `AXI_STREAM_VIP_PATCH), UVM_LOW);
endfunction: build_phase

function void axi_stream_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  if (master_not_slave) begin
    if (has_driver) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
    end
  end

  if (has_monitor) begin
    mon.ap.connect(this.ap);
  end
endfunction: connect_phase

function void axi_stream_agent::reset();
  if (master_not_slave) begin
    if (has_driver) begin
      drv.reset();
    end
  end
endfunction: reset

`endif  // AXI_STREAM_AGENT_SVH_
