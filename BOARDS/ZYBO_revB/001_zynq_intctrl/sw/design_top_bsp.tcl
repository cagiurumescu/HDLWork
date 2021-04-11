set DNAME     design_top
setws .
if { [lindex [version] 1]==2019.1 } {
   set DNAME_HW  ${DNAME}_hw 
   set DNAME_BSP ${DNAME}_bsp
   if { [file exists $DNAME_HW] == 0 } {
      createhw  -name $DNAME_HW  -hwspec ../hdf/$DNAME.hdf
   }
   if { [file exists $DNAME_BSP] == 0 } {
      createbsp -name $DNAME_BSP -hwproject $DNAME_HW -proc ps7_cortexa9_0 -os standalone
   }
   projects -type bsp -name $DNAME_BSP -build
}
if { [lindex [version] 1]==2020.1 } {
   set DNAME_PFRM ${DNAME}_platform
   platform create -name $DNAME_PFRM -hw ../hdf/$DNAME.xsa
   domain remove zynq_fsbl
   set DNAME_DOM ${DNAME}_domain
   domain create -name $DNAME_DOM -proc ps7_cortexa9_0 -support-app {Empty Application}
   platform generate
}
