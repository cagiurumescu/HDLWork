
VIVADO_CMD = vivado

SOURCE_FILES=../src/*.v 

build_out/design_top.bit:  $(SOURCE_FILES) ../xdc/design_top.xdc design_top.tcl
	-mkdir  build_out
	-cd build_out; \
		$(VIVADO_CMD) -mode tcl -source ../design_top.tcl -log vivado.log -journal vivado.jou
	-@cd build_out; \
		rm -f usage_statistics_webtalk.*
	-@rm -f webtalk*

clean:
	-rm -rf build_out

all: build_out/design_top.bit

prog: prog.tcl build_out/design_top.bit
	$(VIVADO_CMD) -mode tcl -source prog.tcl -nolog -nojournal
	-@rm -f webtalk*
