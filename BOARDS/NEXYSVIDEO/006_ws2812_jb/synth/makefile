
VIVADO_CMD = vivado

SOURCE_FILES=../src/*.v 

build_out/fpga.bit:  $(SOURCE_FILES) ../xdc/fpga.xdc fpga.tcl
	-mkdir  build_out
	-cd build_out; \
		$(VIVADO_CMD) -mode tcl -source ../fpga.tcl -log vivado.log -journal vivado.jou
	-@rm -f webtalk*

clean:
	-rm -rf build_out

all: build_out/fpga.bit

prog: prog.tcl build_out/fpga.bit
	$(VIVADO_CMD) -mode tcl -source prog.tcl -nolog -nojournal
	-@rm -f webtalk*
