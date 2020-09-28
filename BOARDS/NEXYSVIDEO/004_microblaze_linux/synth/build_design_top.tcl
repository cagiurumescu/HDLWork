open_project design_top.xpr
open_bd_design ../bd/design_top_bd/design_top_bd.bd
launch_runs -jobs 4 -to_step write_bitstream impl_1
wait_on_run impl_1
write_sysdef   -hwdef   design_top.runs/impl_1/design_top_bd_wrapper.hwdef \
               -bitfile design_top.runs/impl_1/design_top_bd_wrapper.bit \
               -meminfo design_top.runs/impl_1/design_top_bd_wrapper.mmi \
               -force ../sw/hdf/design_top_bd_wrapper.hdf
close_project
