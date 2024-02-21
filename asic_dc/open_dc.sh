todaysdate=$( date +%b%d%Y%H%M%S)
bsub -Is -q i_soc_rh7 -R "rusage[mem=32000]" dcnxt_shell -topo -64 -output_log_file dc_${todaysdate}.log -f rm_setup/dc_setup.tcl
