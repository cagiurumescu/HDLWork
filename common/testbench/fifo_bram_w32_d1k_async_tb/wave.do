onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group WR /fifo_bram_w32_d1k_async_tb/rst_src
add wave -noupdate -expand -group WR -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/wr_en
add wave -noupdate -expand -group WR -radix hexadecimal /fifo_bram_w32_d1k_async_tb/din
add wave -noupdate -expand -group WR -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/wr_full
add wave -noupdate -expand -group WR -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/wr_empty
add wave -noupdate -expand -group WR -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/wr_data_count
add wave -noupdate -expand -group WR -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/wr_ptr_wrclk
add wave -noupdate -expand -group WR -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/rd_ptr_wrclk
add wave -noupdate -expand -group RD /fifo_bram_w32_d1k_async_tb/rst_dst
add wave -noupdate -expand -group RD -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/rd_en
add wave -noupdate -expand -group RD -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/dout
add wave -noupdate -expand -group RD -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/rd_full
add wave -noupdate -expand -group RD -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/rd_empty
add wave -noupdate -expand -group RD -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/rd_data_count
add wave -noupdate -expand -group RD -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/wr_ptr_rdclk
add wave -noupdate -expand -group RD -radix hexadecimal /fifo_bram_w32_d1k_async_tb/i_fifo/rd_ptr_rdclk
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {674788 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 147
configure wave -valuecolwidth 87
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
WaveRestoreZoom {231974 ps} {1000386 ps}
