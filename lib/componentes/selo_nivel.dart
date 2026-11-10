import 'package:flutter/material.dart';

import '../dominio/modelos/nivel_alerta.dart';
import '../nucleo/tema/cores.dart';

/// Etiqueta de nível de alerta: cor, ícone e rótulo juntos.
class SeloNivel extends StatelessWidget {
  const SeloNivel(this.nivel, {super.key, this.rotulo});

  /// `null` = sem dado.
  final NivelAlerta? nivel;

  /// Substitui o rótulo padrão (ex.: "Inundação" quando o nível vem do rio).
  final String? rotulo;

  @override
  Widget build(BuildContext context) {
    final corTexto = CoresApp.sobreNivel(nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CoresApp.doNivel(nivel),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CoresApp.iconeDoNivel(nivel), size: 16, color: corTexto),
          const SizedBox(width: 4),
          Text(
            rotulo ?? nivel?.rotulo ?? 'Sem dado',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: corTexto, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
