onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /interface_hcsr04_tb/clock_in
add wave -noupdate /interface_hcsr04_tb/reset_in
add wave -noupdate /interface_hcsr04_tb/medir_in
add wave -noupdate /interface_hcsr04_tb/echo_in
add wave -noupdate /interface_hcsr04_tb/trigger_out
add wave -noupdate -radix decimal /interface_hcsr04_tb/medida_out
add wave -noupdate /interface_hcsr04_tb/pronto_out
add wave -noupdate /interface_hcsr04_tb/db_estado_out
add wave -noupdate /interface_hcsr04_tb/caso
add wave -noupdate -radix decimal /interface_hcsr04_tb/larguraPulso
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {6398930 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 222
configure wave -valuecolwidth 200
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {0 ns} {23767454 ns}
