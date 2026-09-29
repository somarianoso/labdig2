module sonar_uc (
    input wire       clock,
    input wire       reset,
    input wire       mensurar,
    input wire       pronto_serial,
    input wire       pronto_medida,
    output reg       medir,
    output reg       contar_endereco,
    output reg       zera_endereco,
    output reg       zera_contador,
    output reg       pronto,
    output reg [3:0] db_estado, 
    output reg       transmite_serial,
    output reg [2:0] sel_letra  // 3 bits para 8 posições (ANG[0:2], VÍRGULA, DIST[0:2], HASHTAG)
);

    // Declaração dos estados
    parameter Inicial          = 4'h0;
    parameter PreparaMedida    = 4'h1;  // Inicia medição do sonar
    parameter AguardaMedida    = 4'h2;  // Aguarda conclusão da medição
    parameter ZeraContador     = 4'h3;  // Reseta contador de caracteres
    parameter TransmiteLaco    = 4'h4;  // Estado de transmissão em loop (8 caracteres)
    parameter EsperaPronto0    = 4'h5;  // Aguarda pronto_serial = 0
    parameter EsperaPronto1    = 4'h6;  // Aguarda pronto_serial = 1
    parameter ProximaPosicao   = 4'h7;  // Incrementa posição do servo
    parameter Final            = 4'h8;  // Ciclo completo (volta para medir próxima posição)

    // Variáveis de estado
    reg [3:0] Eatual, Eprox;
    reg [3:0] contador_transmissoes;  // Contador para 8 transmissões (0-7)

    // Memória de estado (Sequencial)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            Eatual <= Inicial;
            contador_transmissoes <= 4'h0;
        end else begin
            Eatual <= Eprox;
            
            // Incrementa contador quando avança de ProximaPosicao
            if (Eatual == ProximaPosicao && Eprox == TransmiteLaco)
                contador_transmissoes <= contador_transmissoes + 1'b1;
            
            // Reseta contador em ZeraContador
            if (Eatual == ZeraContador)
                contador_transmissoes <= 4'h0;
        end
    end

    // Lógica de próximo estado (Combinacional)
    always @* begin
        case (Eatual)
            Inicial:          Eprox = !mensurar ? PreparaMedida : Inicial;
            PreparaMedida:    Eprox = AguardaMedida;
            AguardaMedida:    Eprox = pronto_medida ? ZeraContador : AguardaMedida;
            ZeraContador:     Eprox = TransmiteLaco;
            
            // Loop genérico de transmissão (0-7 caracteres)
            TransmiteLaco:    Eprox = EsperaPronto0;
            EsperaPronto0:    Eprox = (pronto_serial == 1'b0) ? EsperaPronto1 : EsperaPronto0;
            EsperaPronto1:    Eprox = (pronto_serial == 1'b1) ? ProximaPosicao : EsperaPronto1;
            
            // Após 8 transmissões, incrementa posição e volta a medir
            ProximaPosicao:   Eprox = (contador_transmissoes == 4'h7) ? Final : TransmiteLaco;
            
            // Final: incrementa servo e volta a medir (ciclo contínuo)
            Final:            Eprox = (mensurar == 1'b1) ? PreparaMedida : Final;
            default:          Eprox = Inicial;
        endcase
    end

    // Lógica de saídas (Máquina de Moore)
    always @* begin
        // Valores padrão (evita latches)
        medir             = 1'b0;
        contar_endereco   = 1'b0;
        zera_endereco     = 1'b0;
        zera_contador     = 1'b0;
        pronto            = 1'b0;
        transmite_serial  = 1'b0;
        sel_letra         = 3'b000;

        case (Eatual)
            PreparaMedida: begin
                medir = 1'b1;
            end
            
            ZeraContador: begin
                zera_endereco = 1'b1;
            end
            
            // Estado de transmissão: seleciona qual dado transmitir baseado no contador
            TransmiteLaco: begin
                transmite_serial = 1'b1;
                sel_letra = contador_transmissoes[2:0];  // 0-7 para as 8 posições
            end
            
            // Esperas mantêm a seleção, mas sem iniciar transmissão
            EsperaPronto0, EsperaPronto1: begin
                sel_letra = contador_transmissoes[2:0];
            end
            
            // Incrementa endereço do servo (posição) a cada 4 caracteres
            ProximaPosicao: begin
                sel_letra = contador_transmissoes[2:0];
                // Incrementa o contador de endereço a cada 4 transmissões
                // (após ângulo + vírgula + distância + hashtag = 8 caracteres, passa para próxima posição)
                if (contador_transmissoes[1:0] == 2'b11)
                    contar_endereco = 1'b1;
            end
            
            Final: begin
                // Incrementa servo para próxima posição antes de medir novamente
                contar_endereco = 1'b1;
            end
        endcase

        // Atualização contínua do estado para depuração
        db_estado = Eatual;
    end

endmodule