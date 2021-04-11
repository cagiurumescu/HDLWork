# vim: set noet:

VIVADO_2019_1:= $(shell vivado -version | grep v2019.1)
VIVADO_2020_1:= $(shell vivado -version | grep v2020.1)

design_top.xpr:
ifneq ($(VIVADO_2019_1),)
	vivado -mode batch -source gen_design_top_v2019_1.tcl
endif
ifneq ($(VIVADO_2020_1),)
	vivado -mode batch -source gen_design_top_v2020_1.tcl
endif

gen: design_top.xpr

build: design_top.xpr
	vivado -mode batch -source build_design_top.tcl

clean:
	-rm -rf design_top.* NA .Xil vivado*.jou vivado*.str vivado*.log
	-cd ../bd_v2019_1/design_top_bd; rm -rf *.bmm *.bxml *.xdc hw_handoff ip ipshared sim synth ui
	-cd ../bd_v2020_1/design_top_bd; rm -rf *.bmm *.bxml *.xdc hw_handoff ip ipshared sim synth ui

.PHONY: gen build clean
