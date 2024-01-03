/*------------------------------------------------------------------------------

*/

`ifndef _AXI_STREAM_IF_
`define _AXI_STREAM_IF_

// ----------------------------------------------------------------------------
// Interface Definition
// ----------------------------------------------------------------------------
interface axi_stream_if#(
    int DW = 32
);

    logic          aclk   ;
    logic          arstn  ;
    logic          tready ;
    logic          tvalid ;
    logic [DW-1:0] tdata  ;
    logic [3:0]    tlast  ;

    // function void reset();
    //     tvalid = 1'b0;
    //     tdata = 0;
    //     tlast = 0;
    // endfunction
endinterface

`endif //_AXI_STREAM_IF_
