# Etapa 0 — decisões da dupla

Registro do que ficou decidido antes de dividir o trabalho. Mudou alguma coisa? Atualize aqui.

| Item | Decisão |
|---|---|
| Tecnologia | Flutter 3.47.9 (canal estável), Dart 3.13 |
| Mapa e gráficos | `flutter_map` e `fl_chart` |
| Versão mínima do Android | Android 7.0 (API 24) |
| Nome do app | **Olho no Rio** |
| Pacote Android | `br.com.olhonorio.olho_no_rio` |
| Repositório | <https://github.com/Yruan-Silveira/monitoramento_hidrometeorol-gico> |
| Branches | `main` (protegida), `dados` (Pessoa A), `telas` (Pessoa B) |

## Versão mínima do Android: 7.0 (API 24)

É o mínimo padrão do Flutter atual, então não exige configuração extra, e cobre praticamente todos os aparelhos Android em uso. Tudo o que o app precisa funciona nela: notificações locais, WorkManager, mapa e gráficos. A permissão de notificação em tempo de execução só existe do Android 13 em diante; em versões anteriores a notificação já é permitida por padrão.

## Fluxo de trabalho no Git

1. Cada pessoa trabalha na sua branch (`dados` ou `telas`) ou em branches curtas criadas a partir dela.
2. Para entrar na `main`, abre um pull request e a outra pessoa revisa.
3. Antes de abrir o PR: `flutter analyze` e `flutter test` sem erros.

A proteção da `main` (exigir PR com uma aprovação) precisa ser ligada pelo dono do repositório em *Settings → Branches → Add branch ruleset*.

## Estrutura de pastas

```
lib/
  main.dart                 ponto de entrada
  injecao.dart              escolhe o repositório (mock ou real): único ponto de troca
  dominio/                  O CONTRATO — mudar só depois de avisar a dupla
    modelos/                Estacao, Medicao, SerieHistorica, NivelAlerta, Variavel
    regras/                 classificação da chuva (tabela mm24/mm48/mm72)
    repositorios/           interface EstacaoRepository
  dados/                    Pessoa A
    mock/                   EstacaoRepositoryMock (dados de exemplo)
    api/                    cliente HTTP e conversão do JSON           (a criar)
    local/                  cache e favoritos no aparelho              (a criar)
  servicos/                 Pessoa A: notificações e tarefa periódica  (a criar)
  nucleo/
    tema/                   cores dos níveis e tema do app
  telas/                    Pessoa B: uma pasta por tela
    inicio/                 resumo das estações (HM-01)
    estacoes/               lista, busca e filtros (HM-02, HM-05)       (a criar)
    mapa/                   mapa com marcadores (HM-02)                 (a criar)
    detalhe/                detalhe e gráficos (HM-03, HM-04)           (a criar)
    sobre/                  tela explicativa (HM-10)                    (a criar)
  componentes/              Pessoa B: widgets usados em mais de uma tela
test/                       espelha a estrutura de lib/
docs/                       documentação entregável
```

Regra de dependência: `telas/` e `componentes/` importam só `dominio/` e `nucleo/`. Nunca importam `dados/` diretamente; quem liga as duas pontas é `injecao.dart`.

## O contrato

As telas falam apenas com `EstacaoRepository`:

| Método | Para quê |
|---|---|
| `listarEstacoes({forcarAtualizacao})` | Todas as estações com a leitura mais recente, mais o horário da atualização |
| `buscarEstacao(codigo)` | Uma estação |
| `buscarSerie(codigo, inicio, fim, intervalo)` | Série histórica para os gráficos |
| `listarFavoritos()` | Códigos das favoritas |
| `definirFavorito(codigo, favorito)` | Marca ou desmarca |

Todo erro chega como `FalhaRepositorio`, com um `TipoFalha` que a tela traduz em mensagem.

Pontos do modelo que vale conhecer:

- **Dois alertas por estação.** `Medicao.alertaRio` vem pronto da API (cotas de inundação). `Medicao.alertaChuva` é calculado no app pela tabela do trabalho. `Medicao.alertaGeral` é o mais grave dos dois e define a cor da estação.
- **`null` significa "sem dado"**, em qualquer valor e em qualquer nível de alerta. A tela mostra "—" e a cor cinza.
- **`Estacao.situacao(agora)`** diz se o dado está atual, atrasado (mais de 30 min), ausente ou se a estação está em manutenção.
- **`Variavel`** traz rótulo e unidade de cada grandeza, e `PontoSerie.valor(variavel)` devolve o número para o gráfico.
- **`PeriodoSerie`** lista os períodos do seletor (24 h, 72 h, 7 dias, 30 dias) com o intervalo recomendado para cada um.

O `EstacaoRepositoryMock` tem 12 estações que cobrem todos os casos de tela: os quatro níveis, dado atrasado, sem leitura, em manutenção, sem limiar de rio e sem coordenadas. Para ver as telas de erro, crie-o com `falha: TipoFalha.semConexao`.

## Identidade visual

**Nome:** Olho no Rio. Vem de "ficar de olho", diz o que o app faz e não soa como canal oficial.

**Ícone:** uma gota com um olho, sobre as ondas do rio. Arquivo-mestre em [identidade/icone.png](identidade/icone.png).

**Cor da marca:** azul-rio `#0B4F6C`. O restante do tema (claro e escuro) é gerado a partir dela pelo Material 3.

**Cores dos níveis:** as mesmas do mapa oficial da Defesa Civil RS, para o usuário reconhecer o código de cores.

| Nível | Cor | Texto por cima | Ícone |
|---|---|---|---|
| Normal | verde `#69A82F` | branco | círculo com "check" |
| Atenção | amarelo `#FABA00` | escuro `#1F1400` | círculo com "i" |
| Alerta | laranja `#E67819` | escuro `#1F1400` | triângulo de aviso |
| Emergência / Inundação | vermelho `#E20228` | branco | octógono de perigo |
| Sem dado | cinza `#8A94A6` | branco | interrogação |

Regra de uso: a cor nunca aparece sozinha. Todo indicador de nível leva também ícone e rótulo em texto, porque verde e vermelho são indistinguíveis para parte dos usuários. Está tudo em `lib/nucleo/tema/cores.dart`.

## Pendências para decidir

Detalhes em [api.md](api.md), seção "O que a especificação pede e a API não entrega".

1. **Chuva de 72h:** a API de dados atuais não traz. Calcular pela série histórica só para favoritas e tela de detalhe?
2. **Faixas de limiar no gráfico do rio:** a API não informa as cotas em metros. Mostrar só a situação atual e a legenda?
3. **Risco de alagamento:** a API não tem o indicador. Usar o maior nível entre rio e chuva?
4. **Login com JWT:** a API é aberta. Confirmar com o professor que o app pode ficar sem login.
5. **Filtro por tipo de estação:** todas são do mesmo tipo. Trocar por "com/sem limiar de rio"?
6. **Período de 30 dias:** a consulta deu erro 504 no teste. Testar de novo antes de oferecer na tela.
