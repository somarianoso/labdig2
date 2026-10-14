`timescale 1ns/1ns

module prova1_servo32_tb;
    reg clock = 1'b0;
    reg reset = 1'b1;
    reg modo_fino = 1'b1;
    reg [4:0] posicao = 5'd0;
    wire controle;
    wire [2:0] db_posicao;

    reg [31:0] larguras_finas [0:31];
    reg [31:0] larguras_localizacao [0:7];
    integer indice;

    always #10 clock = ~clock;

    controle_servo_32 dut (
        .clock      (clock),
        .reset      (reset),
        .posicao    (posicao),
        .modo_fino  (modo_fino),
        .controle   (controle),
        .db_posicao (db_posicao)
    );

    initial begin
        larguras_finas[0] = 32'd35000;
        larguras_finas[1] = 32'd37675;
        larguras_finas[2] = 32'd39815;
        larguras_finas[3] = 32'd42490;
        larguras_finas[4] = 32'd44630;
        larguras_finas[5] = 32'd47313;
        larguras_finas[6] = 32'd49463;
        larguras_finas[7] = 32'd52150;
        larguras_finas[8] = 32'd54300;
        larguras_finas[9] = 32'd56985;
        larguras_finas[10] = 32'd59125;
        larguras_finas[11] = 32'd61800;
        larguras_finas[12] = 32'd63940;
        larguras_finas[13] = 32'd66615;
        larguras_finas[14] = 32'd68755;
        larguras_finas[15] = 32'd71430;
        larguras_finas[16] = 32'd73570;
        larguras_finas[17] = 32'd76245;
        larguras_finas[18] = 32'd78385;
        larguras_finas[19] = 32'd81060;
        larguras_finas[20] = 32'd83200;
        larguras_finas[21] = 32'd85875;
        larguras_finas[22] = 32'd88015;
        larguras_finas[23] = 32'd90700;
        larguras_finas[24] = 32'd92850;
        larguras_finas[25] = 32'd95538;
        larguras_finas[26] = 32'd97688;
        larguras_finas[27] = 32'd100370;
        larguras_finas[28] = 32'd102510;
        larguras_finas[29] = 32'd105185;
        larguras_finas[30] = 32'd107325;
        larguras_finas[31] = 32'd110000;

        larguras_localizacao[0] = 32'd35000;
        larguras_localizacao[1] = 32'd45700;
        larguras_localizacao[2] = 32'd56450;
        larguras_localizacao[3] = 32'd67150;
        larguras_localizacao[4] = 32'd77850;
        larguras_localizacao[5] = 32'd88550;
        larguras_localizacao[6] = 32'd99300;
        larguras_localizacao[7] = 32'd110000;

        repeat (2) @(posedge clock);
        #1 reset = 1'b0;
        force dut.contagem = 32'd999999;

        for (indice = 0; indice < 32; indice = indice + 1) begin
            posicao = indice[4:0];
            @(posedge clock);
            #1;
            if (dut.largura_pwm !== larguras_finas[indice])
                $fatal(1, "fine servo address %0d: width=%0d expected=%0d",
                       indice, dut.largura_pwm, larguras_finas[indice]);
        end

        modo_fino = 1'b0;
        for (indice = 0; indice < 8; indice = indice + 1) begin
            posicao = indice[4:0];
            @(posedge clock);
            #1;
            if (dut.largura_pwm !== larguras_localizacao[indice])
                $fatal(1, "localization servo address %0d: width=%0d expected=%0d",
                       indice, dut.largura_pwm, larguras_localizacao[indice]);
        end

        $display("PASS: 32 fine PWM positions and original 8 localization calibrations");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "servo PWM mapping test timed out");
    end
endmodule
