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
    parameter inicial      = 3'b000;
    parameter espera       = 3'b001;
    parameter contagem     = 3'b010;
    parameter estado_final = 3'b011;

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
            inicial: begin
                if (pulso)
                    Eprox = contagem;
                else
                    Eprox = inicial;
            end

            espera: begin
                if (pulso)
                    Eprox = contagem;
                else
                    Eprox = inicial;
            end

            contagem: begin
                if (pulso)
                    Eprox = contagem;
                else
                    Eprox = estado_final;
            end

            estado_final: begin
                Eprox = inicial;
            end

            default: begin
                Eprox = inicial;
            end
        endcase
    end

    // Lógica de saída (Moore)
    always @(*) begin
        zera_tick = 1'b0;
        conta_tick = 1'b0;
        zera_bcd = 1'b0;
        conta_bcd = 1'b0;
        pronto = 1'b0;

        case (Eatual)
            inicial: begin
                zera_tick = 1'b1;
                zera_bcd = 1'b1;
            end

            contagem: begin
                conta_tick = 1'b1;
                if (tick)
                    conta_bcd = 1'b1;
            end

            estado_final: begin
                pronto = 1'b1;
            end

            default: begin
                zera_tick = 1'b0;
                conta_tick = 1'b0;
                zera_bcd = 1'b0;
                conta_bcd = 1'b0;
                pronto = 1'b0;
            end
        endcase
    end

endmodule