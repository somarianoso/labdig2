/* --------------------------------------------------------------------------
 *  Arquivo   : exp4_trena_tb.v
 * --------------------------------------------------------------------------
 *  Descricao : testbench para a trena digital com saida serial.
 *              O fluxo segue a estrutura do roteiro da experiencia 4 e
 *              os padroes utilizados nas experiencias 2 e 3.
 * --------------------------------------------------------------------------
 */

`timescale 1ns/1ns

module exp4_trena_tb;

    // Sinais de entrada
    reg         clock_in = 0;
    reg         reset_in = 0;
    reg         mensurar_in = 1;
    reg         echo_in = 0;

    // Sinais de saida
    wire        trigger_out;
    wire        saida_serial_out;
    wire [6:0]  medida0_out;
    wire [6:0]  medida1_out;
    wire [6:0]  medida2_out;
    wire        pronto_out;
    wire        db_mensurar_out;
    wire        db_echo_out;
    wire        db_trigger_out;
    wire        db_saida_serial_out;
    wire [6:0]  db_estado_out;

    // DUT
    exp4_trena dut (
        .clock           (clock_in             ),
        .reset           (reset_in             ),
        .mensurar        (mensurar_in          ),
        .echo            (echo_in              ),
        .trigger         (trigger_out          ),
        .saida_serial    (saida_serial_out     ),
        .medida0         (medida0_out          ),
        .medida1         (medida1_out          ),
        .medida2         (medida2_out          ),
        .pronto          (pronto_out           ),
        .db_mensurar     (db_mensurar_out      ),
        .db_echo         (db_echo_out          ),
        .db_trigger      (db_trigger_out       ),
        .db_saida_serial (db_saida_serial_out  ),
        .db_estado       (db_estado_out        )
    );

    // Configuracao do clock -> 50 MHz
    parameter clockPeriod = 20;
    always #(clockPeriod/2) clock_in = ~clock_in;

    // Casos de teste e parametros de tempo
    reg [31:0] casos_teste [0:3];
    integer caso;
    reg [31:0] larguraPulso;

    // Tarefa para inicializar o sistema
    task reset_dut;
    begin
        mensurar_in = 1'b1;
        echo_in     = 1'b0;

        #(2 * clockPeriod);
        reset_in = 1'b1;
        #(2_000); // 2 us
        reset_in = 1'b0;
        @(negedge clock_in);
        #(100_000); // 100 us
    end
    endtask

    // Tarefa para executar um caso de medida
    task executar_caso;
        input [31:0] largura_us;
        begin
            $display("\nCaso de teste %0d: echo = %0d us", caso, largura_us);

            // 4.1: atribui a largura do pulso echo
            larguraPulso = largura_us * 1000; // converte us -> ns

            // 4.2: envia pulso mensurar
            @(negedge clock_in);
            mensurar_in = 1'b0;
            #(5 * clockPeriod);
            mensurar_in = 1'b1;

            // 4.3: espera 400 us entre trigger e echo
            #(400_000);

            // 4.4: gera pulso echo com largura definida
            echo_in = 1'b1;
            #(larguraPulso);
            echo_in = 1'b0;

            // 4.5: espera pelo final da medida e da transmissao serial
            wait (pronto_out == 1'b1);
            $display("  pronto_out = %b | trigger = %b | saida_serial = %b", pronto_out, trigger_out, saida_serial_out);
            $display("  medida0 = %0d | medida1 = %0d | medida2 = %0d", medida0_out, medida1_out, medida2_out);

            // 4.6: espera entre casos de teste
            #(100_000);
        end
    endtask

    initial begin
        $display("Inicio da simulacao da Trena Digital com Saida Serial");
        $dumpfile("exp4_trena.vcd");
        $dumpvars(0, clock_in, reset_in, mensurar_in, echo_in,
                 trigger_out, saida_serial_out, medida0_out,
                 medida1_out, medida2_out, pronto_out,
                 db_estado_out);

        // Casos de teste usando a mesma base de valores do sensor HC-SR04
        casos_teste[0] = 5882;  // 5882 us -> 100 cm
        casos_teste[1] = 5899;  // 5899 us -> 100,29 cm (truncamento)
        casos_teste[2] = 4353;  // 4353 us -> 74 cm
        casos_teste[3] = 4399;  // 4399 us -> 74,79 cm (arredondamento)

        // Reset inicial do sistema
        reset_dut();

        // Loop dos cenarios de teste
        for (caso = 0; caso < 4; caso = caso + 1) begin
            executar_caso(casos_teste[caso]);
        end

        $display("\nFim da simulacao da Trena Digital");
        $dumpoff;
        $stop;
    end

endmodule