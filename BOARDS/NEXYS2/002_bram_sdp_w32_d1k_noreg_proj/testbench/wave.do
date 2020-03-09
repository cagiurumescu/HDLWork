onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fpga_tb/i_fpga/clk50
add wave -noupdate /fpga_tb/i_fpga/clk40
add wave -noupdate /fpga_tb/i_fpga/rst_clk50
add wave -noupdate /fpga_tb/i_fpga/rst_clk40
add wave -noupdate /fpga_tb/i_fpga/wea
add wave -noupdate -radix hexadecimal /fpga_tb/i_fpga/addra
add wave -noupdate -radix hexadecimal /fpga_tb/i_fpga/dina
add wave -noupdate /fpga_tb/i_fpga/decr_incr_n
add wave -noupdate /fpga_tb/i_fpga/enb
add wave -noupdate -radix hexadecimal /fpga_tb/i_fpga/addrb
add wave -noupdate /fpga_tb/i_fpga/doutb
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8405461533 ps} 0}
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
WaveRestoreZoom {0 ps} {1863484 ps}
