`timescale 1ns/1ns

module prova1_intervalo_duplo_tb;
    reg clock = 1'b0;
    reg reset = 1'b0;
    reg habilitado = 1'b1;
    reg conta_intervalo_duplo = 1'b0;
    wire fim_intervalo_duplo;

    always #5 clock = ~clock;

    sonar_fd #(
        .CONTAGEM_2SEG(8),
        .CONTAGEM_1SEG(4)
    ) dut (
        .clock                 (clock),
        .reset                 (reset),
        .habilitado            (habilitado),
        .entrada_serial        (1'b1),
        .medir                 (1'b0),
        .echo                  (1'b0),
        .transmite_serial      (1'b0),
        .zera_contador         (1'b0),
        .zera_transmissao      (1'b0),
        .contar_endereco       (1'b0),
        .zera_endereco         (1'b0),
        .zera_timeout_echo     (1'b0),
        .conta_timeout_echo    (1'b0),
        .conta_intervalo_duplo (conta_intervalo_duplo),
        .trigger               (),
        .medida0               (),
        .medida1               (),
        .medida2               (),
        .saida_serial          (),
        .pronto_medida         (),
        .pronto_serial         (),
        .mensurar_automatico   (),
        .pwm                   (),
        .timeout_echo          (),
        .fim_intervalo_duplo   (fim_intervalo_duplo),
        .fim_tx_8              (),
        .modo_solicitado       (),
        .db_estado_rx          (),
        .db_estado_tx          (),
        .db_estado_hcsr04      (),
        .posicao_servo         (),
        .dado_rx_recebido      (),
        .dado_tx_transmitido   (),
        .estado_tx_sonar       (),
        .contagem_selmux       (),
        .angulo2               (),
        .angulo1               (),
        .angulo0               (),
        .paridade_par          (),
        .pronto_rx             ()
    );

    task step;
        begin
            @(posedge clock);
            #1;
        end
    endtask

    initial begin
        #1 reset = 1'b1;
        #10 reset = 1'b0;
        conta_intervalo_duplo = 1'b1;

        step;
        if (fim_intervalo_duplo)
            $fatal(1, "one-second timer ended before four enabled clocks");
        step;
        if (fim_intervalo_duplo)
            $fatal(1, "one-second timer ended before four enabled clocks");
        step;
        if (!fim_intervalo_duplo)
            $fatal(1, "one-second timer did not end after four enabled clocks");
        step;
        if (fim_intervalo_duplo)
            $fatal(1, "one-second timer terminal condition was not a single-cycle pulse");

        conta_intervalo_duplo = 1'b0;
        step;
        if (fim_intervalo_duplo)
            $fatal(1, "one-second timer did not clear outside the interval state");

        $display("PASS: FD one-second timer counts only while enabled");
        $finish;
    end

    initial begin
        #1_000;
        $fatal(1, "interval timer test timed out");
    end
endmodule
