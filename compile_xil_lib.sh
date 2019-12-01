#!/bin/bash

export XILINX_VIVADO=/opt/Xilinx/Vivado/2019.1

# Verilog
mkdir xil_2019_1_ver
cd xil_2019_1_ver
vlib unisim
vlib glbl
vlib secureip

vlog -work unisim      $XILINX_VIVADO/data/verilog/src/unisims/*.v
vlog -work glbl        $XILINX_VIVADO/data/verilog/src/glbl.v
vlog -work secureip -f $XILINX_VIVADO/data/secureip/secureip_cell.list.f

cd ..
mkdir xil_2019_1_vhd
cd xil_2019_1_vhd
vlib unisim
vlib secureip

vcom -work unisim    $XILINX_VIVADO/data/vhdl/src/unisims/unisim_VPKG.vhd
vcom -work unisim    $XILINX_VIVADO/data/vhdl/src/unisims/unisim_VCOMP.vhd
vcom -work unisim    $XILINX_VIVADO/data/vhdl/src/unisims/primitive/*.vhd

vcom -work secureip  $XILINX_VIVADO/data/vhdl/src/unisims/secureip/*.vhd
