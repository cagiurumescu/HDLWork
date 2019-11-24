create_project -in_memory -part xc7a200tsbg484-1

read_verilog ../../src/fpga.v

synth_design \
    -top fpga \
    -part xc7a200tsbg484-1

#link_design -part xc7a200tsbg484-1 -top fpga

source ../../xdc/fpga.xdc

place_design -directive Explore
route_design -directive Explore
write_checkpoint -force fpga_post_route.dcp
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
write_bitstream -force fpga.bit

quit
