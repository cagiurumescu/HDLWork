DNAME=design_top
DNAME_HW=design_top_hw
# design_top_app, xiomodule_app
DNAME_APP=design_top_app

bsp:
	-mkdir build; cd build; xsct ../design_top_bsp.tcl

app:
	-mkdir build; cd build; xsct ../design_top_app.tcl $(DNAME_APP)

updatemem: ./build/$(DNAME_APP)/Debug/$(DNAME_APP).elf
	-cd build; updatemem -meminfo ./$(DNAME_HW)/$(DNAME).mmi -data ./$(DNAME_APP)/Debug/$(DNAME_APP).elf -bit ./$(DNAME_HW)/$(DNAME).bit -proc i_microblaze/inst/microblaze_I -force -out ./$(DNAME_HW)/$(DNAME)_out.bit 
	-cd build; rm -f updatemem.*

load: updatemem
	-cd build; xsct ../design_top_load.tcl

clean:
	-rm -rf build
.PHONY: updatemem bsp
