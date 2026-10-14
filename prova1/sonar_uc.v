module sonar_uc (
    input  wire       clock,
    input  wire       reset,
    input  wire       mensurar,
    input  wire       pronto_serial,
    input  wire       pronto_medida,
    input  wire       fim_2seg,
    input  wire       timeout_echo,
    input  wire       fim_tx_8,
    input  wire       fim_intervalo_duplo,
    input  wire [1:0] modo_solicitado,
    output reg        medir,
    output reg        contar_endereco,
    output reg        passo_fino,
    output reg        zera_endereco,
    output reg        zera_contador,
    output reg        zera_transmissao,
    output reg        pronto,
    output reg  [5:0] db_estado,
    output reg        transmite_serial,
    output reg        zera_timeout_echo,
    output reg        conta_timeout_echo,
    output reg        conta_intervalo_duplo,
    output reg        db_modo,
    output reg        db_modo_duplo
);

    localparam MODO_LOCALIZACAO = 2'b00;
    localparam MODO_ATENCAO     = 2'b01;
    localparam MODO_DUPLO       = 2'b10;
    localparam MODO_VARREDURA_FINA = 2'b11;

    localparam inicial                 = 6'd0;
    localparam normal_prepara         = 6'd1;
    localparam normal_aguarda_medida  = 6'd2;
    localparam normal_inicia_tx       = 6'd3;
    localparam normal_espera_tx_baixo = 6'd4;
    localparam normal_espera_tx_alto  = 6'd5;
    localparam normal_verifica_tx     = 6'd6;
    localparam normal_aguarda_2s      = 6'd7;
    localparam normal_decide_modo     = 6'd8;
    localparam normal_avanca_posicao  = 6'd9;

    localparam atencao_prepara         = 6'd10;
    localparam atencao_aguarda_medida  = 6'd11;
    localparam atencao_inicia_tx       = 6'd12;
    localparam atencao_espera_tx_baixo = 6'd13;
    localparam atencao_espera_tx_alto  = 6'd14;
    localparam atencao_verifica_tx     = 6'd15;
    localparam atencao_aguarda_2s      = 6'd16;
    localparam atencao_decide_modo     = 6'd17;
    localparam atencao_mantem_posicao  = 6'd18;

    localparam duplo_prepara_1         = 6'd19;
    localparam duplo_aguarda_medida_1  = 6'd20;
    localparam duplo_inicia_tx_1       = 6'd21;
    localparam duplo_espera_tx_baixo_1 = 6'd22;
    localparam duplo_espera_tx_alto_1  = 6'd23;
    localparam duplo_verifica_tx_1     = 6'd24;
    localparam duplo_aguarda_1s        = 6'd25;
    localparam duplo_prepara_2         = 6'd26;
    localparam duplo_aguarda_medida_2  = 6'd27;
    localparam duplo_inicia_tx_2       = 6'd28;
    localparam duplo_espera_tx_baixo_2 = 6'd29;
    localparam duplo_espera_tx_alto_2  = 6'd30;
    localparam duplo_verifica_tx_2     = 6'd31;
    localparam duplo_decide_modo       = 6'd32;
    localparam duplo_avanca_posicao    = 6'd33;

    localparam fina_prepara              = 6'd34;
    localparam fina_aguarda_medida       = 6'd35;
    localparam fina_inicia_tx            = 6'd36;
    localparam fina_espera_tx_baixo      = 6'd37;
    localparam fina_espera_tx_alto       = 6'd38;
    localparam fina_verifica_tx          = 6'd39;
    localparam fina_aguarda_2s           = 6'd40;
    localparam fina_decide_modo          = 6'd41;
    localparam fina_avanca_posicao       = 6'd42;

    reg [5:0] estado_atual;
    reg [5:0] estado_proximo;

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
                inicial: begin
                    case (modo_solicitado)
                        MODO_ATENCAO: estado_proximo = atencao_prepara;
                        MODO_DUPLO:   estado_proximo = duplo_prepara_1;
                        MODO_VARREDURA_FINA: estado_proximo = fina_prepara;
                        default:      estado_proximo = normal_prepara;
                    endcase
                end

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
                    estado_proximo = pronto_serial ? normal_espera_tx_baixo :
                                                     normal_espera_tx_alto;
                normal_espera_tx_alto:
                    estado_proximo = pronto_serial ? normal_verifica_tx :
                                                     normal_espera_tx_alto;
                normal_verifica_tx:
                    estado_proximo = fim_tx_8 ? normal_aguarda_2s : normal_inicia_tx;
                normal_aguarda_2s:
                    if (fim_2seg)
                        estado_proximo = normal_decide_modo;
                normal_decide_modo: begin
                    case (modo_solicitado)
                        MODO_ATENCAO: estado_proximo = atencao_prepara;
                        MODO_DUPLO:   estado_proximo = duplo_prepara_1;
                        MODO_VARREDURA_FINA: estado_proximo = fina_prepara;
                        default:      estado_proximo = normal_avanca_posicao;
                    endcase
                end
                normal_avanca_posicao: begin
                    case (modo_solicitado)
                        MODO_ATENCAO: estado_proximo = atencao_prepara;
                        MODO_DUPLO:   estado_proximo = duplo_prepara_1;
                        MODO_VARREDURA_FINA: estado_proximo = fina_prepara;
                        default:      estado_proximo = normal_prepara;
                    endcase
                end

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
                    estado_proximo = pronto_serial ? atencao_espera_tx_baixo :
                                                     atencao_espera_tx_alto;
                atencao_espera_tx_alto:
                    estado_proximo = pronto_serial ? atencao_verifica_tx :
                                                     atencao_espera_tx_alto;
                atencao_verifica_tx:
                    estado_proximo = fim_tx_8 ? atencao_aguarda_2s : atencao_inicia_tx;
                atencao_aguarda_2s:
                    if (fim_2seg)
                        estado_proximo = atencao_decide_modo;
                atencao_decide_modo: begin
                    case (modo_solicitado)
                        MODO_ATENCAO: estado_proximo = atencao_mantem_posicao;
                        MODO_DUPLO:   estado_proximo = duplo_prepara_1;
                        MODO_VARREDURA_FINA: estado_proximo = fina_prepara;
                        default:      estado_proximo = normal_prepara;
                    endcase
                end
                atencao_mantem_posicao: begin
                    case (modo_solicitado)
                        MODO_ATENCAO: estado_proximo = atencao_prepara;
                        MODO_DUPLO:   estado_proximo = duplo_prepara_1;
                        MODO_VARREDURA_FINA: estado_proximo = fina_prepara;
                        default:      estado_proximo = normal_prepara;
                    endcase
                end

                duplo_prepara_1:
                    estado_proximo = duplo_aguarda_medida_1;
                duplo_aguarda_medida_1: begin
                    if (pronto_medida)
                        estado_proximo = duplo_inicia_tx_1;
                    else if (timeout_echo)
                        estado_proximo = duplo_aguarda_1s;
                end
                duplo_inicia_tx_1:
                    estado_proximo = duplo_espera_tx_baixo_1;
                duplo_espera_tx_baixo_1:
                    estado_proximo = pronto_serial ? duplo_espera_tx_baixo_1 :
                                                     duplo_espera_tx_alto_1;
                duplo_espera_tx_alto_1:
                    estado_proximo = pronto_serial ? duplo_verifica_tx_1 :
                                                     duplo_espera_tx_alto_1;
                duplo_verifica_tx_1:
                    estado_proximo = fim_tx_8 ? duplo_aguarda_1s : duplo_inicia_tx_1;
                duplo_aguarda_1s:
                    if (fim_intervalo_duplo)
                        estado_proximo = duplo_prepara_2;
                duplo_prepara_2:
                    estado_proximo = duplo_aguarda_medida_2;
                duplo_aguarda_medida_2: begin
                    if (pronto_medida)
                        estado_proximo = duplo_inicia_tx_2;
                    else if (timeout_echo)
                        estado_proximo = duplo_decide_modo;
                end
                duplo_inicia_tx_2:
                    estado_proximo = duplo_espera_tx_baixo_2;
                duplo_espera_tx_baixo_2:
                    estado_proximo = pronto_serial ? duplo_espera_tx_baixo_2 :
                                                     duplo_espera_tx_alto_2;
                duplo_espera_tx_alto_2:
                    estado_proximo = pronto_serial ? duplo_verifica_tx_2 :
                                                     duplo_espera_tx_alto_2;
                duplo_verifica_tx_2:
                    estado_proximo = fim_tx_8 ? duplo_decide_modo : duplo_inicia_tx_2;
                duplo_decide_modo:
                    estado_proximo = duplo_avanca_posicao;
                duplo_avanca_posicao: begin
                    case (modo_solicitado)
                        MODO_DUPLO:   estado_proximo = duplo_prepara_1;
                        MODO_ATENCAO: estado_proximo = atencao_prepara;
                        MODO_VARREDURA_FINA: estado_proximo = fina_prepara;
                        default:      estado_proximo = normal_prepara;
                    endcase
                end

                fina_prepara:
                    estado_proximo = fina_aguarda_medida;
                fina_aguarda_medida: begin
                    if (pronto_medida)
                        estado_proximo = fina_inicia_tx;
                    else if (timeout_echo)
                        estado_proximo = fina_aguarda_2s;
                end
                fina_inicia_tx:
                    estado_proximo = fina_espera_tx_baixo;
                fina_espera_tx_baixo:
                    estado_proximo = pronto_serial ? fina_espera_tx_baixo :
                                                     fina_espera_tx_alto;
                fina_espera_tx_alto:
                    estado_proximo = pronto_serial ? fina_verifica_tx :
                                                     fina_espera_tx_alto;
                fina_verifica_tx:
                    estado_proximo = fim_tx_8 ? fina_aguarda_2s : fina_inicia_tx;
                fina_aguarda_2s:
                    if (fim_2seg)
                        estado_proximo = fina_decide_modo;
                fina_decide_modo: begin
                    case (modo_solicitado)
                        MODO_VARREDURA_FINA:
                            estado_proximo = fina_avanca_posicao;
                        MODO_ATENCAO:
                            estado_proximo = atencao_prepara;
                        MODO_DUPLO:
                            estado_proximo = duplo_prepara_1;
                        default:
                            estado_proximo = normal_prepara;
                    endcase
                end
                fina_avanca_posicao: begin
                    case (modo_solicitado)
                        MODO_VARREDURA_FINA:
                            estado_proximo = fina_prepara;
                        MODO_ATENCAO:
                            estado_proximo = atencao_prepara;
                        MODO_DUPLO:
                            estado_proximo = duplo_prepara_1;
                        default:
                            estado_proximo = normal_prepara;
                    endcase
                end

                default:
                    estado_proximo = inicial;
            endcase
        end
    end

    always @* begin
        medir                 = 1'b0;
        contar_endereco       = 1'b0;
        passo_fino            = 1'b0;
        zera_endereco         = 1'b0;
        zera_contador         = 1'b0;
        zera_transmissao      = 1'b0;
        pronto                = 1'b0;
        transmite_serial      = 1'b0;
        zera_timeout_echo     = 1'b0;
        conta_timeout_echo    = 1'b0;
        conta_intervalo_duplo = 1'b0;
        db_modo               = 1'b0;
        db_modo_duplo         = 1'b0;

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
            normal_aguarda_medida:
                conta_timeout_echo = 1'b1;
            normal_inicia_tx:
                transmite_serial = 1'b1;
            normal_decide_modo:
                if (modo_solicitado == MODO_VARREDURA_FINA)
                    zera_endereco = 1'b1;
            normal_avanca_posicao: begin
                if (modo_solicitado == MODO_VARREDURA_FINA)
                    zera_endereco = 1'b1;
                else
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
            atencao_aguarda_2s:
                db_modo = 1'b1;
            atencao_decide_modo,
            atencao_mantem_posicao: begin
                db_modo = 1'b1;
                if (modo_solicitado == MODO_LOCALIZACAO ||
                    modo_solicitado == MODO_VARREDURA_FINA)
                    zera_endereco = 1'b1;
            end

            duplo_prepara_1,
            duplo_prepara_2: begin
                medir              = 1'b1;
                zera_contador      = 1'b1;
                zera_transmissao   = 1'b1;
                zera_timeout_echo  = 1'b1;
                db_modo_duplo      = 1'b1;
            end
            duplo_aguarda_medida_1,
            duplo_aguarda_medida_2: begin
                conta_timeout_echo = 1'b1;
                db_modo_duplo      = 1'b1;
            end
            duplo_inicia_tx_1,
            duplo_inicia_tx_2: begin
                transmite_serial = 1'b1;
                db_modo_duplo    = 1'b1;
            end
            duplo_aguarda_1s: begin
                conta_intervalo_duplo = 1'b1;
                db_modo_duplo         = 1'b1;
            end
            duplo_avanca_posicao: begin
                if (modo_solicitado == MODO_LOCALIZACAO ||
                    modo_solicitado == MODO_VARREDURA_FINA)
                    zera_endereco = 1'b1;
                else
                    contar_endereco = 1'b1;
                pronto          = 1'b1;
                zera_contador   = 1'b1;
                db_modo_duplo   = 1'b1;
            end
            duplo_espera_tx_baixo_1,
            duplo_espera_tx_alto_1,
            duplo_verifica_tx_1,
            duplo_prepara_2,
            duplo_espera_tx_baixo_2,
            duplo_espera_tx_alto_2,
            duplo_verifica_tx_2,
            duplo_decide_modo:
                db_modo_duplo = 1'b1;

            fina_prepara: begin
                medir              = 1'b1;
                zera_contador      = 1'b1;
                zera_transmissao   = 1'b1;
                zera_timeout_echo  = 1'b1;
                passo_fino         = 1'b1;
            end
            fina_aguarda_medida: begin
                conta_timeout_echo = 1'b1;
                passo_fino         = 1'b1;
            end
            fina_inicia_tx: begin
                transmite_serial = 1'b1;
                passo_fino       = 1'b1;
            end
            fina_espera_tx_baixo,
            fina_espera_tx_alto,
            fina_verifica_tx,
            fina_aguarda_2s: begin
                passo_fino = 1'b1;
            end
            fina_decide_modo: begin
                passo_fino = 1'b1;
                if (modo_solicitado != MODO_VARREDURA_FINA)
                    zera_endereco = 1'b1;
            end
            fina_avanca_posicao: begin
                passo_fino = 1'b1;
                if (modo_solicitado != MODO_VARREDURA_FINA)
                    zera_endereco = 1'b1;
                else
                    contar_endereco = 1'b1;
                pronto        = 1'b1;
                zera_contador = 1'b1;
            end

            default:
                ;
        endcase

        db_estado = estado_atual;
    end

endmodule
