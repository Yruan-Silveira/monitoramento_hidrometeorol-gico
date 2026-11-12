import 'package:flutter/material.dart';

import '../../componentes/barra_atualizacao.dart';
import '../../componentes/carregamento_estacoes.dart';
import '../../componentes/item_estacao.dart';
import '../../componentes/mensagem_falha.dart';
import '../../dominio/modelos/estacao.dart';
import '../../dominio/modelos/nivel_alerta.dart';
import '../../nucleo/estado/estado_estacoes.dart';
import '../../nucleo/tema/cores.dart';

/// Tela inicial (HM-01): resumo da rede por nível, as estações favoritas e
/// as estações em atenção ou pior.
class TelaInicio extends StatelessWidget {
  const TelaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    final estado = EstadoEstacoes.de(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Olho no Rio'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: estado.carregando ? null : () => estado.atualizar(forcar: true),
          ),
        ],
      ),
      body: CarregamentoEstacoes(
        construtor: (context, estacoes) => RefreshIndicator(
          onRefresh: () => estado.atualizar(forcar: true),
          child: _Conteudo(estacoes: estacoes, favoritas: estado.favoritas),
        ),
      ),
    );
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({required this.estacoes, required this.favoritas});

  final List<Estacao> estacoes;
  final List<Estacao> favoritas;

  @override
  Widget build(BuildContext context) {
    final emAlerta = estacoes.where((e) => (e.alerta?.index ?? -1) >= NivelAlerta.atencao.index).toList()
      ..sort(ordenarPorGravidade);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        const BarraAtualizacao(),
        _ResumoRede(estacoes: estacoes),
        const _Titulo(icone: Icons.star, texto: 'Minhas estações'),
        if (favoritas.isEmpty)
          const MensagemVazia(
            icone: Icons.star_border,
            texto: 'Toque na estrela de uma estação para acompanhá-la aqui.',
          )
        else
          for (final estacao in [...favoritas]..sort(ordenarPorGravidade)) ItemEstacao(estacao: estacao),
        const _Titulo(icone: Icons.warning_amber, texto: 'Em atenção, alerta ou emergência'),
        if (emAlerta.isEmpty)
          const MensagemVazia(
            icone: Icons.check_circle_outline,
            texto: 'Nenhuma estação acima do nível normal agora.',
          )
        else
          for (final estacao in emAlerta) ItemEstacao(estacao: estacao),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Text(
            'Alertas indicativos. Não substituem os comunicados da Defesa Civil. '
            'Em emergência, ligue 199.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Mais grave primeiro; empate por nome.
int ordenarPorGravidade(Estacao a, Estacao b) {
  final porNivel = (b.alerta?.index ?? -1).compareTo(a.alerta?.index ?? -1);
  return porNivel != 0 ? porNivel : a.nome.compareTo(b.nome);
}

/// Quantas estações há em cada nível.
class _ResumoRede extends StatelessWidget {
  const _ResumoRede({required this.estacoes});

  final List<Estacao> estacoes;

  @override
  Widget build(BuildContext context) {
    final niveis = <NivelAlerta?>[...NivelAlerta.values.reversed, null];
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${estacoes.length} estações monitoradas', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final nivel in niveis)
                  Expanded(
                    child: _Contador(
                      nivel: nivel,
                      quantidade: estacoes.where((e) => e.alerta == nivel).length,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Contador extends StatelessWidget {
  const _Contador({required this.nivel, required this.quantidade});

  final NivelAlerta? nivel;
  final int quantidade;

  @override
  Widget build(BuildContext context) {
    final rotulo = nivel?.rotulo ?? 'Sem dado';
    return Semantics(
      label: '$quantidade $rotulo',
      excludeSemantics: true,
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: CoresApp.doNivel(nivel),
            foregroundColor: CoresApp.sobreNivel(nivel),
            child: Text('$quantidade', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(rotulo, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icone, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: Theme.of(context).textTheme.titleMedium)),
        ],
      ),
    );
  }
}
