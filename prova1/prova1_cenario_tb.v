`timescale 1ns/1ns

module prova1_cenario_tb;
    localparam CLOCK_PERIOD = 20;
    localparam BIT_PERIOD = 434 * CLOCK_PERIOD;

    localparam NORMAL_PREPARA = 6'd1;
    localparam NORMAL_AGUARDA_MEDIDA = 6'd2;
    localparam NORMAL_ESPERA_TX_BAIXO = 6'd4;
    localparam NORMAL_ESPERA_TX_ALTO = 6'd5;
    localparam NORMAL_VERIFICA_TX = 6'd6;
    localparam NORMAL_AGUARDA_2S = 6'd7;
    localparam NORMAL_DECIDE_MODO = 6'd8;
    localparam NORMAL_AVANCA_POSICAO = 6'd9;
    localparam ATENCAO_PREPARA = 6'd10;
    localparam ATENCAO_AGUARDA_MEDIDA = 6'd11;
    localparam ATENCAO_ESPERA_TX_BAIXO = 6'd13;
    localparam ATENCAO_ESPERA_TX_ALTO = 6'd14;
    localparam ATENCAO_VERIFICA_TX = 6'd15;
    localparam ATENCAO_AGUARDA_2S = 6'd16;
    localparam ATENCAO_DECIDE_MODO = 6'd17;
    localparam ATENCAO_MANTEM_POSICAO = 6'd18;

    localparam MODO_LOCALIZACAO = 2'b00;
    localparam MODO_ATENCAO = 2'b01;
    localparam MODO_DUPLO = 2'b10;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg ligar = 1'b1;
    reg entrada_serial = 1'b1;
    reg echo = 1'b0;
    reg [1:0] sel_mux = 2'b11;
    reg serial_pronto_fake = 1'b1;
    reg medida_pronta_fake = 1'b0;
    reg fim_tx_fake = 1'b0;
    reg fim_2s_fake = 1'b0;
    reg timeout_echo_fake = 1'b0;
    reg fim_1s_fake = 1'b0;

    wire trigger;
    wire pwm;
    wire saida_serial;
    wire fim_posicao;
    wire db_modo;
    wire [6:0] hex0, hex1, hex2, hex3, hex4, hex5;
    wire [9:0] ledr;

    sonar #(
        .CONTAGEM_2SEG(100),
        .CONTAGEM_1SEG(50)
    ) dut (
        .clock          (clock),
        .reset          (reset),
        .ligar          (ligar),
        .entrada_serial (entrada_serial),
        .echo           (echo),
        .sel_mux        (sel_mux),
        .trigger        (trigger),
        .pwm            (pwm),
        .saida_serial   (saida_serial),
        .fim_posicao    (fim_posicao),
        .db_modo        (db_modo),
        .hex0           (hex0),
        .hex1           (hex1),
        .hex2           (hex2),
        .hex3           (hex3),
        .hex4           (hex4),
        .hex5           (hex5),
        .LEDR           (ledr)
    );

    always #(CLOCK_PERIOD / 2) clock = ~clock;

    task step;
        begin
            @(posedge clock);
            #1;
        end
    endtask

    task wait_state(input [5:0] expected);
        begin
            wait (dut.w_estado_uc === expected);
            #1;
        end
    endtask

    task send_ascii(input [6:0] value, input parity_error);
        integer bit_index;
        reg parity_bit;
        begin
            parity_bit = (^value) ^ parity_error;
            entrada_serial = 1'b0;
            #(BIT_PERIOD);
            for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1) begin
                entrada_serial = value[bit_index];
                #(BIT_PERIOD);
            end
            entrada_serial = parity_bit;
            #(BIT_PERIOD);
            entrada_serial = 1'b1;
            #(3 * BIT_PERIOD);
        end
    endtask

    task complete_measurement;
        begin
            force dut.w_pronto_medida = medida_pronta_fake;
            medida_pronta_fake = 1'b1;
            step;
            medida_pronta_fake = 1'b0;
            #1;
            release dut.w_pronto_medida;
        end
    endtask

    task complete_transmission(input [5:0] wait_low_state,
                               input [5:0] wait_high_state,
                               input [5:0] verify_state);
        begin
            wait_state(wait_low_state);
            force dut.w_pronto_serial = 1'b0;
            step;
            wait_state(wait_high_state);
            force dut.w_pronto_serial = 1'b1;
            step;
            wait_state(verify_state);
            force dut.w_fim_tx_8 = 1'b1;
            step;
            force dut.w_fim_tx_8 = 1'b0;
        end
    endtask

    task finish_normal_cycle;
        begin
            wait_state(NORMAL_AGUARDA_MEDIDA);
            complete_measurement;
            complete_transmission(NORMAL_ESPERA_TX_BAIXO,
                                  NORMAL_ESPERA_TX_ALTO,
                                  NORMAL_VERIFICA_TX);
            wait_state(NORMAL_AGUARDA_2S);
            force dut.w_mensurar_automatico = 1'b1;
            step;
            force dut.w_mensurar_automatico = 1'b0;
            wait_state(NORMAL_DECIDE_MODO);
            step;
            wait_state(NORMAL_AVANCA_POSICAO);
            step;
            wait_state(NORMAL_PREPARA);
        end
    endtask

    task finish_attention_cycle;
        begin
            wait_state(ATENCAO_PREPARA);
            step;
            wait_state(ATENCAO_AGUARDA_MEDIDA);
            complete_measurement;
            complete_transmission(ATENCAO_ESPERA_TX_BAIXO,
                                  ATENCAO_ESPERA_TX_ALTO,
                                  ATENCAO_VERIFICA_TX);
            wait_state(ATENCAO_AGUARDA_2S);
            force dut.w_mensurar_automatico = 1'b1;
            step;
            force dut.w_mensurar_automatico = 1'b0;
            wait_state(ATENCAO_DECIDE_MODO);
            step;
            wait_state(ATENCAO_MANTEM_POSICAO);
            step;
            wait_state(ATENCAO_PREPARA);
        end
    endtask

    initial begin
        force dut.w_pronto_medida = 1'b0;
        force dut.w_pronto_serial = 1'b1;
        force dut.w_fim_tx_8 = 1'b0;
        force dut.w_timeout_echo = timeout_echo_fake;
        force dut.w_mensurar_automatico = 1'b0;
        force dut.w_fim_intervalo_duplo = fim_1s_fake;

        #100;
        reset = 1'b0;
        step;
        wait_state(NORMAL_PREPARA);
        step;
        wait_state(NORMAL_AGUARDA_MEDIDA);
        finish_normal_cycle;
        finish_normal_cycle;

        // Send 'a' during the third localization cycle, before its mode decision.
        wait_state(NORMAL_AGUARDA_MEDIDA);
        complete_measurement;
        complete_transmission(NORMAL_ESPERA_TX_BAIXO,
                              NORMAL_ESPERA_TX_ALTO,
                              NORMAL_VERIFICA_TX);
        wait_state(NORMAL_AGUARDA_2S);
        send_ascii(7'h61, 1'b0);
        if (dut.w_modo_solicitado !== MODO_ATENCAO)
            $fatal(1, "valid 'a' command was not decoded as attention mode");
        force dut.w_mensurar_automatico = 1'b1;
        step;
        force dut.w_mensurar_automatico = 1'b0;
        wait_state(NORMAL_DECIDE_MODO);
        step;
        wait_state(ATENCAO_PREPARA);
        if (!db_modo)
            $fatal(1, "attention mode was not reflected by the debug output");

        finish_attention_cycle;
        finish_attention_cycle;
        if (dut.fd_sonar.w_endereco !== 5'd2)
            $fatal(1, "attention mode must hold the current servo position");

        send_ascii(7'h64, 1'b1);
        if (dut.w_modo_solicitado !== MODO_ATENCAO)
            $fatal(1, "a command with invalid parity must be ignored");
        send_ascii(7'h64, 1'b0);
        if (dut.w_modo_solicitado !== MODO_DUPLO)
            $fatal(1, "valid 'd' command was not decoded as double-measure mode");
        send_ascii(7'h78, 1'b0);
        if (dut.w_modo_solicitado !== MODO_LOCALIZACAO)
            $fatal(1, "valid 'x' command was not decoded as localization mode");
        send_ascii(7'h61, 1'b0);
        if (dut.w_modo_solicitado !== MODO_ATENCAO)
            $fatal(1, "legacy 'a' command behavior changed");
        send_ascii(7'h76, 1'b0);
        if (dut.w_modo_solicitado !== MODO_LOCALIZACAO)
            $fatal(1, "legacy 'v' command behavior changed");

        $display("PASS: localization/attention scenario and valid a/v/d/x commands");
        $finish;
    end

    initial begin
        #100_000_000;
        $fatal(1, "scenario test timed out");
    end
endmodule
