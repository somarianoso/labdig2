module contador_endereco (
    input wire       clock,
    input wire       conta,
    input wire       zera,
    output reg [2:0] endereco
);

    // Contador sequencial que incrementa de 000 a 111 e volta para 000 (movimento "vai")
    always @(posedge clock) begin
        if (zera)
            endereco <= 3'b000;
        else if (conta) begin
            // Se atingiu 111, volta para 000; caso contrário, incrementa
            if (endereco == 3'b111)
                endereco <= 3'b000;
            else
                endereco <= endereco + 1'b1;
        end
    end

endmodule