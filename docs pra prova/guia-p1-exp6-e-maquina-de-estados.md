# Guia de estudo — P1 e Experiência 6

Este guia reúne um roteiro para entender e explicar o Sistema de Sonar da Experiência 6, verificar seu comportamento no ModelSim e projetar a adição de um novo modo de funcionamento.

## 1. O que a prova modelo cobra

Pelos documentos da P1 e pela prova modelo, prepare-se para:

1. Sintetizar e programar o projeto da Experiência 6 na FPGA DE0-CV.
2. Montar o sonar na bancada e executar o plano de testes.
3. Demonstrar o funcionamento e responder perguntas sobre o projeto.
4. Explicar como os caracteres seriais mudam o modo e como monitorar a transmissão.
5. Simular no ModelSim o cenário: três ciclos de localização, recepção de `a` e dois ciclos de atenção.
6. Analisar as ondas: recepção do comando, mudança de modo e transições da Unidade de Controle (UC).
7. Projetar logicamente a modificação da prova modelo: modo de medidas duplas, acionado por `d`, com retorno ao modo normal por `x`.

Na questão de medidas duplas, cada posição angular deve ter duas medidas, com intervalo de 1 segundo entre elas. A UC só deve mudar o funcionamento no final do ciclo, depois da transmissão dos dados da última medida realizada.

## 2. Arquitetura: quem faz o quê

O projeto separa o sistema em dois blocos principais:

- **Unidade de Controle (UC):** mantém o estado atual, decide o próximo estado e gera sinais de controle.
- **Fluxo de Dados (FD):** contém contadores, sensor, servo, ROM e interfaces seriais; recebe controles da UC e devolve condições, como “medida pronta” ou “transmissão concluída”.

No código:

- [`sonar_uc.v`](../experiencia6/sonar_uc.v) implementa a máquina de estados e seus sinais de controle.
- [`sonar_fd.v`](../experiencia6/sonar_fd.v) implementa os componentes do fluxo de dados, recebe caracteres seriais e gera condições para a UC.
- [`sonar.v`](../experiencia6/sonar.v) conecta UC e FD e seleciona sinais para depuração nos displays e LEDs.
- [`sonar_uc_moore_tb.v`](../experiencia6/sonar_uc_moore_tb.v) é um exemplo de teste da sequência e das saídas da UC.
- [`sonar_mode_tb.v`](../experiencia6/sonar_mode_tb.v) testa os comandos seriais `a` e `v` e a validação de paridade.

Regra importante da especificação do projeto: implemente o novo comportamento alterando a sequência de estados da UC. Não acrescente lógica combinacional no FD para inibir diretamente um componente — por exemplo, não desligue o PWM “por fora” com uma porta AND sobre o modo.

## 3. Como a máquina atual está organizada

Em `sonar_uc.v`, os estados estão codificados em 5 bits (`reg [4:0]`):

- `inicial`: estado de reset.
- `normal_*`: sequência de localização, com medidas, transmissão, espera e avanço de posição.
- `atencao_*`: sequência sem avanço do servo, mas com medidas e transmissão.

A UC tem três partes que vale saber apontar e explicar:

1. **Registrador de estado:** atualiza `estado_atual` na borda de clock e volta para `inicial` no reset.
2. **Lógica de próximo estado:** escolhe `estado_proximo` conforme o estado atual e condições do FD.
3. **Lógica de saídas:** define controles como `medir`, `transmite_serial`, `contar_endereco`, `zera_contador` e os sinais de depuração.

É uma máquina do tipo Moore: as saídas de controle são definidas pelo estado atual. Uma entrada pode decidir qual será o próximo estado sem alterar imediatamente as saídas do estado em que a máquina ainda está.

## 4. Receita para adicionar novos estados

### Passo 1 — Traduza o enunciado em uma sequência

Escreva os passos do modo em frases curtas. Para cada passo, pergunte:

- O que a UC está esperando ou fazendo?
- Qual sinal indica que o passo terminou?
- Qual estado vem em seguida?
- O que acontece se a condição ainda não aconteceu?
- Há algum comando ou condição que só pode ser considerado no fim do ciclo?

Evite começar escolhendo códigos binários; primeiro entenda a sequência funcional.

### Passo 2 — Desenhe os estados e as transições

Faça um diagrama com um círculo por etapa e uma seta para cada transição. Identifique a condição de cada seta. Inclua:

- reset e estado inicial;
- caminho normal do modo;
- caminho do novo modo;
- permanência no estado enquanto a condição não chega;
- pontos de decisão de modo;
- caminhos para sair e voltar;
- comportamento quando uma medida ou transmissão demora.

### Passo 3 — Identifique os sinais necessários

Separe as condições em duas categorias:

- **Entradas da UC:** condições do FD, por exemplo `pronto_medida`, `pronto_serial`, `fim_tx_8` e o pulso de temporização.
- **Saídas da UC:** controles do FD, por exemplo `medir`, `transmite_serial`, `contar_endereco` e sinais de zeramento.

Se o enunciado exige um intervalo de 1 segundo e não existe uma condição adequada disponível para a UC, projete no FD o temporizador correspondente e conecte sua saída à UC. Não trate uma condição de 2 segundos como se fosse de 1 segundo.

### Passo 4 — Reserve os códigos e nomeie os estados

Os estados atuais usam os valores `5'd0` até `5'd18`. Com 5 bits há 32 códigos possíveis (`0` a `31`), portanto ainda há códigos livres. Evite repetir um valor e mantenha os nomes coerentes com as etapas e modos.

No RTL, os nomes são declarados com `localparam`. Se o projeto ultrapassar 32 estados, será necessário aumentar a largura do estado e atualizar todos os sinais e portas de depuração relacionados.

### Passo 5 — Complete a lógica de próximo estado

No `case (estado_atual)`, descreva as transições:

- Uma condição verdadeira escolhe o próximo estado.
- Se for preciso esperar, mantenha `estado_proximo = estado_atual`.
- Inclua um `default` seguro que volte para `inicial`.
- Verifique a prioridade de condições quando mais de uma puder estar ativa ao mesmo tempo.

O padrão existente `estado_proximo = estado_atual` no início do bloco combinacional é útil para manter a máquina no estado enquanto espera.

### Passo 6 — Defina as saídas da UC

No bloco de saídas:

- Dê valores padrão a todos os sinais antes do `case`.
- Ative somente os controles necessários em cada estado.
- Em particular, confirme quando medir, iniciar transmissão, avançar posição e zerar contadores.
- Mantenha as saídas associadas aos estados, respeitando o estilo Moore usado no projeto.

### Passo 7 — Ligue todas as novas condições e controles

Se a modificação exige um sinal novo:

1. Declare-o na interface correta.
2. Gere-o no módulo responsável.
3. Conecte-o entre FD, UC e topo em `sonar.v`.
4. Confira larguras e direções (`input`/`output`).
5. Se for útil para a demonstração, inclua-o na estratégia de depuração.

Não basta declarar o sinal ou o estado: o novo caminho precisa estar conectado de ponta a ponta.

### Passo 8 — Teste estados e transições

Em cada teste, confira tanto `db_estado` quanto as saídas de controle. Teste:

- reset;
- cada transição esperada;
- espera quando uma condição não chega;
- comando válido e inválido;
- alternância de modos;
- conclusão de cada transmissão;
- contagem correta das medidas;
- avanço ou retenção da posição;
- retorno ao modo normal somente no ponto especificado.

## 5. Exercício completo: modo de medidas duplas (`d` / `x`)

### 5.1 Interpretando o requisito

- `d` solicita o modo de medidas duplas.
- Em cada posição angular, o sonar faz duas medidas.
- Deve haver um intervalo de 1 segundo entre a primeira e a segunda medida.
- Cada medida deve ser transmitida.
- `x` solicita o retorno à varredura normal.
- A mudança de funcionamento só ocorre ao final do ciclo, depois da transmissão dos dados da última medida realizada.

Não mude para o modo normal assim que o receptor detectar `x` se ainda existe uma medida/transmissão do ciclo em andamento. O comando pode ser armazenado antes; a UC consulta o modo solicitado no ponto de decisão permitido pelo diagrama.

### 5.2 Um diagrama lógico possível

Uma organização possível, avançando a posição depois do par completo:

```text
reset
  |
modo normal: preparar medida
  → aguardar medida
  → transmitir resultado
  → esperar 2 s
  → decidir modo
       ├─ modo normal: avançar posição e iniciar próximo ciclo normal
       └─ modo duplo: preparar primeira medida do par

modo duplo: preparar medida 1
  → aguardar medida 1
  → transmitir resultado 1
  → esperar 1 s
  → preparar medida 2
  → aguardar medida 2
  → transmitir resultado 2
  → decidir modo
       ├─ continuar duplo: avançar posição e começar outro par
       └─ modo normal solicitado: voltar à sequência normal
```

O diagrama é uma proposta de organização, não uma lista de estados obrigatória. A decisão sobre quando avançar o servo deve ficar explícita e consistente com o que o grupo pretende demonstrar. O requisito central é fazer duas medidas na mesma posição, esperar 1 segundo entre elas e respeitar o ponto de transição definido no enunciado.

### 5.3 Como representar os modos

O projeto atual guarda um modo binário: `0` para localização e `1` para atenção. Para distinguir três modos — localização, atenção (se mantida) e medidas duplas — um único bit já não é suficiente. Uma possibilidade é usar um código de dois bits, por exemplo:

| Código sugerido | Modo |
|---|---|
| `2'b00` | localização |
| `2'b01` | atenção |
| `2'b10` | medidas duplas |

O código é uma escolha de projeto; o diagrama e todos os módulos devem usar a mesma definição. No receptor serial, os códigos ASCII relevantes são:

- `a` = `7'h61`;
- `v` = `7'h76`;
- `d` = `7'h64`;
- `x` = `7'h78`.

Atualize o modo solicitado somente quando o receptor indicar um dado válido, incluindo a verificação de paridade usada no projeto. Para qualquer outro caractere ou paridade inválida, preserve o modo atual. Confirme também se o comportamento original de `a`/`v` deve ser mantido no exercício que estiver implementando.

### 5.4 Temporização de 1 segundo

O FD atual tem um contador de 2 segundos associado a `CONTAGEM_2SEG`, usado pelo ciclo normal. Há também um timeout do eco, mas ele serve para detectar ausência de resposta do sensor; não o reutilize automaticamente como intervalo entre medidas, pois sua habilitação e função são diferentes.

Projete uma condição temporal própria e inequívoca para o intervalo entre as medidas. No diagrama, anote:

- qual estado habilita a contagem;
- qual sinal inicia/zera a contagem;
- qual condição sinaliza o fim de 1 segundo;
- como a UC sai do estado de espera;
- como o temporizador volta a ficar pronto para a próxima utilização.

Para a FPGA a 50 MHz, 1 segundo corresponde a 50 milhões de ciclos de clock. Na simulação, reduza os parâmetros de contagem para que o teste seja rápido, sem alterar a relação funcional pretendida.

### 5.5 Roteiro de explicação oral

Uma explicação clara pode seguir esta ordem:

1. “O receptor serial informa quando recebeu um caractere e a lógica valida o dado.”
2. “Um caractere válido atualiza o modo solicitado; caracteres inválidos são ignorados.”
3. “A UC executa a sequência própria do modo e usa condições do FD para avançar.”
4. “No modo duplo, duas medidas ocorrem na mesma posição, com 1 segundo entre elas, e cada resultado é transmitido.”
5. “A UC só considera a troca no ponto de decisão depois que a transmissão da última medida do ciclo termina.”
6. “A movimentação do servo é controlada pela sequência de estados, não por uma lógica extra que bloqueie diretamente o PWM no FD.”

## 6. Como estudar o cenário de simulação da prova

O cenário modelo pede:

1. Aplicar reset e ligar o sistema.
2. Confirmar que começa no modo de localização.
3. Deixar completar três ciclos/posições de localização.
4. Enviar `a` pela entrada serial.
5. Confirmar a recepção válida e a solicitação de atenção.
6. Acompanhar a conclusão do ciclo em andamento e a entrada na sequência de atenção.
7. Deixar completar dois ciclos de atenção.

### Sinais para observar

Os nomes hierárquicos concretos variam conforme o testbench; procure os equivalentes destes sinais:

- entrada serial;
- dado recebido pelo receptor;
- `pronto`/valid do receptor;
- sinal de paridade válida;
- modo solicitado;
- saída de depuração do modo;
- estado da UC (`db_estado`);
- `pronto_medida` e timeout do eco;
- sinal de início e sinal de pronto da transmissão serial;
- condição de fim da mensagem;
- contador/endereço da posição;
- `contar_endereco` e `pronto`.

### Como ler as ondas

1. Localize a palavra serial recebida e confira o caractere `a`.
2. Verifique o pulso de dado pronto e a validação da paridade.
3. Veja quando o modo solicitado passa para atenção.
4. Siga `db_estado` estado a estado.
5. Confirme que não há avanço de posição durante a sequência de atenção.
6. Confira que medidas e transmissões continuam acontecendo.
7. Relacione cada mudança de estado à condição que a provocou.

Uma resposta forte não diz apenas “o modo mudou”: identifica no tempo o caractere recebido, a validação, o modo solicitado, a decisão da UC e a sequência de estados que se seguiu.

## 7. Depuração e demonstração na bancada

O topo `sonar.v` seleciona conjuntos de sinais de depuração pelos displays e LEDs. Use esses sinais para demonstrar:

- sensor e servo;
- estados das interfaces seriais;
- caractere transmitido/recebido;
- estado da UC;
- modo solicitado e modo atual;
- fim de temporização e conclusão da mensagem.

Antes da prova:

- confirme o cabo e as ligações do sensor, servo e comunicação serial;
- saiba qual posição do seletor de depuração mostra cada grupo de sinais;
- confira a frequência/temporização esperada e os parâmetros de simulação versus FPGA;
- ensaie a sequência inteira, incluindo os comandos e o retorno ao modo normal;
- tenha à mão o projeto da Experiência 6, o testbench e o diagrama atualizado.

Na apresentação, mostre primeiro um comportamento observável e depois explique qual estado e quais sinais o produzem. Isso torna a arguição mais fácil de acompanhar.

## 8. Erros comuns a evitar

- Adicionar estados sem desenhar as transições.
- Usar o mesmo código para dois estados ou exceder a largura do registrador.
- Esquecer um sinal de saída no bloco combinacional e inferir latch.
- Fazer uma decisão de modo no meio de uma transmissão.
- Avançar o servo entre as duas medidas do mesmo par.
- Usar o timeout do eco como se fosse o temporizador entre medidas.
- Afirmar que uma contagem de 2 segundos representa 1 segundo.
- Alterar o modo com qualquer caractere ou com paridade inválida.
- Manter apenas um bit para representar mais de dois modos.
- Acrescentar lógica no FD que contorne a UC para ligar/desligar um componente.
- Verificar apenas o nome do estado sem conferir as saídas e as condições da transição.
- Testar só o caminho feliz e não verificar espera, reset, retorno e comandos inválidos.

## 9. Checklist final

### Projeto lógico

- [ ] O diagrama tem todos os estados, condições, caminhos de espera e decisões de modo.
- [ ] Os modos têm sequências claramente distintas.
- [ ] A decisão de troca ocorre no ponto especificado pelo enunciado.
- [ ] O temporizador representa o intervalo correto.
- [ ] A posição do servo durante e após a sequência está definida.
- [ ] As saídas de cada estado estão documentadas.

### RTL e integração

- [ ] Os estados têm códigos únicos e largura suficiente.
- [ ] A lógica de próximo estado tem valor padrão e `default`.
- [ ] Todas as saídas têm valores padrão.
- [ ] Os modos e comandos são representados sem ambiguidade.
- [ ] Condições e controles novos estão conectados até o topo.
- [ ] Não há controle direto do FD fora da UC para contornar o projeto.
- [ ] Os sinais necessários à depuração estão acessíveis.

### Verificação e prova

- [ ] Reset e início no modo correto foram verificados.
- [ ] Comandos válidos, inválidos e paridade foram testados.
- [ ] A transmissão completa precede a decisão de modo.
- [ ] A contagem de medidas e os intervalos foram verificados.
- [ ] A posição do servo foi conferida nos dois modos.
- [ ] O cenário do ModelSim foi executado e as ondas foram interpretadas.
- [ ] A montagem e a demonstração foram ensaiadas.
- [ ] Consigo explicar cada transição apontando a condição e os sinais no código/onda.

## 10. Testbenches e como estendê-los

Há três testes dirigidos úteis no workspace:

| Testbench | Escopo | O que verifica |
|---|---|---|
| [`sonar_uc_moore_tb.v`](../experiencia6/sonar_uc_moore_tb.v) | UC | Caminhos principais de localização e atenção, saídas Moore, retenção da posição e decisões de modo. |
| [`sonar_uc_corner_tb.v`](../experiencia6/sonar_uc_corner_tb.v) | UC | Reset assíncrono, espera sem condição, estabilidade das saídas antes da borda de clock, timeout do eco, desabilitação, repetição da transmissão e fim da mensagem. |
| [`sonar_uc_conditions_tb.v`](../experiencia6/sonar_uc_conditions_tb.v) | UC | Prioridade de `pronto_medida` sobre timeout, timeouts em localização/atenção, espera pelo temporizador, ciclo de transmissão e troca de modo nos estados de decisão. |
| [`contador_m_tb.v`](../experiencia6/contador_m_tb.v) | FD / contador | Habilitação, retenção, flags `meio`/`fim`, rollover e clear síncrono/assíncrono com uma contagem curta. |
| [`rx_serial_tb.v`](../experiencia6/rx_serial_tb.v) | Receptor serial | Quadros 7E1, valores de dados, paridade par, pulso `pronto` e indicação de paridade inválida. |
| [`sonar_mode_tb.v`](../experiencia6/sonar_mode_tb.v) | Integração | Recepção dos comandos atuais `a`/`v`, caractere ignorado e paridade inválida. |
| [`sonar_tb.v`](../experiencia6/sonar_tb.v) | Integração | Varredura, dados transmitidos, sensor/eco simulado, comandos de modo, posição do servo, displays, LEDs e multiplexador de depuração. |

Com Icarus Verilog instalado, execute a partir da pasta raiz do repositório:

```sh
iverilog -g2012 -s sonar_uc_moore_tb -o /tmp/sonar_uc_moore.vvp experiencia6/sonar_uc.v experiencia6/sonar_uc_moore_tb.v
vvp /tmp/sonar_uc_moore.vvp

iverilog -g2012 -s sonar_uc_corner_tb -o /tmp/sonar_uc_corner.vvp experiencia6/sonar_uc.v experiencia6/sonar_uc_corner_tb.v
vvp /tmp/sonar_uc_corner.vvp

iverilog -g2012 -s sonar_uc_conditions_tb -o /tmp/sonar_uc_conditions.vvp experiencia6/sonar_uc.v experiencia6/sonar_uc_conditions_tb.v
vvp /tmp/sonar_uc_conditions.vvp

iverilog -g2012 -s contador_m_tb -o /tmp/contador_m_tb.vvp experiencia6/contador_m.v experiencia6/contador_m_tb.v
vvp /tmp/contador_m_tb.vvp

iverilog -g2012 -s rx_serial_tb -o /tmp/rx_serial.vvp experiencia6/rx_serial_7E1.v experiencia6/rx_serial_7E1_fd.v experiencia6/rx_serial_uc.v experiencia6/contador_m.v experiencia6/deslocador_n.v experiencia6/registrador_n.v experiencia6/rx_serial_tb.v
vvp /tmp/rx_serial.vvp

iverilog -g2012 -s sonar_mode_tb -o /tmp/sonar_mode.vvp experiencia6/*.v
vvp /tmp/sonar_mode.vvp

iverilog -g2012 -s sonar_tb -o /tmp/sonar_tb.vvp experiencia6/*.v
vvp /tmp/sonar_tb.vvp
```

Cada teste deve terminar com uma mensagem `PASS`. Um `$fatal` indica a primeira condição que não correspondeu ao comportamento esperado.

O contador do teste `contador_m_tb.v` usa `M=6` apenas para exercitar rapidamente o comportamento do módulo. Ele não prova por si só que o temporizador de 1 segundo do modo de medidas duplas foi dimensionado ou integrado corretamente.

### Adaptando um bench quando um estado novo for adicionado

1. Declare no testbench os mesmos valores simbólicos de `db_estado` usados pelo RTL. Isso facilita a leitura; o teste também pode comparar diretamente o código numérico.
2. Crie uma tarefa de estímulo para chegar ao estado novo pela sequência normal, em vez de forçar o registrador interno `estado_atual`.
3. Verifique o estado e suas saídas logo após a borda de clock que o alcança.
4. Mantenha a condição de avanço inativa por um ou mais ciclos e confirme que a máquina permanece no estado.
5. Ative a condição, confira que o estado só muda na borda seguinte e valide as saídas do estado de destino.
6. Teste a transição alternativa, o reset e qualquer comando inválido.
7. Para um modo com contagem repetida, confira o número exato de medidas/transmissões e que o avanço de posição só ocorre no ponto definido pelo diagrama.

`sonar_uc_corner_tb.v` serve de exemplo para esses padrões: ele verifica estado, saídas, espera e a diferença entre alterar uma entrada e efetivamente atualizar o estado na borda de clock.

Os testes atuais verificam a implementação presente (modos de localização e atenção). Eles **não** afirmam que o modo de medidas duplas (`d`/`x`) já está implementado. Depois de definir a interface, os códigos de modo e os estados da nova sequência, acrescente um teste de integração que envie `d` e `x` serialmente e verifique duas medidas por posição, intervalo de 1 segundo entre elas e decisão de retorno somente após a transmissão da última medida do ciclo.

## 11. Materiais de referência do workspace

- [Dicas da P1](./PCS3645-6-P1-2026-v1.2.pdf)
- [Prova modelo da P1](./PCS3645-P1.modelo-2026.pdf)
- [Especificação e dicas da Experiência 6](../experiencia6/docs/PCS3645-6-Modificacao-Sonar-2026-v1.1.pdf)
- [Outra cópia das dicas da Experiência 6](../experiencia6/docs/modificacao-sonar-2026-v1.1.pdf)
- [UC do sonar](../experiencia6/sonar_uc.v)
- [FD do sonar](../experiencia6/sonar_fd.v)
- [Topo do sonar](../experiencia6/sonar.v)
- [Testbench Moore da UC](../experiencia6/sonar_uc_moore_tb.v)
- [Testbench de casos de borda da UC](../experiencia6/sonar_uc_corner_tb.v)
- [Testbench de prioridades e condições da UC](../experiencia6/sonar_uc_conditions_tb.v)
- [Testbench do contador módulo M](../experiencia6/contador_m_tb.v)
- [Testbench do receptor serial 7E1](../experiencia6/rx_serial_tb.v)
- [Testbench dos comandos seriais](../experiencia6/sonar_mode_tb.v)
- [Testbench de integração do sonar](../experiencia6/sonar_tb.v)

## 12. Sinal a sinal: Unidade de Controle do sonar (`sonar_uc`)

Esta tabela descreve a interface real de [`sonar_uc.v`](../experiencia6/sonar_uc.v).
“Origem/destino” identifica o módulo que produz o sinal ou o bloco que o
consome. `sonar_uc` não instancia o sensor nem a UART: recebe condições do FD,
atualiza sua máquina e devolve comandos ao FD.

### 12.1 Entradas da UC

| Sinal | Origem | Papel na UC |
|---|---|---|
| `clock` | Entrada externa, distribuída pelo topo | Atualiza o registrador de estado na borda de subida. |
| `reset` | Entrada externa, distribuída pelo topo | Reset assíncrono ativo em nível alto; força `estado_atual` para `inicial`. |
| `mensurar` | Entrada do topo (`ligar`) | Habilita a operação. Quando está em zero, a lógica de próximo estado retorna a `inicial` na próxima borda de clock. |
| `pronto_serial` | FD, vindo do transmissor `tx_serial_7E1` | Indica que o transmissor não está ocupado. A UC observa sua mudança para coordenar a espera pela transmissão de cada caractere. |
| `pronto_medida` | FD, vindo da interface HC-SR04 | Indica que uma distância foi medida e registrada; a UC então inicia o envio da mensagem. |
| `fim_2seg` | FD, saída do temporizador parametrizado por `CONTAGEM_2SEG` | Condição de fim do intervalo entre ciclos de localização/atenção. A 50 MHz, o padrão de 100 milhões de contagens corresponde a 2 s. |
| `timeout_echo` | FD, saída do temporizador de timeout do eco | Indica que a espera por uma resposta do sensor expirou. A UC segue o caminho de timeout, em vez de esperar indefinidamente por `pronto_medida`. |
| `fim_tx_8` | FD, contador associado aos caracteres da mensagem do sonar | Indica que a sequência de oito caracteres foi concluída; a UC pode sair do ciclo de transmissão e seguir para a espera/decisão de modo. |
| `modo_solicitado` | FD, registrador atualizado pelo receptor serial | Modo pedido pelo comando serial: `0` para localização e `1` para atenção. A UC consulta esse valor nos estados de decisão, não interrompendo arbitrariamente um ciclo em andamento. |

### 12.2 Saídas da UC

Estas são as saídas de controle da UC para o FD, exceto os sinais de estado e
depuração identificados como tal.

| Sinal | Destino | Papel |
|---|---|---|
| `medir` | FD → interface HC-SR04 | Inicia a sequência de medição do sensor. É ativado nos estados `normal_prepara` e `atencao_prepara`. |
| `transmite_serial` | FD → transmissor UART | Solicita o envio do caractere atualmente selecionado para a mensagem do sonar. |
| `contar_endereco` | FD → contador de endereço | Incrementa a posição do servo na varredura de localização; é ativado no estado `normal_avanca_posicao`. |
| `zera_endereco` | FD → contador de endereço | Zera a posição/endereço, principalmente no estado inicial. |
| `zera_contador` | FD → temporizador do ciclo de 2 s | Zera/reinicia o contador usado para o intervalo entre ciclos. |
| `zera_transmissao` | FD → contador de caracteres do sonar | Reinicia o índice dos caracteres para começar uma nova mensagem. |
| `zera_timeout_echo` | FD → temporizador de timeout do eco | Zera o temporizador de timeout, por exemplo ao preparar uma nova medição. |
| `conta_timeout_echo` | FD → temporizador de timeout do eco | Habilita a contagem enquanto a UC espera a resposta/medida do sensor. |
| `pronto` | Topo (`sonar.v`) | Sinal de fim de ciclo/posição exposto como `fim_posicao`; não é o `pronto_medida` do sensor nem o `pronto_serial` da UART. |
| `db_estado[4:0]` | Topo e depuração | Mostra o estado atual codificado da UC. É uma saída de observabilidade, não uma condição de controle do FD. |
| `db_modo` | Topo e depuração | Indica que a UC está executando os estados de atenção. É um indicador de modo atual, distinto do modo solicitado pelo receptor. |

**Distinção importante:** `pronto_medida` e `pronto_serial` são entradas da UC
produzidas pelo FD; `pronto` é uma saída da UC. Numa explicação oral, diga qual
bloco produz cada sinal e evite chamar os três apenas de “pronto”.

## 13. Sinal a sinal: Fluxo de Dados do sonar (`sonar_fd`)

O FD recebe comandos da UC e sinais físicos/externos, executa as operações e
devolve condições e dados. A interface completa está em
[`sonar_fd.v`](../experiencia6/sonar_fd.v).

### 13.1 Entradas do FD

| Sinal | Origem | Papel no FD |
|---|---|---|
| `clock` | Entrada externa, distribuída pelo topo | Clock comum dos contadores, registradores, sensor e interfaces seriais. |
| `reset` | Entrada externa, distribuída pelo topo | Reset do receptor e parte do reset das operações. |
| `habilitado` | Entrada do topo (`ligar`) | Habilita a operação e participa do reset operacional; desabilitar impede os temporizadores de continuarem a operação. |
| `entrada_serial` | Pino/entrada serial externa | Linha recebida pelo módulo `rx_serial_7E1`; comandos são interpretados apenas quando há dado pronto e paridade válida. |
| `echo` | Entrada física do sensor HC-SR04 | Pulso de retorno do sensor, medido pela interface para calcular a distância. |
| `medir` | UC | Comando de medição encaminhado à interface HC-SR04. |
| `transmite_serial` | UC | Comando de início encaminhado ao transmissor. |
| `zera_contador` | UC | Clear síncrono do temporizador do ciclo de 2 s. |
| `zera_transmissao` | UC | Clear do contador que seleciona os caracteres da mensagem. |
| `contar_endereco` | UC | Habilita o contador de endereço/posição angular. |
| `zera_endereco` | UC | Zera o contador de endereço/posição. |
| `zera_timeout_echo` | UC | Limpa o temporizador que vigia a espera por resposta do sensor. |
| `conta_timeout_echo` | UC | Habilita o temporizador de timeout apenas nos estados de espera por medição. |

### 13.2 Saídas funcionais do FD

| Sinal | Destino/consumidor | Papel |
|---|---|---|
| `pronto_medida` | UC | Indica medida concluída pela interface HC-SR04. |
| `pronto_serial` | UC e contador de mensagem | Estado de prontidão do transmissor; o FD também usa sua conclusão para avançar o índice da mensagem. |
| `mensurar_automatico` | UC (`fim_2seg`) | Flag de fim do temporizador parametrizado `CONTAGEM_2SEG`. |
| `timeout_echo` | UC | Flag do temporizador de timeout do eco, habilitado por `conta_timeout_echo`. |
| `fim_tx_8` | UC | Flag do contador que marca o término da mensagem de oito caracteres. |
| `modo_solicitado` | UC | Registrador do comando de modo válido recebido. O receptor atual reconhece `a` (atenção) e `v` (localização). |
| `trigger` | Sensor HC-SR04 externo | Pulso de disparo gerado pela interface do sensor. |
| `medida0`, `medida1`, `medida2` | MUX da mensagem e displays | Dígitos BCD da distância, separados a partir do barramento de 12 bits. |
| `saida_serial` | Pino de transmissão externo | Linha serial transmitida pelo módulo UART. |
| `pwm` | Saída para servo | PWM gerado pelo controle do servo a partir do endereço/posição atual. |

### 13.3 Saídas de depuração do FD

Estas portas permitem observar a implementação interna sem confundi-las com
os sinais de handshake:

| Sinal | O que revela |
|---|---|
| `db_estado_rx[3:0]` | Estado da máquina interna do receptor serial. |
| `db_estado_tx[3:0]` | Estado da máquina interna do transmissor serial. |
| `db_estado_hcsr04[3:0]` | Estado da interface HC-SR04. |
| `posicao_servo[2:0]` | Endereço/posição corrente usado pelo servo. |
| `dado_rx_recebido[6:0]` | Byte de 7 bits recebido, apresentado em ASCII/código numérico. |
| `dado_tx_transmitido[6:0]` | Caractere selecionado para transmissão naquele momento. |
| `estado_tx_sonar[3:0]` | Contagem/estado do envio da mensagem do sonar. |
| `contagem_selmux[2:0]` | Índice que seleciona o caractere da mensagem `ANG,DIS#`. |
| `angulo2`, `angulo1`, `angulo0` | Dígitos do ângulo ASCII da ROM, apresentados como nibbles para depuração. |
| `paridade_par` | Resultado da verificação da paridade do quadro recebido; a UC do modo só aceita comando se for válido. |
| `pronto_rx` | Indica que o receptor concluiu a recepção de um caractere. |

## 14. Caminho dos sinais entre topo, UC e FD

Uma forma clara de responder “de onde vem esse sinal?” é seguir três etapas:

```text
sensor/UART/temporizador no FD
    → condição de entrada da UC (pronto_medida, pronto_serial, timeout_echo...)
    → transição da máquina na borda de clock
    → comando de saída da UC (medir, transmite_serial, contar_endereco...)
    → componente correspondente no FD
```

Exemplos:

1. O sensor conclui a medida e o FD eleva `pronto_medida`. A UC observa a
   condição, passa do estado de espera para o estado de início de transmissão
   e ativa `transmite_serial`.
2. O transmissor do FD altera `pronto_serial` conforme transmite os caracteres.
   A UC acompanha o handshake e consulta `fim_tx_8` para saber se deve enviar
   outro caractere ou encerrar a mensagem.
3. O temporizador do FD eleva `mensurar_automatico` (`fim_2seg`). A UC que está
   em `normal_aguarda_2s` ou `atencao_aguarda_2s` avança para decidir o modo.
4. A UC ativa `contar_endereco` em `normal_avanca_posicao`; o contador do FD
   incrementa o endereço e a ROM entrega o novo ângulo ao servo e à mensagem.

O prefixo `w_` usado em [`sonar.v`](../experiencia6/sonar.v) marca em geral fios
internos de conexão. Por exemplo, `w_pronto_medida` liga a saída
`pronto_medida` do FD à entrada homônima da UC; o prefixo não indica uma nova
função lógica.

## 15. Informações úteis para explicar a Experiência 6 na prova

### 15.1 Sequência da UC principal

Os códigos abaixo são os `localparam` atuais da UC e são expostos em
`db_estado`. Em localização, o caminho principal é:

| Estado | Código | Ação/saída relevante | Transição típica |
|---|---:|---|---|
| `inicial` | 0 | Zera posição e contadores | Escolhe a sequência conforme `modo_solicitado`. |
| `normal_prepara` | 1 | `medir`, `zera_contador`, `zera_transmissao`, `zera_timeout_echo` | Vai aguardar a medida. |
| `normal_aguarda_medida` | 2 | `conta_timeout_echo` | `pronto_medida` inicia TX; `timeout_echo` segue o caminho de timeout. |
| `normal_inicia_tx` | 3 | `transmite_serial` | Inicia a transferência do caractere atual. |
| `normal_espera_tx_baixo` | 4 | Aguarda o transmissor sair do estado pronto | Permanece enquanto `pronto_serial` ainda está alto. |
| `normal_espera_tx_alto` | 5 | Aguarda o transmissor terminar o caractere | Quando volta a pronto, verifica a mensagem. |
| `normal_verifica_tx` | 6 | Consulta `fim_tx_8` | Se a mensagem acabou, espera; caso contrário, inicia outro caractere. |
| `normal_aguarda_2s` | 7 | Espera pelo temporizador | `fim_2seg` leva à decisão de modo. |
| `normal_decide_modo` | 8 | Decide o caminho seguinte | Atenção solicitada entra no modo atenção; localização segue para avanço. |
| `normal_avanca_posicao` | 9 | `contar_endereco` e `pronto` | Avança a posição e retorna à preparação normal. |

Na sequência de atenção, os estados de preparação, espera da medida,
transmissão, espera temporizada e decisão usam códigos `10` a `18`. O caminho
`atencao_mantem_posicao` retorna a `atencao_prepara` sem ativar
`contar_endereco`. Essa é a diferença observável central: atenção continua
medindo/transmitindo, mas mantém o ângulo do servo.

### 15.2 Temporização: números para ter em mente

O clock da placa é 50 MHz, portanto:

- um ciclo dura 20 ns;
- 50 milhões de ciclos correspondem a 1 s;
- 100 milhões de ciclos correspondem a 2 s;
- para UART a 115200 baud, o período de bit é aproximadamente 434 ciclos de
  clock (cerca de 8,68 μs).

No FD atual, `CONTAGEM_2SEG` controla o intervalo de 2 s. O timeout do eco usa
separadamente um contador de 50 milhões de ciclos e só conta quando
`conta_timeout_echo` está ativo. Não confunda esses dois fins de contagem:
`fim_2seg` regula o intervalo do ciclo; `timeout_echo` evita esperar para
sempre por uma resposta do sensor.

Na simulação, parâmetros de contagem podem ser reduzidos para acelerar os
testes, desde que se preserve a função de cada temporizador. Uma redução para
simulação não significa que o intervalo da FPGA também mudou.

### 15.3 UART 7E1 e comandos de modo

O receptor e o transmissor trabalham com quadros 7E1:

1. linha em repouso no nível alto;
2. start bit em nível baixo;
3. sete bits de dado, enviados/recebidos primeiro pelo bit menos significativo;
4. um bit de paridade par;
5. um stop bit em nível alto.

O dado ASCII do comando chega a `dado_rx_recebido`. O receptor gera `pronto_rx`
e a verificação `paridade_par`; o FD só altera `modo_solicitado` na condição
`pronto_rx && paridade_par`. No projeto atual, `a` solicita atenção e `v`
solicita localização. Um caractere desconhecido ou uma paridade inválida não
deve alterar o modo armazenado.

O transmissor recebe cada caractere selecionado e emite a mensagem
`ANG,DIS#`: três caracteres de ângulo, vírgula, três caracteres de distância e
`#`. Em `sonar_fd.v`, o MUX usa `contagem_selmux` para escolher cada caractere.
Durante a depuração, associe o dado atual (`dado_tx_transmitido`) ao estado da
UART e à saída física `saida_serial`.

### 15.4 Sensor, distância e posição do servo

A interface HC-SR04 tem uma máquina própria, independente da UC principal:

| Estado do sensor | Função |
|---|---|
| `inicial` | Aguarda `medir`. |
| `preparacao` | Limpa a lógica de medição. |
| `envia_trigger` | Gera o pulso `trigger`. |
| `espera_echo` | Aguarda a borda/nível de resposta `echo`. |
| `medida` | Conta a duração do pulso de eco e espera o fim da medida. |
| `armazenamento` | Registra o valor calculado. |
| `final_medida` | Ativa `pronto` por um ciclo e retorna ao estado inicial. |

O fluxo de dados converte a duração do eco em distância e registra os dígitos
BCD que alimentam a mensagem e os displays. Em paralelo, o contador de
endereço percorre oito posições (0 a 7); a ROM associa cada endereço a um
ângulo entre 20° e 160°. `contar_endereco` muda a posição lógica; o bloco de
servo converte essa posição em PWM. A UC decide quando avançar, enquanto o FD
implementa contador, ROM e gerador PWM.

### 15.5 Depuração no topo `sonar.v`

O seletor `sel_mux` escolhe qual grupo aparece nos HEX e nos LEDs. Os índices
dos displays abaixo seguem a concatenação usada pelo topo; HEX0 é o nibble
menos significativo.

| `sel_mux` | HEX5 → HEX0 | LEDs relevantes |
|---|---|---|
| `00` | Posição do servo, estado HC-SR04, nibble reservado e três dígitos de distância | `LEDR[5:0]`: timeout, medida pronta, comando medir, PWM, echo, trigger. |
| `01` | Estado TX, caractere TX, estado RX, caractere RX | `LEDR[5:0]`: paridade, pronto RX, entrada serial, pedido TX, pronto TX, saída serial. |
| `10` | Estado/índice TX do sonar, caractere atual; nibbles inferiores reservados | `LEDR[3:0]`: zerar transmissão, fim da mensagem, pronto TX, pedido de transmissão. |
| `11` | Estado da UC e ângulo da ROM; nibble intermediário reservado | `LEDR[3:0]`: modo atual (`db_modo`), fim de 2 s, `pronto` da UC/fim de ciclo, modo solicitado. |

Na tabela de LEDs, os nomes estão listados do bit mais significativo relevante
para o menos significativo. `sel_mux` serve à instrumentação/depuração; não é
um comando de modo nem deve alterar a sequência funcional.

### 15.6 Perguntas orais prováveis e estrutura de resposta

- **“Como sabe que a medida terminou?”** — A interface HC-SR04 conclui e
  sinaliza `pronto_medida` ao FD/UC; então a UC entra na sequência de TX.
- **“O que acontece se não houver echo?”** — O temporizador habilitado durante
  a espera gera `timeout_echo`, e a UC usa o caminho de timeout em vez de ficar
  presa aguardando indefinidamente.
- **“Quando o servo muda de ângulo?”** — Quando a UC entra em
  `normal_avanca_posicao` e ativa `contar_endereco`; o contador do FD incrementa
  e a ROM/PWM refletem o novo endereço.
- **“Por que o comando serial não muda imediatamente as saídas da UC?”** — O
  receptor atualiza o modo solicitado, mas a máquina Moore só muda suas saídas
  quando muda de estado na borda de clock; a solicitação é aplicada no ponto
  de decisão da sequência.
- **“Qual a diferença entre estado, modo solicitado e modo atual?”** —
  `db_estado` identifica a etapa da máquina; `modo_solicitado` guarda o último
  comando válido; `db_modo` indica a sequência de atenção atualmente executada.
- **“Como prova que o ciclo de transmissão terminou?”** — Relaciono o handshake
  `pronto_serial`, o contador/índice de caracteres e `fim_tx_8`; não uso apenas
  a aparência do caractere no display.

Ao responder, siga sempre a cadeia **condição observada → transição na UC →
comando gerado → efeito no FD**. Isso demonstra entendimento da arquitetura,
em vez de apenas recitar nomes de sinais.

## Conversão do `echo` em distância

O circuito não arredonda a leitura para o centímetro mais próximo. O contador
`contador_cm` usa `R=2941`; a cada 2941 ciclos de clock enquanto `echo` está
ativo, gera um `tick` que incrementa o contador BCD em um centímetro. Com clock
de 50 MHz, esse intervalo corresponde a `2941 × 20 ns = 58,82 μs`,
aproximadamente o tempo de ida e volta do som para um centímetro.

Quando `echo` termina, a UC para a contagem e sinaliza `pronto`. Os dígitos
representam, portanto, o número de intervalos completos contados; a parte
fracionária é descartada. Por exemplo, uma duração equivalente a cerca de
10,49 cm tende a resultar em 10, não em 11. Como a contagem é amostrada pelo
clock, uma medida próxima ao limite entre dois intervalos pode variar em um
centímetro.

O caminho é: `echo` → `contador_cm` → `tick` a cada intervalo → incremento do
contador BCD → captura dos dígitos pela interface HC-SR04.
