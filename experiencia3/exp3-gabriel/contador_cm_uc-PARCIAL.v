/* --------------------------------------------------------------------------
 *  Arquivo   : contador_cm_uc-PARCIAL.v
 * --------------------------------------------------------------------------
 *  Descricao : unidade de controle do componente contador_cm
 *              
 *              incrementa contagem de cm a cada sinal de tick enquanto
 *              o pulso de entrada permanece ativo
 *              
 * --------------------------------------------------------------------------
 *  Revisoes  :
 *      Data        Versao  Autor             Descricao
 *      07/09/2024  1.0     Edson Midorikawa  versao em Verilog
 * --------------------------------------------------------------------------
 */

module contador_cm_uc (
    input wire clock,
    input wire reset,
    input wire pulso,
    input wire tick,
    output reg zera_tick,
    output reg conta_tick,
    output reg zera_bcd,
    output reg conta_bcd,
    output reg pronto
);

    // Tipos e sinais
    reg [2:0] Eatual, Eprox; // 3 bits são suficientes para os estados

    // Parâmetros para os estados
	/* completar */
    parameter inicial = 3'b000;
    parameter preparacao = 3'b001;
    parameter contaCm = 3'b010;
    parameter esperaTick = 3'b011;
    parameter estadoFinal = 3'b100;

    // Memória de estado
    always @(posedge clock, posedge reset) begin
        if (reset)
            Eatual <= inicial;
        else
            Eatual <= Eprox; 
    end

    // Lógica de próximo estado
    always @(*) begin
        case (Eatual)
            inicial: Eprox = (pulso == 1) ? preparacao : inicial;
            preparacao: Eprox = esperaTick;
            esperaTick: Eprox = (pulso == 0) ? estadoFinal : ((tick == 1) ? contaCm : esperaTick);
            contaCm: Eprox = esperaTick;
            estadoFinal: Eprox = inicial;
            default: Eprox = inicial; 
        endcase
    end

    // Lógica de saída (Moore)
    always @(*) begin
        zera_tick = (Eatual == contaCm || Eatual == preparacao) ? 1'b1 : 1'b0;
        conta_tick = (Eatual == esperaTick) ? 1'b1 : 1'b0;
        zera_bcd = (Eatual == preparacao) ? 1'b1 : 1'b0;
        conta_bcd = (Eatual == contaCm) ? 1'b1 : 1'b0;
        pronto = (Eatual == estadoFinal) ? 1'b1 : 1'b0; 

    end

endmodule