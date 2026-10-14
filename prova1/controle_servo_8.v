/*
 * controle_servo_8.v - Instancia o PWM com os parâmetros da Tabela 1
 */
module controle_servo_8 (
    input  wire       clock,
    input  wire       reset,
    input  wire [2:0] posicao,
    output wire       controle,
    output wire       db_reset,
    output wire [2:0] db_posicao,
    output wire       db_controle
);

circuito_pwm #(
    .conf_periodo(1000000), // Período de 20ms para clock de 50MHz
    .largura_000(35000),    // 20°
    .largura_001(45700),    // 40°
    .largura_010(56450),    // 60°
    .largura_011(67150),    // 80°
    .largura_100(77850),    // 100°
    .largura_101(88550),    // 120°
    .largura_110(99300),    // 140°
    .largura_111(110000)    // 160°
) gera_pwm (
    .clock(clock), 
    .reset(reset), 
    .largura(posicao), 
    .pwm(controle), 
    .db_pwm(db_controle)
);

// Atribuição dos sinais de depuração
assign db_reset   = reset;
assign db_posicao = posicao;

endmodule