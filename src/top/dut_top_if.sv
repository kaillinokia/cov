/*------------------------------------------------------------------------------

*/

`ifndef _DUT_TOP_IF_
`define _DUT_TOP_IF_

// ----------------------------------------------------------------------------
// Interface Definition
// ----------------------------------------------------------------------------
interface dut_top_if;

    bit     clk;
    bit     rst;
    bit     arst_n;

// ------------------------------------------------------------------------
    function void fpga_reset();
        rst = 1'b1;
    endfunction

// ------------------------------------------------------------------------
    function void fpga_start();
        rst = 1'b0;
    endfunction

// ------------------------------------------------------------------------
    function void asic_resetn();
        arst_n = 1'b0;
    endfunction

// ------------------------------------------------------------------------
    function void asic_start();
        arst_n = 1'b1;
    endfunction
    
endinterface

`endif //_DUT_TOP_IF_
