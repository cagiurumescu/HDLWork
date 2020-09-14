set DNAME     design_top
set DNAME_HW  design_top_hw
set DNAME_BSP design_top_bsp
if { $::argc > 0 } {
   foreach arg $::argv {
      set DNAME_APP $arg
   }
} else {
   set DNAME_APP design_top_app
}
setws .
if { [file exists $DNAME_APP] == 0 } {
   createapp -name $DNAME_APP -hwproject $DNAME_HW -proc microblaze_I -os standalone -bsp $DNAME_BSP -app {Empty Application}
}
importsources -name $DNAME_APP -path ../src/$DNAME_APP
projects -type app -name $DNAME_APP -build
