onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /pulse_cdc_tb/clk_src
add wave -noupdate /pulse_cdc_tb/rst_src
add wave -noupdate /pulse_cdc_tb/pulse_src
add wave -noupdate /pulse_cdc_tb/clk_dst
add wave -noupdate /pulse_cdc_tb/rst_dst
add wave -noupdate /pulse_cdc_tb/pulse_dst
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 133
configure wave -valuecolwidth 40
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
WaveRestoreZoom {0 ps} {4346264 ps}
