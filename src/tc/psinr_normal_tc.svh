/*------------------------------------------------------------------------------

*/

`ifndef _PSINR_NORMAL_TC_SVH_
`define _PSINR_NORMAL_TC_SVH_

// ----------------------------------------------------------------------------
// Class Definition 
// ----------------------------------------------------------------------------
class psinr_normal_tc extends psinr_test_base;
    `uvm_component_utils(psinr_normal_tc)


    extern function new(string name = "psinr_normal_tc",uvm_component parent = null);

    // Group: UVM Phasing.
    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);
    extern         task          main_phase(uvm_phase phase);

endclass : psinr_normal_tc


function psinr_normal_tc::new(string name = "psinr_normal_tc", uvm_component parent = null);
    super.new(name,parent);
endfunction : new

// ----------------------------------------------------------------------------
function void psinr_normal_tc::build_phase(uvm_phase phase);
    super.build_phase(phase);
    m_psinr_env.scb_enable = 1;
endfunction : build_phase

// ----------------------------------------------------------------------------
function void psinr_normal_tc::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
endfunction : connect_phase


// ----------------------------------------------------------------------------
task psinr_normal_tc::main_phase(uvm_phase phase);
    phase.raise_objection(this);
    reset_dut(1);

    `uvm_info("psinr_normal_tc", "*************psinr normal test case *************", UVM_LOW);

    fork
        combiner_cfg_input_flow:begin
            `uvm_info(get_full_name(), "combiner cfg start to transfer", UVM_LOW);
            combiner_cfg_input(1);
            `uvm_info(get_full_name(), "all combiner cfg transfer done", UVM_LOW);
        end
        combiner_data_input_flow:begin
            `uvm_info(get_full_name(), "combiner data start to transfer", UVM_LOW);
            combiner_data_input(1);
            `uvm_info(get_full_name(), "all symbol combiner data transfer done", UVM_LOW);
        end
        psinr_calc_cfg_input_flow:begin
            `uvm_info(get_full_name(), "psinr_calc cfg start to transfer", UVM_LOW);
            psinr_calc_cfg_input(1);
            `uvm_info(get_full_name(), "all psinr_calc cfg transfer done", UVM_LOW);
        end
        psinr_out_cfg_input_flow:begin
            `uvm_info(get_full_name(), "psinr_out cfg start to transfer", UVM_LOW);
            psinr_out_cfg_input(1);
            `uvm_info(get_full_name(), "all psinr_out cfg transfer done", UVM_LOW);
        end
        psinr_out_uci_input_flow:begin
            `uvm_info(get_full_name(), "psinr_out uci start to transfer", UVM_LOW);
            psinr_out_uci_input(1);
            `uvm_info(get_full_name(), "psinr_out uci transfer done", UVM_LOW);
        end

        psinr_back_pressure:begin
            @(posedge m_psinr_bp_vif.aclk);
            m_psinr_bp_vif.tready = 4'b1111;
            `uvm_info(get_full_name(), "psinr back pressure is disable", UVM_LOW);
        end

    join
    // #1ms; 
    `uvm_info("psinr_normal_tc", "*************all dut cfg & data send done  *************", UVM_LOW);
    // $finish;

    phase.drop_objection(this);
endtask: main_phase


`endif //_PSINR_NORMAL_TC_SVH_