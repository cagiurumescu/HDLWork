all: 
	# need the xiomodule_app elf to run the sim
	make -C ../sw bsp
	make -C ../sw app DNAME_APP=xiomodule_app
	vivado -mode batch -source design_top_tb.tcl -nojou -nolog

clean:
	-rm -rf design_top_tb.cache design_top_tb.hw design_top_tb.ip_user_files design_top_tb.runs design_top_tb.sim design_top_tb.xpr
