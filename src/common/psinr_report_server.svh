/*------------------------------------------------------------------------------
*/

`ifndef _PSINR_REPORT_SERVER_SVH_
`define _PSINR_REPORT_SERVER_SVH_


// This is needed because 1.2 has different report_server class to extend than 1.1.
class psinr_report_server extends uvm_default_report_server;
  `uvm_object_utils(psinr_report_server)

  // ----------------------------------------------------------------------------
  function new(string name="psinr_report_server");
    super.new(name);
  endfunction: new
  
  virtual function string compose_report_message( uvm_report_message report_message, string report_object_name = "" );
   
    string filename_nopath = "";
    uvm_severity severity = report_message.get_severity();
   
    string name     = report_message.get_report_object().get_full_name();
    string id       = report_message.get_id();
    string message  = report_message.get_message();
    string filename = report_message.get_filename();
    int    line     = report_message.get_line();
 
    // Timeformat function configures $time print format through print functions (e.g. $psprintf). 
    // One call is enough for the entire test bench.
    // $timeformat(-9, 0, " ns", 11); // Would look like "     57350 ns "
    $timeformat(-9, 3, " ns", 15); // With 3 decimals for picoseconds, looks like: "    57350.123 ns "
 
    // Note that every if-clause here slows down simulation noticably, 
    // if they have lots of uvm_info prints (e.g on HIGH/DEBUG verbosity)
    // At one point I just removed one if-clause from here, and UVM_HIGH simulation speeded up by 50%.
    
    // Extract just the file name, remove the preceeding path
      foreach(filename[i])
        begin
          if (filename[i]=="/") filename_nopath = "";
          else filename_nopath = {filename_nopath, filename[i]};
        end

      // Cut off "uvm_test_top.m_leka_tx_env." from each name field
    //   if (name.substr(0,26) == "uvm_test_top.m_leka_tx_env.") begin
    //     name = name.substr(27,name.len()-1);
    //   end
    
      return $psprintf( "%-9s | %-s | L: %-4d | %-8t | %s | %s | %s", severity.name(), filename_nopath, line, $time, name, id, message );
    
  endfunction: compose_report_message

endclass: psinr_report_server

`endif
