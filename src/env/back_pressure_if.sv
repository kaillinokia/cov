/*------------------------------------------------------------------------------

*/

`ifndef _BACK_PRESSURE_IF_
`define _BACK_PRESSURE_IF_

// ----------------------------------------------------------------------------
// Interface Definition
// ----------------------------------------------------------------------------
interface back_pressure_if;

    logic          aclk   ;
    logic          arstn  ;
    logic [3:0]    tready ;
    logic [3:0]    tvalid ;

endinterface

`endif //_BACK_PRESSURE_IF_
