# vim: set noet:

DNAME=design_top
DNAME_HW=design_top_hw
DNAME_APP=design_top_app

bsp:
	-mkdir build; cd build; xsct ../design_top_bsp.tcl

app:
	-mkdir build; cd build; xsct ../design_top_app.tcl $(DNAME_APP)
	cd build; bootgen -arch zynq -image ../sdcard_boot.bif -o ./output/BOOT.bin

load: app
	-cd build; xsct ../design_top_load.tcl

clean:
	-rm -rf build .Xil hdf/ps7_init*.* hdf/*.bit
.PHONY: bsp app load clean
