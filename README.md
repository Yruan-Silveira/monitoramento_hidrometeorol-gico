# Olho no Rio

App Android em Flutter que consulta a Rede Hidrometeorológica da Defesa Civil RS e mostra o nível dos rios, a chuva, o histórico e os alertas das estações. Trabalho de Dispositivos Móveis, Opção 3.

Os alertas do app são indicativos. Não são previsão garantida de enchente e não substituem os comunicados oficiais da Defesa Civil.

## Documentação

- [docs/etapa-0.md](docs/etapa-0.md): decisões da dupla, estrutura de pastas, contrato, identidade visual e pendências
- [docs/api.md](docs/api.md): o que a API entrega, campos, erros e limitações

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

Hoje o app roda com dados de exemplo (`EstacaoRepositoryMock`). A troca para a API real é feita em [lib/injecao.dart](lib/injecao.dart).

## Fluxo de trabalho

- `dados`: branch da Pessoa A (integração com a API, cache, favoritos, notificações)
- `telas`: branch da Pessoa B (telas, mapa, gráficos, filtros, identidade visual)
- `main`: só recebe pull request revisado pela outra pessoa

Antes de abrir um PR, `dart analyze` e `flutter test` precisam passar. Mudanças em `lib/dominio/` (modelos e `EstacaoRepository`) só depois de avisar a dupla.
