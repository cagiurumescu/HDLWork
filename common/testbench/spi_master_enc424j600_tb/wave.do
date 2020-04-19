onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/clk
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/rst
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/opbyte
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/opbyte_valid
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/state
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/next_state
add wave -noupdate -expand -group SPI -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/SCK
add wave -noupdate -expand -group SPI -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/CS_N
add wave -noupdate -expand -group SPI -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/MOSI
add wave -noupdate -expand -group SPI -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/MISO
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/opbyte_shift
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/bit_cnt
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/txn_done
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/clk_cnt
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/rd_byte
add wave -noupdate -radix hexadecimal -childformat {{{/spi_master_enc424j600_tb/i_spi_master/rddat_byte[7]} -radix hexadecimal} {{/spi_master_enc424j600_tb/i_spi_master/rddat_byte[6]} -radix hexadecimal} {{/spi_master_enc424j600_tb/i_spi_master/rddat_byte[5]} -radix hexadecimal} {{/spi_master_enc424j600_tb/i_spi_master/rddat_byte[4]} -radix hexadecimal} {{/spi_master_enc424j600_tb/i_spi_master/rddat_byte[3]} -radix hexadecimal} {{/spi_master_enc424j600_tb/i_spi_master/rddat_byte[2]} -radix hexadecimal} {{/spi_master_enc424j600_tb/i_spi_master/rddat_byte[1]} -radix hexadecimal} {{/spi_master_enc424j600_tb/i_spi_master/rddat_byte[0]} -radix hexadecimal}} -subitemconfig {{/spi_master_enc424j600_tb/i_spi_master/rddat_byte[7]} {-height 17 -radix hexadecimal} {/spi_master_enc424j600_tb/i_spi_master/rddat_byte[6]} {-height 17 -radix hexadecimal} {/spi_master_enc424j600_tb/i_spi_master/rddat_byte[5]} {-height 17 -radix hexadecimal} {/spi_master_enc424j600_tb/i_spi_master/rddat_byte[4]} {-height 17 -radix hexadecimal} {/spi_master_enc424j600_tb/i_spi_master/rddat_byte[3]} {-height 17 -radix hexadecimal} {/spi_master_enc424j600_tb/i_spi_master/rddat_byte[2]} {-height 17 -radix hexadecimal} {/spi_master_enc424j600_tb/i_spi_master/rddat_byte[1]} {-height 17 -radix hexadecimal} {/spi_master_enc424j600_tb/i_spi_master/rddat_byte[0]} {-height 17 -radix hexadecimal}} /spi_master_enc424j600_tb/i_spi_master/rddat_byte
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/rddat_valid
add wave -noupdate /spi_master_enc424j600_tb/i_spi_master/rddat_byte_ff
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/wr_byte
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/wrdat_valid
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/wrdat_ready
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/wrdat_byte
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/wrdat_byte_latched
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/nbyte_isread
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/i_spi_master/mosi_ff
add wave -noupdate -radix hexadecimal /spi_master_enc424j600_tb/wrdat_valid
add wave -noupdate /spi_master_enc424j600_tb/i_spi_master/unbanked_txn
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8387888 ps} 0} {{Cursor 2} {17480388 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 117
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
WaveRestoreZoom {16176536 ps} {20765624 ps}
