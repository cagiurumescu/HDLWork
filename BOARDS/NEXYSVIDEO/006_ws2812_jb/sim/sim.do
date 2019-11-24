
vlib work;

vlog -work work sim.v

vsim -L work sim;

add log -recursive /*

if {[file exists wave.do]} {
   do wave.do
}

run -all

