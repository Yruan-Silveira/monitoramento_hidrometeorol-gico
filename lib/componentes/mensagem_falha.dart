import 'package:flutter/material.dart';

import '../dominio/repositorios/estacao_repository.dart';

/// Texto para o usuário de cada tipo de falha (HM-09).
String textoFalha(TipoFalha? tipo) => switch (tipo) {
      TipoFalha.semConexao => 'Sem conexão com a internet.',
      TipoFalha.tempoEsgotado => 'O serviço de dados demorou demais para responder.',
      TipoFalha.limiteExcedido => 'Muitas consultas seguidas. Aguarde um minuto e tente de novo.',
      TipoFalha.naoEncontrado => 'Estação não encontrada.',
      TipoFalha.periodoInvalido => 'O histórico só cobre os últimos 3 meses.',
      TipoFalha.respostaInvalida => 'O serviço de dados respondeu de forma inesperada.',
      TipoFalha.servicoIndisponivel || null => 'O serviço de dados está indisponível no momento.',
    };

IconData _iconeFalha(TipoFalha? tipo) => switch (tipo) {
      TipoFalha.semConexao => Icons.wifi_off,
      TipoFalha.tempoEsgotado => Icons.hourglass_empty,
      TipoFalha.naoEncontrado => Icons.search_off,
      _ => Icons.cloud_off,
    };

/// Mensagem de erro de tela inteira, com botão para tentar de novo.
class MensagemFalha extends StatelessWidget {
  const MensagemFalha({super.key, required this.falha, this.aoTentarDeNovo});

  final Object? falha;
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final tipo = falha is FalhaRepositorio ? (falha! as FalhaRepositorio).tipo : null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconeFalha(tipo), size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(textoFalha(tipo), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
            if (aoTentarDeNovo != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: aoTentarDeNovo,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mensagem simples para listas vazias.
class MensagemVazia extends StatelessWidget {
  const MensagemVazia({super.key, required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final cor = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Icon(icone, color: cor),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: TextStyle(color: cor))),
        ],
      ),
    );
  }
}
