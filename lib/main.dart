import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'dominio/repositorios/estacao_repository.dart';
import 'injecao.dart';
import 'nucleo/estado/estado_estacoes.dart';
import 'nucleo/tema/tema.dart';
import 'telas/principal/tela_principal.dart';

void main() {
  runApp(OlhoNoRioApp(repositorio: criarRepositorio()));
}

class OlhoNoRioApp extends StatefulWidget {
  const OlhoNoRioApp({
    super.key,
    required this.repositorio,
    this.mostrarMapaBase = true,
    this.atualizacaoAutomatica = const Duration(minutes: 5),
  });

  final EstacaoRepository repositorio;

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

  @override
  void dispose() {
    _estado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
