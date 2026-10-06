module sonar #(
    parameter CONTAGEM_2SEG = 100_000_000
) (
    input  wire clock,
    input  wire reset,
    input  wire ligar,
    input  wire entrada_serial,
    input  wire echo,
    output wire trigger,
    output wire pwm,
    output wire saida_serial,
    output wire fim_posicao,
    output wire db_modo
);

    wire        w_medir;
    wire        w_contar_endereco;
    wire        w_zera_endereco;
    wire        w_zera_contador;
    wire        w_zera_transmissao;
    wire        w_pronto;
    wire        w_transmite_serial;
    wire        w_pronto_serial;
    wire        w_pronto_medida;
    wire        w_mensurar_automatico;
    wire        w_timeout_echo;
    wire        w_fim_tx_8;
    wire        w_zera_timeout_echo;
    wire        w_conta_timeout_echo;
    wire        w_modo_solicitado;

    sonar_uc uc_sonar (
        .clock              (clock),
        .reset              (reset),
        .mensurar           (ligar),
        .pronto_serial      (w_pronto_serial),
        .pronto_medida      (w_pronto_medida),
        .fim_2seg           (w_mensurar_automatico),
        .timeout_echo       (w_timeout_echo),
        .fim_tx_8           (w_fim_tx_8),
        .modo_solicitado    (w_modo_solicitado),
        .medir              (w_medir),
        .contar_endereco    (w_contar_endereco),
        .zera_endereco      (w_zera_endereco),
        .zera_contador      (w_zera_contador),
        .zera_transmissao   (w_zera_transmissao),
        .pronto             (w_pronto),
        .db_estado          (),
        .transmite_serial   (w_transmite_serial),
        .zera_timeout_echo  (w_zera_timeout_echo),
        .conta_timeout_echo (w_conta_timeout_echo),
        .db_modo            (db_modo)
    );

    sonar_fd #(
        .CONTAGEM_2SEG(CONTAGEM_2SEG)
    ) fd_sonar (
        .clock              (clock),
        .reset              (reset),
        .habilitado         (ligar),
        .entrada_serial     (entrada_serial),
        .medir              (w_medir),
        .echo               (echo),
        .transmite_serial   (w_transmite_serial),
        .zera_contador      (w_zera_contador),
        .zera_transmissao   (w_zera_transmissao),
        .contar_endereco    (w_contar_endereco),
        .zera_endereco      (w_zera_endereco),
        .zera_timeout_echo  (w_zera_timeout_echo),
        .conta_timeout_echo (w_conta_timeout_echo),
        .trigger            (trigger),
        .medida0            (),
        .medida1            (),
        .medida2            (),
        .saida_serial       (saida_serial),
        .pronto_medida      (w_pronto_medida),
        .pronto_serial      (w_pronto_serial),
        .mensurar_automatico(w_mensurar_automatico),
        .pwm                (pwm),
        .timeout_echo       (w_timeout_echo),
        .fim_tx_8           (w_fim_tx_8),
        .modo_solicitado    (w_modo_solicitado)
    );

    assign fim_posicao = w_pronto;

endmodule
