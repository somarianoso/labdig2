module tx_serial_7E1 (
    input  wire       clock,
    input  wire       reset,
    input  wire       partida,
    input  wire [6:0] dados_ascii,
    output wire       saida_serial,
    output wire       pronto,
    output wire       db_partida,
    output wire       db_saida_serial,
    output wire [3:0] db_estado
);

    wire       s_reset        ;
    wire       s_partida      ;
    wire       s_zera         ;
    wire       s_conta        ;
    wire       s_carrega      ;
    wire       s_desloca      ;
    wire       s_tick         ;
    wire       s_fim          ;
    wire       s_saida_serial ;
    wire [3:0] s_estado       ;

    // Sinais reset e partida
    assign s_reset   = reset;
    assign s_partida = partida;
     
    // Instanciação do Fluxo de Dados
    tx_serial_7E1_fd U1_FD (
        .clock        ( clock          ),
        .reset        ( s_reset        ),
        .zera         ( s_zera         ),
        .conta        ( s_conta        ),
        .carrega      ( s_carrega      ),
        .desloca      ( s_desloca      ),
        .dados_ascii  ( dados_ascii    ),
        .saida_serial ( s_saida_serial ),
        .fim          ( s_fim          )
    );

    // Instanciação da Unidade de Controle
    // O sinal 'partida' agora entra direto, sem o edge_detector
    tx_serial_uc U2_UC (
        .clock     ( clock      ),
        .reset     ( s_reset    ),
        .partida   ( s_partida  ), 
        .tick      ( s_tick     ),
        .fim       ( s_fim      ),
        .zera      ( s_zera     ),
        .conta     ( s_conta    ),
        .carrega   ( s_carrega  ),
        .desloca   ( s_desloca  ),
        .pronto    ( pronto     ),
        .db_estado ( s_estado   )
    );

    // Gerador de tick (Mantido para 115200 bauds)
    contador_m #(
        .M(434), 
        .N(9) 
     ) U3_TICK (
        .clock   ( clock  ),
        .zera_as ( 1'b0   ),
        .zera_s  ( s_zera ),
        .conta   ( 1'b1   ),
        .Q       (        ),
        .fim     ( s_tick ),
        .meio    (        )
    );

    // Atribuição das saídas
    assign saida_serial = s_saida_serial;

    // Saídas de depuração (agora db_estado reflete diretamente o binário)
    assign db_partida      = s_partida;
    assign db_saida_serial = s_saida_serial;
    assign db_estado       = s_estado; 

endmodule