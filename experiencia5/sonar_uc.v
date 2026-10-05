module sonar_uc (
    input wire       clock,
    input wire       reset,
    input wire       mensurar,
    input wire       pronto_serial,
    input wire       pronto_medida,
    input wire       fim_2seg,        // NOVO SINAL: vem do timer no sonar_fd (mensurar_automatico)
    input wire       timeout_echo,
    input wire       fim_tx_8,
    output reg       medir,
    output reg       contar_endereco,
    output reg       zera_endereco,
    output reg       zera_contador,
    output reg       pronto,
    output reg [3:0] db_estado, 
    output reg       transmite_serial,
    output reg zera_timeout_echo,
    output reg conta_timeout_echo
);

    // Declaração dos estados
    parameter Inicial            = 4'h0;
    parameter PreparaMedida      = 4'h1;  
    parameter AguardaMedida      = 4'h2;  
    parameter TransmiteLaco      = 4'h3;  
    parameter EsperaPronto0      = 4'h4;  
    parameter EsperaPronto1      = 4'h5;  
    parameter VerificaFimTx      = 4'h6;  
    parameter EsperaTemporizador = 4'h7;  // Aguarda 2 segundos
    parameter AvancaPosicao      = 4'h8;  // Incrementa servo e gera pulso de fim
    parameter VerificaMensurar   = 4'h9;

    // Variáveis de estado
    reg [3:0] Eatual, Eprox;

    // Memória de estado (Sequencial)
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            Eatual <= Inicial;
        end else begin
            Eatual <= Eprox;
        end
    end

    // Lógica de próximo estado (Combinacional)
    always @* begin
        if (!mensurar) begin
            Eprox = Inicial;
        end else case (Eatual)
            Inicial:            
                Eprox = mensurar ? PreparaMedida : Inicial; // CORRIGIDO: Só avança se mensurar for 1
            
            PreparaMedida:
                Eprox = AguardaMedida;
            
            AguardaMedida:
                Eprox = pronto_medida ? TransmiteLaco : ((timeout_echo == 1'b1) ? AvancaPosicao : AguardaMedida);
            
            // Loop de transmissão (0 a 7 caracteres)
            TransmiteLaco:      
                Eprox = EsperaPronto0;
            
            EsperaPronto0:      
                Eprox = (pronto_serial == 1'b0) ? EsperaPronto1 : EsperaPronto0;
            
            EsperaPronto1:      
                Eprox = (pronto_serial == 1'b1) ? VerificaFimTx : EsperaPronto1;
            
            VerificaFimTx:      
                // Finaliza a mensagem ou inicia os caracteres restantes.
                Eprox = fim_tx_8 ? EsperaTemporizador : TransmiteLaco;

            EsperaTemporizador: 
                Eprox = (fim_2seg == 1'b1) ? AvancaPosicao : EsperaTemporizador;
            
            AvancaPosicao:
                Eprox = VerificaMensurar;

            VerificaMensurar:
                Eprox = mensurar ? PreparaMedida : Inicial;
                
            default:            
                Eprox = Inicial;
        endcase
    end

    // Lógica de saídas (Máquina de Moore)
    always @* begin
        // Valores por defeito
        medir             = 1'b0;
        contar_endereco   = 1'b0;
        zera_endereco     = 1'b0;
        zera_contador     = 1'b0;
        pronto            = 1'b0;
        transmite_serial  = 1'b0;
        conta_timeout_echo  = 1'b0;
        zera_timeout_echo  = 1'b0;

        case (Eatual)
            Inicial: begin
                zera_contador = 1'b1;
            end
            
            PreparaMedida: begin
                medir = 1'b1;
                zera_contador = 1'b1;
                zera_timeout_echo = 1'b1;
            end

            AguardaMedida: begin
                conta_timeout_echo = 1'b1;
            end
            
            TransmiteLaco: begin
                transmite_serial = 1'b1;
            end
            
            EsperaTemporizador: begin
                zera_contador = 1'b0;
            end
            
            AvancaPosicao: begin
                zera_contador  = 1'b1;
                contar_endereco = 1'b1;
                pronto          = 1'b1;
            end
        endcase

        medir = medir && mensurar;
        contar_endereco = contar_endereco && mensurar;
        pronto = pronto && mensurar;
        transmite_serial = transmite_serial && mensurar;

        db_estado = Eatual;
    end

endmodule