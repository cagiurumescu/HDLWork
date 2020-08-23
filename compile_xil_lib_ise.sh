#!/bin/bash

export XILINX_ISE=/opt/Xilinx/14.7/ISE_DS/ISE

# Verilog
mkdir xil_ise14_7_ver
cd xil_ise14_7_ver
vlib unisims
vlib glbl

vlog -work unisims     $XILINX_ISE/verilog/src/unisims/*.v
vlog -work glbl        $XILINX_ISE/verilog/src/glbl.v
cd ..

# VHDL
mkdir xil_ise14_7_vhd
cd xil_ise14_7_vhd
vlib unisim
vlib secureip

vcom -work unisim    $XILINX_ISE/vhdl/src/unisims/unisim_VPKG.vhd
vcom -work unisim    $XILINX_ISE/vhdl/src/unisims/unisim_VCOMP.vhd
vcom -work unisim    $XILINX_ISE/vhdl/src/unisims/primitive/*.vhd
for file in `cat $XILINX_ISE/vhdl/src/unisims/secureip/vhdl_analyze_order`; do
   vcom -work secureip $XILINX_ISE/vhdl/src/unisims/secureip/$file
done
