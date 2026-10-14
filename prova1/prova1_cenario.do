vlib work
vlog *.v
vsim -voptargs=+acc work.prova1_cenario_tb
add wave sim:/prova1_cenario_tb/clock
add wave sim:/prova1_cenario_tb/reset
add wave sim:/prova1_cenario_tb/entrada_serial
add wave sim:/prova1_cenario_tb/dut/fd_sonar/w_dados_ascii_rx
add wave sim:/prova1_cenario_tb/dut/fd_sonar/w_pronto_rx
add wave sim:/prova1_cenario_tb/dut/fd_sonar/w_paridade_par
add wave sim:/prova1_cenario_tb/dut/w_estado_rx
add wave sim:/prova1_cenario_tb/dut/w_modo_solicitado
add wave sim:/prova1_cenario_tb/dut/w_estado_uc
add wave sim:/prova1_cenario_tb/dut/db_modo
add wave sim:/prova1_cenario_tb/dut/w_db_modo_duplo
add wave sim:/prova1_cenario_tb/dut/w_pronto_medida
add wave sim:/prova1_cenario_tb/dut/w_pronto_serial
add wave sim:/prova1_cenario_tb/dut/w_fim_tx_8
add wave sim:/prova1_cenario_tb/dut/w_mensurar_automatico
add wave sim:/prova1_cenario_tb/dut/w_fim_intervalo_duplo
add wave sim:/prova1_cenario_tb/dut/fd_sonar/w_endereco
run -all
