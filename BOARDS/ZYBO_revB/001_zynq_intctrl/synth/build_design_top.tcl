open_project design_top.xpr
set bd_design_opened 0
if {[string range [version -short] 0 5]==2019.1} {
   open_bd_design ../bd_v2019_1/design_top_bd/design_top_bd.bd
   set bd_design_opened 1
}
if {[string range [version -short] 0 5]==2020.1} {
   open_bd_design ../bd_v2020_1/design_top_bd/design_top_bd.bd
   set bd_design_opened 1
}
if { $bd_design_opened==0 } {
   close_project
   quit
} 
launch_runs -jobs 4 -to_step write_bitstream impl_1
wait_on_run impl_1
if {([string range [version -short] 0 5]==2019.2)||([string range [version -short] 0 3]>=2020)} {
   write_hw_platform -fixed -include_bit \
                     -force  ../sw/hdf/design_top.xsa
} else {
   write_sysdef   -hwdef   design_top.runs/impl_1/design_top.hwdef \
                  -bitfile design_top.runs/impl_1/design_top.bit \
                  -meminfo design_top.runs/impl_1/design_top.mmi \
                  -force ../sw/hdf/design_top.hdf
}
close_project
