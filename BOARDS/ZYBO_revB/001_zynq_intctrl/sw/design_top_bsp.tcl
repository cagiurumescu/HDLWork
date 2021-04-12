set DNAME     design_top
setws .
file mkdir output
if { [lindex [version] 1]==2019.1 } {
   set DNAME_HW  ${DNAME}_hw 
   set DNAME_BSP ${DNAME}_bsp
   if { [file exists $DNAME_HW] == 0 } {
      createhw  -name $DNAME_HW  -hwspec ../hdf/$DNAME.hdf
   }
   if { [file exists $DNAME_BSP] == 0 } {
      createbsp -name $DNAME_BSP -hwproject $DNAME_HW -proc ps7_cortexa9_0 -os standalone
      # must add xilffs to be able to create zynq_fsbl
      setlib -bsp $DNAME_BSP -lib xilffs
      regenbsp -bsp $DNAME_BSP
   }
   createapp -name zynq_fsbl -hwproject $DNAME_HW -proc ps7_cortexa9_0 \
                -os standalone -bsp $DNAME_BSP -app {Zynq FSBL}
   projects -type bsp -name $DNAME_BSP -build
   projects -type app -name zynq_fsbl -build
   file copy -force ./zynq_fsbl/Debug/zynq_fsbl.elf ./output/fsbl.elf
   file copy -force ./$DNAME_HW/$DNAME.bit ./output
}
if { [lindex [version] 1]==2020.1 } {
   set DNAME_PFRM ${DNAME}_platform
   platform create -name $DNAME_PFRM -hw ../hdf/$DNAME.xsa
   # uncomment below only if not producing sdcard image
   # then comment the copying of fsbl.elf below to output directory
   # domain remove zynq_fsbl
   set DNAME_DOM ${DNAME}_domain
   domain create -name $DNAME_DOM -proc ps7_cortexa9_0 -support-app {Empty Application}
   platform generate
   file copy -force ./$DNAME_PFRM/export/$DNAME_PFRM/sw/$DNAME_PFRM/boot/fsbl.elf ./output
   file copy -force ./$DNAME_PFRM/hw/$DNAME.bit ./output
}
