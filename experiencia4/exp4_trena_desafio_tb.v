`timescale 1ns/1ns

module exp4_trena_desafio_tb;

    reg        clock = 1'b0;
    reg        reset = 1'b1;
    reg        echo  = 1'b0;

    wire       trigger;
    wire       saida_serial;
    wire [6:0] medida0;
    wire [6:0] medida1;
    wire [6:0] medida2;
    wire       pronto;
    wire       db_mensurar;
    wire       db_echo;
    wire       db_trigger;
    wire       db_saida_serial;
    wire [6:0] db_estado;

    integer erros;
    integer quadros_serial;
    integer ciclos_echo;

    exp4_trena_desafio dut (
        .clock           (clock),
        .reset           (reset),
        .echo            (echo),
        .trigger         (trigger),
        .saida_serial    (saida_serial),
        .medida0         (medida0),
        .medida1         (medida1),
        .medida2         (medida2),
        .pronto          (pronto),
        .db_mensurar     (db_mensurar),
        .db_echo         (db_echo),
        .db_trigger      (db_trigger),
        .db_saida_serial (db_saida_serial),
        .db_estado       (db_estado)
    );

    always #10 clock = ~clock;

    always @(posedge dut.FD.pronto_serial) begin
        if (!reset)
            quadros_serial = quadros_serial + 1;
    end

    task verificar;
        input condicao;
        input [255:0] mensagem;
        begin
            if (!condicao) begin
                $display("ERRO: %0s", mensagem);
                erros = erros + 1;
            end
        end
    endtask

    initial begin
        erros = 0;
        quadros_serial = 0;
        ciclos_echo = 74 * 2941;

        $dumpfile("exp4_trena_desafio.vcd");
        $dumpvars(0, exp4_trena_desafio_tb);

        repeat (5) @(posedge clock);
        reset = 1'b0;

        // Evita esperar 1 s real: simula o pulso do contador de intervalo.
        force dut.FD.mensurar_automatico = 1'b1;
        @(posedge clock);
        force dut.FD.mensurar_automatico = 1'b0;

        @(posedge trigger);
        $display("Trigger detectado em %0t ns", $time);

        // Pequeno atraso para o sensor apresentar o echo.
        repeat (5) @(posedge clock);
        echo = 1'b1;
        repeat (ciclos_echo) @(posedge clock);
        echo = 1'b0;

        wait (pronto);
        #1;

        verificar(medida2 == 7'b1000000, "centena deveria ser 0");
        verificar(medida1 == 7'b1111000, "dezena deveria ser 7");
        verificar(medida0 == 7'b0011001, "unidade deveria ser 4");
        verificar(quadros_serial == 4, "deveriam ser transmitidos 4 quadros seriais");

        $display("Resultado: pronto=%b, medida=74 cm, quadros_seriais=%0d, erros=%0d",
                 pronto, quadros_serial, erros);

        $dumpoff;
        if (erros == 0)
            $display("TESTE PASSOU");
        else
            $display("TESTE FALHOU");
        $finish;
    end

endmodule