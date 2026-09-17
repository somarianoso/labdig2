module exp4_trena_fd ( 
    input clock,
    input reset,
    input mensurar,
    input echo,
    input transmite_serial,
    input sel_letra [1:0],
    output trigger,
    output medida0 [6:0],
    output medida1 [6:0],
    output medida2 [6:0],
    output saida_serial,
    output pronto_medida,
    output pronto_serial

);

wire w_medida[20:0];
wire dados_ascii[6:0];
wire bitsConversao[2:0];

assign bitsConversao = 3'b011;

interface_hcsr04 U1 (
    .clock(clock),
    .reset(reset),
    .medir(mensurar),
    .echo(echo),
    .trigger(trigger),
    .medida(w_medida),
    .pronto(pronto_medida),
    .db_estado()//desconectado pq esse é o estado da interface e nao da trena
);

always @(*) begin
    case(sel_letra):
        2'b00: dados_ascii = {bitsConversao,medida2};
        2'b01: dados_ascii = {bitsConversao,medida1};
        2'b10: dados_ascii = {bitsConversao,medida0};
        2'b11: dados_ascii = 2'h23; //se der pau voltar aq
    endcase
    
end

tx_serial_7E1 U2 (
    .clock(clock),
    .reset(reset),
    .partida(trasmite_serial), //entradas
    .dados_ascii(dados_ascii),
    .saida_serial(saida_serial), //saidas
    .pronto(pronto_serial),
    .db_tick(), //saidas de depuracao
    .db_partida(),
    .db_saida_serial(),
    .db_estado()
);

assign medida0 = w_medida[6:0];
assign medida1 = w_medida[13:7];
assign medida2 = w_medida[20:14];


endmodule