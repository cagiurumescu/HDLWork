create_project -in_memory -part xc7a200tsbg484-1

read_verilog ../../../../../common/rtl/syncrst.v
read_verilog ../../../../../common/rtl/value_cdc.v
read_verilog ../../../../../common/rtl/pulse_cdc.v
read_verilog ../../src/design_top.v
set iplist [list \
   mig_7series_0 \
   microblaze_mcs_1 \
   ila_0 \
]
foreach ip $iplist {
   read_ip      ../../../ip/$ip/$ip.xci
   if { [file exists ../../../ip/$ip/${ip}_sim_netlist.v]==0 } {
      synth_ip [get_ips $ip] -force
   }
}

if { [file exists ../../../ip/ila_0/ila_0_stub.v]==0 } {
   synth_ip -force [get_ips ila_0]
}

synth_design \
    -top design_top \
    -part xc7a200tsbg484-1

#link_design -part xc7a200tsbg484-1 -top design_top

source ../../xdc/design_top.xdc

# to use ILA
# Run opt_design or implement_debug_core prior to launching place_design.
implement_debug_core

place_design -directive Explore
route_design -directive Explore
write_checkpoint -force design_top_post_route.dcp
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_hwdef     -force design_top.hwdef
write_mem_info  -force design_top.mmi
write_bitstream -force design_top.bit
write_sysdef    -force -hwdef design_top.hwdef -meminfo design_top.mmi -bitfile design_top.bit design_top.hdf

write_debug_probes -force design_top.ltx

quit
