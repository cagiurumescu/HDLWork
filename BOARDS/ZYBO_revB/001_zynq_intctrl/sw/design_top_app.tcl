set DNAME     design_top
if { $::argc > 0 } {
   foreach arg $::argv {
      set DNAME_APP $arg
   }
} else {
   set DNAME_APP design_top_app
}
setws .
if { [lindex [version] 1]==2019.1 } {
   if { [file exists $DNAME_APP] == 0 } {
      set DNAME_HW  design_top_hw
      set DNAME_BSP design_top_bsp
      createapp -name $DNAME_APP -hwproject $DNAME_HW -proc ps7_cortexa9_0 \
                -os standalone -bsp $DNAME_BSP -app {Empty Application}
   }
   importsources -name $DNAME_APP -path ../src/$DNAME_APP
   projects -type app -name $DNAME_APP -build
}
if { [lindex [version] 1]==2020.1 } {
   if { [file exists $DNAME_APP] == 0 } {
      set DNAME_PFRM ${DNAME}_platform
      set DNAME_DOM ${DNAME}_domain
      app create -name $DNAME_APP -platform $DNAME_PFRM -domain $DNAME_DOM -lang C -template {Empty Application}
   }
   importsources -name $DNAME_APP -path ../src/$DNAME_APP
   app build -name $DNAME_APP
}
file copy -force ./$DNAME_APP/Debug/$DNAME_APP.elf ./output
