import 'package:flutter/material.dart';

import '../dominio/modelos/estacao.dart';
import '../nucleo/formatacao.dart';

/// Texto curto sobre o dado da estação quando ele não está atual (HM-09).
/// `null` quando o dado está em dia.
String? textoSituacao(Estacao estacao, DateTime agora) {
  final horario = estacao.medicao.horario;
  return switch (estacao.situacao(agora)) {
    SituacaoDado.atual => null,
    SituacaoDado.atrasado => 'Dado atrasado: última leitura ${Formatar.tempoDesde(horario!, agora)}',
    SituacaoDado.ausente => 'Estação sem leitura recente',
    SituacaoDado.manutencao => 'Estação em manutenção',
  };
}

/// Faixa de aviso para dado atrasado, ausente ou estação em manutenção.
/// Não ocupa espaço quando o dado está em dia.
class AvisoSituacao extends StatelessWidget {
  const AvisoSituacao({super.key, required this.estacao});

  final Estacao estacao;

  @override
  Widget build(BuildContext context) {
    final texto = textoSituacao(estacao, DateTime.now());
    if (texto == null) return const SizedBox.shrink();
    final esquema = Theme.of(context).colorScheme;
    final icone = estacao.emManutencao ? Icons.build : Icons.schedule;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: esquema.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icone, size: 20, color: esquema.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: TextStyle(color: esquema.onTertiaryContainer))),
        ],
      ),
    );
  }
}
