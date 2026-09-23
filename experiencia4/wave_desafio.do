onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /exp4_trena_desafio_tb/clock
add wave -noupdate /exp4_trena_desafio_tb/reset
add wave -noupdate /exp4_trena_desafio_tb/echo
add wave -noupdate /exp4_trena_desafio_tb/trigger
add wave -noupdate /exp4_trena_desafio_tb/saida_serial
add wave -noupdate /exp4_trena_desafio_tb/medida0
add wave -noupdate /exp4_trena_desafio_tb/medida1
add wave -noupdate /exp4_trena_desafio_tb/medida2
add wave -noupdate /exp4_trena_desafio_tb/pronto
add wave -noupdate /exp4_trena_desafio_tb/db_mensurar
add wave -noupdate /exp4_trena_desafio_tb/db_echo
add wave -noupdate /exp4_trena_desafio_tb/db_trigger
add wave -noupdate /exp4_trena_desafio_tb/db_saida_serial
add wave -noupdate /exp4_trena_desafio_tb/db_estado
add wave -noupdate /exp4_trena_desafio_tb/erros
add wave -noupdate /exp4_trena_desafio_tb/quadros_serial
add wave -noupdate /exp4_trena_desafio_tb/ciclos_echo
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4521925 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 230
configure wave -valuecolwidth 100
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
WaveRestoreZoom {4201031 ns} {4745095 ns}
