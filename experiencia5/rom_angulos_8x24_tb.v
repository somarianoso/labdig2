/*
 * rom_angulos_8x24_tb.sv
 *
 * testbench em SystemVerilog
 */
 
`timescale 1ns / 1ns

module rom_angulos_8x24_tb;

  reg [2:0] endereco;
  wire [23:0] saida;
  reg [23:0] valores_esperados [0:7];
  integer i;

  // instanciacao do modulo ROM 
  rom_angulos_8x24 dut (
    .endereco(endereco),
    .saida   (saida   )
  );

  initial begin
    // ajusta endereco para valor inicial da varredura
    endereco = 3'b000;
    valores_esperados[0] = 24'h303230;
    valores_esperados[1] = 24'h303430;
    valores_esperados[2] = 24'h303630;
    valores_esperados[3] = 24'h303830;
    valores_esperados[4] = 24'h313030;
    valores_esperados[5] = 24'h313230;
    valores_esperados[6] = 24'h313430;
    valores_esperados[7] = 24'h313630;

    // varredura percorre todos os enderecos da ROM
    for (i = 0; i < 8; i = i + 1) begin
      #10; // atraso para visualizacao da saida

      // mostra endereco e valores de saida esperado e da ROM
      $display("Endereco: %0d, Saida esperada: %h, Saida da ROM: %h",
               i, valores_esperados[i], saida);

      // verifica se saida da ROM é igual ao valor esperado
      if (saida !== valores_esperados[i]) begin
        $display("Erro no endereco %0d: Esperado=%h, Saida=%h",
                 i, valores_esperados[i], saida);
        $stop;
      end

      // Incrementa endereco da varredura
      endereco = endereco + 1;
    end

    $display("Fim dos testes!");
    $stop;
  end

endmodule