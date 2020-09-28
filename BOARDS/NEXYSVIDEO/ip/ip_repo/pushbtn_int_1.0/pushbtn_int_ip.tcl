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

# this TCL script is very similar to that used by ADI IP (I've used the ADI
# GitHub for figuring out how to create IP with custom interfaces rather than
# using Xilinx's package IP).

set ip_name pushbtn_int
# adi_ip_create
create_project -in_memory $ip_name
# adi_ip_files
set proj_fileset [get_filesets sources_1]
set proj_filelist [list $ip_name.v]
foreach m_file $proj_filelist {
   add_files -norecurse -scan_for_includes -fileset $proj_fileset $m_file
}
set_property "top" "$ip_name" $proj_fileset
# adi_ip_properties_lite
ipx::package_project -root_dir . -vendor claudiug.com -library user -taxonomy /claudiug.com
set_property name $ip_name [ipx::current_core]
set_property vendor_display_name {Claudiu Giurumescu} [ipx::current_core]
set_property company_url         {https://www.claudiug.com} [ipx::current_core]
set_property supported_families "artix7 Production" [ipx::current_core]
# add signal/bus interfaces
ipx::remove_all_bus_interface [ipx::current_core]
foreach map [ipx::get_memory_maps * -of_objects [ipx::current_core]] {
   ipx::remove_memory_map [lindex $map 2] [ipx::current_core]
}
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
# adi_ip_properties
ipx::infer_bus_interface {\
   S_AXI_AWVALID \
   S_AXI_AWADDR \
   S_AXI_AWPROT \
   S_AXI_AWREADY \
   S_AXI_WVALID \
   S_AXI_WDATA \
   S_AXI_WSTRB \
   S_AXI_WREADY \
   S_AXI_BVALID \
   S_AXI_BRESP \
   S_AXI_BREADY \
   S_AXI_ARVALID \
   S_AXI_ARADDR \
   S_AXI_ARPROT \
   S_AXI_ARREADY \
   S_AXI_RVALID \
   S_AXI_RDATA \
   S_AXI_RRESP \
   S_AXI_RREADY \
} xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface S_AXI_ACLK xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface S_AXI_ARESETN xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface INTERRUPT_OUT xilinx.com:signal:interrupt:1.0 [ipx::current_core]
# LEVEL_HIGH, LEVEL_LOW, EDGE_RISING, EDGE_FALLING
set_property value "EDGE_RISING" [ipx::get_bus_parameters -of_objects [ipx::get_bus_interfaces -filter {NAME=~"INTERRUPT_OUT"}]]
set s_axi_addrw [expr [get_property SIZE_LEFT [ipx::get_ports -nocase true S_AXI_ARADDR -of_objects [ipx::current_core]]] + 1]
if {$s_axi_addrw >= 16} {
   set range 65536
} elseif {$s_axi_addrw < 12} {
   set range 4096
} else {
   set range [expr 1 << $s_axi_addrw]
}
ipx::add_memory_map {S_AXI} [ipx::current_core]
set_property slave_memory_map_ref {S_AXI} [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_address_block {Reg} [ipx::get_memory_maps S_AXI -of_objects [ipx::current_core]]
set_property range $range [ipx::get_address_blocks Reg \
    -of_objects [ipx::get_memory_maps S_AXI -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -clock S_AXI_ACLK -reset S_AXI_ARESETN [ipx::current_core]
ipx::save_core
close_project
quit
