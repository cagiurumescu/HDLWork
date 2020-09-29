#!/bin/bash

if [ ! -d design_top ]; then
   petalinux-create --type project --template microblaze --name design_top
   cd design_top; 
   petalinux-config --get-hw-description=../../hdf
   petalinux-create -t modules -n test-module --enable
else
   cd design_top;
   petalinux-build -x mrproper
   petalinux-config --get-hw-description=../../hdf --silentconfig
fi
petalinux-build
#petalinux-boot --jtag --kernel --fpga -v
