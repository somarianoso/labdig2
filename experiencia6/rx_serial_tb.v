/* ---------------------------------------------------------------------------
 *  Arquivo   : rx_serial_tb.v
 * ---------------------------------------------------------------------------
 *  Descricao : testbench autochecking para o receptor serial assincrono 7E1
 *              verifica dados, paridade par e pulso pronto
 *
 *  modulo rx_serial_7E1
 * ---------------------------------------------------------------------------
 *  Revisoes  :
 *      Data        Versao  Autor             Descricao
 *      28/10/2024  4.0     Edson Midorikawa  versao em Verilog
 *      07/10/2026  1.1     Testbench autochecking para 7E1
 * ---------------------------------------------------------------------------
 */

`timescale 1ns/1ns

module rx_serial_tb;

    localparam CLOCK_PERIOD = 20;
    localparam BIT_PERIOD = 434 * CLOCK_PERIOD;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg rx = 1'b1;
    wire pronto;
    wire [6:0] dados_ascii;
    wire paridade;
    wire paridade_par;
    integer quantidade_pronto = 0;

    always #(CLOCK_PERIOD / 2) clock = ~clock;

    rx_serial_7E1 dut (
        .clock        (clock),
        .reset        (reset),
        .RX           (rx),
        .pronto       (pronto),
        .dados_ascii  (dados_ascii),
        .paridade     (paridade),
        .paridade_par (paridade_par),
        .db_clock     (),
        .db_tick      (),
        .db_estado    ()
    );

    always @(posedge pronto)
        quantidade_pronto = quantidade_pronto + 1;

    task envia_quadro(input [6:0] valor, input erro_paridade);
        integer bit_indice;
        reg bit_paridade;
        begin
            bit_paridade = (^valor) ^ erro_paridade;
            rx = 1'b0;
            #(BIT_PERIOD);
            for (bit_indice = 0; bit_indice < 7; bit_indice = bit_indice + 1) begin
                rx = valor[bit_indice];
                #(BIT_PERIOD);
            end
            rx = bit_paridade;
            #(BIT_PERIOD);
            rx = 1'b1;
            #(2 * BIT_PERIOD);
        end
    endtask

    task verifica_quadro(input integer numero, input [6:0] esperado, input erro_paridade);
        integer contagem_anterior;
        reg paridade_esperada;
        begin
            contagem_anterior = quantidade_pronto;
            envia_quadro(esperado, erro_paridade);
            wait (quantidade_pronto == contagem_anterior + 1);
            #1;

            paridade_esperada = (^esperado) ^ erro_paridade;
            if (dados_ascii !== esperado)
                $fatal(1, "quadro %0d: dados recebidos %h, esperado %h",
                       numero, dados_ascii, esperado);
            if (paridade !== paridade_esperada)
                $fatal(1, "quadro %0d: bit de paridade recebido incorreto", numero);
            if (paridade_par !== !erro_paridade)
                $fatal(1, "quadro %0d: indicador de paridade par incorreto", numero);

            @(posedge clock);
            #1;
            if (pronto !== 1'b0)
                $fatal(1, "quadro %0d: pronto deveria ser um pulso de um ciclo", numero);
        end
    endtask

    initial begin
        repeat (5) @(posedge clock);
        reset = 1'b0;
        #(2 * BIT_PERIOD);

        verifica_quadro(1, 7'h35, 1'b0);
        verifica_quadro(2, 7'h61, 1'b0);
        verifica_quadro(3, 7'h00, 1'b0);
        verifica_quadro(4, 7'h7F, 1'b0);
        verifica_quadro(5, 7'h76, 1'b1);

        if (quantidade_pronto != 5)
            $fatal(1, "foram recebidos %0d quadros; esperado 5", quantidade_pronto);

        $display("PASS: RX 7E1 data, parity, ready pulse, and invalid parity reporting");
        $finish;
    end

    initial begin
        #2_000_000;
        $fatal(1, "teste do receptor serial excedeu o tempo limite");
    end

endmodule
