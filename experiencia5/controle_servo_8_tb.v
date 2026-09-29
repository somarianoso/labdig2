`timescale 1ns/1ns

module controle_servo_8_tb;

    parameter clockPeriod = 20;
    parameter periodo_pwm_ns = 20_000_000;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg [2:0] posicao = 3'b000;
    wire pwm;
    wire db_reset;
    wire [2:0] db_posicao;
    wire db_controle;

    reg [2:0] posicoes [0:7];
    integer larguras_ciclos [0:7];
    integer caso;
    integer erros;
    integer pulsos_medidos;
    time inicio_pulso;
    time duracao_pulso;
    time inicio_anterior;

    controle_servo_8 dut (
        .clock       (clock),
        .reset       (reset),
        .posicao     (posicao),
        .controle    (pwm),
        .db_reset    (db_reset),
        .db_posicao  (db_posicao),
        .db_controle (db_controle)
    );

    always #(clockPeriod/2) clock = ~clock;

    task verificar_pulso;
        input [2:0] posicao_teste;
        input integer largura_esperada;
        begin
            posicao = posicao_teste;
            wait (pwm === 1'b1);
            inicio_pulso = $time;

            if (pulsos_medidos > 0 && ($time - inicio_anterior) != periodo_pwm_ns) begin
                $display("ERRO: periodo PWM %0t ns, esperado %0d ns.",
                         $time - inicio_anterior, periodo_pwm_ns);
                erros = erros + 1;
            end
            inicio_anterior = $time;
            pulsos_medidos = pulsos_medidos + 1;

            wait (pwm === 1'b0);
            duracao_pulso = $time - inicio_pulso;
            if (duracao_pulso != largura_esperada * clockPeriod) begin
                $display("ERRO: posicao %03b largura %0t ns, esperada %0d ns.",
                         posicao_teste, duracao_pulso, largura_esperada * clockPeriod);
                erros = erros + 1;
            end else begin
                $display("OK: posicao %03b, largura %0d ciclos (%0t ns).",
                         posicao_teste, largura_esperada, duracao_pulso);
            end
        end
    endtask

    initial begin
        posicoes[0] = 3'b000; larguras_ciclos[0] = 35000;
        posicoes[1] = 3'b001; larguras_ciclos[1] = 45700;
        posicoes[2] = 3'b010; larguras_ciclos[2] = 56450;
        posicoes[3] = 3'b011; larguras_ciclos[3] = 67150;
        posicoes[4] = 3'b100; larguras_ciclos[4] = 77850;
        posicoes[5] = 3'b101; larguras_ciclos[5] = 88550;
        posicoes[6] = 3'b110; larguras_ciclos[6] = 99300;
        posicoes[7] = 3'b111; larguras_ciclos[7] = 110000;
        erros = 0;
        pulsos_medidos = 0;
        inicio_anterior = 0;

        #40;
        reset = 1'b0;

        for (caso = 0; caso < 8; caso = caso + 1)
            verificar_pulso(posicoes[caso], larguras_ciclos[caso]);

        if (erros == 0)
            $display("PASSOU: oito larguras e o periodo PWM foram verificados.");
        else
            $display("FALHOU: %0d verificacao(oes) com erro.", erros);

        $finish;
    end

endmodule