module controle_servo_32 (
    input  wire       clock,
    input  wire       reset,
    input  wire [4:0] posicao,
    input  wire       modo_fino,
    output wire       controle,
    output wire [2:0] db_posicao
);

    reg [31:0] contagem;
    reg [31:0] largura_pwm;
    reg pwm;

    function [31:0] largura_da_posicao(input [4:0] endereco,
                                       input modo_varredura_fina);
        begin
            if (!modo_varredura_fina) begin
                case (endereco[2:0])
                    3'd0: largura_da_posicao = 32'd35000;
                    3'd1: largura_da_posicao = 32'd45700;
                    3'd2: largura_da_posicao = 32'd56450;
                    3'd3: largura_da_posicao = 32'd67150;
                    3'd4: largura_da_posicao = 32'd77850;
                    3'd5: largura_da_posicao = 32'd88550;
                    3'd6: largura_da_posicao = 32'd99300;
                    3'd7: largura_da_posicao = 32'd110000;
                endcase
            end else begin
                case (endereco)
                5'd0:  largura_da_posicao = 32'd35000;
                5'd1:  largura_da_posicao = 32'd37675;
                5'd2:  largura_da_posicao = 32'd39815;
                5'd3:  largura_da_posicao = 32'd42490;
                5'd4:  largura_da_posicao = 32'd44630;
                5'd5:  largura_da_posicao = 32'd47313;
                5'd6:  largura_da_posicao = 32'd49463;
                5'd7:  largura_da_posicao = 32'd52150;
                5'd8:  largura_da_posicao = 32'd54300;
                5'd9:  largura_da_posicao = 32'd56985;
                5'd10: largura_da_posicao = 32'd59125;
                5'd11: largura_da_posicao = 32'd61800;
                5'd12: largura_da_posicao = 32'd63940;
                5'd13: largura_da_posicao = 32'd66615;
                5'd14: largura_da_posicao = 32'd68755;
                5'd15: largura_da_posicao = 32'd71430;
                5'd16: largura_da_posicao = 32'd73570;
                5'd17: largura_da_posicao = 32'd76245;
                5'd18: largura_da_posicao = 32'd78385;
                5'd19: largura_da_posicao = 32'd81060;
                5'd20: largura_da_posicao = 32'd83200;
                5'd21: largura_da_posicao = 32'd85875;
                5'd22: largura_da_posicao = 32'd88015;
                5'd23: largura_da_posicao = 32'd90700;
                5'd24: largura_da_posicao = 32'd92850;
                5'd25: largura_da_posicao = 32'd95538;
                5'd26: largura_da_posicao = 32'd97688;
                5'd27: largura_da_posicao = 32'd100370;
                5'd28: largura_da_posicao = 32'd102510;
                5'd29: largura_da_posicao = 32'd105185;
                5'd30: largura_da_posicao = 32'd107325;
                5'd31: largura_da_posicao = 32'd110000;
                default: largura_da_posicao = 32'd35000;
                endcase
            end
        end
    endfunction

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            contagem   <= 32'd0;
            largura_pwm <= 32'd35000;
            pwm        <= 1'b0;
        end else begin
            pwm <= contagem < largura_pwm;
            if (contagem == 32'd999999) begin
                contagem    <= 32'd0;
                largura_pwm <= largura_da_posicao(posicao, modo_fino);
            end else begin
                contagem <= contagem + 1'b1;
            end
        end
    end

    assign controle = pwm;
    assign db_posicao = posicao[2:0];

endmodule
