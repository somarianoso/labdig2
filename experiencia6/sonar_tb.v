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

    wire trigger;
    wire pwm;
    wire saida_serial;
    wire fim_posicao;
    wire db_modo;

    reg [7:0] dados_tx [0:255];
    integer quantidade_tx = 0;
    integer quantidade_fim_posicao = 0;
    integer bit_indice;
    integer indice_mensagem;
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
        .trigger       (trigger),
        .pwm           (pwm),
        .saida_serial  (saida_serial),
        .fim_posicao   (fim_posicao),
        .db_modo       (db_modo)
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

            for (indice_mensagem = 4; indice_mensagem < 7; indice_mensagem = indice_mensagem + 1) begin
                if (dados_tx[base + indice_mensagem] < 8'h30 ||
                    dados_tx[base + indice_mensagem] > 8'h39)
                    $fatal(1, "distancia nao esta em ASCII decimal na mensagem %0d", numero);
            end

            if (dados_tx[base + 7] !== 8'h23)
                $fatal(1, "terminador '#' ausente na mensagem %0d", numero);
        end
    endtask

    initial begin
        repeat (5) @(posedge clock);
        reset = 1'b0;
        repeat (5) @(posedge clock);
        if (db_modo !== 1'b0)
            $fatal(1, "o sonar deve iniciar no modo de localizacao");

        ligar = 1'b1;

        wait (quantidade_tx >= 8);
        verifica_mensagem(0, 24'h303230);
        wait (dut.fd_sonar.w_endereco == 3'd1);
        if (quantidade_fim_posicao != 1)
            $fatal(1, "a varredura normal nao sinalizou o fim da primeira posicao");

        envia_caractere(7'h61);
        wait (db_modo === 1'b1);
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
        wait (quantidade_tx >= 48);
        verifica_mensagem(5, 24'h303430);
        wait (dut.fd_sonar.w_endereco == 3'd2);
        if (quantidade_fim_posicao != 2)
            $fatal(1, "o sonar nao retomou a varredura apos o comando 'v'");

        wait (quantidade_tx >= 56);
        verifica_mensagem(6, 24'h303630);

        $display("PASS: trigger, sonar measurement, 7E1 TX, localization/attention modes");
        $finish;
    end

    initial begin
        #100_000_000;
        $fatal(1, "teste de integracao excedeu o tempo limite");
    end
endmodule
