import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../dados/estacao_repository_api.dart';
import '../dominio/repositorios/estacao_repository.dart';
import 'notificacoes.dart';
import 'verificacao_alertas.dart';

/// Nome da tarefa periódica que verifica as favoritas.
const String tarefaVerificarAlertas = 'verificar-alertas-favoritas';

/// Ponto de entrada da tarefa em segundo plano. Roda num isolate separado,
/// mesmo com o app fechado. Precisa ser função de topo com
/// `vm:entry-point` para o compilador não removê-la.
@pragma('vm:entry-point')
void despacharTarefas() {
  Workmanager().executeTask((tarefa, dados) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Notificacoes.inicializar();
      await VerificadorAlertas(
        repositorio: EstacaoRepositoryApi(),
        notificar: Notificacoes.avisarSubida,
      ).verificar();
    } on FalhaRepositorio catch (falha) {
      // sem rede ou API fora: tenta de novo na próxima janela de 15 min
      debugPrint('Tarefa $tarefa: $falha');
    } catch (e, pilha) {
      debugPrint('Tarefa $tarefa falhou: $e\n$pilha');
      return false; // o WorkManager tenta de novo com espera crescente
    }
    return true;
  });
}

/// Agenda a verificação a cada 15 minutos (mínimo do Android), só com
/// internet. Se já estiver agendada, mantém a existente.
Future<void> agendarVerificacaoPeriodica() async {
  await Workmanager().initialize(despacharTarefas);
  await Workmanager().registerPeriodicTask(
    tarefaVerificarAlertas,
    tarefaVerificarAlertas,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

Future<void> cancelarVerificacaoPeriodica() => Workmanager().cancelByUniqueName(tarefaVerificarAlertas);

/// Liga notificações e a verificação periódica. Chamado no `main`.
/// No Android apenas; em outras plataformas não faz nada. Falhas aqui não
/// impedem o app de abrir.
Future<void> inicializarServicos() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    await Notificacoes.inicializar();
    await agendarVerificacaoPeriodica();
  } catch (e) {
    debugPrint('inicializarServicos: $e');
  }
}
