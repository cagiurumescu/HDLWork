create_project -in_memory -part xc7a200tsbg484-1

read_verilog -sv ../../src/fpga.sv
read_ip      ../../../ip/ila_0/ila_0.xci

synth_design \
    -top fpga \
    -part xc7a200tsbg484-1

#link_design -part xc7a200tsbg484-1 -top fpga

source ../../xdc/fpga.xdc

implement_debug_core

place_design -directive Explore
route_design -directive Explore
write_checkpoint -force fpga_post_route.dcp
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_debug_probes fpga.ltx
write_bitstream -force fpga.bit

quit
