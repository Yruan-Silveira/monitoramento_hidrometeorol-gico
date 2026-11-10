import 'package:flutter/material.dart';

import '../../componentes/selo_nivel.dart';
import '../../dominio/modelos/estacao.dart';
import '../../dominio/modelos/nivel_alerta.dart';
import '../../dominio/repositorios/estacao_repository.dart';

/// Tela inicial (HM-01): resumo por nível e lista das estações, da mais
/// grave para a menos grave.
///
/// Versão de partida da Etapa 0: prova que o contrato funciona de ponta a
/// ponta. Favoritos, busca, navegação para o detalhe e acabamento ficam para
/// as próximas semanas.
class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key, required this.repositorio});

  final EstacaoRepository repositorio;

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  late Future<LeituraEstacoes> _leitura = widget.repositorio.listarEstacoes();

  Future<void> _atualizar() async {
    final nova = widget.repositorio.listarEstacoes(forcarAtualizacao: true);
    setState(() => _leitura = nova);
    try {
      await nova;
    } on FalhaRepositorio {
      // O FutureBuilder mostra o erro.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Olho no Rio')),
      body: FutureBuilder<LeituraEstacoes>(
        future: _leitura,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final leitura = snapshot.data;
          if (leitura == null) {
            return _Erro(falha: snapshot.error, aoTentarDeNovo: _atualizar);
          }
          return RefreshIndicator(
            onRefresh: _atualizar,
            child: _Conteudo(leitura: leitura),
          );
        },
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.leitura});

  final LeituraEstacoes leitura;

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final estacoes = [...leitura.estacoes]..sort(_maisGravePrimeiro);
    final hora = TimeOfDay.fromDateTime(leitura.atualizadoEm).format(context);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final nivel in NivelAlerta.values.reversed)
                SeloNivel(
                  nivel,
                  rotulo: '${estacoes.where((e) => e.alerta == nivel).length} ${nivel.rotulo}',
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            leitura.doCache ? 'Sem conexão. Dados salvos às $hora' : 'Atualizado às $hora',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        for (final estacao in estacoes) _ItemEstacao(estacao: estacao, agora: agora),
      ],
    );
  }

  static int _maisGravePrimeiro(Estacao a, Estacao b) {
    final porNivel = (b.alerta?.index ?? -1).compareTo(a.alerta?.index ?? -1);
    return porNivel != 0 ? porNivel : a.nome.compareTo(b.nome);
  }
}

class _ItemEstacao extends StatelessWidget {
  const _ItemEstacao({required this.estacao, required this.agora});

  final Estacao estacao;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final medicao = estacao.medicao;
    final situacao = switch (estacao.situacao(agora)) {
      SituacaoDado.atual => null,
      SituacaoDado.atrasado => 'Dado atrasado',
      SituacaoDado.ausente => 'Sem leitura',
      SituacaoDado.manutencao => 'Em manutenção',
    };
    final partes = [
      if (medicao.nivelRio != null) 'Rio ${_numero(medicao.nivelRio!)} m',
      if (medicao.chuva.mm24 != null) 'Chuva 24 h ${_numero(medicao.chuva.mm24!)} mm',
      ?situacao,
    ];

    return ListTile(
      title: Text(estacao.nome),
      subtitle: Text(partes.isEmpty ? estacao.codigo : partes.join(' · ')),
      trailing: SeloNivel(estacao.alerta),
    );
  }

  static String _numero(double valor) => valor.toStringAsFixed(valor % 1 == 0 ? 0 : 2).replaceAll('.', ',');
}

class _Erro extends StatelessWidget {
  const _Erro({required this.falha, required this.aoTentarDeNovo});

  final Object? falha;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final tipo = falha is FalhaRepositorio ? (falha! as FalhaRepositorio).tipo : null;
    final mensagem = switch (tipo) {
      TipoFalha.semConexao => 'Sem conexão com a internet.',
      TipoFalha.tempoEsgotado => 'O serviço demorou demais para responder.',
      TipoFalha.limiteExcedido => 'Muitas consultas seguidas. Aguarde um minuto.',
      _ => 'O serviço de dados está indisponível no momento.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: aoTentarDeNovo, child: const Text('Tentar de novo')),
          ],
        ),
      ),
    );
  }
}
