#!/bin/bash

if [ ! -d design_top ]; then
   petalinux-create --type project --template microblaze --name design_top
   cd design_top; petalinux-create -t modules -n test_module --enable
fi
cd design_top
petalinux-config --get-hw-description=../../hdf --oldconfig
#petalinux-build -x mrproper
petalinux-build
#petalinux-boot --jtag --kernel --fpga -v
