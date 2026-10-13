`timescale 1ns/1ns

module sonar_tb;
    localparam CLOCK_PERIOD = 20;
    localparam BIT_PERIOD = 434 * CLOCK_PERIOD;
    localparam CONTAGEM_2S_SIM = 150_000;
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

    reg [7:0] dados_tx [0:255];
    integer quantidade_tx = 0;
    integer quantidade_fim_posicao = 0;
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

    // Simula um alvo a aproximadamente 3 cm para cada pulso de trigger.
    always @(posedge trigger) begin
        @(negedge trigger);
        repeat (2) @(posedge clock);
        echo = 1'b1;
        repeat (3 * CLOCKS_POR_CM) @(posedge clock);
        echo = 1'b0;
    end

    always @(posedge fim_posicao)
        quantidade_fim_posicao = quantidade_fim_posicao + 1;

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

            if (quantidade_tx > 255)
                $fatal(1, "buffer de caracteres transmitidos excedido");
            dados_tx[quantidade_tx] = {1'b0, dado_recebido};
            quantidade_tx = quantidade_tx + 1;
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

    task verifica_mensagem(input integer numero, input [23:0] angulo);
        integer base;
        begin
            base = numero * 8;
            if (dados_tx[base]     !== {1'b0, angulo[22:16]} ||
                dados_tx[base + 1] !== {1'b0, angulo[14:8]}  ||
                dados_tx[base + 2] !== {1'b0, angulo[6:0]}   ||
                dados_tx[base + 3] !== 8'h2C)
                $fatal(1, "angulo/separador incorreto na mensagem %0d", numero);

            if (dados_tx[base + 4] !== 8'h30 ||
                dados_tx[base + 5] !== 8'h30 ||
                dados_tx[base + 6] !== 8'h33)
                $fatal(1, "distancia deveria ser 003 cm na mensagem %0d", numero);

            if (dados_tx[base + 7] !== 8'h23)
                $fatal(1, "terminador '#' ausente na mensagem %0d", numero);
        end
    endtask

    function [6:0] decodifica_7seg(input [3:0] hexa);
        begin
            case (hexa)
                4'h0: decodifica_7seg = 7'b1000000;
                4'h1: decodifica_7seg = 7'b1111001;
                4'h2: decodifica_7seg = 7'b0100100;
                4'h3: decodifica_7seg = 7'b0110000;
                4'h4: decodifica_7seg = 7'b0011001;
                4'h5: decodifica_7seg = 7'b0010010;
                4'h6: decodifica_7seg = 7'b0000010;
                4'h7: decodifica_7seg = 7'b1111000;
                4'h8: decodifica_7seg = 7'b0000000;
                4'h9: decodifica_7seg = 7'b0010000;
                4'hA: decodifica_7seg = 7'b0001000;
                4'hB: decodifica_7seg = 7'b0000011;
                4'hC: decodifica_7seg = 7'b1000110;
                4'hD: decodifica_7seg = 7'b0100001;
                4'hE: decodifica_7seg = 7'b0000110;
                4'hF: decodifica_7seg = 7'b0001110;
            endcase
        end
    endfunction

    task verifica_mux(input [1:0] selecao, input [23:0] esperado);
        reg [9:0] leds_esperados;
        begin
            sel_mux = selecao;
            #1;
            case (selecao)
                2'b00: leds_esperados =
                    {4'b0000, dut.w_timeout_echo, dut.w_pronto_medida, dut.w_medir,
                     pwm, echo, trigger};
                2'b01: leds_esperados =
                    {4'b0000, dut.w_paridade_par, dut.w_pronto_rx, entrada_serial,
                     dut.w_transmite_serial, dut.w_pronto_serial, saida_serial};
                2'b10: leds_esperados =
                    {6'b000000, dut.w_zera_transmissao, dut.w_fim_tx_8,
                     dut.w_pronto_serial, dut.w_transmite_serial};
                2'b11: leds_esperados =
                    {6'b000000, db_modo, dut.w_mensurar_automatico,
                     dut.w_pronto, dut.w_modo_solicitado};
            endcase

            if (dut.mux_out !== esperado)
                $fatal(1, "MUX sel=%b: valor %h, esperado %h",
                       selecao, dut.mux_out, esperado);
            if (ledr !== leds_esperados)
                $fatal(1, "LEDR sel=%b: valor %b, esperado %b",
                       selecao, ledr, leds_esperados);
            if (hex0 !== decodifica_7seg(esperado[3:0]) ||
                hex1 !== decodifica_7seg(esperado[7:4]) ||
                hex2 !== decodifica_7seg(esperado[11:8]) ||
                hex3 !== decodifica_7seg(esperado[15:12]) ||
                hex4 !== decodifica_7seg(esperado[19:16]) ||
                hex5 !== decodifica_7seg(esperado[23:20]))
                $fatal(1, "displays nao correspondem ao MUX sel=%b", selecao);
        end
    endtask

    task verifica_todos_muxes;
        begin
            verifica_mux(2'b00,
                {{1'b0, dut.w_posicao_servo}, dut.w_estado_hcsr04, 4'h0,
                 dut.w_medida2, dut.w_medida1, dut.w_medida0});
            verifica_mux(2'b01,
                {dut.w_estado_tx, {1'b0, dut.w_dado_tx_transmitido[6:4]},
                 dut.w_dado_tx_transmitido[3:0], dut.w_estado_rx,
                 {1'b0, dut.w_dado_rx_recebido[6:4]}, dut.w_dado_rx_recebido[3:0]});
            verifica_mux(2'b10,
                {dut.w_estado_tx_sonar, {1'b0, dut.w_contagem_selmux},
                 {1'b0, dut.w_dado_tx_transmitido[6:4]},
                 dut.w_dado_tx_transmitido[3:0], 8'h00});
            verifica_mux(2'b11,
                {{3'b000, dut.w_estado_uc[4]}, dut.w_estado_uc[3:0], 4'h0,
                 dut.w_angulo2, dut.w_angulo1, dut.w_angulo0});
        end
    endtask

    initial begin
        repeat (5) @(posedge clock);
        reset = 1'b0;
        repeat (5) @(posedge clock);
        if (db_modo !== 1'b0)
            $fatal(1, "o sonar deve iniciar no modo de localizacao");

        verifica_todos_muxes();
        ligar = 1'b1;

        wait (quantidade_tx >= 8);
        verifica_mensagem(0, 24'h303230);
        wait (dut.fd_sonar.w_endereco == 3'd1);
        if (quantidade_fim_posicao != 1)
            $fatal(1, "a varredura normal nao sinalizou o fim da primeira posicao");

        envia_caractere(7'h61);
        wait (db_modo === 1'b1);
        verifica_todos_muxes();
        wait (quantidade_tx >= 40);
        verifica_mensagem(1, 24'h303430);
        verifica_mensagem(2, 24'h303430);
        verifica_mensagem(3, 24'h303430);
        verifica_mensagem(4, 24'h303430);
        if (dut.fd_sonar.w_endereco !== 3'd1 || quantidade_fim_posicao != 1)
            $fatal(1, "o modo de atencao movimentou o servomotor");

        envia_caractere(7'h41);
        if (dut.fd_sonar.modo_solicitado !== 1'b1 || db_modo !== 1'b1)
            $fatal(1, "um comando diferente de 'a'/'v' alterou o modo");

        envia_caractere(7'h76);
        wait (db_modo === 1'b0);
        verifica_todos_muxes();
        wait (quantidade_tx >= 48);
        verifica_mensagem(5, 24'h303430);
        wait (dut.fd_sonar.w_endereco == 3'd2);
        if (quantidade_fim_posicao != 2)
            $fatal(1, "o sonar nao retomou a varredura apos o comando 'v'");

        wait (quantidade_tx >= 56);
        verifica_mensagem(6, 24'h303630);
        wait (quantidade_tx >= 64);
        verifica_mensagem(7, 24'h303830);
        wait (quantidade_tx >= 72);
        verifica_mensagem(8, 24'h313030);
        wait (quantidade_tx >= 80);
        verifica_mensagem(9, 24'h313230);
        wait (quantidade_tx >= 88);
        verifica_mensagem(10, 24'h313430);
        wait (quantidade_tx >= 96);
        verifica_mensagem(11, 24'h313630);
        wait (quantidade_tx >= 104);
        verifica_mensagem(12, 24'h303230);
        wait (quantidade_fim_posicao == 9);
        @(posedge clock);
        #1;
        if (dut.fd_sonar.w_endereco !== 3'd1)
            $fatal(1, "a varredura nao retornou a posicao inicial apos o ciclo completo");

        $display("PASS: full localization sweep, 7E1, attention mode, debug mux and LEDs");
        $finish;
    end

    initial begin
        #100_000_000;
        $fatal(1, "teste de integracao excedeu o tempo limite");
    end
endmodule
