# API da Rede Hidrometeorológica — o que o app consome

Levantamento feito em 10/11/2026, lendo o guia oficial e chamando a API de produção.

- Guia oficial: <https://sistemas.defesacivil.rs.gov.br/api-redehidrometeorologica>
- Endereço da API: `https://redehidrometeorologica.defesacivil.rs.gov.br/graphql`
- Mapa oficial (para conferir valores): <https://redehidrometeorologica.defesacivil.rs.gov.br/Mapa>

## Resumo

| Pergunta | Resposta |
|---|---|
| Que tipo de API é? | GraphQL, sempre `POST` com JSON no mesmo endereço |
| Precisa de login ou token? | Não. Não há JWT nem chave; o cliente `casa-militar-defesa-civil-rs` já vai fixo no texto da consulta |
| Quais consultas existem? | Só duas: `tags_data` (dados atuais de todas as estações) e `historic` (série de uma estação) |
| Com que frequência os dados mudam? | A cada 5 minutos, publicados 1 a 2 minutos depois de cada marco (:00, :05, :10…) |
| Quantas estações? | 130, todas do tipo `HidroMeteo` |
| Limite de uso | 120 requisições por minuto por IP |
| Até quando vai o histórico? | Últimos 3 meses |

## Regras que quebram o app se forem ignoradas

1. **O texto da consulta é fixo.** A API compara o texto campo por campo e recusa qualquer diferença (campo a mais, a menos ou fora de ordem) com `QUERY_NOT_ALLOWED`. Espaços e quebras de linha não importam. Os textos exatos estão em [api/tags_data.graphql](api/tags_data.graphql) e [api/historic.graphql](api/historic.graphql): copiar dali, sem editar.
2. **Não existe filtro no servidor.** `tags_data` sempre devolve as 130 estações (cerca de 320 KB). Busca e filtros são feitos no aparelho.
3. **Na `historic`, os valores vão em `variables`**, nunca dentro do texto da consulta.
4. **Horários sem fuso são de Brasília.** `timestamp` e `ts` vêm como `2026-11-10T20:35:00.000`, sem `Z`. Já `proximaAtualizacaoEm` vem em UTC, com `Z`. Ao converter, acrescentar `-03:00` aos primeiros.
5. **Erro pode vir com HTTP 200.** Erros de regra chegam no campo `errors` do JSON, com o código em `errors[0].extensions.code`. É preciso olhar o corpo, não só o status.

## Consulta 1 — `tags_data` (dados atuais)

Corpo da requisição: `{"query": "<texto de api/tags_data.graphql>"}`. Sem variáveis.

Resposta de exemplo (uma estação): [api/exemplo_tags_data.json](api/exemplo_tags_data.json).

Caminhos a partir de `data.tags_data`:

| Campo | Significado | Vai para o modelo |
|---|---|---|
| `proximaAtualizacaoEm` | Quando vale consultar de novo (UTC) | `LeituraEstacoes.proximaAtualizacaoEm` |
| `qualle_meteorologia[]` | Lista das estações | `List<Estacao>` |

Dentro de cada estação:

| Campo | Significado | Vai para o modelo |
|---|---|---|
| `codigo` | Identificador, ex.: `DCRS-00001` | `Estacao.codigo` |
| `name.general` | Nome (município, às vezes com rio ou bairro) | `Estacao.nome` |
| `timestamp` | Início do bloco de 5 min da última leitura (Brasília) | `Medicao.horario` |
| `position.latitude`, `longitude`, `altitude` | Coordenadas | `Estacao.latitude` etc. |
| `position.regiao` | Mesorregião | `Estacao.regiao` |
| `position.bacia` | Bacia hidrográfica | `Estacao.bacia` |
| `position.filtros.outros.crepdec.nome.value` | Coordenadoria regional da Defesa Civil | `Estacao.coordenadoria` |
| `data.rio.rio_nivel.value` | Cota do rio (m) | `Medicao.nivelRio` |
| `data.rio.rio_nivel_tendencia.value` | Nível atual menos a média da última hora (m) | `Medicao.variacaoNivelRio` |
| `data.rio.rio_alarmes.inundacao.ativo.value` | Se a estação tem cotas de inundação cadastradas | `Medicao.temLimiarRio` |
| `data.rio.rio_alarmes.inundacao.status.value` | 0 a 3, ver tabela abaixo | `Medicao.alertaRio` |
| `data.chuva.acumulado.{min005,h001,h003,h006,h012,h024,h048,h168}.value` | Chuva acumulada (mm) | `Medicao.chuva` |
| `data.temperatura.atual.value` | °C | `Medicao.temperatura` |
| `data.senstermica.atual.value` | °C | `Medicao.sensacaoTermica` |
| `data.umidade.atual.value` | % | `Medicao.umidade` |
| `data.pressaoatmos.atual.value` | hPa | `Medicao.pressao` |
| `data.vento.velocidade_media.value`, `velocidade_maxima.value` | km/h | `Medicao.ventoVelocidade…` |
| `data.vento.direcao.value` | graus, 0 = norte | `Medicao.ventoDirecao` |
| `data.radiacaosolar.atual.value` | W/m² | `Medicao.radiacaoSolar` |
| `filter.relacao.tem_*` | Sensores que a estação declara ter | `Estacao.tipo` |
| `resource.estacao.estado.manutencao.value` | Estação em manutenção | `Estacao.emManutencao` |

Campos que a API devolve e o modelo ainda não usa: médias de hoje e de ontem (`historico.diaatual`, `diaanterior`), máxima e mínima de temperatura do dia, `tendencia` das variáveis meteorológicas e `homologacao.relacao.valido` (falso = sensor com dado não homologado). Se alguma tela precisar, combinamos e acrescentamos ao modelo.

### Situação do rio (`rio_alarmes.inundacao`)

| `ativo` | `status` | Situação | Cor oficial | `Medicao.alertaRio` |
|---|---|---|---|---|
| true | 0 | Normalidade | verde `#69A82F` | `normal` |
| true | 1 | Atenção | amarelo `#FABA00` | `atencao` |
| true | 2 | Alerta | laranja `#E67819` | `alerta` |
| true | 3 | Inundação | vermelho `#E20228` | `emergencia` |
| true | null | Sem leitura recente de nível | branco | `null` |
| false | 0 | Estação sem limiar cadastrado | branco | `null`, com `temLimiarRio = false` |

No dia do levantamento: 90 estações em normalidade, 4 em atenção, 34 sem limiar e 2 sem leitura.

### Casos reais que o app precisa aguentar

Todos apareceram na resposta de 10/11/2026:

- **Qualquer `value` pode ser `null`**: quer dizer que o sensor não mandou dado nos últimos 20 minutos. 7 estações estavam sem nível de rio.
- **O objeto inteiro pode ser `null`**, não só o `value`: `rio_nome` e `rio_area_drenagem` vieram `null` nas 130 estações.
- **`timestamp` nulo**: duas estações (DCRS-00060 e DCRS-00112) não tinham leitura nenhuma.
- **Estação sem nome nem coordenadas**: a DCRS-00129 veio com `name.general`, `latitude`, `longitude` e `regiao` nulos. Usar o código como nome e deixá-la fora do mapa.
- **`bacia` ou `regiao` nulos** em estações que têm o resto.
- **Números ora inteiros, ora decimais** (`0` e `27.31` no mesmo campo): converter com `(valor as num).toDouble()`.
- **Nomes com espaço sobrando** (`"São Borja "`) e espaço não separável: aplicar `trim()`.
- `show` vem como texto (`"true"`), não como booleano.

## Consulta 2 — `historic` (série de uma estação)

Corpo: `{"query": "<texto de api/historic.graphql>", "variables": {...}}`.

| Variável | Obrigatória | Formato |
|---|---|---|
| `stationCode` | sim | `DCRS-00001` |
| `startDate` | sim | `AAAA-MM-DD HH:MM:SS`, horário de Brasília, no máximo 3 meses atrás |
| `endDate` | sim | mesmo formato; se for no futuro, a API usa o horário atual |
| `interval` | não | `MIN_5`, `MIN_10`, `HOUR_1`, `HOUR_3`, `HOUR_6` ou `HOUR_12` |

Resposta de exemplo: [api/exemplo_historic.json](api/exemplo_historic.json). Os itens ficam em `data.historic.items`, em ordem cronológica, e `totalCount` traz a quantidade.

| Campo do item | Significado | Unidade | `PontoSerie` |
|---|---|---|---|
| `ts` | Horário do bloco (Brasília) | — | `horario` |
| `rio_nivel` | Cota do rio | m | `nivelRio` |
| `rio_variacao` | Variação do nível no bloco | m | `variacaoNivelRio` |
| `chuva_mm` | Chuva dentro do bloco | mm | `chuva` |
| `chuva_total` | Chuva total (o guia não detalha) | mm | não usado |
| `chuva_taxa_med`, `chuva_taxa_max` | Intensidade da chuva | mm/h | `chuvaTaxaMedia`, `chuvaTaxaMaxima` |
| `temp_media` | Temperatura | °C | `temperatura` |
| `sens_termica` | Sensação térmica | °C | `sensacaoTermica` |
| `umid_rel` | Umidade relativa | % | `umidade` |
| `pres_atmos` | Pressão atmosférica | hPa | `pressao` |
| `vento_vel_med`, `vento_vel_max` | Vento | km/h | `ventoVelocidade…` |
| `vento_dir` | Direção do vento | graus | `ventoDirecao` |
| `radiacao` | Radiação solar | W/m² | `radiacaoSolar` |

Observações dos testes:

- A ordem das chaves no JSON real é diferente da do exemplo do guia: ler por nome, nunca por posição.
- Pedindo de 00:00 a 20:00 com `HOUR_1`, vieram 20 itens, de `01:00` a `20:00`. O primeiro `ts` não coincide com o `startDate`.
- 7 dias em `MIN_5` devolveram 2.263 itens (738 KB) e levaram 11,5 s. Para gráfico, usar `HOUR_1` ou maior.
- **30 dias em `HOUR_6` deram erro 504 (Gateway Time-out)** na única tentativa. Não foi repetido para não gastar o limite; testar de novo antes de oferecer o período de 30 dias na tela.
- O guia se contradiz sobre o intervalo padrão (`MIN_5` num trecho, `MIN_10` em outro). Enviar sempre o `interval`.
- A mesma consulta repetida em menos de 30 segundos devolve a resposta em cache do servidor.

## Erros

| Situação | HTTP | Como aparece | `TipoFalha` |
|---|---|---|---|
| Consulta com texto diferente | 400 | `extensions.code = QUERY_NOT_ALLOWED` | `servicoIndisponivel` |
| Estação inexistente | 200 | `extensions.code = NOT_FOUND`, "Estação não encontrada: X" | `naoEncontrado` |
| Início anterior a 3 meses | 200 | `extensions.code = BAD_REQUEST`, com a data mínima aceita | `periodoInvalido` |
| Data em formato errado | 200 | `extensions.code = BAD_REQUEST`, "Datas inválidas" | `periodoInvalido` |
| Mais de 120 requisições/min | — | "ThrottlerException: Too Many Requests" (segundo o guia; não testado) | `limiteExcedido` |
| Servidor sobrecarregado | 504 | página HTML, não JSON | `servicoIndisponivel` |
| Sem internet / sem resposta | — | exceção do cliente HTTP | `semConexao` / `tempoEsgotado` |

Os três primeiros e o 504 foram confirmados em teste.

## O que a especificação pede e a API não entrega

Três pontos precisam de decisão da dupla, e possivelmente do professor:

1. **Chuva de 72h (`mm72`).** A tabela de níveis do trabalho usa 24h, 48h e 72h, mas `tags_data` só traz 24h, 48h e 7 dias. Para ter as 72h é preciso somar `chuva_mm` da `historic`, o que custa uma requisição por estação. Sugestão: calcular só para as favoritas e para a estação aberta na tela de detalhe; nas demais, classificar com 24h e 48h (`mm72` fica `null`).
2. **Valores dos limiares do rio (HM-06).** A API informa em que faixa o rio está (status 0 a 3), mas não as cotas de atenção, alerta e inundação em metros. Não dá para desenhar as faixas de nível no gráfico do rio; dá para mostrar a situação atual e a legenda. As faixas no gráfico só são possíveis para a chuva, cuja tabela é conhecida.
3. **Risco de alagamento (HM-08).** O requisito fala em cruzamento "feito no backend", mas a API não tem esse indicador. Sugestão adotada no modelo: `Medicao.alertaGeral`, o mais grave entre o nível do rio e o da chuva, apresentado como indicativo.

Também vale saber:

- **Tipo de estação (HM-05).** As 130 estações são `HidroMeteo` e declaram os mesmos sensores, então o filtro por tipo hoje não separa nada. Um filtro mais útil é "com limiar de rio" (96 estações) contra "sem limiar" (34).
- **Município (HM-05).** Não há campo de município. O nome da estação costuma ser o município; os filtros possíveis são região, bacia e coordenadoria, e a busca por texto cobre o município.
- **Login (JWT).** A premissa comum do trabalho cita JWT "conforme a necessidade de cada projeto". Esta API é aberta, então o app não tem tela de login.

## Ritmo de consulta recomendado

- `tags_data`: no máximo uma vez a cada 5 minutos, de preferência só depois de `proximaAtualizacaoEm`. Consultar antes não traz dado novo.
- Tarefa em segundo plano das notificações: o WorkManager do Android não roda com intervalo menor que 15 minutos, o que fica bem dentro do limite.
- `historic`: uma chamada por gráfico aberto; guardar em cache por estação, período e intervalo.
