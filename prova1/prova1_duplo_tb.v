`timescale 1ns/1ns

module prova1_duplo_tb;
    localparam INICIAL = 6'd0;
    localparam NORMAL_PREPARA = 6'd1;
    localparam DUPLO_PREPARA_1 = 6'd19;
    localparam DUPLO_AGUARDA_MEDIDA_1 = 6'd20;
    localparam DUPLO_INICIA_TX_1 = 6'd21;
    localparam DUPLO_ESPERA_TX_BAIXO_1 = 6'd22;
    localparam DUPLO_ESPERA_TX_ALTO_1 = 6'd23;
    localparam DUPLO_VERIFICA_TX_1 = 6'd24;
    localparam DUPLO_AGUARDA_1S = 6'd25;
    localparam DUPLO_PREPARA_2 = 6'd26;
    localparam DUPLO_AGUARDA_MEDIDA_2 = 6'd27;
    localparam DUPLO_INICIA_TX_2 = 6'd28;
    localparam DUPLO_ESPERA_TX_BAIXO_2 = 6'd29;
    localparam DUPLO_ESPERA_TX_ALTO_2 = 6'd30;
    localparam DUPLO_VERIFICA_TX_2 = 6'd31;
    localparam DUPLO_DECIDE_MODO = 6'd32;
    localparam DUPLO_AVANCA_POSICAO = 6'd33;
    localparam MODO_LOCALIZACAO = 2'b00;
    localparam MODO_DUPLO = 2'b10;

    reg clock = 1'b0;
    reg reset = 1'b0;
    reg mensurar = 1'b1;
    reg pronto_serial = 1'b1;
    reg pronto_medida = 1'b0;
    reg fim_2seg = 1'b0;
    reg timeout_echo = 1'b0;
    reg fim_tx_8 = 1'b0;
    reg fim_intervalo_duplo = 1'b0;
    reg [1:0] modo_solicitado = MODO_LOCALIZACAO;

    wire medir;
    wire contar_endereco;
    wire zera_endereco;
    wire zera_contador;
    wire zera_transmissao;
    wire pronto;
    wire [5:0] db_estado;
    wire transmite_serial;
    wire zera_timeout_echo;
    wire conta_timeout_echo;
    wire conta_intervalo_duplo;
    wire db_modo;
    wire db_modo_duplo;
    wire [4:0] endereco;

    always #10 clock = ~clock;

    sonar_uc dut (
        .clock                 (clock),
        .reset                 (reset),
        .mensurar              (mensurar),
        .pronto_serial         (pronto_serial),
        .pronto_medida         (pronto_medida),
        .fim_2seg              (fim_2seg),
        .timeout_echo          (timeout_echo),
        .fim_tx_8              (fim_tx_8),
        .fim_intervalo_duplo   (fim_intervalo_duplo),
        .modo_solicitado       (modo_solicitado),
        .medir                 (medir),
        .contar_endereco       (contar_endereco),
        .zera_endereco         (zera_endereco),
        .zera_contador         (zera_contador),
        .zera_transmissao      (zera_transmissao),
        .pronto                (pronto),
        .db_estado             (db_estado),
        .transmite_serial      (transmite_serial),
        .zera_timeout_echo     (zera_timeout_echo),
        .conta_timeout_echo    (conta_timeout_echo),
        .conta_intervalo_duplo (conta_intervalo_duplo),
        .db_modo               (db_modo),
        .db_modo_duplo         (db_modo_duplo)
    );

    contador_endereco contador_endereco_teste (
        .clock    (clock),
        .conta    (contar_endereco),
        .passo_fino(1'b0),
        .zera     (zera_endereco),
        .endereco (endereco)
    );

    task step;
        begin
            @(posedge clock);
            #1;
        end
    endtask

    task wait_state(input [5:0] expected);
        begin
            wait (db_estado === expected);
            #1;
        end
    endtask

    task complete_measurement(input [5:0] expected_wait_state,
                               input [5:0] expected_tx_state);
        begin
            wait_state(expected_wait_state);
            if (!db_modo_duplo || !conta_timeout_echo)
                $fatal(1, "double mode measurement wait controls are incorrect");
            pronto_medida = 1'b1;
            step;
            pronto_medida = 1'b0;
            wait_state(expected_tx_state);
            if (!transmite_serial)
                $fatal(1, "measurement result was not scheduled for transmission");
        end
    endtask

    task complete_transmission(input [5:0] wait_low_state,
                               input [5:0] wait_high_state,
                               input [5:0] verify_state,
                               input exit_to_localization);
        begin
            step;
            wait_state(wait_low_state);
            pronto_serial = 1'b0;
            step;
            wait_state(wait_high_state);
            if (exit_to_localization) begin
                modo_solicitado = MODO_LOCALIZACAO;
                #1;
                if (db_estado !== wait_high_state || !db_modo_duplo)
                    $fatal(1, "x interrupted the second transmission");
            end
            pronto_serial = 1'b1;
            step;
            wait_state(verify_state);
            fim_tx_8 = 1'b1;
            step;
            fim_tx_8 = 1'b0;
        end
    endtask

    initial begin
        #1 reset = 1'b1;
        #1;
        if (db_estado !== INICIAL)
            $fatal(1, "asynchronous reset did not select the initial state");
        #18 reset = 1'b0;
        modo_solicitado = MODO_DUPLO;
        step;
        wait_state(DUPLO_PREPARA_1);
        if (!medir || !db_modo_duplo)
            $fatal(1, "first double-mode measurement was not prepared");
        step;

        complete_measurement(DUPLO_AGUARDA_MEDIDA_1, DUPLO_INICIA_TX_1);
        complete_transmission(DUPLO_ESPERA_TX_BAIXO_1,
                              DUPLO_ESPERA_TX_ALTO_1,
                              DUPLO_VERIFICA_TX_1,
                              1'b0);
        wait_state(DUPLO_AGUARDA_1S);
        if (!conta_intervalo_duplo || medir || contar_endereco)
            $fatal(1, "one-second interval controls are incorrect");
        step;
        if (db_estado !== DUPLO_AGUARDA_1S)
            $fatal(1, "second measurement began before the interval completed");
        fim_intervalo_duplo = 1'b1;
        step;
        fim_intervalo_duplo = 1'b0;
        wait_state(DUPLO_PREPARA_2);
        if (!medir)
            $fatal(1, "second measurement was not prepared after the interval");
        step;

        complete_measurement(DUPLO_AGUARDA_MEDIDA_2, DUPLO_INICIA_TX_2);
        complete_transmission(DUPLO_ESPERA_TX_BAIXO_2,
                              DUPLO_ESPERA_TX_ALTO_2,
                              DUPLO_VERIFICA_TX_2,
                              1'b1);
        wait_state(DUPLO_DECIDE_MODO);

        // x was latched during the last transmission, but is applied at this boundary.
        if (db_estado !== DUPLO_DECIDE_MODO || !db_modo_duplo)
            $fatal(1, "mode change did not wait for the second transmission");
        step;
        wait_state(DUPLO_AVANCA_POSICAO);
        if (contar_endereco || !zera_endereco || !pronto)
            $fatal(1, "localization return did not restart the servo position");
        step;
        wait_state(NORMAL_PREPARA);
        if (endereco !== 5'd0 || db_modo_duplo)
            $fatal(1, "x did not restart localization at the first position");

        $display("PASS: two measurements, a one-second interval, and deferred x transition");
        $finish;
    end

    initial begin
        #10_000;
        $fatal(1, "double-mode test timed out");
    end
endmodule
