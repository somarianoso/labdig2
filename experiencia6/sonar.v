module sonar #(
    parameter CONTAGEM_2SEG = 100_000_000
) (
    input  wire clock,
    input  wire reset,
    input  wire ligar,
    input  wire entrada_serial,
    input  wire echo,
    input  wire [1:0] sel_mux,    // Chaves para seleção da multiplexação
    output wire trigger,
    output wire pwm,
    output wire saida_serial,
    output wire fim_posicao,
    output wire db_modo,
    output wire [6:0] hex0,       // Saídas para os 6 displays
    output wire [6:0] hex1,
    output wire [6:0] hex2,
    output wire [6:0] hex3,
    output wire [6:0] hex4,
    output wire [6:0] hex5,
    output reg  [9:0] LEDR
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

    // Fios adicionados para receber as medidas do Fluxo de Dados
    wire [3:0]  w_medida0;
    wire [3:0]  w_medida1;
    wire [3:0]  w_medida2;
    wire [4:0]  w_estado_uc; // Exemplo de captura de estado da UC (ajuste conforme seu código)

    // Fios de depuração vindos do Fluxo de Dados
    wire [3:0] w_estado_rx;
    wire [3:0] w_estado_tx;
    wire [3:0] w_estado_hcsr04;
    wire [2:0] w_posicao_servo;
    wire [6:0] w_dado_rx_recebido;

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
        .db_estado          (w_estado_uc), // Conecte o estado interno aqui se quiser exibi-lo
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
        .medida0            (w_medida0), // Conectados aos fios criados
        .medida1            (w_medida1),
        .medida2            (w_medida2),
        .saida_serial       (saida_serial),
        .pronto_medida      (w_pronto_medida),
        .pronto_serial      (w_pronto_serial),
        .mensurar_automatico(w_mensurar_automatico),
        .pwm                (pwm),
        .timeout_echo       (w_timeout_echo),
        .fim_tx_8           (w_fim_tx_8),
        .modo_solicitado    (w_modo_solicitado)
        // === NOVAS PORTAS DE DEPURAÇÃO ADICIONADAS AQUI ===
        .db_estado_rx       (w_estado_rx),
        .db_estado_tx       (w_estado_tx),
        .db_estado_hcsr04   (w_estado_hcsr04),
        .posicao_servo      (w_posicao_servo),
        .dado_rx_recebido   (w_dado_rx_recebido)
    );

    // ========================================================
    // MULTIPLEXAÇÃO DE DEPURAÇÃO (MUX 4x1 - 24 bits)
    // ========================================================
    wire [23:0] sinais00, sinais01, sinais10, sinais11;
    reg  [23:0] mux_out;

    // ========================================================
    // sel_mux == 00: servomotor + HC-SR04
    // HEX5: posição do servo (3 bits c/ padding)
    // HEX4: estado_hcsr04
    // HEX3: a definir (apagado)
    // HEX2, HEX1, HEX0: distancia2, distancia1, distancia0
    // ========================================================
    assign sinais00 = { {1'b0, w_posicao_servo}, w_estado_hcsr04, 4'h0, w_medida2, w_medida1, w_medida0 };    
    
    // ========================================================
    // sel_mux == 01: uart
    // HEX5: estado_tx
    // HEX4, HEX3: DADO_TX1 e DADO_TX0 (nibbles do dado ASCII transmitido)
    // HEX2: estado_rx
    // HEX1, HEX0: DADO_RX1 e DADO_RX0 (nibbles do dado ASCII recebido)
    // ========================================================    
    assign sinais01 = { w_estado_tx, {1'b0, w_dado_tx_transmitido[6:4]}, w_dado_tx_transmitido[3:0], w_estado_rx, {1'b0, w_dado_rx_recebido[6:4]}, w_dado_rx_recebido[3:0] };    
    
    // ========================================================
    // sel_mux == 10: tx dados sonar
    // HEX5: estado_tx_sonar
    // HEX4: contagem_selmux
    // HEX3, HEX2: dado_sonar1, dado_sonar2
    // HEX1, HEX0: a definir (apagados)
    // ========================================================
    // HEX3 e HEX2 mostrando o caractere atual da mensagem "ANG,DIS#"
    assign sinais10 = { w_estado_tx_sonar, {1'b0, w_contagem_selmux}, 
                        {1'b0, w_dado_tx_transmitido[6:4]}, w_dado_tx_transmitido[3:0], 
                        4'h0, 4'h0 };    
    // ========================================================
    // sel_mux == 11: sonar
    // HEX5: estado_sonar (bit mais significativo, p/ fechar 5 bits)
    // HEX4: a definir (usaremos para os 4 bits menos significativos do estado)
    // HEX3: a definir (apagado)
    // HEX2, HEX1, HEX0: angulo2, angulo1, angulo0
    // ========================================================
    assign sinais11 = { {3'b000, w_estado_uc[4]}, w_estado_uc[3:0], 4'h0, 
                        w_angulo2, w_angulo1, w_angulo0 };    
    
    always @(*) begin
        case (sel_mux)
            2'b00: mux_out = sinais00;
            2'b01: mux_out = sinais01;
            2'b10: mux_out = sinais10;
            2'b11: mux_out = sinais11;
            default: mux_out = 24'h000000;
        endcase
    end

    // ========================================================
    // MULTIPLEXAÇÃO DOS 10 LEDs VERMELHOS (LEDR[9:0])
    // ========================================================
    always @(*) begin
        case (sel_mux)
            2'b00: // Sinais físicos do Sensor e Servo
                LEDR = {4'b0000, w_timeout_echo, w_pronto_medida, w_medir, pwm, echo, trigger};
            
            2'b01: // Sinais da UART
                LEDR = {4'b0000, w_paridade_par, w_pronto_rx, entrada_serial, w_transmite_serial, w_pronto_serial, saida_serial};
            
            2'b10: // Sinais de temporização / timeout
                LEDR = {6'b000000, w_zera_transmissao, w_fim_tx_8, w_pronto_serial, w_transmite_serial};
            
            2'b11: // Sinais da Máquina Central e Modos
                LEDR = {6'b000000, w_mensurar_automatico, w_pronto, w_modo_solicitado, w_modo_atual};
                
            default: 
                LEDR = 10'b0000000000;
        endcase
    end

    // ========================================================
    // INSTANCIAÇÃO DOS 6 DISPLAYS DE 7 SEGMENTOS
    // ========================================================
    // Cada display recebe 4 bits correspondentes da saída do MUX
    hexa7seg HEX0 (.hexa(mux_out[3:0]),   .display(hex0));
    hexa7seg HEX1 (.hexa(mux_out[7:4]),   .display(hex1));
    hexa7seg HEX2 (.hexa(mux_out[11:8]),  .display(hex2));
    hexa7seg HEX3 (.hexa(mux_out[15:12]), .display(hex3));
    hexa7seg HEX4 (.hexa(mux_out[19:16]), .display(hex4));
    hexa7seg HEX5 (.hexa(mux_out[23:20]), .display(hex5));

endmodule