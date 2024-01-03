/*------------------------------------------------------------------------------

*/
`ifndef _TIME_MON_IF_SV
`define _TIME_MON_IF_SV

interface time_mon_if();

  logic clk;

  int   time_val_tab[3];
  
endinterface: time_mon_if
    
`endif //_TIME_MON_IF_SV
