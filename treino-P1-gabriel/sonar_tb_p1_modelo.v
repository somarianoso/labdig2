`timescale 1ns/1ns

module sonar_tb_p1_modelo;

    localparam CLOCK_PERIOD = 20;
    localparam BIT_PERIOD   = 434 * CLOCK_PERIOD;
    localparam CONTAGEM_2S_SIM = 50_000;
    localparam CLOCKS_POR_CM = 2941;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg ligar = 1'b0;
    reg entrada_serial = 1'b1;
    reg echo = 1'b0;
    reg [1:0] sel_mux = 2'b00;

    wire trigger;
    wire pwm;
    wire saida_serial;
    wire fim_posicao;
    wire db_modo;
    wire [6:0] hex0;
    wire [6:0] hex1;
    wire [6:0] hex2;
    wire [6:0] hex3;
    wire [6:0] hex4;
    wire [6:0] hex5;
    wire [9:0] ledr;

    integer contador_tx = 0;
    integer tx_inicial = 0;
    integer bit_indice;
    reg [6:0] dado_recebido;
    reg paridade_recebida;
    reg stop_recebido;

    sonar #(
        .CONTAGEM_2SEG(CONTAGEM_2S_SIM)
    ) dut (
        .clock         (clock),
        .reset         (reset),
        .ligar         (ligar),
        .entrada_serial(entrada_serial),
        .echo          (echo),
        .sel_mux       (sel_mux),
        .trigger       (trigger),
        .pwm           (pwm),
        .saida_serial  (saida_serial),
        .fim_posicao   (fim_posicao),
        .db_modo       (db_modo),
        .hex0          (hex0),
        .hex1          (hex1),
        .hex2          (hex2),
        .hex3          (hex3),
        .hex4          (hex4),
        .hex5          (hex5),
        .LEDR          (ledr)
    );

    always #(CLOCK_PERIOD / 2) clock = ~clock;

    // Simula uma distancia de aproximadamente 3 cm para cada pulso de trigger.
    always @(posedge trigger) begin
        @(negedge trigger);
        repeat (2) @(posedge clock);
        echo = 1'b1;
        repeat (3 * CLOCKS_POR_CM) @(posedge clock);
        echo = 1'b0;
    end

    // Recebe e valida os bytes 7E1 transmitidos pelo sonar.
    always begin
        @(negedge saida_serial);
        #(BIT_PERIOD / 2);
        if (saida_serial === 1'b0) begin
            for (bit_indice = 0; bit_indice < 7; bit_indice = bit_indice + 1) begin
                #(BIT_PERIOD);
                dado_recebido[bit_indice] = saida_serial;
            end

            #(BIT_PERIOD);
            paridade_recebida = saida_serial;
            #(BIT_PERIOD);
            stop_recebido = saida_serial;

            if ((^dado_recebido) !== paridade_recebida)
                $fatal(1, "paridade invalida no caractere serial transmitido");
            if (stop_recebido !== 1'b1)
                $fatal(1, "bit de parada invalido no caractere serial transmitido");

            contador_tx = contador_tx + 1;
        end
    end

    task envia_caractere(input [6:0] valor);
        integer bit_serial;
        reg bit_paridade;
        begin
            bit_paridade = ^valor;
            entrada_serial = 1'b0;
            #(BIT_PERIOD);
            for (bit_serial = 0; bit_serial < 7; bit_serial = bit_serial + 1) begin
                entrada_serial = valor[bit_serial];
                #(BIT_PERIOD);
            end
            entrada_serial = bit_paridade;
            #(BIT_PERIOD);
            entrada_serial = 1'b1;
            #(3 * BIT_PERIOD);
        end
    endtask

    initial begin
        repeat (5) @(posedge clock);
        reset = 1'b0;
        ligar = 1'b1;

        // O circuito deve iniciar em localizacao.
        wait (db_modo === 1'b0);
        if (dut.fd_sonar.modo_solicitado !== 1'b0)
            $fatal(1, "o sonar deve iniciar no modo de localizacao");

        // Aguarda a terceira posicao da varredura (60 graus). O temporizador
        // simulado deixa tempo para receber o comando durante esse ciclo.
        wait (dut.fd_sonar.w_endereco == 3'd2);
        if (dut.fd_sonar.w_endereco !== 3'd2)
            $fatal(1, "a varredura nao chegou a posicao de 60 graus");
        $display("varredura chegou a 60 graus; enviando comando 'a'");

        // O comando chega antes da decisao da FSM, ao fim do envio em 60 graus.
        envia_caractere(7'h61);
        wait (dut.fd_sonar.modo_solicitado === 1'b1);
        $display("caractere 'a' recebido: modo_solicitado=%b", dut.fd_sonar.modo_solicitado);
        wait (db_modo === 1'b1);
        $display("modo de atencao confirmado; db_modo=%b", db_modo);

        if (contador_tx !== 24)
            $fatal(1, "esperadas exatamente 3 mensagens de localizacao antes da atencao; tx=%0d",
                   contador_tx);

        // Espera 2 medidas/tx no modo de atencao.
        tx_inicial = contador_tx;
        wait (contador_tx >= (tx_inicial + 16));
        if (contador_tx !== 40)
            $fatal(1, "esperadas exatamente 2 mensagens no modo de atencao; tx=%0d",
                   contador_tx);
        if (dut.fd_sonar.w_endereco !== 3'd2)
            $fatal(1, "o modo de atencao nao deve mover o servomotor");

        $display("PASS: cenário M concluido");
        $finish;
    end

    initial begin
        #20_000_000;
        $fatal(1, "teste excedeu o tempo limite");
    end

endmodule
