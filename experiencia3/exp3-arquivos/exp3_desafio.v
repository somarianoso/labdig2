module exp3_desafio (
 input wire clock,
 input wire reset,
 input wire medir,
 input wire echo,
 input wire [1:0] posicao,
 output wire trigger,
 output wire [6:0] hex0, // digito da unidade da medida
 output wire [6:0] hex1, // digito da dezena da medida
 output wire [6:0] hex2, // digito da centena da medida
 output wire pronto,
 output wire controle_servo,
 output wire db_medir, // depuracao do sinal medir
 output wire db_echo, // depuracao do sinal echo
 output wire db_trigger, // depuracao do sinal trigger
 output wire db_controle,// depuracao do sinal controle_servo
 output wire [1:0] db_posicao, // depuração do sinal posicao (servo)
 output wire [6:0] db_estado // depuracao: estado da UC
);