import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../dominio/modelos/nivel_alerta.dart';
import 'verificacao_alertas.dart';

/// Notificações locais do app (HM-07).
///
/// Para a tela de detalhe abrir quando o usuário toca numa notificação, as
/// telas escutam [estacaoTocada] (o valor é o código da estação).
abstract final class Notificacoes {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String canalId = 'alertas_estacoes';
  static const String _canalNome = 'Alertas das estações favoritas';
  static const String _canalDescricao =
      'Avisa quando o nível de uma estação favorita sobe para atenção, alerta ou emergência.';

  /// Ícone pequeno em android/app/src/main/res/drawable/ic_notificacao.xml.
  static const String _icone = 'ic_notificacao';

  /// Código da estação da notificação tocada pelo usuário.
  static final ValueNotifier<String?> estacaoTocada = ValueNotifier(null);

  static bool _iniciado = false;

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Prepara o plugin e cria o canal. Chamar uma vez ao abrir o app (e na
  /// tarefa em segundo plano, que roda em outro isolate).
  static Future<void> inicializar() async {
    if (_iniciado) return;
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings(_icone)),
      onDidReceiveNotificationResponse: (resposta) {
        final codigo = resposta.payload;
        if (codigo != null && codigo.isNotEmpty) estacaoTocada.value = codigo;
      },
    );
    await _android?.createNotificationChannel(const AndroidNotificationChannel(
      canalId,
      _canalNome,
      description: _canalDescricao,
      importance: Importance.high,
    ));
    _iniciado = true;

    // app aberto pelo toque numa notificação
    final abertura = await _plugin.getNotificationAppLaunchDetails();
    final codigo = abertura?.notificationResponse?.payload;
    if ((abertura?.didNotificationLaunchApp ?? false) && codigo != null && codigo.isNotEmpty) {
      estacaoTocada.value = codigo;
    }
  }

  /// Pede a permissão de notificação (diálogo do sistema no Android 13+).
  /// Até o Android 12 já é concedida. Devolve se ficou permitida.
  static Future<bool> pedirPermissao() async {
    final android = _android;
    if (android == null) return false;
    if (await android.areNotificationsEnabled() ?? false) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  static Future<bool> permitidas() async => await _android?.areNotificationsEnabled() ?? false;

  /// Notificação de nível subindo numa favorita.
  static Future<void> avisarSubida(AvisoSubida aviso) async {
    await inicializar();
    final estacao = aviso.estacao;
    final medicao = estacao.medicao;
    final rotulo = _rotulo(aviso.atual, rio: aviso.atual == medicao.alertaRio);
    final partes = <String>[
      if (medicao.alertaRio != null) 'Rio: ${medicao.alertaRio!.rotuloRio}',
      if (medicao.chuva.mm24 != null) 'Chuva 24 h: ${_mm(medicao.chuva.mm24!)}',
      if (medicao.chuva.mm72 != null) '72 h: ${_mm(medicao.chuva.mm72!)}',
    ];
    final antes = aviso.anterior == null ? '' : 'Subiu de ${aviso.anterior!.rotulo} para $rotulo. ';
    await _mostrar(
      id: _id(estacao.codigo),
      titulo: '${estacao.nome}: $rotulo',
      texto: '$antes${partes.join(' · ')}. Alerta indicativo; siga a Defesa Civil (199).',
      codigo: estacao.codigo,
    );
  }

  /// Notificação de teste, para conferir canal e permissão.
  static Future<void> enviarTeste() async {
    await inicializar();
    await _mostrar(
      id: 1,
      titulo: 'Olho no Rio: notificação de teste',
      texto: 'As notificações estão funcionando. Você será avisado quando uma favorita subir de nível.',
    );
  }

  static Future<void> _mostrar({
    required int id,
    required String titulo,
    required String texto,
    String? codigo,
  }) =>
      _plugin.show(
        id: id,
        title: titulo,
        body: texto,
        payload: codigo,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            canalId,
            _canalNome,
            channelDescription: _canalDescricao,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(texto),
          ),
        ),
      );

  static String _rotulo(NivelAlerta nivel, {required bool rio}) => rio ? nivel.rotuloRio : nivel.rotulo;

  static String _mm(double valor) => '${valor.toStringAsFixed(1).replaceAll('.', ',')} mm';

  /// Um id por estação: a notificação nova substitui a anterior da mesma.
  static int _id(String codigo) =>
      1000 + (int.tryParse(codigo.replaceAll(RegExp(r'\D'), '')) ?? codigo.hashCode.abs() % 100000);
}
