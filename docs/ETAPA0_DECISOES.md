# Etapa 0 — Decisões do projeto (semana 1)

Registro das decisões tomadas antes de dividir o trabalho. Mudanças aqui precisam ser combinadas pela dupla.

## Checklist da Etapa 0

| Item | Decisão / situação |
|---|---|
| Tecnologia | **Android nativo em Java** (Android Studio). O documento recomendava Flutter; a dupla optou por Java. Bibliotecas equivalentes: OkHttp (HTTP), Gson (JSON), WorkManager (tarefas em segundo plano). Para a Pessoa B: sugestão de **osmdroid** ou Google Maps SDK para mapa e **MPAndroidChart** para gráficos. |
| Versão mínima do Android | **minSdk 24 (Android 7.0)**, cobre praticamente todos os aparelhos em uso. targetSdk/compileSdk 37. |
| Repositório no GitHub | **A fazer em dupla**: criar o repositório, branch `main` protegida, uma branch por pessoa (`pessoa-a`, `pessoa-b`) e revisão por pull request. Comandos no README. |
| Explorar a API | **Feito.** Ver [ENDPOINTS.md](ENDPOINTS.md). Resumo abaixo. |
| Modelos | **Feito**: `Estacao`, `Medicao`, `SerieHistorica` (+ `PontoHistorico`), `NivelAlerta` e auxiliares (`SituacaoDados`, `TipoEstacao`, `IntervaloSerie`, `Unidades`). Pacote `model/`. |
| Interface `EstacaoRepository` + mock | **Feito**: `data/EstacaoRepository.java` e `data/MockEstacaoRepository.java`. Trocar entre mock e real em `RepositoryProvider.USAR_MOCK`. |
| Estrutura de pastas | **Feito**. Ver abaixo. |
| Identidade visual básica | Nome provisório **"Monitor Hidro RS"** (`res/values/strings.xml`). Cores dos níveis = cores oficiais do mapa da Defesa Civil (`res/values/colors.xml`). Ícone do app: Pessoa B. |

## O que a exploração da API mostrou

- A API é **GraphQL** (não REST), num único endereço: `https://redehidrometeorologica.defesacivil.rs.gov.br/graphql`.
- Só aceita **duas consultas, com o texto exato do guia**: `tags_data` (situação atual de todas as ~130 estações) e `historic` (série de uma estação). Qualquer campo a mais ou a menos é recusado.
- Não há autenticação por usuário (nem JWT): o acesso é identificado pelo cliente `casa-militar-defesa-civil-rs`. Limite de **120 requisições por minuto por IP**.
- Os dados mudam **a cada 5 minutos**. Medida sem envio há 20 minutos vem como `null`.
- O **nível do rio já vem classificado** pela API (`rio_alarmes.inundacao.status` 0 a 3). Os valores das cotas **não** são fornecidos.
- O `tags_data` traz chuva acumulada de 5 min, 1h, 3h, 6h, 12h, **24h, 48h** e 168h, mas **não traz 72h**. O app calcula o mm72 somando a série `historic` de 1 hora das últimas 72h. Conferimos que essa soma bate exatamente com os acumulados da própria API.
- O histórico só cobre os **últimos 3 meses**.
- **Não existe** indicador pronto de "risco de alagamento" (HM-08) nem serviço de disparo de notificações (HM-07). O app usa como indicação de risco o **maior nível entre rio e chuva** (`Estacao.getNivelGeral()`), e as notificações são locais, geradas pelo WorkManager. *Levar ao professor/responsável técnico para validar.*

## Regra dos níveis

| Nível | Chuva acumulada (qualquer condição) | Rio (status da API) | Cor |
|---|---|---|---|
| NORMAL | nenhuma condição atingida | 0 Normalidade | verde `#69A82F` |
| ATENÇÃO | mm24 ≥ 30 ou mm48 ≥ 50 ou mm72 ≥ 60 | 1 Atenção inundação | amarelo `#FABA00` |
| ALERTA | mm24 ≥ 50 ou mm48 ≥ 70 ou mm72 ≥ 90 | 2 Alerta inundação | laranja `#E67819` |
| EMERGÊNCIA | mm24 ≥ 80 ou mm48 ≥ 100 ou mm72 ≥ 120 | 3 Inundação | vermelho `#E20228` |
| SEM DADOS | sem leitura | sem leitura ou sem cota cadastrada | cinza `#9E9E9E` |

Vale sempre o **maior nível atingido**.

## Estrutura de pastas

```
app/src/main/java/com/example/monitoramentohidrometeorologico/
├── HidroApp.java                 inicialização (canal de notificação, agendamento)
├── MainActivity.java             tela inicial (Pessoa B)
├── model/                        CONTRATO — modelos compartilhados
│   ├── Estacao, Medicao, SerieHistorica, PontoHistorico
│   ├── NivelAlerta, SituacaoDados, TipoEstacao, IntervaloSerie, Unidades
├── data/                         CONTRATO + Pessoa A
│   ├── EstacaoRepository         interface que as telas usam
│   ├── Callback, ResultadoEstacoes, ErroDados
│   ├── RepositoryProvider        escolhe mock ou real
│   ├── MockEstacaoRepository     dados falsos (assets/mock/tags_data.json)
│   ├── RemoteEstacaoRepository   implementação real
│   ├── remote/                   HidroApiClient, Queries, ConversorJson, DatasApi
│   └── local/                    CacheEstacoes, FavoritosStore
├── notificacao/                  Pessoa A — HM-07
│   ├── VerificacaoAlertasWorker, AgendadorAlertas
│   └── NotificacaoHelper, PermissaoNotificacao
└── ui/                           Pessoa B — telas (criar subpastas por tela)

app/src/debug/.../debug/DiagnosticoActivity.java   ferramenta de teste da Pessoa A (só na build debug)
```

## Combinados

- Mudanças em `model/` ou em `EstacaoRepository` só depois de avisar a outra pessoa.
- Cada pull request é revisado pela outra pessoa antes de entrar na `main`.
- Reunião rápida semanal para mostrar o que ficou pronto.
