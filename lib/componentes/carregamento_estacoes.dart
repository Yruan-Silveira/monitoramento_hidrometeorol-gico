import 'package:flutter/material.dart';

import '../dominio/modelos/estacao.dart';
import '../nucleo/estado/estado_estacoes.dart';
import 'mensagem_falha.dart';

/// Trata o carregamento inicial das estações para as telas: mostra o
/// indicador enquanto não há dados, a mensagem de erro se a primeira busca
/// falhar e, havendo dados, chama [construtor].
class CarregamentoEstacoes extends StatelessWidget {
  const CarregamentoEstacoes({super.key, required this.construtor});

  final Widget Function(BuildContext context, List<Estacao> estacoes) construtor;

  @override
  Widget build(BuildContext context) {
    final estado = EstadoEstacoes.de(context);
    if (estado.leitura == null) {
      if (estado.falha != null && !estado.carregando) {
        return MensagemFalha(falha: estado.falha, aoTentarDeNovo: () => estado.atualizar(forcar: true));
      }
      return const Center(child: CircularProgressIndicator());
    }
    return construtor(context, estado.estacoes);
  }
}
