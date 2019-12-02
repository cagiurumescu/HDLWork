quit -sim

vmap unisim ../../../../xil_2019_1_ver/unisim
vmap glbl    ../../../../xil_2019_1_ver/glbl

if {[file exists work]==1} {
   vdel -lib work -all
   vlib work;
} else {
   vlib work;
}

vlog -work work sim.sv

vsim -L work -L unisim -L glbl sim glbl.glbl;

add log -recursive /*

if {[file exists wave.do]} {
   do wave.do
}

run -all

