# Olho no Rio

App Android em Flutter que consulta a Rede Hidrometeorológica da Defesa Civil RS e mostra o nível dos rios, a chuva, o histórico e os alertas das estações. Trabalho de Dispositivos Móveis, Opção 3.

Os alertas do app são indicativos. Não são previsão garantida de enchente e não substituem os comunicados oficiais da Defesa Civil.

## Documentação

- [docs/etapa-0.md](docs/etapa-0.md): decisões da dupla, estrutura de pastas, contrato, identidade visual e pendências
- [docs/api.md](docs/api.md): o que a API entrega, campos, erros e limitações
- [docs/telas.md](docs/telas.md): telas, capturas, fluxo de navegação e estados de erro
- [docs/permissoes.md](docs/permissoes.md): permissões do aparelho, justificativas e dados guardados

## Como rodar

Requisitos: Flutter 3.47 (canal estável) e Android SDK (vem com o Android Studio).

```bash
flutter pub get
flutter run          # com um emulador ou celular conectado
flutter test         # testes
dart analyze         # análise estática
```

Gerar os pacotes:

```bash
flutter build apk --release      # APK para testes
flutter build appbundle          # AAB para distribuição
```

## Mock × API real

Por padrão o app roda com dados de exemplo (`EstacaoRepositoryMock`). Para usar a API real da Defesa Civil, sem mudar código:

```bash
flutter run --dart-define=API_REAL=true
flutter build apk --release --dart-define=API_REAL=true
```

A escolha fica em [lib/injecao.dart](lib/injecao.dart) (`usarApiReal`); na integração final basta trocar o `defaultValue` para `true`. Com a API real o app também liga as notificações e a verificação das favoritas a cada 15 minutos (HM-07).

## Camada de dados (Pessoa A)

| Arquivo | O que faz |
|---|---|
| `lib/dados/api/cliente_api.dart` | POST para a API, tempo limite e tradução de todo erro em `FalhaRepositorio` |
| `lib/dados/api/consultas.dart` | Textos fixos das consultas (iguais a `docs/api/*.graphql`) |
| `lib/dados/api/conversor_json.dart` | JSON → modelos, tolerando nulos, números em texto e nomes com espaço |
| `lib/dados/api/datas_api.dart` | Horários de Brasília ↔ fuso do aparelho |
| `lib/dados/estacao_repository_api.dart` | Implementação real do `EstacaoRepository`: memória, cache em disco, chuva de 72 h e favoritos |
| `lib/dados/local/` | Cache da última resposta e preferências (favoritos, últimos níveis) |
| `lib/servicos/` | Notificações locais e verificação periódica (WorkManager) |

Para testar as notificações: rode com `API_REAL=true`, favorite uma estação e aceite a permissão. A verificação roda a cada 15 minutos com internet e só avisa quando o nível de uma favorita **sobe** para atenção ou acima. Tocar na notificação abre o detalhe da estação.

Os testes da camada (`test/dados/`, `test/servicos/`) simulam a API: sem internet, API lenta, 504 em HTML, corpo vazio, consulta recusada, estação inexistente, período inválido e limite de requisições.

## Fluxo de trabalho

- `dados`: branch da Pessoa A (integração com a API, cache, favoritos, notificações)
- `telas`: branch da Pessoa B (telas, mapa, gráficos, filtros, identidade visual)
- `main`: só recebe pull request revisado pela outra pessoa

Antes de abrir um PR, `dart analyze` e `flutter test` precisam passar. Mudanças em `lib/dominio/` (modelos e `EstacaoRepository`) só depois de avisar a dupla.
