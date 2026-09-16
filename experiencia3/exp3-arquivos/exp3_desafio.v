module exp3_desafio (
 input wire clock,
 input wire reset,
 input wire medir,
 input wire echo,
 input wire [1:0] posicao,
 output wire trigger,
 output wire [6:0] hex0, // digito da unidade da medida
 output wire [6:0] hex1, // digito da dezena da medida
 output wire [6:0] hex2, // digito da centena da medida
 output wire pronto,
 output wire controle_servo,
 output wire db_medir, // depuracao do sinal medir
 output wire db_echo, // depuracao do sinal echo
 output wire db_trigger, // depuracao do sinal trigger
 output wire db_controle,// depuracao do sinal controle_servo
 output wire [1:0] db_posicao, // depuração do sinal posicao (servo)
 output wire [6:0] db_estado // depuracao: estado da UC
);


    // Sinais internos
    wire        s_medir  ;
    wire        s_trigger;
    wire [11:0] s_medida ;
    wire [3:0]  s_estado ;

    // Circuito de interface com sensor
    interface_hcsr04 INT (
        .clock    (clock    ),
        .reset    (reset    ),
        .medir    (s_medir  ),
        .echo     (echo     ),
        .trigger  (s_trigger),
        .medida   (s_medida ),
        .pronto   (pronto   ),
        .db_estado(s_estado )
    );

    // Displays para medida (4 dígitos BCD)
    hexa7seg H0 (
        .hexa   (s_medida[3:0]), 
        .display(hex0         )
    );
    hexa7seg H1 (
        .hexa   (s_medida[7:4]), 
        .display(hex1         )
    );
    hexa7seg H2 (
        .hexa   (s_medida[11:8]), 
        .display(hex2          )
    );

    // Trata entrada medir (considerando borda de subida)
    edge_detector DB (
        .clock(clock  ),
        .reset(reset  ),
        .sinal(medir  ), 
        .pulso(s_medir)
    );

    // Sinais de saída
    assign trigger = s_trigger;

    // Sinal de depuração (estado da UC)
    hexa7seg H5 (
        .hexa   (s_estado ), 
        .display(db_estado)
    );
    assign db_echo    = echo;
    assign db_trigger = s_trigger;
    assign db_medir   = medir;

    controle_servo servo (
        .clock(clock),
        .reset(reset)
        .posicao(posicao),
        .controle(controle_servo),
        .db_controle(db_controle)
    )


endmodule