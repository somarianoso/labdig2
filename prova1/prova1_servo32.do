vlib work
vlog *.v
vsim -voptargs=+acc work.prova1_servo32_tb
add wave sim:/prova1_servo32_tb/clock
add wave sim:/prova1_servo32_tb/reset
add wave sim:/prova1_servo32_tb/modo_fino
add wave sim:/prova1_servo32_tb/posicao
add wave sim:/prova1_servo32_tb/dut/largura_pwm
add wave sim:/prova1_servo32_tb/controle
run -all
