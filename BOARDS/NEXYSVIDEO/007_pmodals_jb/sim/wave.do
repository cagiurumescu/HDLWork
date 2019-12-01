onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /sim/i_fpga/spi_cs_n
add wave -noupdate /sim/i_fpga/spi_sclk
add wave -noupdate /sim/i_fpga/fsm_state
add wave -noupdate -radix unsigned /sim/i_fpga/spi_sclk_count
add wave -noupdate /sim/i_fpga/spi_read_valid
add wave -noupdate /sim/i_fpga/spi_sdata
add wave -noupdate -radix hexadecimal /sim/i_fpga/spi_data
add wave -noupdate -radix hexadecimal /sim/i_fpga/spi_data_cdc
add wave -noupdate -radix hexadecimal /sim/i_fpga/spi_data_latched
add wave -noupdate /sim/i_fpga/spi_read_valid_cdc
add wave -noupdate /sim/i_fpga/spi_read_valid_cdc_d
add wave -noupdate -radix hexadecimal /sim/i_fpga/als_value
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {30555000 ps} 0}
quietly wave cursor active 1
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
WaveRestoreZoom {0 ps} {293249250 ps}
