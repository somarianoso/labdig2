module exp4_trena ( 
input clock, 
input reset,         
input mensurar,          
input echo,         
output trigger,      
output saida_serial,        
output  [6:0] medida0, 
output  [6:0] medida1, 
output  [6:0] medida2, 
output pronto, 
output db_mensurar, 
output db_echo,      
output db_trigger,       
output db_saida_serial,
output  [6:0] db_estado 
);

wire w_medida[20:0];

interface_hcsr04 U1 (
    .clock(clock),
    .reset(reset),
    .medir(mensurar),
    .echo(echo),
    .trigger(trigger),
    .medida(w_medida),
    .pronto(pronto),
    .db_estado()//desconectado pq esse é o estado da interface e nao da trena
);

always @(*) begin
    case(sel_letra):
        
    
end

assign medida0 = w_medida[6:0];
assign medida1 = w_medida[13:7];
assign medida2 = w_medida[20:14];


endmodule