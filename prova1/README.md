# P1 — simulacao e modo de medidas duplas

Esta pasta contem uma copia independente dos modulos RTL necessarios do
Experimento 6. As alteracoes para a P1 estao somente nesta pasta; os arquivos
em `experiencia6/` foram mantidos sem modificacao.

## Comandos seriais

| Caractere | Modo solicitado |
|---|---|
| `v` | Localizacao (`00`) |
| `a` | Atencao (`01`) |
| `d` | Duas medidas por posicao (`10`) |
| `x` | Retorno a localizacao (`00`) |
| `f` | Varredura fina (`11`) |
| `r` | Retorno a localizacao (`00`) |

Os comandos so atualizam o modo solicitado quando o receptor sinaliza um byte
com paridade valida. Outros caracteres e bytes com paridade invalida sao
ignorados. A UC consulta a solicitacao em seus pontos de decisao, em vez de
interromper uma medida ou transmissao em andamento.

No modo duplo, cada posicao usa a sequencia:

1. preparar e realizar a primeira medida;
2. transmitir a mensagem da medida;
3. aguardar 1 segundo;
4. preparar e realizar a segunda medida;
5. transmitir a mensagem da segunda medida;
6. avancar uma posicao e entao selecionar o proximo modo solicitado.

Assim, `x` recebido durante o par so e aplicado depois da transmissao da
segunda medida. O servo avanca uma vez ao concluir cada par, inclusive quando
o proximo modo continuar em duplo ou for atencao. Ao retornar a localizacao,
a varredura recomeca na posicao de 20 graus. O temporizador de 1 segundo usa
`CONTAGEM_1SEG` (50 milhoes de ciclos a 50 MHz); o parametro e reduzido nos
testbenches para acelerar a simulacao.

## Varredura fina

O comando `f` seleciona a varredura fina; `r` solicita o retorno a localizacao.
Ambos so alteram o modo solicitado quando o receptor serial valida a paridade.
A UC termina a medida e a transmissao em andamento antes de trocar de modo.
Na fronteira, a UC aciona o clear ja existente do contador de endereco e inicia
a nova varredura na posicao de 20 graus; nao reinicia o circuito nem interfere
diretamente nos componentes do fluxo de dados.

Na varredura fina, o contador percorre 32 enderecos (0 a 31), correspondentes
aos angulos inteiros arredondados de `20 + 140*n/31` graus. Assim, a lista vai
de 20 a 160 graus com incrementos de 4 ou 5 graus. A ROM de 32 posicoes fornece
o angulo em ASCII para a mensagem serial; o controlador do servo seleciona a
largura PWM correspondente, interpolada entre os oito valores de calibracao do
Experimento 6. O contador usa o mesmo endereco numerico de 0 a 7 no modo de
localizacao, mantendo os angulos e as larguras PWM originais de 20 em 20 graus.
O sinal `passo_fino`, gerado pela UC, seleciona a progressao e a interpretacao
do endereco no fluxo de dados.

## Testbenches

- `prova1_cenario_tb.v` reproduz tres ciclos de localizacao, recebe `a` pelo
  receptor serial real e completa dois ciclos de atencao. Tambem testa `d`, `x`
  e a rejeicao de comando com paridade invalida.
- `prova1_duplo_tb.v` testa os estados do modo duplo, as duas medidas e
  transmissoes, a espera entre elas e o retorno atrasado por `x`.
- `prova1_intervalo_duplo_tb.v` verifica a contagem e o clear do temporizador
  de 1 segundo do fluxo de dados.
- `prova1_varredura_tb.v` recebe `f` e `r` pela UART real, verifica a troca
  apenas na fronteira do ciclo, percorre os 32 angulos finos e depois as oito
  posicoes de localizacao, conferindo o endereco e o ASCII do angulo em cada
  posicao.
- `prova1_servo32_tb.v` verifica as larguras PWM das 32 posicoes finas e
  confirma que as oito calibracoes originais de localizacao foram preservadas.
- `prova1_cenario.do` compila e inicia o cenario no ModelSim com sinais de
  recepcao, modo, UC, temporizadores e posicao ja adicionados a janela Wave.
- `prova1_varredura.do` executa o teste de varredura fina e adiciona a forma de
  onda do comando serial, estado da UC, modo de varredura, endereco e angulo.
- `prova1_servo32.do` executa o teste das larguras PWM.

No ModelSim, entre nesta pasta e execute:

```tcl
do prova1_cenario.do
```

## Leitura esperada da onda do cenario

No ModelSim, o estado da UC e mostrado em `w_estado_uc` (decimal). Na sequencia
de localizacao, os estados relevantes sao `1` preparar, `2` aguardar medida,
`3` iniciar transmissao, `4` aguardar inicio serial, `5` aguardar fim serial,
`6` verificar mensagem, `7` aguardar temporizacao, `8` decidir modo e `9`
avancar posicao. Cada ciclo normal segue esse caminho e retorna a `1`.

No terceiro ciclo, acompanhe `entrada_serial`, `w_estado_rx`,
`w_dado_rx_recebido`, `w_pronto_rx` e `w_paridade_par`. A recepcao valida o
ASCII `0x61` (`a`) e altera `w_modo_solicitado` para `01`. A UC continua no
ciclo normal ate `w_mensurar_automatico`; entao percorre `8` e entra no estado
`10` (preparar atencao). Cada ciclo de atencao percorre `10` a `18` e volta a
`10`; o endereco do servo nao avanca.

Para executar tambem o teste focado no modo duplo:

```tcl
vsim -voptargs=+acc work.prova1_duplo_tb
run -all

vsim -voptargs=+acc work.prova1_intervalo_duplo_tb
run -all
```

Para executar o teste da funcionalidade adicional:

```tcl
do prova1_varredura.do
```

Para verificar tambem o mapeamento das larguras PWM:

```tcl
do prova1_servo32.do
```

No teste de varredura, os estados `34` a `42` da UC correspondem,
respectivamente, a preparar, aguardar medida, iniciar transmissao, aguardar
serial baixo, aguardar serial alto, verificar transmissao, aguardar
temporizacao, decidir modo e avancar endereco. Em modo fino, o endereco avanca
de um em um; ao concluir o endereco 31 retorna a 0. Em localizacao, o endereco
avanca de 0 a 7 e retorna a 0.

O testbench do cenario usa respostas controladas para o sensor, o transmissor e
os temporizadores, de modo que a forma de onda seja curta e deterministica. A
recepcao UART do comando de modo continua sendo exercitada pelo modulo real.
