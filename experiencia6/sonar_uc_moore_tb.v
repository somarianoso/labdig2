`timescale 1ns/1ns

module sonar_uc_moore_tb;
    localparam inicial                 = 5'd0;
    localparam normal_prepara          = 5'd1;
    localparam normal_aguarda_medida   = 5'd2;
    localparam normal_inicia_tx        = 5'd3;
    localparam normal_espera_tx_baixo  = 5'd4;
    localparam normal_espera_tx_alto   = 5'd5;
    localparam normal_verifica_tx      = 5'd6;
    localparam normal_aguarda_2s       = 5'd7;
    localparam normal_decide_modo      = 5'd8;
    localparam normal_avanca_posicao   = 5'd9;
    localparam atencao_prepara         = 5'd10;
    localparam atencao_aguarda_medida  = 5'd11;
    localparam atencao_inicia_tx       = 5'd12;
    localparam atencao_espera_tx_baixo = 5'd13;
    localparam atencao_espera_tx_alto  = 5'd14;
    localparam atencao_verifica_tx     = 5'd15;
    localparam atencao_aguarda_2s      = 5'd16;
    localparam atencao_decide_modo     = 5'd17;
    localparam atencao_mantem_posicao  = 5'd18;

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

    sonar_uc dut (.*);

    task step;
        begin
            @(posedge clock);
            #1;
        end
    endtask

    initial begin
        #12 reset = 1'b0;
        step;
        if (db_estado !== normal_prepara || db_modo !== 1'b0 || !medir)
            $fatal(1, "reset did not start the localization sequence");

        modo_solicitado = 1'b1;
        #1;
        if (db_modo !== 1'b0 || !medir || contar_endereco)
            $fatal(1, "outputs changed with mode input while state was fixed");
        step;
        if (db_estado !== normal_aguarda_medida || db_modo !== 1'b0)
            $fatal(1, "localization measurement sequence is incorrect");

        pronto_medida = 1'b1;
        step;
        pronto_medida = 1'b0;
        if (db_estado !== normal_inicia_tx || !transmite_serial)
            $fatal(1, "localization did not start serial transmission");
        step;
        if (db_estado !== normal_espera_tx_baixo)
            $fatal(1, "localization did not wait for serial start");
        step;
        if (db_estado !== normal_espera_tx_alto)
            $fatal(1, "localization did not wait for serial completion");
        pronto_serial = 1'b1;
        step;
        pronto_serial = 1'b0;
        if (db_estado !== normal_verifica_tx)
            $fatal(1, "localization did not check message completion");
        fim_tx_8 = 1'b1;
        step;
        fim_tx_8 = 1'b0;
        if (db_estado !== normal_aguarda_2s)
            $fatal(1, "localization did not wait after serial transmission");
        fim_2seg = 1'b1;
        step;
        fim_2seg = 1'b0;
        if (db_estado !== normal_decide_modo)
            $fatal(1, "localization did not reach its mode decision state");
        step;
        if (db_estado !== atencao_prepara || db_modo !== 1'b1 || !medir)
            $fatal(1, "attention mode did not start its own measurement sequence");

        step;
        if (db_estado !== atencao_aguarda_medida || db_modo !== 1'b1)
            $fatal(1, "attention measurement sequence is incorrect");
        pronto_medida = 1'b1;
        step;
        pronto_medida = 1'b0;
        if (db_estado !== atencao_inicia_tx || !transmite_serial || !db_modo)
            $fatal(1, "attention did not start serial transmission");
        step;
        if (db_estado !== atencao_espera_tx_baixo)
            $fatal(1, "attention did not wait for serial start");
        step;
        if (db_estado !== atencao_espera_tx_alto)
            $fatal(1, "attention did not wait for serial completion");
        pronto_serial = 1'b1;
        step;
        pronto_serial = 1'b0;
        if (db_estado !== atencao_verifica_tx)
            $fatal(1, "attention did not check message completion");
        fim_tx_8 = 1'b1;
        step;
        fim_tx_8 = 1'b0;
        if (db_estado !== atencao_aguarda_2s || contar_endereco || pronto)
            $fatal(1, "attention did not wait without moving the servo");
        fim_2seg = 1'b1;
        step;
        fim_2seg = 1'b0;
        if (db_estado !== atencao_decide_modo)
            $fatal(1, "attention did not reach its mode decision state");

        modo_solicitado = 1'b0;
        step;
        if (db_estado !== normal_prepara || db_modo !== 1'b0 || contar_endereco)
            $fatal(1, "return to localization did not preserve the current position");

        step;
        timeout_echo = 1'b1;
        step;
        timeout_echo = 1'b0;
        fim_2seg = 1'b1;
        step;
        fim_2seg = 1'b0;
        step;
        if (db_estado !== normal_avanca_posicao || !contar_endereco || !pronto)
            $fatal(1, "localization did not advance the position");

        modo_solicitado = 1'b1;
        #1;
        if (!contar_endereco || !pronto || db_modo !== 1'b0)
            $fatal(1, "position advance outputs depend on non-state inputs");
        step;
        if (db_estado !== atencao_prepara || db_modo !== 1'b1)
            $fatal(1, "attention sequence did not resume after position advance");

        $display("PASS: Moore outputs and mode-specific sequences");
        $finish;
    end

    initial begin
        #10_000;
        $fatal(1, "test timed out");
    end
endmodule
