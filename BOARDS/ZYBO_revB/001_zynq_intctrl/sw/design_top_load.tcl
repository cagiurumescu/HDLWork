set DNAME design_top
connect
if { [lindex [version] 1]==2019.1 } {
   set FPGA_BIT ./${DNAME}_hw/$DNAME.bit
   set PS7_INIT ./${DNAME}_hw/ps7_init.tcl
}
if { [lindex [version] 1]==2020.1 } {
   set FPGA_BIT ./${DNAME}_platform/hw/$DNAME.bit
   set PS7_INIT ./${DNAME}_platform/hw/ps7_init.tcl
}
targets -set -filter {name =~ "APU"}
rst
targets -set -filter {name =~ "xc7z010"}
fpga $FPGA_BIT
targets -set -filter {name =~ "*#0"}
source $PS7_INIT
ps7_init
dow    ./${DNAME}_app/Debug/${DNAME}_app.elf
ps7_post_config
con
disconnect
