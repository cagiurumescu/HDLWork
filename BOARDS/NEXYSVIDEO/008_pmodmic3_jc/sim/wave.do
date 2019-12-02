onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sim/i_fpga/sysclk
add wave -noupdate /sim/i_fpga/spi_cs_n
add wave -noupdate /sim/i_fpga/spi_sclk
add wave -noupdate /sim/i_fpga/fsm_state
add wave -noupdate /sim/i_fpga/spi_sdata
add wave -noupdate -radix hexadecimal /sim/i_fpga/clk_divide_count
add wave -noupdate -radix hexadecimal /sim/i_fpga/clk_count_onehot
add wave -noupdate -radix hexadecimal /sim/i_fpga/sclk_count_onehot
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {524836 ps} 0} {{Cursor 2} {7951228 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 154
configure wave -valuecolwidth 78
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
WaveRestoreZoom {7653801 ps} {8327970 ps}
