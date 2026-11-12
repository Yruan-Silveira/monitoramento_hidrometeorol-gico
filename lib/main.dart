import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dominio/repositorios/estacao_repository.dart';
import 'injecao.dart';
import 'nucleo/estado/estado_estacoes.dart';
import 'nucleo/tema/tema.dart';
import 'telas/detalhe/tela_detalhe.dart';
import 'telas/principal/tela_principal.dart';

void main() {
  runApp(OlhoNoRioApp(
    repositorio: criarRepositorio(),
    estacaoTocada: estacaoTocadaNaNotificacao,
  ));
}

class OlhoNoRioApp extends StatefulWidget {
  const OlhoNoRioApp({
    super.key,
    required this.repositorio,
    this.mostrarMapaBase = true,
    this.atualizacaoAutomatica = const Duration(minutes: 5),
    this.estacaoTocada,
  });

  final EstacaoRepository repositorio;

  /// Código da estação cuja notificação foi tocada: abre o detalhe dela.
  /// `null` nos testes.
  final ValueNotifier<String?>? estacaoTocada;

  /// Nos testes fica desligado: não há internet para baixar o mapa.
  final bool mostrarMapaBase;

  /// Intervalo da atualização automática; `null` desliga (usado nos testes).
  final Duration? atualizacaoAutomatica;

  @override
  State<OlhoNoRioApp> createState() => _OlhoNoRioAppState();
}

class _OlhoNoRioAppState extends State<OlhoNoRioApp> {
  late final EstadoEstacoes _estado =
      EstadoEstacoes(widget.repositorio, intervaloAtualizacao: widget.atualizacaoAutomatica)..iniciar();

  final _navegador = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.estacaoTocada?.addListener(_abrirEstacaoTocada);
    // app aberto pelo toque numa notificação: o valor pode já ter chegado
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrirEstacaoTocada());
  }

  void _abrirEstacaoTocada() {
    final notificador = widget.estacaoTocada;
    final codigo = notificador?.value;
    final navegador = _navegador.currentState;
    if (notificador == null || codigo == null || navegador == null) return;
    notificador.value = null;
    navegador.push(MaterialPageRoute<void>(builder: (_) => TelaDetalhe(codigo: codigo)));
  }

  @override
  void dispose() {
    widget.estacaoTocada?.removeListener(_abrirEstacaoTocada);
    _estado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navegador,
      title: 'Olho no Rio',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      darkTheme: TemaApp.escuro,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Acima do Navigator, para as telas abertas por push também enxergarem o estado.
      builder: (context, filho) => EscopoEstacoes(estado: _estado, child: filho!),
      home: TelaPrincipal(mostrarMapaBase: widget.mostrarMapaBase),
    );
  }
}
