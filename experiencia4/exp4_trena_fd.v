module exp4_trena_fd ( 
    input wire clock,
    input wire reset,
    input wire medir,
    input wire echo,
    input wire transmite_serial,
    input wire [1:0] sel_letra,
    output wire trigger,
    output wire [3:0] medida0, // Agora exporta apenas 4 bits (BCD)
    output wire [3:0] medida1, // Agora exporta apenas 4 bits (BCD)
    output wire [3:0] medida2, // Agora exporta apenas 4 bits (BCD)
    output wire saida_serial,
    output wire pronto_medida,
    output wire pronto_serial
);

    wire [11:0] w_medida; // Saída bruta do HC-SR04 (12 bits)
    reg  [6:0]  dados_ascii;
    wire [2:0]  bitsConversao;

    assign bitsConversao = 3'b011;

    // Fatiamento dos 12 bits para as saídas BCD de 4 bits
    assign medida0 = w_medida[3:0];   // Unidade
    assign medida1 = w_medida[7:4];   // Dezena
    assign medida2 = w_medida[11:8];  // Centena

    // Módulo da Interface do Sensor
    interface_hcsr04 U1 (
        .clock(clock),
        .reset(reset),
        .medir(medir),
        .echo(echo),
        .trigger(trigger),
        .medida(w_medida), // Retorna 12 bits[cite: 1]
        .pronto(pronto_medida),
        .db_estado() 
    );

    // MUX 4x1 para converter e selecionar o caractere ASCII[cite: 1]
    always @(*) begin
        case(sel_letra)
            2'b00: dados_ascii = {bitsConversao, medida2}; // Centena
            2'b01: dados_ascii = {bitsConversao, medida1}; // Dezena
            2'b10: dados_ascii = {bitsConversao, medida0}; // Unidade
            2'b11: dados_ascii = 7'h23; // Código ASCII da Hashtag (#)
            default: dados_ascii = 7'h23;
        endcase
    end

    // Módulo de Transmissão Serial
    tx_serial_7E1 U2 (
        .clock(clock),
        .reset(reset),
        .partida(transmite_serial),
        .dados_ascii(dados_ascii),
        .saida_serial(saida_serial),
        .pronto(pronto_serial),
        .db_tick(), 
        .db_partida(),
        .db_saida_serial(),
        .db_estado()
    );

endmodule