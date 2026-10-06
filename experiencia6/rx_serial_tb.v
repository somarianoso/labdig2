/* ---------------------------------------------------------------------------
 *  Arquivo   : rx_serial_tb.v
 * ---------------------------------------------------------------------------
 *  Descricao : testbench basico para o circuito de recepcao serial assincrona
 *              usa task UART_WRITE_BYTE para envio de bits seriais
 *              pode ser usado para verificar diversas configuracoes seriais
 *
 *  modulo rx_serial_8N1 de autoria de Augusto Vaccarelli
 * ---------------------------------------------------------------------------
 *  Revisoes  :
 *      Data        Versao  Autor             Descricao
 *      28/10/2024  4.0     Edson Midorikawa  versao em Verilog
 *      27/09/2026  1.0     Edson Midorikawa  revisao para 7E1
 * ---------------------------------------------------------------------------
 */

`timescale 1ns/1ns

module rx_serial_tb;

    reg        clock_in         = 1'b0;
    reg        reset_in         = 1'b0;
    wire       pronto_out;
    wire [6:0] dados_ascii_out;
    wire       paridade_out;
    wire       paridade_par_out;

    reg        Sinal_Serial;
    reg [7:0]  serialData;
    reg [7:0]  casos_teste_dado [0:7];
    reg [7:0]  casos_teste_id   [0:7];

    localparam clockPeriod = 20;
    localparam bitPeriod   = 434 * clockPeriod;

    always #(clockPeriod/2) clock_in = ~clock_in;

    task UART_WRITE_BYTE;
        input [7:0] Data_In;
        integer ii;
        begin
            Sinal_Serial = 1'b0;
            #bitPeriod;

            for (ii = 0; ii < 8; ii = ii + 1) begin
                Sinal_Serial = Data_In[ii];
                #bitPeriod;
            end

            Sinal_Serial = 1'b1;
            #(2 * bitPeriod);
        end
    endtask

    integer caso;
    integer ii;

    rx_serial_7E1 DUT (
        .clock        (clock_in),
        .reset        (reset_in),
        .RX           (Sinal_Serial),
        .pronto       (pronto_out),
        .dados_ascii  (dados_ascii_out),
        .paridade     (paridade_out),
        .paridade_par (paridade_par_out),
        .db_clock     (),
        .db_tick      (),
        .db_estado    ()
    );

    initial begin
        casos_teste_id[0] = 8'd1;
        casos_teste_dado[0] = 8'b00110101;
        casos_teste_id[1] = 8'd2;
        casos_teste_dado[1] = 8'b11010101;
        casos_teste_id[2] = 8'd3;
        casos_teste_dado[2] = 8'b11111101;
        casos_teste_id[3] = 8'd4;
        casos_teste_dado[3] = 8'b10110101;
        casos_teste_id[4] = 8'd5;
        casos_teste_dado[4] = 8'b01000001;
        casos_teste_id[5] = 8'd6;
        casos_teste_dado[5] = 8'b11000001;
        casos_teste_id[6] = 8'd7;
        casos_teste_dado[6] = 8'b00000000;
        casos_teste_id[7] = 8'd8;
        casos_teste_dado[7] = 8'b10000000;

        $display("Inicio da simulacao");
        Sinal_Serial = 1'b1;

        reset_in = 1'b1;
        #(5 * clockPeriod);
        reset_in = 1'b0;
        #bitPeriod;

        for (ii = 0; ii < 8; ii = ii + 1) begin
            caso = casos_teste_id[ii];
            $display("Caso de teste %0d", casos_teste_id[ii]);
            serialData = casos_teste_dado[ii];
            #(2 * bitPeriod);
            UART_WRITE_BYTE(serialData);
            #bitPeriod;
            #(2 * bitPeriod);
        end

        caso = 99;
        reset_in = 1'b0;
        reset_in = #(5 * clockPeriod) 1'b1;
        #bitPeriod;

        $display("Fim da simulacao");
        $stop;
    end

endmodule
