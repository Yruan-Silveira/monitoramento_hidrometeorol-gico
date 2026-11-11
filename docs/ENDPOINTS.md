# Endpoints consumidos

Guia oficial: <https://sistemas.defesacivil.rs.gov.br/api-redehidrometeorologica>

| Item | Valor |
|---|---|
| URL | `https://redehidrometeorologica.defesacivil.rs.gov.br/graphql` |
| Método | `POST`, corpo JSON `{"query": "...", "variables": {...}}` |
| Protocolo | GraphQL sobre HTTPS |
| Autenticação | nenhuma por usuário; cliente fixo `casa-militar-defesa-civil-rs` dentro da consulta |
| Limite | 120 requisições/minuto por IP |
| Atualização dos dados | a cada 5 minutos (1–2 min depois de :00, :05, :10…) |
| Código no app | `data/remote/HidroApiClient.java`; texto das consultas em `data/remote/Queries.java` |

A API só aceita o **texto exato** das duas consultas abaixo (campo por campo, na mesma ordem). Espaços e quebras de linha não importam.

---

## 1. `tags_data` — situação atual de todas as estações

Usada em: `HidroApiClient.buscarTagsDataJson()` → `EstacaoRepository.listarEstacoes()` e `buscarEstacao()`; também pelo `VerificacaoAlertasWorker`.

**Parâmetros:** nenhum. Sempre devolve todas as ~130 estações (não existe filtro por estação ou local).

**Consulta:** ver `Queries.TAGS_DATA` (texto longo, copiado do guia).

**Exemplo de resposta (resumido, uma estação):**

```json
{
  "data": {
    "tags_data": {
      "qualle_meteorologia": [
        {
          "codigo": "DCRS-00001",
          "name": { "prefix": "DCRS-00001", "general": "Igrejinha", "local": "" },
          "show": "true",
          "timestamp": "2026-11-10T20:50:00.000",
          "position": {
            "bacia": "RS - Sinos",
            "latitude": -29.5743,
            "longitude": -50.7961,
            "regiao": "Metropolitana de Porto Alegre",
            "altitude": null,
            "filtros": { "outros": { "crepdec": { "nome": { "value": "METROPOLITANA" }, "codigo": { "value": 1 } } } }
          },
          "data": {
            "rio": {
              "rio_alarmes": { "inundacao": { "ativo": { "value": true }, "status": { "value": 0 } } },
              "rio_nivel": { "value": 27.31 },
              "rio_nivel_tendencia": { "value": 0.01 },
              "homologacao": { "relacao": { "valido": { "value": true } } }
            },
            "chuva": {
              "acumulado": {
                "min005": { "value": 0 }, "h001": { "value": 0 }, "h003": { "value": 0 },
                "h006": { "value": 0 }, "h012": { "value": 0 }, "h024": { "value": 0 },
                "h048": { "value": 0 }, "h168": { "value": 55.4 }
              }
            },
            "temperatura": { "atual": { "value": 21.87 } },
            "umidade": { "atual": { "value": 61.84 } }
          },
          "type": "HidroMeteo",
          "filter": { "relacao": { "tem_chuva_acumulada": true, "tem_nivel_do_rio": true } },
          "resource": { "estacao": { "estado": { "manutencao": { "value": false } } } }
        }
      ],
      "proximaAtualizacaoEm": "2026-11-10T23:57:50.000Z"
    }
  }
}
```

**Como o app lê os campos (`ConversorJson`):**

| Campo da API | Modelo |
|---|---|
| `codigo` | `Estacao.codigo` |
| `name.general` / `name.local` | `Estacao.nome` / `local` |
| `position.latitude/longitude/bacia/regiao` | `Estacao.latitude/longitude/bacia/regiao` |
| `position.filtros.outros.crepdec.nome.value` | `Estacao.coordenadoria` |
| `filter.relacao.tem_*` | `Estacao.temNivelRio`, `temChuva`… → `getTipo()` |
| `resource.estacao.estado.manutencao.value` | `Estacao.emManutencao` |
| `data.rio.rio_alarmes.inundacao.ativo/status` | `Estacao.limiarRioCadastrado/statusRio` → `getNivelRio()` |
| `timestamp` (Brasília) | `Medicao.dataHora` → `getSituacaoDados()` |
| `data.rio.rio_nivel.value` | `Medicao.rioNivel` (m) |
| `data.chuva.acumulado.h024/h048` | `Medicao.chuva24h/48h` (mm) → `getNivelChuva()` |
| demais `data.*.atual.value` | temperatura, umidade, pressão, vento, radiação |
| `proximaAtualizacaoEm` (UTC) | `ResultadoEstacoes.proximaAtualizacao` |

`value: null` = a estação não enviou a medida nos últimos 20 minutos.

---

## 2. `historic` — série de uma estação

Usada em: `HidroApiClient.buscarHistoricoJson()` → `EstacaoRepository.buscarSerieHistorica()` e cálculo da chuva de 72h.

**Consulta:** ver `Queries.HISTORIC`.

**Variáveis:**

| Variável | Obrigatória | Formato |
|---|---|---|
| `stationCode` | sim | ex.: `DCRS-00001` |
| `startDate` | sim | `AAAA-MM-DD HH:MM:SS`, horário de Brasília, no máximo 3 meses atrás |
| `endDate` | sim | mesmo formato; se for no futuro a API usa o horário atual |
| `interval` | não | `MIN_5`, `MIN_10`, `HOUR_1`, `HOUR_3`, `HOUR_6`, `HOUR_12` |

**Exemplo de requisição:**

```json
{
  "query": "query Historic($stationCode: String!, ...) { historic(...) }",
  "variables": {
    "stationCode": "DCRS-00001",
    "startDate": "2026-11-10 15:00:00",
    "endDate": "2026-11-10 21:00:00",
    "interval": "HOUR_1"
  }
}
```

**Exemplo de resposta:**

```json
{
  "data": {
    "historic": {
      "items": [
        {
          "ts": "2026-11-10T16:00:00.000",
          "codigo": "DCRS-00001",
          "rio_nivel": 27.34, "rio_variacao": 0,
          "chuva_mm": 0, "chuva_total": 0, "chuva_taxa_med": 0, "chuva_taxa_max": 0,
          "temp_media": 29.98, "sens_termica": 29.98, "umid_rel": 32.68, "pres_atmos": 1014.58,
          "vento_vel_med": 8.70, "vento_vel_max": 22.03, "vento_dir": 143.73, "radiacao": 531.17
        }
      ],
      "totalCount": 1
    }
  }
}
```

Observação: em alguns itens um campo **não aparece** (em vez de vir `null`); o conversor trata os dois casos.

---

## Erros tratados (`ErroDados.Tipo`)

| Situação | Como a API responde | Tipo no app |
|---|---|---|
| Sem internet / DNS | falha de conexão | `SEM_INTERNET` |
| API lenta | sem resposta em 30 s | `TIMEOUT` |
| Servidor fora | HTTP 5xx | `SERVICO_INDISPONIVEL` |
| Limite de 120/min | `ThrottlerException: Too Many Requests` | `LIMITE_REQUISICOES` |
| Consulta alterada | `QUERY_NOT_ALLOWED` | `CONSULTA_RECUSADA` |
| Cliente errado | `FORBIDDEN` | `ACESSO_NEGADO` |
| Período > 3 meses / data inválida | `BAD_REQUEST` + mensagem | `PARAMETRO_INVALIDO` (com a mensagem da API) |
| Corpo vazio / `data: null` | — | `RESPOSTA_VAZIA` |
| HTML ou JSON quebrado | — | `RESPOSTA_INVALIDA` |

Quando a `tags_data` falha e existe cache, o repositório devolve os dados guardados com `ResultadoEstacoes.isDoCache() == true`.
