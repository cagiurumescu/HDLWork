onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fpga_tb/i_fpga/clk50
add wave -noupdate /fpga_tb/i_fpga/clk40
add wave -noupdate /fpga_tb/i_fpga/rst_clk50
add wave -noupdate /fpga_tb/i_fpga/rst_clk40
add wave -noupdate -radix hexadecimal /fpga_tb/i_fpga/dout
add wave -noupdate -radix hexadecimal /fpga_tb/i_fpga/dout_d
add wave -noupdate -radix hexadecimal /fpga_tb/i_fpga/fifo_error
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {110750100 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 129
configure wave -valuecolwidth 50
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {110164669 ps} {111423879 ps}
