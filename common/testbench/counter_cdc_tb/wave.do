onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /counter_cdc_tb/clk_src
add wave -noupdate /counter_cdc_tb/rst_src
add wave -noupdate /counter_cdc_tb/clk_dst
add wave -noupdate /counter_cdc_tb/rst_dst
add wave -noupdate -radix hexadecimal /counter_cdc_tb/counter_src
add wave -noupdate -radix hexadecimal /counter_cdc_tb/i_counter_cdc/counter_gray_src
add wave -noupdate -radix hexadecimal /counter_cdc_tb/i_counter_cdc/meta_counter_gray_src
add wave -noupdate -radix hexadecimal /counter_cdc_tb/i_counter_cdc/counter_gray_dst
add wave -noupdate -radix hexadecimal /counter_cdc_tb/i_counter_cdc/counter_gray_dst_d
add wave -noupdate -radix hexadecimal /counter_cdc_tb/i_counter_cdc/counter_dst_comb
add wave -noupdate -radix hexadecimal /counter_cdc_tb/i_counter_cdc/counter_dst_ff
add wave -noupdate -radix hexadecimal /counter_cdc_tb/counter_dst
add wave -noupdate -childformat {{{/counter_cdc_tb/i_counter_cdc/counter_bin_dst[0]} -radix hexadecimal} {{/counter_cdc_tb/i_counter_cdc/counter_bin_dst[1]} -radix hexadecimal} {{/counter_cdc_tb/i_counter_cdc/counter_bin_dst[2]} -radix hexadecimal} {{/counter_cdc_tb/i_counter_cdc/counter_bin_dst[3]} -radix hexadecimal} {{/counter_cdc_tb/i_counter_cdc/counter_bin_dst[4]} -radix hexadecimal} {{/counter_cdc_tb/i_counter_cdc/counter_bin_dst[5]} -radix hexadecimal} {{/counter_cdc_tb/i_counter_cdc/counter_bin_dst[6]} -radix hexadecimal}} -subitemconfig {{/counter_cdc_tb/i_counter_cdc/counter_bin_dst[0]} {-height 17 -radix hexadecimal} {/counter_cdc_tb/i_counter_cdc/counter_bin_dst[1]} {-height 17 -radix hexadecimal} {/counter_cdc_tb/i_counter_cdc/counter_bin_dst[2]} {-height 17 -radix hexadecimal} {/counter_cdc_tb/i_counter_cdc/counter_bin_dst[3]} {-height 17 -radix hexadecimal} {/counter_cdc_tb/i_counter_cdc/counter_bin_dst[4]} {-height 17 -radix hexadecimal} {/counter_cdc_tb/i_counter_cdc/counter_bin_dst[5]} {-height 17 -radix hexadecimal} {/counter_cdc_tb/i_counter_cdc/counter_bin_dst[6]} {-height 17 -radix hexadecimal}} /counter_cdc_tb/i_counter_cdc/counter_bin_dst
add wave -noupdate -radix hexadecimal /counter_cdc_tb/i_counter_cdc/counter_bin_comb_dst
add wave -noupdate -radix hexadecimal /counter_cdc_tb/i_counter_cdc/counter_gray_dst_d_latched
add wave -noupdate /counter_cdc_tb/i_counter_cdc/pipe_stage_onehot
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {342 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 143
configure wave -valuecolwidth 105
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
WaveRestoreZoom {1264813 ps} {1265278 ps}
