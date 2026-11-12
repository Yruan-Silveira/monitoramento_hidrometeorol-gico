# Permissões do dispositivo

Declaradas em `android/app/src/main/AndroidManifest.xml`. Os plugins acrescentam as deles na fusão do manifesto (o WorkManager traz `ACCESS_NETWORK_STATE` e `WAKE_LOCK`).

| Permissão | Tipo | Pedida ao usuário? | Para que serve |
|---|---|---|---|
| `INTERNET` | normal | Não (concedida na instalação) | Consultar a API da Defesa Civil RS por HTTPS. Sem ela o app não tem dados. |
| `POST_NOTIFICATIONS` | perigosa (Android 13+) | **Sim**, diálogo do sistema | Avisar quando o nível de uma estação favorita sobe (HM-07). Até o Android 12 já vem concedida. |
| `RECEIVE_BOOT_COMPLETED` | normal | Não | O WorkManager reagenda a verificação das favoritas depois que o aparelho reinicia. |
| `ACCESS_NETWORK_STATE` | normal (via WorkManager) | Não | A verificação em segundo plano só roda com internet, para não gastar bateria à toa. |

## Quando a permissão de notificação é pedida

Em contexto: quando o usuário marca uma estação como favorita, e não logo ao abrir o app. Isso está em `lib/injecao.dart` (`aoFavoritar` do `EstacaoRepositoryApi`), então as telas não precisam saber de permissão.

Se o usuário negar, o app continua funcionando; apenas não envia notificações.

## O que o app não usa

- **Localização:** o mapa posiciona as estações pelas coordenadas da API; não precisa saber onde o usuário está.
- **Câmera, armazenamento externo, contatos:** não usados.
- **HTTP sem criptografia:** o Android bloqueia por padrão (target 28+) e toda comunicação com a API é HTTPS.

## Dados guardados no aparelho

Todos na área privada do app (outros apps não acessam) e apagados ao desinstalar:

- `cache_tags_data.json` (pasta de suporte do app): última resposta da API, para abrir sem internet (HM-09).
- SharedPreferences `favoritos`: códigos das estações favoritas (HM-05).
- SharedPreferences `ultimos_niveis`: último nível visto de cada favorita, para só notificar quando sobe e não repetir (HM-07).

Nenhum dado pessoal do usuário é coletado ou enviado.
