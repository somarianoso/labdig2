`timescale 1ns/1ns

module sonar_tb_prova1;
    parameter CLOCK_PERIOD = 20;
    parameter BIT_PERIOD = 8680;
    parameter CONTAGEM_2SEG_SIM = 500000;
    parameter CLOCKS_POR_CM = 2941;

    reg clock;
    reg reset;
    reg ligar;
    reg entrada_serial;
    reg echo;
    reg [1:0] sel_mux;

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

    reg [7:0] dados_tx [0:63];
    integer quantidade_tx;
    integer bit_indice;
    reg [6:0] dado_recebido;
    reg paridade_recebida;
    reg stop_recebido;

    sonar #(
        .CONTAGEM_2SEG(CONTAGEM_2SEG_SIM)
    ) dut (
        .clock(clock),
        .reset(reset),
        .ligar(ligar),
        .entrada_serial(entrada_serial),
        .echo(echo),
        .sel_mux(sel_mux),
        .trigger(trigger),
        .pwm(pwm),
        .saida_serial(saida_serial),
        .fim_posicao(fim_posicao),
        .db_modo(db_modo),
        .hex0(hex0),
        .hex1(hex1),
        .hex2(hex2),
        .hex3(hex3),
        .hex4(hex4),
        .hex5(hex5),
        .LEDR(ledr)
    );

    always #(CLOCK_PERIOD / 2) clock = ~clock;

    always @(posedge trigger) begin
        @(negedge trigger);
        repeat (2) @(posedge clock);
        echo = 1'b1;
        repeat (3 * CLOCKS_POR_CM) @(posedge clock);
        echo = 1'b0;
    end

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

            if ((^dado_recebido) !== paridade_recebida) begin
                $display("ERRO: paridade serial invalida.");
                $finish;
            end
            if (stop_recebido !== 1'b1) begin
                $display("ERRO: bit de parada serial invalido.");
                $finish;
            end
            if (quantidade_tx >= 64) begin
                $display("ERRO: buffer de transmissao excedido.");
                $finish;
            end

            dados_tx[quantidade_tx] = {1'b0, dado_recebido};
            quantidade_tx = quantidade_tx + 1;
        end
    end

    task envia_caractere;
        input [6:0] valor;
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

    task verifica_mensagem;
        input integer numero;
        input [23:0] angulo;
        integer base;
        begin
            base = numero * 8;
            if (quantidade_tx < base + 8) begin
                $display("ERRO: mensagem %0d ainda nao foi transmitida.", numero + 1);
                $finish;
            end
            if (dados_tx[base] !== {1'b0, angulo[22:16]} ||
                dados_tx[base + 1] !== {1'b0, angulo[14:8]} ||
                dados_tx[base + 2] !== {1'b0, angulo[6:0]} ||
                dados_tx[base + 3] !== 8'h2C ||
                dados_tx[base + 4] !== 8'h30 ||
                dados_tx[base + 5] !== 8'h30 ||
                dados_tx[base + 6] !== 8'h33 ||
                dados_tx[base + 7] !== 8'h23) begin
                $display("ERRO: dados incorretos na mensagem %0d.", numero + 1);
                $finish;
            end
        end
    endtask

    initial begin
        clock = 1'b0;
        reset = 1'b1;
        ligar = 1'b0;
        entrada_serial = 1'b1;
        echo = 1'b0;
        sel_mux = 2'b00;
        quantidade_tx = 0;

        repeat (5) @(posedge clock);
        @(negedge clock);
        reset = 1'b0;
        repeat (2) @(posedge clock);

        if (db_modo !== 1'b0) begin
            $display("ERRO: o modo apos reset deveria ser localizacao.");
            $finish;
        end

        ligar = 1'b1;
        $display("[%0t] Sonar ligado em modo de localizacao.", $time);

        wait (quantidade_tx >= 8);
        verifica_mensagem(0, 24'h303230);
        $display("[%0t] Localizacao 1/3: posicao 20.", $time);

        wait (quantidade_tx >= 16);
        verifica_mensagem(1, 24'h303430);
        $display("[%0t] Localizacao 2/3: posicao 40.", $time);

        wait (quantidade_tx >= 24);
        verifica_mensagem(2, 24'h303630);
        if (dut.fd_sonar.w_endereco !== 3'd2) begin
            $display("ERRO: apos tres ciclos, a posicao deveria ser 60.");
            $finish;
        end
        $display("[%0t] Localizacao 3/3: posicao 60.", $time);

        envia_caractere(7'h61);
        wait (dut.fd_sonar.modo_solicitado === 1'b1);
        wait (db_modo === 1'b1);
        if (dut.fd_sonar.w_endereco !== 3'd2) begin
            $display("ERRO: a entrada em atencao deveria manter 60 graus.");
            $finish;
        end
        $display("[%0t] Caractere 'a' recebido; modo de atencao.", $time);

        wait (quantidade_tx >= 32);
        verifica_mensagem(3, 24'h303630);
        $display("[%0t] Atencao 1/5.", $time);

        wait (quantidade_tx >= 40);
        verifica_mensagem(4, 24'h303630);
        $display("[%0t] Atencao 2/5.", $time);

        wait (quantidade_tx >= 48);
        verifica_mensagem(5, 24'h303630);
        $display("[%0t] Atencao 3/5.", $time);

        wait (quantidade_tx >= 56);
        verifica_mensagem(6, 24'h303630);
        $display("[%0t] Atencao 4/5.", $time);

        wait (quantidade_tx >= 64);
        verifica_mensagem(7, 24'h303630);
        if (dut.fd_sonar.w_endereco !== 3'd2) begin
            $display("ERRO: o modo de atencao moveu a posicao do servo.");
            $finish;
        end
        $display("[%0t] Atencao 5/5.", $time);

        @(negedge clock);
        reset = 1'b1;
        repeat (3) @(posedge clock);
        #1;
        if (db_modo !== 1'b0 ||
            dut.fd_sonar.modo_solicitado !== 1'b0 ||
            dut.fd_sonar.w_endereco !== 3'd0) begin
            $display("ERRO: reset final nao restaurou o estado inicial.");
            $finish;
        end

        $display("[%0t] Reset final aplicado.", $time);
        $display("PASS: 3 ciclos de localizacao, comando 'a', 5 ciclos de atencao e reset.");
        $finish;
    end

    initial begin
        #2000000000;
        $display("ERRO: tempo limite da simulacao excedido.");
        $finish;
    end
endmodule
