onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /sim/i_fpga/sysclk
add wave -noupdate -radix hexadecimal /sim/i_fpga/jb
add wave -noupdate -radix hexadecimal /sim/i_fpga/sw
add wave -noupdate -radix hexadecimal /sim/i_fpga/sdo
add wave -noupdate -radix hexadecimal /sim/i_fpga/rst_count
add wave -noupdate -radix hexadecimal /sim/i_fpga/led_count
add wave -noupdate -radix hexadecimal /sim/i_fpga/grb
add wave -noupdate -radix hexadecimal /sim/i_fpga/rst
add wave -noupdate -radix hexadecimal /sim/i_fpga/sysclk_cnt
add wave -noupdate -radix hexadecimal /sim/i_fpga/lfsr
add wave -noupdate -radix hexadecimal /sim/i_fpga/on_count
add wave -noupdate -radix hexadecimal /sim/i_fpga/LED_COUNT
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3539205000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 91
configure wave -valuecolwidth 66
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
WaveRestoreZoom {3439758290 ps} {3648932780 ps}
