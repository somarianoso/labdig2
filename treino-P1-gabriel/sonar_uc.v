module sonar_uc (
    input  wire       clock,
    input  wire       reset,
    input  wire       mensurar,
    input  wire       pronto_serial,
    input  wire       pronto_medida,
    input  wire       fim_2seg,
    input  wire       timeout_echo,
    input  wire       fim_tx_8,
    input  wire       modo_solicitado,
    output reg        medir,
    output reg        contar_endereco,
    output reg        zera_endereco,
    output reg        zera_contador,
    output reg        zera_transmissao,
    output reg        pronto,
    output reg  [4:0] db_estado,
    output reg        transmite_serial,
    output reg        zera_timeout_echo,
    output reg        conta_timeout_echo,
    output reg        db_modo
);

    localparam inicial                 = 5'd0;

    localparam normal_prepara         = 5'd1;
    localparam normal_aguarda_medida  = 5'd2;
    localparam normal_inicia_tx       = 5'd3;
    localparam normal_espera_tx_baixo = 5'd4;
    localparam normal_espera_tx_alto  = 5'd5;
    localparam normal_verifica_tx     = 5'd6;
    localparam normal_aguarda_2s      = 5'd7;
    localparam normal_decide_modo     = 5'd8;
    localparam normal_avanca_posicao  = 5'd9;

    localparam atencao_prepara         = 5'd10;
    localparam atencao_aguarda_medida  = 5'd11;
    localparam atencao_inicia_tx       = 5'd12;
    localparam atencao_espera_tx_baixo = 5'd13;
    localparam atencao_espera_tx_alto  = 5'd14;
    localparam atencao_verifica_tx     = 5'd15;
    localparam atencao_aguarda_2s      = 5'd16;
    localparam atencao_decide_modo     = 5'd17;
    localparam atencao_mantem_posicao  = 5'd18;

    reg [4:0] estado_atual;
    reg [4:0] estado_proximo;

    always @(posedge clock or posedge reset) begin
        if (reset)
            estado_atual <= inicial;
        else
            estado_atual <= estado_proximo;
    end

    always @* begin
        estado_proximo = estado_atual;

        if (!mensurar) begin
            estado_proximo = inicial;
        end else begin
            case (estado_atual)
                inicial:
                    estado_proximo = modo_solicitado ? atencao_prepara : normal_prepara;

                normal_prepara:
                    estado_proximo = normal_aguarda_medida;
                normal_aguarda_medida: begin
                    if (pronto_medida)
                        estado_proximo = normal_inicia_tx;
                    else if (timeout_echo)
                        estado_proximo = normal_aguarda_2s;
                end
                normal_inicia_tx:
                    estado_proximo = normal_espera_tx_baixo;
                normal_espera_tx_baixo:
                    estado_proximo = pronto_serial ? normal_espera_tx_baixo : normal_espera_tx_alto;
                normal_espera_tx_alto:
                    estado_proximo = pronto_serial ? normal_verifica_tx : normal_espera_tx_alto;
                normal_verifica_tx:
                    estado_proximo = fim_tx_8 ? normal_aguarda_2s : normal_inicia_tx;
                normal_aguarda_2s:
                    if (fim_2seg)
                        estado_proximo = normal_decide_modo;
                normal_decide_modo:
                    estado_proximo = modo_solicitado ? atencao_prepara : normal_avanca_posicao;
                normal_avanca_posicao:
                    estado_proximo = modo_solicitado ? atencao_prepara : normal_prepara;

                atencao_prepara:
                    estado_proximo = atencao_aguarda_medida;
                atencao_aguarda_medida: begin
                    if (pronto_medida)
                        estado_proximo = atencao_inicia_tx;
                    else if (timeout_echo)
                        estado_proximo = atencao_aguarda_2s;
                end
                atencao_inicia_tx:
                    estado_proximo = atencao_espera_tx_baixo;
                atencao_espera_tx_baixo:
                    estado_proximo = pronto_serial ? atencao_espera_tx_baixo : atencao_espera_tx_alto;
                atencao_espera_tx_alto:
                    estado_proximo = pronto_serial ? atencao_verifica_tx : atencao_espera_tx_alto;
                atencao_verifica_tx:
                    estado_proximo = fim_tx_8 ? atencao_aguarda_2s : atencao_inicia_tx;
                atencao_aguarda_2s:
                    if (fim_2seg)
                        estado_proximo = atencao_decide_modo;
                atencao_decide_modo:
                    estado_proximo = modo_solicitado ? atencao_mantem_posicao : normal_prepara;
                atencao_mantem_posicao:
                    estado_proximo = atencao_prepara;

                default:
                    estado_proximo = inicial;
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
        transmite_serial   = 1'b0;
        zera_timeout_echo  = 1'b0;
        conta_timeout_echo = 1'b0;
        db_modo            = 1'b0;

        case (estado_atual)
            inicial: begin
                zera_endereco     = 1'b1;
                zera_contador     = 1'b1;
                zera_transmissao  = 1'b1;
                zera_timeout_echo = 1'b1;
            end

            normal_prepara: begin
                medir              = 1'b1;
                zera_contador      = 1'b1;
                zera_transmissao   = 1'b1;
                zera_timeout_echo  = 1'b1;
            end
            normal_aguarda_medida: begin
                conta_timeout_echo = 1'b1;
            end
            normal_inicia_tx:
                transmite_serial = 1'b1;
            normal_aguarda_2s:
                ;
            normal_avanca_posicao: begin
                contar_endereco = 1'b1;
                pronto          = 1'b1;
                zera_contador   = 1'b1;
            end

            atencao_prepara: begin
                medir              = 1'b1;
                zera_contador      = 1'b1;
                zera_transmissao   = 1'b1;
                zera_timeout_echo  = 1'b1;
                db_modo            = 1'b1;
            end
            atencao_aguarda_medida: begin
                conta_timeout_echo = 1'b1;
                db_modo            = 1'b1;
            end
            atencao_inicia_tx: begin
                transmite_serial = 1'b1;
                db_modo          = 1'b1;
            end
            atencao_espera_tx_baixo,
            atencao_espera_tx_alto,
            atencao_verifica_tx,
            atencao_aguarda_2s,
            atencao_decide_modo,
            atencao_mantem_posicao: begin
                db_modo = 1'b1;
            end

            default:
                ;
        endcase

        case (estado_atual)
            normal_espera_tx_baixo,
            normal_espera_tx_alto,
            normal_verifica_tx:
                db_modo = 1'b0;
            default:
                ;
        endcase

        db_estado = estado_atual;
    end

endmodule
