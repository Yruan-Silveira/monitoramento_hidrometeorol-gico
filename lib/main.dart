import 'package:flutter/material.dart';

import 'dominio/repositorios/estacao_repository.dart';
import 'injecao.dart';
import 'nucleo/tema/tema.dart';
import 'telas/inicio/tela_inicio.dart';

void main() {
  runApp(OlhoNoRioApp(repositorio: criarRepositorio()));
}

class OlhoNoRioApp extends StatelessWidget {
  const OlhoNoRioApp({super.key, required this.repositorio});

  final EstacaoRepository repositorio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Olho no Rio',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      darkTheme: TemaApp.escuro,
      home: TelaInicio(repositorio: repositorio),
    );
  }
}
