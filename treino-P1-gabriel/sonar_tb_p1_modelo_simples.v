`timescale 1ns/1ns

module sonar_tb_p1_modelo_simples;

    localparam CLOCK_PERIOD = 20;
    localparam BIT_PERIOD   = 434 * CLOCK_PERIOD;

    reg clock = 1'b0;
    reg reset = 1'b1;
    reg ligar = 1'b0;
    reg entrada_serial = 1'b1;
    reg echo = 1'b0;
    reg [1:0] sel_mux = 2'b00;

    wire trigger;
    wire pwm;
    wire saida_serial;
    wire fim_posicao;
    wire db_modo;
    wire [6:0] hex0;
    wire [6:0] hex1;
    wire [6:0] hex2;
    wire [6:0] hex3;
    wire [6:0] hex4;
    wire [6:0] hex5;
    wire [9:0] ledr;

    sonar #(
        .CONTAGEM_2SEG(100)
    ) dut (
        .clock         (clock),
        .reset         (reset),
        .ligar         (ligar),
        .entrada_serial(entrada_serial),
        .echo          (echo),
        .sel_mux       (sel_mux),
        .trigger       (trigger),
        .pwm           (pwm),
        .saida_serial  (saida_serial),
        .fim_posicao   (fim_posicao),
        .db_modo       (db_modo),
        .hex0          (hex0),
        .hex1          (hex1),
        .hex2          (hex2),
        .hex3          (hex3),
        .hex4          (hex4),
        .hex5          (hex5),
        .LEDR          (ledr)
    );

    always #(CLOCK_PERIOD / 2) clock = ~clock;

    task send_ascii(input [6:0] value);
        integer bit_index;
        reg parity_bit;
        begin
            parity_bit = ^value;
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

    initial begin
        repeat (5) @(posedge clock);
        reset = 1'b0;
        ligar = 1'b1;

        // Espera um pouco para o sonar começar a operar em localização.
        repeat (3000) @(posedge clock);

        // Envia 'a' para pedir modo de atenção.
        send_ascii(7'h61);

        // Espera o tempo suficiente para o modo mudar e alguns ciclos de atencao.
        repeat (5000) @(posedge clock);

        $display("PASS: teste simples concluido");
        $finish;
    end

    initial begin
        #5_000_000;
        $fatal(1, "teste simples excedeu o tempo limite");
    end

endmodule
