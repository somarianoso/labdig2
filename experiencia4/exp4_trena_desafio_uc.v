module exp4_trena_desafio_uc (
    input wire       clock,
    input wire       reset,
    input wire       mensurar,
    input wire       pronto_serial,
    input wire       pronto_medida,
    output reg       medir,
    output reg       pronto,
    output reg [3:0] db_estado, 
    output reg       transmite_serial,
    output reg [1:0] sel_letra, // CORRIGIDO: precisa de 2 bits para as 4 opções (00, 01, 10, 11)
    output reg zera_contador
);

    // Declaração dos estados (16 estados cabem perfeitamente em 4 bits)
    parameter Inicial          = 4'h0;
    parameter PreparaMedida    = 4'h1;
    parameter AguardaMedida    = 4'h2;
    
    parameter TransmiteCentena = 4'h3;
    parameter EsperaTxCent0    = 4'h4;
    parameter EsperaTxCent1    = 4'h5;
    
    parameter TransmiteDezena  = 4'h6;
    parameter EsperaTxDez0     = 4'h7;
    parameter EsperaTxDez1     = 4'h8;
    
    parameter TransmiteUnidade = 4'h9;
    parameter EsperaTxUni0     = 4'hA;
    parameter EsperaTxUni1     = 4'hB;
    
    parameter TransmiteHashtag = 4'hC;
    parameter EsperaTxHash0    = 4'hD;
    parameter EsperaTxHash1    = 4'hE;
    
    parameter Final            = 4'hF;

    // Variáveis de estado
    reg [3:0] Eatual, Eprox;

    // Memória de estado (Sequencial)
    always @(posedge clock or posedge reset) begin
        if (reset)
            Eatual <= Inicial;
        else
            Eatual <= Eprox;
    end

    // Lógica de próximo estado (Combinacional)
    always @* begin
        case (Eatual)
            Inicial:          Eprox = !mensurar ? PreparaMedida : Inicial;
            PreparaMedida:    Eprox = AguardaMedida;
            AguardaMedida:    Eprox = pronto_medida ? TransmiteCentena : AguardaMedida;
            
            // Ciclo da Centena
            TransmiteCentena: Eprox = EsperaTxCent0;
            EsperaTxCent0:    Eprox = (pronto_serial == 1'b0) ? EsperaTxCent1 : EsperaTxCent0;
            EsperaTxCent1:    Eprox = (pronto_serial == 1'b1) ? TransmiteDezena : EsperaTxCent1;
            
            // Ciclo da Dezena
            TransmiteDezena:  Eprox = EsperaTxDez0;
            EsperaTxDez0:     Eprox = (pronto_serial == 1'b0) ? EsperaTxDez1 : EsperaTxDez0;
            EsperaTxDez1:     Eprox = (pronto_serial == 1'b1) ? TransmiteUnidade : EsperaTxDez1;
            
            // Ciclo da Unidade
            TransmiteUnidade: Eprox = EsperaTxUni0;
            EsperaTxUni0:     Eprox = (pronto_serial == 1'b0) ? EsperaTxUni1 : EsperaTxUni0;
            EsperaTxUni1:     Eprox = (pronto_serial == 1'b1) ? TransmiteHashtag : EsperaTxUni1;
            
            // Ciclo da Hashtag
            TransmiteHashtag: Eprox = EsperaTxHash0;
            EsperaTxHash0:    Eprox = (pronto_serial == 1'b0) ? EsperaTxHash1 : EsperaTxHash0;
            EsperaTxHash1:    Eprox = (pronto_serial == 1'b1) ? Final : EsperaTxHash1;
            
            Final:            Eprox = (mensurar == 1'b1) ? Inicial : Final;
            default:          Eprox = Inicial;
        endcase
    end

    // Lógica de saídas (Máquina de Moore)
    always @* begin
        // Valores padrão (evita latches)
        medir            = 1'b0;
        pronto           = 1'b0;
        transmite_serial = 1'b0;
        sel_letra        = 2'b00;
        zera_contador = 1'b0;

        case (Eatual)
            PreparaMedida: begin
                medir = 1'b1;
                zera_contador = 1'b1;
            end
            
            // --------------------------------------------------
            // Transmissões (transmite_serial em 1)
            // --------------------------------------------------
            TransmiteCentena: begin
                transmite_serial = 1'b1;
                sel_letra        = 2'b00;
            end
            TransmiteDezena: begin
                transmite_serial = 1'b1;
                sel_letra        = 2'b01;
            end
            TransmiteUnidade: begin
                transmite_serial = 1'b1;
                sel_letra        = 2'b10;
            end
            TransmiteHashtag: begin
                transmite_serial = 1'b1;
                sel_letra        = 2'b11;
            end
            
            // --------------------------------------------------
            // Esperas (mantêm a seleção da letra, mas transmite_serial = 0)
            // --------------------------------------------------
            EsperaTxCent0, EsperaTxCent1: begin
                sel_letra = 2'b00;
            end
            EsperaTxDez0, EsperaTxDez1: begin
                sel_letra = 2'b01;
            end
            EsperaTxUni0, EsperaTxUni1: begin
                sel_letra = 2'b10;
            end
            EsperaTxHash0, EsperaTxHash1: begin
                sel_letra = 2'b11;
            end
            
            // --------------------------------------------------
            // Finalização
            // --------------------------------------------------
            Final: begin
                pronto = 1'b1;
            end
        endcase

        // Atualização contínua do estado para depuração
        db_estado = Eatual;
    end

endmodule