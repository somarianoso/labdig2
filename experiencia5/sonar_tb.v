`timescale 1ns/1ns

module sonar_tb;

    parameter clockPeriod = 20;
    parameter TEST_TIMER_COUNT = 1_000_000;
    parameter BIT_TIME_NS = 8_680;
    parameter TEST_TIMER_PERIOD_NS = TEST_TIMER_COUNT * clockPeriod;
    parameter TEST_TIMER_TOLERANCE_NS = 5 * clockPeriod;

    // Sinais de entrada
    reg        clock_in = 0;
    reg        reset_in = 0;
    reg        ligar_in = 0;
    reg        echo_in = 0;

    // Sinais de saida
    wire       trigger_out;
    wire       pwm_out;
    wire       saida_serial_out;
    wire       fim_posicao_out;

    // DUT
    sonar #(
        .CONTAGEM_2SEG(TEST_TIMER_COUNT)
    ) dut (
        .clock       (clock_in),
        .reset       (reset_in),
        .ligar       (ligar_in),
        .echo        (echo_in),
        .trigger     (trigger_out),
        .pwm         (pwm_out),
        .saida_serial(saida_serial_out),
        .fim_posicao (fim_posicao_out)
    );

    // Configuracao do clock -> 50 MHz
    always #(clockPeriod/2) clock_in = ~clock_in;

    // Casos de teste e parametros de tempo
    reg [7:0] distancias_cm [0:7];
    reg [11:0] medidas_teste [0:7];
    reg [23:0] angulos_teste [0:7];
    integer caso;
    reg [31:0] larguraPulso;
    integer erros;
    integer trigger_count;
    integer fim_count;
    integer quadros_verificados;
    integer medidas_iniciadas;
    reg trigger_anterior;
    reg verificar_periodo;
    time tempo_medida_anterior;
    time intervalo_medido;

    always @(posedge clock_in) begin
        if ((trigger_out === 1'b1) && !trigger_anterior)
            trigger_count = trigger_count + 1;
        trigger_anterior = (trigger_out === 1'b1);
    end

    always @(posedge fim_posicao_out)
        fim_count = fim_count + 1;

    always @(posedge dut.w_medir) begin
        if (verificar_periodo && medidas_iniciadas > 0) begin
            intervalo_medido = $time - tempo_medida_anterior;
            if (intervalo_medido + TEST_TIMER_TOLERANCE_NS < TEST_TIMER_PERIOD_NS ||
                intervalo_medido > TEST_TIMER_PERIOD_NS + TEST_TIMER_TOLERANCE_NS) begin
                $display("ERRO: intervalo entre medidas foi %0t ns; esperado %0d ns.",
                         intervalo_medido, TEST_TIMER_PERIOD_NS);
                erros = erros + 1;
            end
        end
        tempo_medida_anterior = $time;
        medidas_iniciadas = medidas_iniciadas + 1;
    end

    task verificar_quadro;
        input [6:0] dado_esperado;
        integer bit_index;
        reg paridade_esperada;
        begin
            wait (saida_serial_out === 1'b1);
            wait (saida_serial_out === 1'b0);

            #(BIT_TIME_NS / 2);
            if (saida_serial_out !== 1'b0) begin
                $display("ERRO: bit de start serial invalido.");
                erros = erros + 1;
            end

            for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1) begin
                #(BIT_TIME_NS);
                if (saida_serial_out !== dado_esperado[bit_index]) begin
                    $display("ERRO: dado serial bit %0d=%b, esperado %b (ASCII %h).",
                             bit_index, saida_serial_out, dado_esperado[bit_index], dado_esperado);
                    erros = erros + 1;
                end
            end

            paridade_esperada = ^dado_esperado;
            #(BIT_TIME_NS);
            if (saida_serial_out !== paridade_esperada) begin
                $display("ERRO: paridade serial=%b, esperada %b (ASCII %h).",
                         saida_serial_out, paridade_esperada, dado_esperado);
                erros = erros + 1;
            end

            #(BIT_TIME_NS);
            if (saida_serial_out !== 1'b1) begin
                $display("ERRO: bit de stop serial invalido.");
                erros = erros + 1;
            end
            quadros_verificados = quadros_verificados + 1;
        end
    endtask

    task verificar_parada;
        input integer triggers_esperados;
        input integer fins_esperados;
        begin
            #(TEST_TIMER_PERIOD_NS + 500_000);
            if (trigger_count != triggers_esperados) begin
                $display("ERRO: %0d triggers observados, esperado %0d.",
                         trigger_count, triggers_esperados);
                erros = erros + 1;
            end
            if (fim_count != fins_esperados || fim_posicao_out !== 1'b0) begin
                $display("ERRO: houve fim_posicao durante a interrupcao.");
                erros = erros + 1;
            end
            if (trigger_out !== 1'b0 || saida_serial_out !== 1'b1) begin
                $display("ERRO: trigger ou serial nao retornou ao repouso apos desligar.");
                erros = erros + 1;
            end
        end
    endtask

    // Tarefa para inicializar o sistema
    task reset_dut;
    begin
        ligar_in = 1'b0;
        echo_in  = 1'b0;

        #(2 * clockPeriod);
        reset_in = 1'b1;
        #(2_000); // 2 us
        reset_in = 1'b0;
        @(negedge clock_in);
        #(100_000); // 100 us de espera antes de ligar
    end
    endtask

    // Tarefa para responder autonomamente a um ciclo do Sonar
    task executar_caso;
        input [7:0] distancia_cm;
        input [11:0] medida_esperada;
        input [23:0] angulo_esperado;
        input espera_fim;
        integer caractere;
        reg [6:0] ascii_esperado;
        time inicio_trigger;
        begin
            $display("\nCaso %0d: posicao %03b, distancia %0d cm.", caso, caso[2:0], distancia_cm);

            // 1: Calcula largura do pulso echo em ns
            larguraPulso = distancia_cm * 58_820;

            // 2: Fica à escuta do pulso Trigger gerado pelo Sonar
            wait (trigger_out == 1'b1);
            inicio_trigger = $time;
            wait (trigger_out == 1'b0); // Espera o trigger de 10us terminar

            if (($time - inicio_trigger) != 10_000) begin
                $display("ERRO: trigger durou %0t ns, esperado 10000 ns.", $time - inicio_trigger);
                erros = erros + 1;
            end

            if (dut.fd_sonar.w_endereco !== caso[2:0]) begin
                $display("ERRO: endereco %b, esperado %b.", dut.fd_sonar.w_endereco, caso[2:0]);
                erros = erros + 1;
            end

            // 3: Espera 400 us entre trigger e echo
            #(400_000);

            // 4: Gera pulso echo com largura definida
            echo_in = 1'b1;
            #(larguraPulso);
            echo_in = 1'b0;

            wait (dut.w_pronto_medida == 1'b1);
            #1;
            if (dut.fd_sonar.w_medida !== medida_esperada) begin
                $display("ERRO: caso %0d mediu BCD %h, esperado %h.",
                         caso, dut.fd_sonar.w_medida, medida_esperada);
                erros = erros + 1;
            end

            for (caractere = 0; caractere < 8; caractere = caractere + 1) begin
                case (caractere)
                    0: ascii_esperado = angulo_esperado[22:16];
                    1: ascii_esperado = angulo_esperado[14:8];
                    2: ascii_esperado = angulo_esperado[6:0];
                    3: ascii_esperado = 7'h2C;
                    4: ascii_esperado = {3'b011, medida_esperada[11:8]};
                    5: ascii_esperado = {3'b011, medida_esperada[7:4]};
                    6: ascii_esperado = {3'b011, medida_esperada[3:0]};
                    7: ascii_esperado = 7'h23;
                    default: ascii_esperado = 7'h3F;
                endcase

                wait (dut.w_transmite_serial == 1'b1);
                #1;
                if (dut.fd_sonar.dados_ascii !== ascii_esperado) begin
                    $display("ERRO: caso %0d caractere %0d: ASCII %h, esperado %h.",
                             caso, caractere, dut.fd_sonar.dados_ascii, ascii_esperado);
                    erros = erros + 1;
                end
                verificar_quadro(ascii_esperado);
                wait (dut.w_pronto_serial == 1'b1);
            end

            if (espera_fim) begin
                wait (fim_posicao_out == 1'b1);
                $display("  FIM_POSICAO detectado.");
                wait (fim_posicao_out == 1'b0);
            end else begin
                wait (dut.uc_sonar.Eatual == 4'h7);
            end
        end
    endtask

    task iniciar_medicao;
        begin
            echo_in = 1'b0;
            ligar_in = 1'b1;
            wait (trigger_out == 1'b1);
        end
    endtask

    initial begin
        $display("Inicio da simulacao do Sistema de Sonar");
        
        // Comandos importados da Exp 4 para gerar formas de onda automaticamente
        $dumpfile("sonar.vcd");
        $dumpvars(0, reset_in, ligar_in, echo_in,
                  trigger_out, pwm_out, saida_serial_out, fim_posicao_out);

        // Oito posicoes com larguras de echo coerentes com R=2941 clocks/cm.
        distancias_cm[0] = 100; medidas_teste[0] = 12'h100; angulos_teste[0] = 24'h303230;
        distancias_cm[1] = 74;  medidas_teste[1] = 12'h074; angulos_teste[1] = 24'h303430;
        distancias_cm[2] = 17;  medidas_teste[2] = 12'h017; angulos_teste[2] = 24'h303630;
        distancias_cm[3] = 30;  medidas_teste[3] = 12'h030; angulos_teste[3] = 24'h303830;
        distancias_cm[4] = 80;  medidas_teste[4] = 12'h080; angulos_teste[4] = 24'h313030;
        distancias_cm[5] = 55;  medidas_teste[5] = 12'h055; angulos_teste[5] = 24'h313230;
        distancias_cm[6] = 42;  medidas_teste[6] = 12'h042; angulos_teste[6] = 24'h313430;
        distancias_cm[7] = 12;  medidas_teste[7] = 12'h012; angulos_teste[7] = 24'h313630;
        erros = 0;
        trigger_count = 0;
        fim_count = 0;
        quadros_verificados = 0;
        medidas_iniciadas = 0;
        trigger_anterior = 1'b0;
        verificar_periodo = 1'b0;

        // 1. Reset inicial do sistema
        reset_dut();

        // 2. Aciona o Sonar e verifica uma varredura completa em 20 ms por ciclo.
        verificar_periodo = 1'b1;
        ligar_in = 1'b1;

        for (caso = 0; caso < 8; caso = caso + 1) begin
            executar_caso(distancias_cm[caso], medidas_teste[caso], angulos_teste[caso], 1'b1);
        end

        verificar_periodo = 1'b0;
        if (medidas_iniciadas != 8 || trigger_count != 8 || fim_count != 8 || quadros_verificados != 64) begin
            $display("ERRO: medidas=%0d triggers=%0d fins=%0d quadros=%0d; esperado 8, 8, 8 e 64.",
                     medidas_iniciadas, trigger_count, fim_count, quadros_verificados);
            erros = erros + 1;
        end
        if (dut.fd_sonar.w_endereco !== 3'b000) begin
            $display("ERRO: varredura nao retornou a posicao 000 apos a posicao 111.");
            erros = erros + 1;
        end

        // Interrompe antes do inicio da proxima medida.
        ligar_in = 1'b0;
        verificar_parada(8, 8);

        // Aborta durante o trigger.
        iniciar_medicao();
        #(100);
        ligar_in = 1'b0;
        verificar_parada(9, 8);

        // Aborta enquanto aguarda o echo.
        iniciar_medicao();
        wait (trigger_out == 1'b0);
        ligar_in = 1'b0;
        verificar_parada(10, 8);

        // Aborta durante a contagem de um echo ativo.
        iniciar_medicao();
        wait (trigger_out == 1'b0);
        #(400_000);
        echo_in = 1'b1;
        #(1_000_000);
        ligar_in = 1'b0;
        echo_in = 1'b0;
        verificar_parada(11, 8);

        // Aborta no meio do primeiro quadro serial.
        iniciar_medicao();
        wait (trigger_out == 1'b0);
        #(400_000);
        echo_in = 1'b1;
        #(10 * 58_820);
        echo_in = 1'b0;
        wait (dut.w_transmite_serial == 1'b1);
        wait (saida_serial_out == 1'b0);
        #(3 * BIT_TIME_NS);
        ligar_in = 1'b0;
        verificar_parada(12, 8);

        // Aborta durante a espera pelo proximo intervalo.
        ligar_in = 1'b1;
        caso = 0;
        executar_caso(distancias_cm[0], medidas_teste[0], angulos_teste[0], 1'b0);
        ligar_in = 1'b0;
        verificar_parada(13, 8);

        // A parada deve manter o ultimo endereco comandado ao servomotor.
        ligar_in = 1'b1;
        executar_caso(distancias_cm[0], medidas_teste[0], angulos_teste[0], 1'b1);
        ligar_in = 1'b0;
        verificar_parada(14, 9);
        if (dut.fd_sonar.w_endereco !== 3'b001) begin
            $display("ERRO: endereco do servo mudou apos desligar; esperado 001.");
            erros = erros + 1;
        end
        if (quadros_verificados != 80) begin
            $display("ERRO: %0d quadros 7E1 verificados, esperado 80.", quadros_verificados);
            erros = erros + 1;
        end

        if (erros == 0)
            $display("\nPASSOU: varredura, periodo, distancias, 7E1 e cancelamentos verificados.");
        else
            $display("\nFALHOU: %0d verificacao(oes) com erro.", erros);

        $display("Fim da simulacao do Sistema de Sonar");
        $dumpoff;
        $finish;
    end

    initial begin
        #500_000_000;
        $display("FALHOU: timeout aguardando algum evento do sistema.");
        $finish;
    end

endmodule