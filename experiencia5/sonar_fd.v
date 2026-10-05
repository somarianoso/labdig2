module sonar_fd #(
    parameter CONTAGEM_2SEG = 100_000_000 // 2s a 50MHz. Ajustar p/ 10000 em simulação (200us)
) ( 
    input  wire       clock,
    input  wire       reset,
    input  wire       habilitado,
    input  wire       medir,
    input  wire       echo,
    input  wire       transmite_serial,
    input  wire [2:0] sel_letra,
    input  wire       zera_contador,
    input  wire       contar_endereco,
    input  wire       zera_endereco,
    input wire zera_timeout_echo,
    input wire conta_timeout_echo,
    output wire       trigger,
    output wire [3:0] medida0, 
    output wire [3:0] medida1, 
    output wire [3:0] medida2, 
    output wire       saida_serial,
    output wire       pronto_medida,
    output wire       pronto_serial,
    output wire       mensurar_automatico,
    output wire       pwm,
    output wire       timeout_echo,
    output wire       fim_tx_8
);

    wire [11:0] w_medida; 
    reg  [6:0]  dados_ascii;
    wire [2:0]  bitsConversao;
    wire [2:0]  w_endereco;
    wire [23:0] w_posicao;
    wire        reset_operacao;
    wire [3:0]  w_q_tx; // contador de caracteres enviados

    assign bitsConversao = 3'b011;
    assign reset_operacao = reset | ~habilitado;

    // Fatiamento dos 12 bits para as saídas BCD de 4 bits
    assign medida0 = w_medida[3:0];   // Unidade
    assign medida1 = w_medida[7:4];   // Dezena
    assign medida2 = w_medida[11:8];  // Centena

    // Contador de caracteres enviados em uma mensagem (0 a 7)
    contador_m #(
        .M(8),
        .N(4)
    ) U3_tx (
        .clock   (clock),
        .zera_as (1'b0),
        .zera_s  (reset | ~habilitado | ~medir),
        .conta   (pronto_serial),
        .Q       (w_q_tx),
        .fim     (fim_tx_8),
        .meio    ()
    );

    // Seleção do caractere no FD: usa o contador de transmissão
    assign sel_letra = w_q_tx[2:0];

    // MUX 8x1 para compor a mensagem: "ANG,DIS#"
    always @(*) begin
        case(sel_letra)
            3'b000: dados_ascii = w_posicao[22:16];       // Ângulo - Centena (da ROM)
            3'b001: dados_ascii = w_posicao[14:8];        // Ângulo - Dezena  (da ROM)
            3'b010: dados_ascii = w_posicao[6:0];         // Ângulo - Unidade (da ROM)
            3'b011: dados_ascii = 7'h2C;                  // Vírgula ','
            3'b100: dados_ascii = {bitsConversao, medida2}; // Distância - Centena
            3'b101: dados_ascii = {bitsConversao, medida1}; // Distância - Dezena
            3'b110: dados_ascii = {bitsConversao, medida0}; // Distância - Unidade
            3'b111: dados_ascii = 7'h23;                  // Hashtag '#'
            default: dados_ascii = 7'h23;
        endcase
    end

    // U1: Módulo da Interface do Sensor
    interface_hcsr04 U1 (
        .clock    (clock),
        .reset    (reset_operacao),
        .medir    (medir),
        .echo     (echo),
        .trigger  (trigger),
        .medida   (w_medida), 
        .pronto   (pronto_medida),
        .db_reset (),
        .db_medir (),
        .db_estado() 
    );

    // U2: Módulo de Transmissão Serial
    tx_serial_7E1 U2 (
        .clock          (clock),
        .reset          (reset_operacao),
        .partida        (transmite_serial),
        .dados_ascii    (dados_ascii),
        .saida_serial   (saida_serial),
        .pronto         (pronto_serial),
        .db_partida     (),
        .db_saida_serial(),
        .db_estado      ()
    );

    // U4: Temporizador (Gera pulso a cada 2 segundos)
    contador_m #(
        .M(CONTAGEM_2SEG),
        .N(27) // Log2(100.000.000) = 26.57 (27 bits necessários)
    ) U4 (
        .clock   (clock),
        .zera_as (1'b0),
        .zera_s  (zera_contador | ~habilitado),
        .conta   (1'b1),
        .Q       (), 
        .fim     (mensurar_automatico),
        .meio    () 
    );

    // U5: Contador de Endereço (0 a 7 posições - movimento "vai" 000→111→000)
    contador_endereco U5 (
        .clock    (clock),
        .conta    (contar_endereco),
        .zera     (zera_endereco | reset),
        .endereco (w_endereco)
    );

    // U6: ROM de Ângulos (Recebe o endereço e entrega o ASCII de 24 bits)
    rom_angulos_8x24 U6 (
        .endereco (w_endereco), 
        .saida    (w_posicao)
    );

    // U7: Controle do Servomotor (Gera o PWM baseado no contador de endereço)
    controle_servo_8 U7 (
        .clock       (clock),
        .reset       (reset),
        .posicao     (w_endereco), // Recebe a posição (3 bits)
        .controle    (pwm),
        .db_reset    (),
        .db_posicao  (),
        .db_controle ()
    );

    // U8: Temporizador (timeout echo a cada 1 seg)
    contador_m #(
        .M(50_000_000),
        .N(26) // Log2(100.000.000) = 26.57 (27 bits necessários)
    ) U8 (
        .clock   (clock),
        .zera_as (1'b0),
        .zera_s  (zera_timeout_echo | ~habilitado),
        .conta   (conta_timeout_echo),
        .Q       (), 
        .fim     (timeout_echo),
        .meio    () 
    );

endmodule