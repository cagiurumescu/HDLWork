if {[file exists ./build_out/fpga.bit]==0} {
   quit;
}
open_hw
connect_hw_server
open_hw_target localhost:3121/xilinx_tcf/Digilent/210276A5A790B
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
set_property PROBES.FILE {} [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {build_out/fpga.bit} [lindex [get_hw_devices] 0]
program_hw_devices [lindex [get_hw_devices] 0]
refresh_hw_device [lindex [get_hw_devices] 0]
close_hw

quit
