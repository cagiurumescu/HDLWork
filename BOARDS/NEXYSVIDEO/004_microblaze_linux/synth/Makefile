design_top.xpr:
	make -C ../../ip/ip_repo/pushbtn_int_1.0 all
	vivado -mode batch -source gen_design_top.tcl

gen: design_top.xpr


build: design_top.xpr
	vivado -mode batch -source build_design_top.tcl

clean:
	rm -rf design_top.* .Xil vivado*.jou vivado*.str vivado*.log
	cd ../bd/design_top_bd; rm -rf *.bmm *.bxml *.xdc hw_handoff ip ipshared sim synth

.PHONY: gen build clean
