/*
 * circuito_pwm.v - descrição comportamental
 *
 * gera saída com modulacao pwm conforme parametros do modulo
 *
 * parametros: valores definidos para clock de 50MHz (periodo=20ns)
 * ------------------------------------------------------------------------
 * Revisoes  :
 *     Data        Versao  Autor             Descricao
 *     26/09/2021  1.0     Edson Midorikawa  criacao do componente VHDL
 *     17/08/2024  2.0     Edson Midorikawa  componente em Verilog
 *     28/08/2025  2.1     Edson Midorikawa  revisao do componente
 * ------------------------------------------------------------------------
 */
 
/*
 * circuito_pwm.v - descrição comportamental
 * Modificado para 8 posições (3 bits)
 */
module circuito_pwm #( 
    parameter conf_periodo = 1000000, // Período do sinal PWM [1000000 => f=50Hz (20ms)]
    parameter largura_000  = 35000,   // Largura do pulso p/ 000 [35000 => 0,7ms]
    parameter largura_001  = 45700,   // Largura do pulso p/ 001 [45700 => 0,914ms]
    parameter largura_010  = 56450,   // Largura do pulso p/ 010 [56450 => 1,129ms]
    parameter largura_011  = 67150,   // Largura do pulso p/ 011 [67150 => 1,343ms]
    parameter largura_100  = 77850,   // Largura do pulso p/ 100 [77850 => 1,557ms]
    parameter largura_101  = 88550,   // Largura do pulso p/ 101 [88550 => 1,771ms]
    parameter largura_110  = 99300,   // Largura do pulso p/ 110 [99300 => 1,986ms]
    parameter largura_111  = 110000   // Largura do pulso p/ 111 [110000 => 2,2ms]
) (
    input  wire       clock,
    input  wire       reset,
    input  wire [2:0] largura, // Modificado de [1:0] para [2:0]
    output wire       pwm,
    output wire       db_pwm
);

reg [31:0] contagem;
reg [31:0] largura_pwm;
reg s_pwm;

always @(posedge clock or posedge reset) begin
    if (reset) begin
        contagem <= 0;
        s_pwm <= 0;
        largura_pwm <= largura_000;
    end else begin
        // Saída PWM
        s_pwm <= (contagem < largura_pwm);

        // Atualização do contador e da largura do pulso
        if (contagem == conf_periodo - 1) begin
            contagem <= 0;
            case (largura)
                3'b000: largura_pwm <= largura_000;
                3'b001: largura_pwm <= largura_001;
                3'b010: largura_pwm <= largura_010;
                3'b011: largura_pwm <= largura_011;
                3'b100: largura_pwm <= largura_100;
                3'b101: largura_pwm <= largura_101;
                3'b110: largura_pwm <= largura_110;
                3'b111: largura_pwm <= largura_111;
                default: largura_pwm <= largura_000;
            endcase
        end else begin
            contagem <= contagem + 1;
        end
    end
end

assign db_pwm = s_pwm;
assign pwm    = s_pwm;

endmodule