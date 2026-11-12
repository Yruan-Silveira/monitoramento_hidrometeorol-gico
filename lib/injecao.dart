import 'dart:async';

import 'package:flutter/widgets.dart';

import 'dados/estacao_repository_api.dart';
import 'dados/mock/estacao_repository_mock.dart';
import 'dominio/repositorios/estacao_repository.dart';
import 'servicos/notificacoes.dart';
import 'servicos/tarefa_periodica.dart';

/// `true` = API real da Defesa Civil; `false` = dados de exemplo (mock).
///
/// Padrão: mock, até a integração da semana 4. Para rodar com a API real sem
/// mudar o código:
///
/// ```
/// flutter run --dart-define=API_REAL=true
/// ```
///
/// Na integração, troque o `defaultValue` para `true`.
const bool usarApiReal = bool.fromEnvironment('API_REAL', defaultValue: false);

/// Único ponto onde se escolhe a implementação do repositório.
///
/// Com a API real, também liga as notificações e a verificação periódica das
/// favoritas (HM-07); a permissão de notificação é pedida quando o usuário
/// marca uma favorita. As telas não sabem qual implementação estão usando.
EstacaoRepository criarRepositorio() {
  if (!usarApiReal) return EstacaoRepositoryMock();
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(inicializarServicos());
  return EstacaoRepositoryApi(aoFavoritar: () async {
    await Notificacoes.pedirPermissao();
  });
}

/// Código da estação cuja notificação o usuário tocou (HM-07). O `main.dart`
/// escuta, abre o detalhe e volta o valor para `null`. Com o mock nunca muda.
ValueNotifier<String?> get estacaoTocadaNaNotificacao => Notificacoes.estacaoTocada;
