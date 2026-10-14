`timescale 1ns/1ns

module sonar_uc_corner_tb;
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

    reg clock = 1'b0;
    reg reset = 1'b0;
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

    task expect_state(input [4:0] expected, input [8*48-1:0] description);
        begin
            if (db_estado !== expected)
                $fatal(1, "%0s: expected state %0d, got %0d",
                       description, expected, db_estado);
        end
    endtask

    initial begin
        reset = 1'b1;
        #1;
        expect_state(inicial, "asynchronous reset");
        if (!zera_endereco || !zera_contador || !zera_transmissao ||
            !zera_timeout_echo)
            $fatal(1, "reset state must clear the address and counters");

        #1 reset = 1'b0;
        step;
        expect_state(normal_prepara, "start in localization mode");
        if (!medir || !zera_contador || !zera_transmissao ||
            !zera_timeout_echo || db_modo)
            $fatal(1, "normal preparation outputs are incorrect");

        step;
        expect_state(normal_aguarda_medida, "wait for measurement");
        if (medir || !conta_timeout_echo)
            $fatal(1, "measurement wait outputs are incorrect");

        // Conditions and requested mode must not change Moore outputs mid-cycle.
        pronto_medida = 1'b1;
        modo_solicitado = 1'b1;
        #1;
        expect_state(normal_aguarda_medida, "state holds before clock edge");
        if (medir || !conta_timeout_echo || db_modo)
            $fatal(1, "outputs changed before the state register clock edge");
        pronto_medida = 1'b0;
        timeout_echo = 1'b1;
        step;
        timeout_echo = 1'b0;
        expect_state(normal_aguarda_2s, "echo timeout path");

        // The wait state must hold until the timer condition arrives.
        step;
        expect_state(normal_aguarda_2s, "hold while waiting for timer");
        fim_2seg = 1'b1;
        step;
        fim_2seg = 1'b0;
        expect_state(normal_decide_modo, "normal mode decision");
        step;
        expect_state(atencao_prepara, "enter requested attention mode");
        if (!db_modo || !medir || contar_endereco || pronto)
            $fatal(1, "attention preparation outputs are incorrect");

        // Dropping mensurar returns to the initial state on the next edge.
        mensurar = 1'b0;
        #1;
        expect_state(atencao_prepara, "disable waits for clock edge");
        if (!db_modo || !medir)
            $fatal(1, "outputs changed before disable was clocked");
        step;
        expect_state(inicial, "disable returns to initial state");
        if (db_modo || !zera_endereco || !zera_contador)
            $fatal(1, "initial outputs after disable are incorrect");

        // Reset from an active state is asynchronous.
        modo_solicitado = 1'b0;
        mensurar = 1'b1;
        step;
        expect_state(normal_prepara, "restart after disable");
        step;
        expect_state(normal_aguarda_medida, "reach active measurement wait");
        reset = 1'b1;
        #1;
        expect_state(inicial, "asynchronous reset while active");
        reset = 1'b0;
        step;
        expect_state(normal_prepara, "restart after reset");

        // Verify a non-final serial character retries the transmit sequence.
        step;
        pronto_medida = 1'b1;
        step;
        pronto_medida = 1'b0;
        expect_state(normal_inicia_tx, "start serial transmission");
        if (!transmite_serial)
            $fatal(1, "transmit request must be asserted in start state");

        step;
        expect_state(normal_espera_tx_baixo, "wait for serial start");
        step;
        expect_state(normal_espera_tx_alto, "wait for serial completion");
        pronto_serial = 1'b1;
        step;
        pronto_serial = 1'b0;
        expect_state(normal_verifica_tx, "check message completion");

        fim_tx_8 = 1'b0;
        step;
        expect_state(normal_inicia_tx, "retry before final message character");
        if (!transmite_serial)
            $fatal(1, "transmit request must be asserted for retry");

        step;
        step;
        pronto_serial = 1'b1;
        step;
        pronto_serial = 1'b0;
        expect_state(normal_verifica_tx, "check final message character");
        fim_tx_8 = 1'b1;
        step;
        fim_tx_8 = 1'b0;
        expect_state(normal_aguarda_2s, "finish complete message");
        if (contar_endereco || pronto)
            $fatal(1, "position must not advance before normal mode decision");

        $display("PASS: UC corner cases and Moore transition timing");
        $finish;
    end

    initial begin
        #10_000;
        $fatal(1, "test timed out");
    end
endmodule
