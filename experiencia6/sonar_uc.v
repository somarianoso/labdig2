module sonar_uc (
    input  wire       clock,
    input  wire       reset,
    input  wire       mensurar,
    input  wire       pronto_serial,
    input  wire       pronto_medida,
    input  wire       fim_2seg,
    input  wire       timeout_echo,
    input  wire       fim_tx_8,
    input  wire [6:0] dados_ascii_rx,
    input  wire       pronto_rx,
    output reg        medir,
    output reg        contar_endereco,
    output reg        zera_endereco,
    output reg        zera_contador,
    output reg        zera_transmissao,
    output reg        pronto,
    output reg  [3:0] db_estado,
    output reg        transmite_serial,
    output reg        zera_timeout_echo,
    output reg        conta_timeout_echo,
    output reg        db_modo
);

    localparam Inicial            = 4'h0;
    localparam PreparaMedida      = 4'h1;
    localparam AguardaMedida      = 4'h2;
    localparam TransmiteCaractere = 4'h3;
    localparam EsperaPronto0      = 4'h4;
    localparam EsperaPronto1      = 4'h5;
    localparam VerificaFimTx      = 4'h6;
    localparam EsperaTemporizador = 4'h7;
    localparam AvancaPosicao      = 4'h8;
    localparam ModoAtencao        = 4'h9;

    reg [3:0] estado_atual;
    reg [3:0] estado_proximo;
    reg       modo;
    reg       ciclo_em_atencao;
    wire      modo_atencao_efetivo;

    // Reconhece 'a' no mesmo ciclo em que a varredura tentaria avancar.
    assign modo_atencao_efetivo = modo || (pronto_rx && dados_ascii_rx == 7'h61);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            estado_atual      <= Inicial;
            modo              <= 1'b0;
            ciclo_em_atencao  <= 1'b0;
        end else begin
            estado_atual <= estado_proximo;

            if (pronto_rx) begin
                case (dados_ascii_rx)
                    7'h61: modo <= 1'b1; // 'a': atencao
                    7'h76: modo <= 1'b0; // 'v': voltar a localizacao
                    default: modo <= modo;
                endcase
            end

            // Guarda o modo no inicio da medida para nao pular a posicao ao voltar.
            if (estado_atual == PreparaMedida)
                ciclo_em_atencao <= modo;
        end
    end

    always @* begin
        estado_proximo = estado_atual;

        if (!mensurar) begin
            estado_proximo = Inicial;
        end else begin
            case (estado_atual)
                Inicial:
                    estado_proximo = PreparaMedida;

                PreparaMedida:
                    estado_proximo = AguardaMedida;

                AguardaMedida: begin
                    if (pronto_medida)
                        estado_proximo = TransmiteCaractere;
                    else if (timeout_echo)
                        estado_proximo = EsperaTemporizador;
                end

                TransmiteCaractere:
                    estado_proximo = EsperaPronto0;

                EsperaPronto0:
                    estado_proximo = pronto_serial ? EsperaPronto0 : EsperaPronto1;

                EsperaPronto1:
                    estado_proximo = pronto_serial ? VerificaFimTx : EsperaPronto1;

                VerificaFimTx:
                    estado_proximo = fim_tx_8 ? EsperaTemporizador : TransmiteCaractere;

                EsperaTemporizador: begin
                    if (fim_2seg) begin
                        if (modo_atencao_efetivo || ciclo_em_atencao)
                            estado_proximo = ModoAtencao;
                        else
                            estado_proximo = AvancaPosicao;
                    end
                end

                AvancaPosicao:
                    estado_proximo = modo_atencao_efetivo ? ModoAtencao : PreparaMedida;

                ModoAtencao:
                    estado_proximo = PreparaMedida;

                default:
                    estado_proximo = Inicial;
            endcase
        end
    end

    always @* begin
        medir              = 1'b0;
        contar_endereco    = 1'b0;
        zera_endereco      = 1'b0;
        zera_contador      = 1'b0;
        zera_transmissao   = 1'b0;
        pronto             = 1'b0;
        transmite_serial  = 1'b0;
        zera_timeout_echo  = 1'b0;
        conta_timeout_echo = 1'b0;
        db_modo            = modo;

        case (estado_atual)
            Inicial: begin
                zera_contador    = 1'b1;
                zera_transmissao = 1'b1;
                zera_timeout_echo = 1'b1;
            end

            PreparaMedida: begin
                medir              = 1'b1;
                zera_contador      = 1'b1;
                zera_transmissao   = 1'b1;
                zera_timeout_echo  = 1'b1;
            end

            AguardaMedida:
                conta_timeout_echo = 1'b1;

            TransmiteCaractere:
                transmite_serial = 1'b1;

            EsperaTemporizador:
                ;

            AvancaPosicao: begin
                contar_endereco = !modo_atencao_efetivo;
                pronto          = !modo_atencao_efetivo;
                zera_contador   = 1'b1;
            end

            default:
                ;
        endcase

        medir             = medir && mensurar;
        contar_endereco   = contar_endereco && mensurar;
        pronto            = pronto && mensurar;
        transmite_serial  = transmite_serial && mensurar;
        db_estado         = estado_atual;
    end

endmodule
