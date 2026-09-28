module contador_endereco (
    input conta,
    input zera,
    output reg [2:0] endereco
);

    reg incrementando;

    initial begin
        incrementando = 1'b1;
    end

    always @(*) begin
        if (conta == 1'b1 and incrementando == 1'b1) begin
            endereco = endereco + 1'b1;
            if (endereco == 3'b111) begin
                incrementando = 0;
            end
        end
        else if (conta == 1'b1 and incrementando == 1'b0) begin
            endereco = endereco - 1'b1;
            if (endereco == 3'b000) begin
                incrementando = 1;
            end
        end
    end

endmodule