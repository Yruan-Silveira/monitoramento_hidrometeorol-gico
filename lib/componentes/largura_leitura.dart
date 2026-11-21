import 'package:flutter/material.dart';

/// Limita a largura do conteúdo e o centraliza em telas largas (tablet,
/// celular deitado). Sem isso, num tablet o rótulo fica a 700 dp do valor e
/// as linhas de texto ficam longas demais para ler (docs/usabilidade.md).
///
/// Em celulares em pé não muda nada.
class LarguraLeitura extends StatelessWidget {
  const LarguraLeitura({super.key, required this.child});

  static const double maxima = 640;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxima),
        child: child,
      ),
    );
  }
}
