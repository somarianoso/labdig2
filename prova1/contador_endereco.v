module contador_endereco (
    input wire       clock,
    input wire       conta,
    input wire       passo_fino,
    input wire       zera,
    output reg [4:0] endereco
);

    always @(posedge clock) begin
        if (zera)
            endereco <= 5'd0;
        else if (conta) begin
            if (passo_fino) begin
                if (endereco == 5'd31)
                    endereco <= 5'd0;
                else
                    endereco <= endereco + 1'b1;
            end
            else begin
                if (endereco == 5'd7)
                    endereco <= 5'd0;
                else
                    endereco <= endereco + 1'b1;
            end
        end
    end

endmodule