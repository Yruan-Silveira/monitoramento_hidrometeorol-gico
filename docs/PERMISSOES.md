# Permissões do dispositivo

Declaradas em `app/src/main/AndroidManifest.xml`.

| Permissão | Tipo | Pedida ao usuário? | Para que serve |
|---|---|---|---|
| `INTERNET` | normal | Não (concedida na instalação) | Consultar a API da Defesa Civil RS por HTTPS (níveis, chuva, histórico). Sem ela o app não tem dados. |
| `ACCESS_NETWORK_STATE` | normal | Não | Permite ao WorkManager só rodar a verificação de alertas quando há conexão, economizando bateria. |
| `POST_NOTIFICATIONS` | perigosa (Android 13+) | **Sim**, diálogo do sistema | Mostrar notificações locais quando o nível de uma estação favorita sobe (HM-07). Até o Android 12 é concedida automaticamente. |

## Quando a permissão de notificação é pedida

O diálogo deve aparecer **em contexto**, por exemplo quando o usuário favorita a primeira estação, e não logo ao abrir o app. Código pronto em `notificacao/PermissaoNotificacao.java`:

```java
// onCreate da Activity
ActivityResultLauncher<String> pedido = PermissaoNotificacao.registrar(this);
// ao favoritar
PermissaoNotificacao.pedirSeNecessario(this, pedido);
```

Se o usuário negar, o app continua funcionando normalmente; apenas não envia notificações (`NotificacaoHelper.podeNotificar()` devolve `false`).

## O que o app NÃO usa

- **Localização**: o mapa mostra as estações pelas coordenadas da API; não é preciso saber onde o usuário está.
- **Câmera, armazenamento externo, contatos**: não usados.
- **Tráfego HTTP sem criptografia**: bloqueado (`usesCleartextTraffic="false"`); toda comunicação é HTTPS.

## Dados guardados no aparelho

Todos na área privada do app (outros apps não acessam), apagados ao desinstalar:

- `files/cache_tags_data.json`: última resposta da API, para abrir sem internet (HM-09).
- SharedPreferences `favoritos`: códigos das estações favoritas (HM-05).
- SharedPreferences `ultimos_niveis`: último nível notificado por favorita, para não repetir notificação (HM-07).

Nenhum dado pessoal do usuário é coletado ou enviado.
