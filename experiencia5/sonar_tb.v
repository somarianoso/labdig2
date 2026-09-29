`timescale 1ns/1ns

module sonar_tb;

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
    sonar dut (
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
    parameter clockPeriod = 20;
    always #(clockPeriod/2) clock_in = ~clock_in;

    // Casos de teste e parametros de tempo
    reg [31:0] casos_teste [0:2];
    integer caso;
    reg [31:0] larguraPulso;

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
        input [31:0] largura_us;
        begin
            $display("\nCaso de teste %0d: aguardando Trigger... (echo = %0d us)", caso, largura_us);

            // 1: Calcula largura do pulso echo em ns
            larguraPulso = largura_us * 1000; 

            // 2: Fica à escuta do pulso Trigger gerado pelo Sonar
            wait (trigger_out == 1'b1);
            wait (trigger_out == 1'b0); // Espera o trigger de 10us terminar

            // 3: Espera 400 us entre trigger e echo
            #(400_000);

            // 4: Gera pulso echo com largura definida
            echo_in = 1'b1;
            #(larguraPulso);
            echo_in = 1'b0;

            // 5: Espera pelo final da medida, transmissao serial e temporizador
            wait (fim_posicao_out == 1'b1);
            $display("  fim_posicao = 1 detetado. Ciclo %0d concluido com sucesso.", caso);
            wait (fim_posicao_out == 1'b0); // Garante que o pulso de fim desceu antes de passar ao proximo
        end
    endtask

    initial begin
        $display("Inicio da simulacao do Sistema de Sonar");
        
        // Comandos importados da Exp 4 para gerar formas de onda automaticamente
        $dumpfile("sonar.vcd");
        $dumpvars(0, clock_in, reset_in, ligar_in, echo_in,
                  trigger_out, pwm_out, saida_serial_out, fim_posicao_out);

        // Casos de teste usando valores da Trena (Exp 4) e outros novos
        casos_teste[0] = 5882;  // 5882 us -> 100 cm (Posição 000)
        casos_teste[1] = 4353;  // 4353 us ->  74 cm (Posição 001)
        casos_teste[2] = 986;   //  986 us ->  17 cm (Posição 010)

        // 1. Reset inicial do sistema
        reset_dut();

        // 2. Aciona o Sonar (mantém ligado para varredura automática)
        ligar_in = 1'b1;
        #(100_000); // 100us para inicio dos ciclos de medidas conforme roteiro

        // 3. Loop dos cenarios de teste (Sistema trabalha sozinho, testbench apenas reage)
        for (caso = 0; caso < 3; caso = caso + 1) begin
            executar_caso(casos_teste[caso]);
        end

        // 4. Teste de paragem
        $display("\nDesligando o Sonar para testar a interrupcao (Regra 2)");
        ligar_in = 1'b0;
        #(500_000); // Aguarda para garantir que o sistema parou e não gera novos triggers

        $display("\nFim da simulacao do Sistema de Sonar");
        $dumpoff;
        $stop;
    end

endmodule