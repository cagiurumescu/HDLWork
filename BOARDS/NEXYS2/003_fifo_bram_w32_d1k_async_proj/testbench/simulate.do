################################################################################
# MIT License
#
# Copyright (c) 2019-2020 Claudiu Giurumescu
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
################################################################################
quit -sim

if {[file exists work]==0} {
   vlib work;
}
quietly set XILINX /opt/Xilinx/14.7/ISE_DS/ISE

vlog -work work $XILINX/verilog/src/unisims/VCC.v
vlog -work work $XILINX/verilog/src/unisims/GND.v
vlog -work work $XILINX/verilog/src/glbl.v
vlog -work work $XILINX/verilog/src/unisims/RAMB16_S18_S18.v

quietly set MODULE fpga

vlog -work work ../../coregen/chipscope_ila_trig0/chipscope_ila_trig0.v
vlog -work work ../../coregen/chipscope_icon_ctrl0/chipscope_icon_ctlr0.v
vlog -work work ../../coregen/bram_sdp_w32_d1k_noreg/bram_sdp_w32_d1k_noreg.v
vlog -work work ../../../../common/rtl/counter_cdc.v
vlog -work work ../../../../common/rtl/fifo_bram_w32_d1k_async.v
vlog -work work ../src/${MODULE}.v
vlog -work work ./${MODULE}_tb.v

vsim -L work ${MODULE}_tb glbl

add log -recursive /*

if {[file exists wave.do]} {
   do wave.do
}

run 150 us
