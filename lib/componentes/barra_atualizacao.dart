import 'package:flutter/material.dart';

import '../nucleo/estado/estado_estacoes.dart';
import '../nucleo/formatacao.dart';
import 'mensagem_falha.dart';

/// Linha "Atualizado às HH:MM" (HM-09). Quando a última atualização falhou,
/// avisa que os dados mostrados são antigos e oferece tentar de novo.
class BarraAtualizacao extends StatelessWidget {
  const BarraAtualizacao({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = EstadoEstacoes.de(context);
    final leitura = estado.leitura;
    if (leitura == null) return const SizedBox.shrink();

    final esquema = Theme.of(context).colorScheme;
    final hora = Formatar.hora(leitura.atualizadoEm);
    final falha = estado.falha;

    if (falha != null || leitura.doCache) {
      return Material(
        color: esquema.errorContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 18, color: esquema.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${falha == null ? 'Sem conexão.' : textoFalha(falha.tipo)} '
                  'Mostrando dados das $hora.',
                  style: TextStyle(color: esquema.onErrorContainer),
                ),
              ),
              TextButton(
                onPressed: estado.carregando ? null : () => estado.atualizar(forcar: true),
                child: const Text('Tentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(Icons.update, size: 16, color: esquema.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              estado.carregando ? 'Atualizando…' : 'Atualizado às $hora',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: esquema.outline),
            ),
          ),
        ],
      ),
    );
  }
}
