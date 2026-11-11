# Monitor Hidro RS — App de Monitoramento Hidrometeorológico

App Android (Java) que consulta a API da Defesa Civil RS e mostra nível dos rios, chuva, histórico e alertas indicativos das estações da rede hidrometeorológica. Opção 3 da especificação.

> Os alertas são **indicativos**, não são previsão garantida de enchente e **não substituem** os comunicados da Defesa Civil.

## Requisitos para compilar

- Android Studio (versão recente, com AGP 9.x)
- JDK 17+ (o Android Studio já traz um: *Settings → Build Tools → Gradle → Gradle JDK*)
- Android SDK 37
- Internet na primeira compilação (baixa as bibliotecas)

## Como abrir e rodar

1. Android Studio → **Open** → selecione a pasta do projeto.
2. Espere o *Gradle Sync* terminar.
3. Escolha um emulador ou aparelho (Android 7.0 ou superior) e clique em **Run ▶**.

Na build **debug** aparecem dois ícones:
- **Monitor Hidro RS**: o app (telas da Pessoa B).
- **Diagnóstico Hidro**: ferramenta da Pessoa A para testar a camada de dados com a API real (carregar estações, histórico, favoritar, notificação de teste). Não existe na build de release.

## Mock × API real

As telas pegam o repositório por `RepositoryProvider.get(context)`. Em `data/RepositoryProvider.java`:

```java
public static final boolean USAR_MOCK = true;   // false = API real (semana 4)
```

O mock (`assets/mock/tags_data.json`) tem 8 estações reais com valores ajustados para cobrir todos os níveis, dado atrasado, manutenção e estação sem limiar.

## Testes

Pela linha de comando, na pasta do projeto:

```bash
./gradlew testDebugUnitTest        # Windows: gradlew.bat testDebugUnitTest
```

| Classe | O que testa |
|---|---|
| `NivelAlertaTest` | tabela de níveis de chuva e status do rio |
| `ConversorJsonTest` | conversão de respostas reais da API para os modelos, fusos, nulos |
| `HidroApiClientTest` | falhas com API simulada: sem internet, API lenta, resposta vazia, 503, HTML, limite de requisições, consulta recusada, período inválido |
| `ApiRealIntegracaoTest` | as duas consultas contra a API real e a estação de teste DCRS-00001 (ignorado sem internet) |

Relatório: `app/build/reports/tests/testDebugUnitTest/index.html`.

## Gerar APK e AAB

- **APK de testes:** `./gradlew assembleDebug` → `app/build/outputs/apk/debug/app-debug.apk`
- **AAB para distribuição:** Android Studio → *Build → Generate Signed App Bundle / APK* → Android App Bundle, crie ou escolha uma keystore. Saída em `app/release/`.
  **Não** coloque a keystore nem as senhas no GitHub.

## Testar as notificações (HM-07)

1. Abra **Diagnóstico Hidro**.
2. *Pedir permissão de notificação* → permitir.
3. *Enviar notificação de teste* → a notificação aparece (critério de aceite 3).
4. *Favoritar DCRS-00001* e *Rodar verificação de alertas agora*: o worker consulta a API e notifica se o nível de alguma favorita subiu desde a última verificação. Logcat: tag `VerificacaoAlertas`.

A verificação automática roda a cada 15 minutos (mínimo do Android), só com internet.

## Repositório GitHub (Etapa 0)

```bash
git init
git add .
git commit -m "Etapa 0: estrutura, modelos, contrato do repositório e camada de dados"
git branch -M main
git remote add origin https://github.com/<usuario>/<repositorio>.git
git push -u origin main
git checkout -b pessoa-a    # cada pessoa trabalha na sua branch e abre pull request
```

No GitHub: *Settings → Branches → Add rule* para `main` exigindo pull request com 1 aprovação.

## Documentação

- [docs/ETAPA0_DECISOES.md](docs/ETAPA0_DECISOES.md): decisões, regra dos níveis e estrutura de pastas
- [docs/ENDPOINTS.md](docs/ENDPOINTS.md): endpoints consumidos, parâmetros, exemplos, erros
- [docs/PERMISSOES.md](docs/PERMISSOES.md): permissões do dispositivo e justificativas

## Fonte dos dados

Rede Hidrometeorológica da Defesa Civil do Estado do Rio Grande do Sul. Guia da API: <https://sistemas.defesacivil.rs.gov.br/api-redehidrometeorologica>
