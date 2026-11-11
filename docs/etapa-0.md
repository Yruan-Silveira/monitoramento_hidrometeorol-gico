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
    estado/                 EstadoEstacoes: leitura atual e favoritos, compartilhados pelas telas
    tema/                   cores dos níveis e tema do app
    formatacao.dart         números, horas e unidades no padrão brasileiro
  telas/                    Pessoa B: uma pasta por tela (ver docs/telas.md)
    principal/              barra inferior com as quatro abas
    inicio/                 resumo, favoritas e estações em alerta (HM-01)
    estacoes/               lista, busca e filtros (HM-02, HM-05)
    mapa/                   mapa com marcadores (HM-02)
    detalhe/                detalhe e gráficos (HM-03, HM-04, HM-06, HM-08)
    sobre/                  tela explicativa (HM-10)
  componentes/              Pessoa B: widgets usados em mais de uma tela
test/                       espelha a estrutura de lib/
docs/                       documentação entregável
```

Regra de dependência: `telas/` e `componentes/` importam só `dominio/`, `nucleo/` e uns aos outros. Nunca importam `dados/` diretamente; quem liga as duas pontas é `injecao.dart`.

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
- **`PeriodoSerie`** lista os períodos do seletor (24 h, 72 h, 7 dias, 30 dias) com o intervalo recomendado para cada um e o limiar de chuva que vale em cada período.
- **`chuva.mm72`** só vem preenchido em `buscarEstacao`; em `listarEstacoes` é `null` (ver decisão 1 abaixo).

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

## Onde a API não cobre a especificação: o que foi decidido

Critério: seguir o requisito sempre que a API permitir; quando não permitir, fazer a solução mais simples que ainda entregue o que o requisito pede ao usuário. Contexto técnico em [api.md](api.md).

### 1. Chuva de 72 h (tabela de níveis)

A tabela do trabalho usa 24 h, 48 h e 72 h; a consulta de dados atuais só traz 24 h e 48 h.

**Decisão:** o repositório real calcula as 72 h somando a série histórica (consulta de 72 h com intervalo de 1 h, menos de 1,5 s no teste), mas só onde isso cabe no limite de 120 requisições por minuto:

- **tela de detalhe** (`buscarEstacao`): `mm72` preenchido, classificação completa;
- **verificação das favoritas** em segundo plano: idem, uma consulta por favorita;
- **lista e mapa** (`listarEstacoes`, 130 estações): `mm72` fica `null` e o nível usa 24 h e 48 h.

Consequência: uma estação pode subir de nível ao abrir o detalhe. É raro (exige muita chuva entre 48 h e 72 h atrás e pouca depois) e o detalhe é a informação mais completa.

### 2. Limiares no gráfico (HM-06)

O requisito pede exibir os limiares "fornecidos pelo serviço responsável". Para o rio, o serviço fornece só a situação (0 a 3), não as cotas em metros.

**Decisão:**

- **Rio:** gráfico do nível sem faixas; acima dele, o selo com a situação atual (Normal / Atenção / Alerta / Inundação) e a legenda das cores.
- **Chuva:** gráfico de chuva **acumulada** no período, com linhas horizontais de Atenção, Alerta e Emergência. Em 24 h as linhas ficam em 30, 50 e 80 mm; em 72 h, em 60, 90 e 120 mm (`PeriodoSerie.limiarChuva`, `SerieHistorica.chuvaAcumuladaPorPonto`). Em 7 e 30 dias não há linhas, porque a tabela não define limiar para esses períodos.

### 3. Risco de alagamento (HM-08)

A API não fornece o cruzamento rio x chuva que o requisito atribui ao backend.

**Decisão:** o app faz o cruzamento mais simples possível, `Medicao.alertaGeral` = o nível mais grave entre rio e chuva, e o mostra com o título **"Risco de alagamento (indicativo)"**. A tela explicativa (HM-10) diz como ele é calculado e que não é previsão.

### 4. Login com JWT

A premissa comum pede autenticação "conforme a necessidade de cada projeto". A Opção 3 não tem perfis de usuário, e a API é pública, sem token. Nenhum critério de aceite da Opção 3 envolve login.

**Decisão:** o app não tem login. Os testes de "autenticação" dos entregáveis comuns viram testes de acesso à API (HTTPS, erros e limite de requisições). A justificativa vai no documento de entrega.

### 5. Filtro por tipo de estação (HM-05)

O requisito pede o filtro, mas hoje as 130 estações são do mesmo tipo.

**Decisão:** o filtro por tipo existe, com o tipo calculado a partir dos sensores que a estação declara, mas só aparece quando a lista tiver mais de um tipo. Assim cumpre o requisito sem mostrar um filtro que não filtra nada. Os filtros que separam estações hoje: **região**, **bacia**, **coordenadoria** e **"só com cota de inundação"**. Município entra pela busca por texto, porque o nome da estação é o município.

### 6. Períodos do histórico (HM-04)

**Decisão:** 24 h, 72 h, 7 dias e 30 dias. Os 30 dias usam intervalo de 3 h: com 6 h a API deu erro 504 nos dois testes, e com 3 h respondeu em 2 s (238 pontos).
