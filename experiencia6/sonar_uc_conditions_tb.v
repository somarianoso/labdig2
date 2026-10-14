`timescale 1ns/1ns

module sonar_uc_conditions_tb;
    localparam inicial                = 5'd0;
    localparam normal_prepara         = 5'd1;
    localparam normal_aguarda_medida  = 5'd2;
    localparam normal_inicia_tx       = 5'd3;
    localparam normal_espera_tx_baixo = 5'd4;
    localparam normal_espera_tx_alto  = 5'd5;
    localparam normal_verifica_tx     = 5'd6;
    localparam normal_aguarda_2s      = 5'd7;
    localparam normal_decide_modo     = 5'd8;
    localparam atencao_prepara        = 5'd10;
    localparam atencao_aguarda_medida = 5'd11;
    localparam atencao_inicia_tx      = 5'd12;
    localparam atencao_espera_tx_baixo = 5'd13;
    localparam atencao_espera_tx_alto = 5'd14;
    localparam atencao_verifica_tx    = 5'd15;
    localparam atencao_aguarda_2s     = 5'd16;
    localparam atencao_decide_modo    = 5'd17;
    localparam atencao_mantem_posicao = 5'd18;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg mensurar = 1'b1;
    reg pronto_serial = 1'b0;
    reg pronto_medida = 1'b0;
    reg fim_2seg = 1'b0;
    reg timeout_echo = 1'b0;
    reg fim_tx_8 = 1'b0;
    reg modo_solicitado = 1'b0;

    wire medir;
    wire contar_endereco;
    wire zera_endereco;
    wire zera_contador;
    wire zera_transmissao;
    wire pronto;
    wire [4:0] db_estado;
    wire transmite_serial;
    wire zera_timeout_echo;
    wire conta_timeout_echo;
    wire db_modo;

    always #5 clock = ~clock;

    sonar_uc dut (
        .clock              (clock),
        .reset              (reset),
        .mensurar           (mensurar),
        .pronto_serial      (pronto_serial),
        .pronto_medida      (pronto_medida),
        .fim_2seg           (fim_2seg),
        .timeout_echo       (timeout_echo),
        .fim_tx_8           (fim_tx_8),
        .modo_solicitado    (modo_solicitado),
        .medir              (medir),
        .contar_endereco    (contar_endereco),
        .zera_endereco      (zera_endereco),
        .zera_contador      (zera_contador),
        .zera_transmissao   (zera_transmissao),
        .pronto             (pronto),
        .db_estado          (db_estado),
        .transmite_serial   (transmite_serial),
        .zera_timeout_echo  (zera_timeout_echo),
        .conta_timeout_echo (conta_timeout_echo),
        .db_modo            (db_modo)
    );

    task step;
        begin
            @(posedge clock);
            #1;
        end
    endtask

    task expect_state(input [4:0] expected, input [8*56-1:0] description);
        begin
            if (db_estado !== expected)
                $fatal(1, "%0s: expected state %0d, got %0d",
                       description, expected, db_estado);
        end
    endtask

    task finish_one_serial_character;
        begin
            expect_state(normal_inicia_tx, "serial character start");
            if (!transmite_serial)
                $fatal(1, "transmite_serial must be asserted at serial start");
            step;
            expect_state(normal_espera_tx_baixo, "wait for serial busy");

            pronto_serial = 1'b0;
            step;
            expect_state(normal_espera_tx_alto, "wait for serial ready");
            pronto_serial = 1'b1;
            step;
            pronto_serial = 1'b0;
            expect_state(normal_verifica_tx, "check character completion");
        end
    endtask

    initial begin
        #12 reset = 1'b0;
        step;
        expect_state(normal_prepara, "initial localization state");
        step;
        expect_state(normal_aguarda_medida, "normal measurement wait");

        // A completed measurement has priority if timeout and ready coincide.
        pronto_medida = 1'b1;
        timeout_echo = 1'b1;
        step;
        pronto_medida = 1'b0;
        timeout_echo = 1'b0;
        expect_state(normal_inicia_tx, "measurement-ready priority over timeout");

        // A mode request is deferred until after the message and normal interval.
        modo_solicitado = 1'b1;
        finish_one_serial_character;
        fim_tx_8 = 1'b0;
        step;
        expect_state(normal_inicia_tx, "repeat transmission while message remains");
        finish_one_serial_character;
        fim_tx_8 = 1'b1;
        step;
        fim_tx_8 = 1'b0;
        expect_state(normal_aguarda_2s, "completed message waits for interval");
        if (contar_endereco || pronto)
            $fatal(1, "position advanced before the mode decision");

        step;
        expect_state(normal_aguarda_2s, "normal interval waits without timer pulse");
        fim_2seg = 1'b1;
        step;
        fim_2seg = 1'b0;
        expect_state(normal_decide_modo, "normal mode decision after interval");
        step;
        expect_state(atencao_prepara, "mode changes after complete normal cycle");
        if (!db_modo || !medir || contar_endereco || pronto)
            $fatal(1, "attention entry outputs or position behavior are incorrect");

        step;
        expect_state(atencao_aguarda_medida, "attention measurement wait");
        if (!db_modo || !conta_timeout_echo)
            $fatal(1, "attention measurement wait outputs are incorrect");

        // A completed measurement has priority over timeout in attention mode too.
        pronto_medida = 1'b1;
        timeout_echo = 1'b1;
        step;
        pronto_medida = 1'b0;
        timeout_echo = 1'b0;
        expect_state(atencao_inicia_tx, "attention measurement-ready priority");
        if (!db_modo || !transmite_serial || contar_endereco)
            $fatal(1, "attention must transmit without moving the position");

        step;
        expect_state(atencao_espera_tx_baixo, "attention waits for serial busy");
        pronto_serial = 1'b0;
        step;
        expect_state(atencao_espera_tx_alto, "attention waits for serial ready");
        pronto_serial = 1'b1;
        step;
        pronto_serial = 1'b0;
        expect_state(atencao_verifica_tx, "attention checks character completion");
        fim_tx_8 = 1'b1;
        step;
        fim_tx_8 = 1'b0;
        expect_state(atencao_aguarda_2s, "attention message completion");
        if (!db_modo || contar_endereco || pronto)
            $fatal(1, "attention message completion must not move the position");

        // Verify the timeout-only branch in attention mode.
        fim_2seg = 1'b1;
        step;
        fim_2seg = 1'b0;
        expect_state(atencao_decide_modo, "attention interval completion");
        step;
        expect_state(atencao_mantem_posicao, "attention keeps current position");
        if (!db_modo || contar_endereco || pronto)
            $fatal(1, "attention hold-position state must not advance the servo");
        step;
        expect_state(atencao_prepara, "repeat attention mode at same position");
        step;
        expect_state(atencao_aguarda_medida, "second attention measurement wait");
        timeout_echo = 1'b1;
        step;
        timeout_echo = 1'b0;
        expect_state(atencao_aguarda_2s, "attention echo timeout");
        if (!db_modo || contar_endereco || pronto || transmite_serial)
            $fatal(1, "attention timeout must not transmit or move the position");
        step;
        expect_state(atencao_aguarda_2s, "attention interval waits for timer pulse");
        fim_2seg = 1'b1;
        step;
        fim_2seg = 1'b0;
        expect_state(atencao_decide_modo, "attention mode decision");

        modo_solicitado = 1'b0;
        step;
        expect_state(normal_prepara, "return to localization mode");
        if (db_modo || contar_endereco || pronto || !medir)
            $fatal(1, "return to localization must preserve the current position");

        // Measurement-ready also wins over timeout after returning to localization.
        step;
        expect_state(normal_aguarda_medida, "localization measurement wait after return");
        modo_solicitado = 1'b1;
        timeout_echo = 1'b1;
        pronto_medida = 1'b1;
        step;
        timeout_echo = 1'b0;
        pronto_medida = 1'b0;
        expect_state(normal_inicia_tx, "measurement-ready priority on next cycle");

        $display("PASS: UC input priorities, timeout paths, and deferred mode changes");
        $finish;
    end

    initial begin
        #20_000;
        $fatal(1, "condition diagnostic test timed out");
    end
endmodule
