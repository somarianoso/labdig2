module exp4_trena ( 
    input  wire clock, 
    input  wire reset,        
    //input  wire mensurar,          
    input  wire echo,        
    output wire trigger,     
    output wire saida_serial,        
    output wire [6:0] medida0, 
    output wire [6:0] medida1, 
    output wire [6:0] medida2, 
    output wire pronto, 
    output wire db_mensurar, 
    output wire db_echo,      
    output wire db_trigger,       
    output wire db_saida_serial,
    output wire [6:0] db_estado 
);

    // Fios de interligação entre UC e FD
    wire       s_medir;
    wire       s_pronto_medida;
    wire       s_pronto_serial;
    wire       s_transmite_serial;
    wire [1:0] s_sel_letra;
    wire [3:0] s_estado;
    
    // Fios para saídas compartilhadas com sinais de depuração
    wire       s_trigger;
    wire       s_saida_serial;

    // Fios para transportar o BCD do FD para os Displays
    wire [3:0] w_medida0_bcd;
    wire [3:0] w_medida1_bcd;
    wire [3:0] w_medida2_bcd;

    wire w_mensurar_automatico;
    wire w_zera_contador;

    // Instanciação do Fluxo de Dados (FD)
    exp4_trena_fd FD (
        .clock(clock),
        .reset(reset),
        .medir(s_medir),
        .echo(echo),
        .transmite_serial(s_transmite_serial),
        .sel_letra(s_sel_letra),
        .zera_contador(w_zera_contador),
        .trigger(s_trigger),
        .medida0(w_medida0_bcd), // Conecta a unidade BCD
        .medida1(w_medida1_bcd), // Conecta a dezena BCD
        .medida2(w_medida2_bcd), // Conecta a centena BCD
        .saida_serial(s_saida_serial),
        .pronto_medida(s_pronto_medida),
        .pronto_serial(s_pronto_serial),
        .mensurar_automatico(w_mensurar_automatico)
        
    );

    // Instanciação da Unidade de Controle (UC)
    exp4_trena_uc UC (
        .clock(clock),
        .reset(reset),
        .mensurar(w_mensurar_automatico), 
        .pronto_serial(s_pronto_serial),
        .pronto_medida(s_pronto_medida),
        .medir(s_medir),
        .pronto(pronto),
        .db_estado(s_estado), 
        .transmite_serial(s_transmite_serial),
        .sel_letra(s_sel_letra),
        .zera_contador()
    );

    // Decodificadores para os Displays da Medida
    hexa7seg HEX0 (.hexa(w_medida0_bcd), .display(medida0));
    hexa7seg HEX1 (.hexa(w_medida1_bcd), .display(medida1));
    hexa7seg HEX2 (.hexa(w_medida2_bcd), .display(medida2));

    // Decodificador para o Display de Depuração do Estado da UC[cite: 1, 3]
    hexa7seg HEX_ESTADO (
        .hexa(s_estado),
        .display(db_estado)
    );

    // Atribuição das saídas principais e de depuração[cite: 3]
    assign trigger         = s_trigger;
    assign saida_serial    = s_saida_serial;
    assign db_mensurar     = w_mensurar_automatico;
    assign db_echo         = echo;
    assign db_trigger      = s_trigger; 
    assign db_saida_serial = s_saida_serial;

endmodule