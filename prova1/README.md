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
o proximo modo for localizacao ou atencao. O temporizador de 1 segundo usa
`CONTAGEM_1SEG` (50 milhoes de ciclos a 50 MHz); o parametro e reduzido nos
testbenches para acelerar a simulacao.

## Testbenches

- `prova1_cenario_tb.v` reproduz tres ciclos de localizacao, recebe `a` pelo
  receptor serial real e completa dois ciclos de atencao. Tambem testa `d`, `x`
  e a rejeicao de comando com paridade invalida.
- `prova1_duplo_tb.v` testa os estados do modo duplo, as duas medidas e
  transmissoes, a espera entre elas e o retorno atrasado por `x`.
- `prova1_intervalo_duplo_tb.v` verifica a contagem e o clear do temporizador
  de 1 segundo do fluxo de dados.
- `prova1_cenario.do` compila e inicia o cenario no ModelSim com sinais de
  recepcao, modo, UC, temporizadores e posicao ja adicionados a janela Wave.

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

O testbench do cenario usa respostas controladas para o sensor, o transmissor e
os temporizadores, de modo que a forma de onda seja curta e deterministica. A
recepcao UART do comando de modo continua sendo exercitada pelo modulo real.
