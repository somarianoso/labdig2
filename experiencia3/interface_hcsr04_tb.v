/* --------------------------------------------------------------------------
 *  Arquivo   : interface_hcsr04_tb.v
 * --------------------------------------------------------------------------
 *  Descricao : testbench basico para o circuito de inteface com sensor
 *              ultrassonico de distancia
 *              possui 4 casos de teste, com truncamento e arredondamento
 *              
 * --------------------------------------------------------------------------
 *  Revisoes  :
 *      Data        Versao  Autor             Descricao
 *      07/09/2024  1.0     Edson Midorikawa  versao em Verilog
 *      07/09/2025  1.1     Edson Midorikawa  revisao
 * --------------------------------------------------------------------------
 */
 
`timescale 1ns/1ns

module interface_hcsr04_tb;

    // Declaração de sinais
    reg         clock_in = 0;
    reg         reset_in = 0;
    reg         medir_in = 0;
    reg         echo_in = 0;
    wire        trigger_out;
    wire [11:0] medida_out;
    wire        pronto_out;
    wire [3:0]  db_estado_out;

    // Componente a ser testado (Device Under Test -- DUT)
    interface_hcsr04 dut (
        .clock    (clock_in     ),
        .reset    (reset_in     ),
        .medir    (medir_in     ),
        .echo     (echo_in      ),
        .trigger  (trigger_out  ),
        .medida   (medida_out   ),
        .pronto   (pronto_out   ),
        .db_estado(db_estado_out)
    );

    // Configurações do clock
    parameter clockPeriod = 20; // clock de 50MHz
    // Gerador de clock
    always #(clockPeriod/2) clock_in = ~clock_in;

    // Array de casos de teste (estrutura equivalente em Verilog)
    reg [31:0] casos_teste [0:4]; // Usando 32 bits para acomodar tempos maiores
    reg [11:0] medidas_esperadas [0:4];
    integer caso;
    integer erros;

    // Largura do pulso
    reg [31:0] larguraPulso; // Usando 32 bits para acomodar tempos maiores
    time inicio_trigger;

    task automatic verifica_trigger;
        begin
            @(posedge trigger_out);
            inicio_trigger = $time;
            @(negedge trigger_out);
            if (($time - inicio_trigger) != 10_000) begin
                $display("ERRO caso %0d: trigger com %0t ns; esperado 10000 ns",
                         caso, $time - inicio_trigger);
                erros = erros + 1;
            end else begin
                $display("OK caso %0d: trigger com 10 us", caso);
            end
        end
    endtask

    // Geração dos sinais de entrada (estímulos)
    initial begin
        $dumpfile("interface_hcsr04_tb.vcd");
        $dumpvars(0, interface_hcsr04_tb);
        $display("Inicio das simulacoes");

        // Inicialização do array de casos de teste
        casos_teste[0] = 117;    // 117us (2cm, arredondar)
        casos_teste[1] = 5882;   // 5882us (100cm)
        casos_teste[2] = 5899;   // 5899us (100,29cm) truncar para 100cm
        casos_teste[3] = 4353;   // 4353us (74cm)
        casos_teste[4] = 4399;   // 4399us (74,79cm) arredondar para 75cm
        medidas_esperadas[0] = 12'h002;
        medidas_esperadas[1] = 12'h100;
        medidas_esperadas[2] = 12'h100;
        medidas_esperadas[3] = 12'h074;
        medidas_esperadas[4] = 12'h075;

        // Valores iniciais
        medir_in = 0;
        echo_in  = 0;
        erros = 0;

        // Reset
        caso = 0; 
        #(2*clockPeriod);
        reset_in = 1;
        #(2_000); // 2 us
        reset_in = 0;
        @(negedge clock_in);

        // Espera de 100us
        #(100_000); // 100 us

        // Loop pelos casos de teste
        for (caso = 1; caso < 6; caso = caso + 1) begin
            // 1) Determina a largura do pulso echo
            $display("Caso de teste %0d: %0dus", caso, casos_teste[caso-1]);
            larguraPulso = casos_teste[caso-1]*1000; // 1us=1000

            fork
                verifica_trigger();
            join_none

            // 2) Envia pulso medir
            @(negedge clock_in);
            medir_in = 1;
            #(5*clockPeriod);
            medir_in = 0;

            // 3) Espera por 400us (tempo entre trigger e echo)
            #(400_000); // 400 us

            // 4) Gera pulso de echo
            echo_in = 1;
            #(larguraPulso);
            echo_in = 0;

            // 5) Espera final da medida
            wait (pronto_out === 1'b1);
            if (medida_out !== medidas_esperadas[caso-1]) begin
                $display("ERRO caso %0d: medida=%03h; esperado=%03h",
                         caso, medida_out, medidas_esperadas[caso-1]);
                erros = erros + 1;
            end else begin
                $display("OK caso %0d: medida BCD=%03h", caso, medida_out);
            end

            @(posedge clock_in);
            if (pronto_out !== 1'b0) begin
                $display("ERRO caso %0d: pronto nao durou um ciclo", caso);
                erros = erros + 1;
            end

            // 6) Espera entre casos de teste
            #(100_000); // 100 us
        end

        // Fim da simulação
        $display("Fim das simulacoes: %0d erro(s)", erros);
        $finish(erros != 0);
    end

endmodule
