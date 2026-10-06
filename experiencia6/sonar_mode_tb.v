`timescale 1ns/1ns

module sonar_mode_tb;

    localparam CLOCK_PERIOD = 20;
    localparam BIT_PERIOD   = 434 * CLOCK_PERIOD;

    reg clock = 1'b0;
    reg reset = 1'b0;
    reg ligar = 1'b0;
    reg entrada_serial = 1'b1;
    reg echo = 1'b0;
    wire trigger;
    wire pwm;
    wire saida_serial;
    wire fim_posicao;
    wire db_modo;

    sonar #(
        .CONTAGEM_2SEG(100)
    ) dut (
        .clock         (clock),
        .reset         (reset),
        .ligar         (ligar),
        .entrada_serial(entrada_serial),
        .echo          (echo),
        .trigger       (trigger),
        .pwm           (pwm),
        .saida_serial  (saida_serial),
        .fim_posicao   (fim_posicao),
        .db_modo       (db_modo)
    );

    always #(CLOCK_PERIOD / 2) clock = ~clock;

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

    initial begin
        reset = 1'b1;
        #(5 * CLOCK_PERIOD);
        reset = 1'b0;
        #(BIT_PERIOD);

        if (db_modo !== 1'b0)
            $fatal(1, "mode must start in localization");

        send_ascii(7'h61, 1'b0);
        if (db_modo !== 1'b1)
            $fatal(1, "lowercase 'a' must select attention mode");

        send_ascii(7'h41, 1'b0);
        if (db_modo !== 1'b1)
            $fatal(1, "uppercase 'A' must not select attention mode");

        send_ascii(7'h76, 1'b1);
        if (db_modo !== 1'b1)
            $fatal(1, "a command with invalid parity must be ignored");

        send_ascii(7'h76, 1'b0);
        if (db_modo !== 1'b0)
            $fatal(1, "lowercase 'v' must return to localization mode");

        $display("PASS: serial mode commands and ignored character");
        $finish;
    end

endmodule
