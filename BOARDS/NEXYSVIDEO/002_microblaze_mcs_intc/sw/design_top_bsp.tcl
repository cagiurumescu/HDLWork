set DNAME     design_top
set DNAME_HW  ${DNAME}_hw 
set DNAME_BSP ${DNAME}_bsp
setws .
if { [file exists $DNAME_HW] == 0 } {
   createhw  -name $DNAME_HW  -hwspec ../../synth/build_out/$DNAME.hdf
}
if { [file exists $DNAME_BSP] == 0 } {
   createbsp -name $DNAME_BSP -hwproject $DNAME_HW -proc microblaze_I -os standalone
}
projects -type bsp -name $DNAME_BSP -build
