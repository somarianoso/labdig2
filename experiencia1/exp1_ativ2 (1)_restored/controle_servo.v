module controle_servo (
 input wire clock,
 input wire reset,
 input wire [1:0] posicao,
 output wire controle,
 output wire db_controle
);

circuito_pwm #(
    .conf_periodo(1000000), // Período do sinal PWM [1000000 => f=50Hz (20ms)]
    .largura_00(0), // Largura do pulso p/ 00 [0 => 0]
    .largura_01(50000), // Largura do pulso p/ 00 [50000 => 1ms]
    .largura_10(75000), // Largura do pulso p/ 00 [75000 => 1,5ms]
    .largura_11(100000) // Largura do pulso p/ 00 [1000000 => 2ms]
) gera_pwm (.clock(clock), .reset(reset), .largura(posicao), .pwm(controle), .db_pwm(db_controle));

endmodule