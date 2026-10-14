`timescale 1ns/1ns

module prova1_varredura_tb;
    localparam CLOCK_PERIOD = 20;
    localparam BIT_PERIOD = 434 * CLOCK_PERIOD;
    localparam NORMAL_PREPARA = 6'd1;
    localparam NORMAL_AGUARDA_MEDIDA = 6'd2;
    localparam NORMAL_INICIA_TX = 6'd3;
    localparam NORMAL_ESPERA_TX_BAIXO = 6'd4;
    localparam NORMAL_ESPERA_TX_ALTO = 6'd5;
    localparam NORMAL_VERIFICA_TX = 6'd6;
    localparam NORMAL_AGUARDA_2S = 6'd7;
    localparam NORMAL_DECIDE_MODO = 6'd8;
    localparam NORMAL_AVANCA_POSICAO = 6'd9;
    localparam FINA_PREPARA = 6'd34;
    localparam FINA_AGUARDA_MEDIDA = 6'd35;
    localparam FINA_INICIA_TX = 6'd36;
    localparam FINA_ESPERA_TX_BAIXO = 6'd37;
    localparam FINA_ESPERA_TX_ALTO = 6'd38;
    localparam FINA_VERIFICA_TX = 6'd39;
    localparam FINA_AGUARDA_2S = 6'd40;
    localparam FINA_DECIDE_MODO = 6'd41;
    localparam FINA_AVANCA_POSICAO = 6'd42;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg ligar = 1'b1;
    reg entrada_serial = 1'b1;

    wire trigger;
    wire pwm;
    wire saida_serial;
    wire fim_posicao;
    wire db_modo;
    wire [6:0] hex0, hex1, hex2, hex3, hex4, hex5;
    wire [9:0] ledr;

    always #(CLOCK_PERIOD / 2) clock = ~clock;

    sonar #(
        .CONTAGEM_2SEG(100),
        .CONTAGEM_1SEG(50)
    ) dut (
        .clock          (clock),
        .reset          (reset),
        .ligar          (ligar),
        .entrada_serial (entrada_serial),
        .echo           (1'b0),
        .sel_mux        (2'b11),
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

    task send_ascii(input [6:0] value);
        integer bit_index;
        begin
            entrada_serial = 1'b0;
            #(BIT_PERIOD);
            for (bit_index = 0; bit_index < 7; bit_index = bit_index + 1) begin
                entrada_serial = value[bit_index];
                #(BIT_PERIOD);
            end
            entrada_serial = ^value;
            #(BIT_PERIOD);
            entrada_serial = 1'b1;
            #(3 * BIT_PERIOD);
        end
    endtask

    function [23:0] expected_angle(input integer address);
        begin
            case (address)
                0:  expected_angle = 24'h303230;
                1:  expected_angle = 24'h303235;
                2:  expected_angle = 24'h303239;
                3:  expected_angle = 24'h303334;
                4:  expected_angle = 24'h303338;
                5:  expected_angle = 24'h303433;
                6:  expected_angle = 24'h303437;
                7:  expected_angle = 24'h303532;
                8:  expected_angle = 24'h303536;
                9:  expected_angle = 24'h303631;
                10: expected_angle = 24'h303635;
                11: expected_angle = 24'h303730;
                12: expected_angle = 24'h303734;
                13: expected_angle = 24'h303739;
                14: expected_angle = 24'h303833;
                15: expected_angle = 24'h303838;
                16: expected_angle = 24'h303932;
                17: expected_angle = 24'h303937;
                18: expected_angle = 24'h313031;
                19: expected_angle = 24'h313036;
                20: expected_angle = 24'h313130;
                21: expected_angle = 24'h313135;
                22: expected_angle = 24'h313139;
                23: expected_angle = 24'h313234;
                24: expected_angle = 24'h313238;
                25: expected_angle = 24'h313333;
                26: expected_angle = 24'h313337;
                27: expected_angle = 24'h313432;
                28: expected_angle = 24'h313436;
                29: expected_angle = 24'h313531;
                30: expected_angle = 24'h313535;
                31: expected_angle = 24'h313630;
                default: expected_angle = 24'hxxxxxx;
            endcase
        end
    endfunction

    function [23:0] expected_local_angle(input integer address);
        begin
            case (address)
                0: expected_local_angle = 24'h303230;
                1: expected_local_angle = 24'h303430;
                2: expected_local_angle = 24'h303630;
                3: expected_local_angle = 24'h303830;
                4: expected_local_angle = 24'h313030;
                5: expected_local_angle = 24'h313230;
                6: expected_local_angle = 24'h313430;
                7: expected_local_angle = 24'h313630;
                default: expected_local_angle = 24'hxxxxxx;
            endcase
        end
    endfunction

    task check_position(input integer address, input reg fine_mode);
        reg [23:0] angle_expected;
        begin
            angle_expected = fine_mode ? expected_angle(address) :
                                         expected_local_angle(address);
            if (dut.fd_sonar.w_endereco !== address[4:0] ||
                dut.fd_sonar.w_posicao !== angle_expected)
                $fatal(1, "position %0d: addr=%0d angle=%h expected=%h",
                       address, dut.fd_sonar.w_endereco,
                       dut.fd_sonar.w_posicao, angle_expected);
        end
    endtask

    task complete_cycle(input reg fine_mode, input integer command);
        reg [5:0] prepare_state;
        reg [5:0] measure_state;
        reg [5:0] transmit_state;
        reg [5:0] wait_low_state;
        reg [5:0] wait_high_state;
        reg [5:0] verify_state;
        reg [5:0] timer_state;
        reg [5:0] decide_state;
        reg [5:0] advance_state;
        begin
            if (fine_mode) begin
                prepare_state = FINA_PREPARA;
                measure_state = FINA_AGUARDA_MEDIDA;
                transmit_state = FINA_INICIA_TX;
                wait_low_state = FINA_ESPERA_TX_BAIXO;
                wait_high_state = FINA_ESPERA_TX_ALTO;
                verify_state = FINA_VERIFICA_TX;
                timer_state = FINA_AGUARDA_2S;
                decide_state = FINA_DECIDE_MODO;
                advance_state = FINA_AVANCA_POSICAO;
            end else begin
                prepare_state = NORMAL_PREPARA;
                measure_state = NORMAL_AGUARDA_MEDIDA;
                transmit_state = NORMAL_INICIA_TX;
                wait_low_state = NORMAL_ESPERA_TX_BAIXO;
                wait_high_state = NORMAL_ESPERA_TX_ALTO;
                verify_state = NORMAL_VERIFICA_TX;
                timer_state = NORMAL_AGUARDA_2S;
                decide_state = NORMAL_DECIDE_MODO;
                advance_state = NORMAL_AVANCA_POSICAO;
            end

            wait_state(prepare_state);
            step;
            wait_state(measure_state);
            if (command != 0)
                send_ascii(command[6:0]);

            force dut.w_pronto_medida = 1'b1;
            step;
            force dut.w_pronto_medida = 1'b0;
            wait_state(transmit_state);
            step;
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
            wait_state(timer_state);
            force dut.w_mensurar_automatico = 1'b1;
            step;
            force dut.w_mensurar_automatico = 1'b0;
            wait_state(decide_state);
            step;

            if (fine_mode && dut.w_estado_uc === advance_state)
                step;
            else if (!fine_mode && dut.w_estado_uc === advance_state)
                step;
        end
    endtask

    integer fine_index;
    integer coarse_index;
    reg [4:0] coarse_addresses [0:7];

    initial begin
        force dut.w_pronto_medida = 1'b0;
        force dut.w_pronto_serial = 1'b1;
        force dut.w_fim_tx_8 = 1'b0;
        force dut.w_timeout_echo = 1'b0;
        force dut.w_mensurar_automatico = 1'b0;

        coarse_addresses[0] = 5'd0;
        coarse_addresses[1] = 5'd1;
        coarse_addresses[2] = 5'd2;
        coarse_addresses[3] = 5'd3;
        coarse_addresses[4] = 5'd4;
        coarse_addresses[5] = 5'd5;
        coarse_addresses[6] = 5'd6;
        coarse_addresses[7] = 5'd7;

        repeat (5) @(posedge clock);
        @(negedge clock);
        reset = 1'b0;
        wait_state(NORMAL_PREPARA);

        check_position(0, 1'b0);
        complete_cycle(1'b0, 0);
        check_position(1, 1'b0);
        complete_cycle(1'b0, 0);
        check_position(2, 1'b0);

        complete_cycle(1'b0, 7'h66);
        if (dut.w_modo_solicitado !== 2'b11 ||
            dut.w_estado_uc !== FINA_PREPARA)
            $fatal(1, "f did not select fine scanning at a cycle boundary");
        check_position(0, 1'b1);

        for (fine_index = 0; fine_index < 32; fine_index = fine_index + 1) begin
            check_position(fine_index, 1'b1);
            if (fine_index == 31) begin
                complete_cycle(1'b1, 7'h72);
                if (dut.w_modo_solicitado !== 2'b00 ||
                    dut.w_estado_uc !== NORMAL_PREPARA)
                    $fatal(1, "r did not select localization at a cycle boundary");
                check_position(0, 1'b0);
            end else begin
                complete_cycle(1'b1, 0);
            end
        end

        for (coarse_index = 0; coarse_index < 8; coarse_index = coarse_index + 1) begin
            check_position(coarse_addresses[coarse_index], 1'b0);
            complete_cycle(1'b0, 0);
        end
        check_position(0, 1'b0);

        $display("PASS: f/r UART commands, deferred mode changes, 32 fine angles and 8 localization angles");
        $finish;
    end

    initial begin
        #10_000_000;
        $fatal(1, "fine-sweep test timed out");
    end
endmodule
