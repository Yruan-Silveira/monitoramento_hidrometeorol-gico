import 'package:flutter/material.dart';

import '../../componentes/mensagem_falha.dart';
import '../../componentes/selo_nivel.dart';
import '../../componentes/situacao_dado.dart';
import '../../dominio/modelos/estacao.dart';
import '../../dominio/modelos/medicao.dart';
import '../../dominio/modelos/serie_historica.dart';
import '../../dominio/modelos/variavel.dart';
import '../../dominio/regras/classificacao_chuva.dart';
import '../../dominio/repositorios/estacao_repository.dart';
import '../../nucleo/estado/estado_estacoes.dart';
import '../../nucleo/formatacao.dart';
import '../../nucleo/tema/cores.dart';
import '../sobre/tela_sobre.dart';
import 'grafico_serie.dart';

/// Detalhe de uma estação (HM-03): risco, rio, chuva, demais variáveis e
/// gráficos do histórico (HM-04, HM-06, HM-08).
class TelaDetalhe extends StatefulWidget {
  const TelaDetalhe({super.key, required this.codigo});

  final String codigo;

  @override
  State<TelaDetalhe> createState() => _TelaDetalheState();
}

class _TelaDetalheState extends State<TelaDetalhe> {
  Future<Estacao>? _estacao;
  final _series = <PeriodoSerie, Future<SerieHistorica>>{};
  var _periodo = PeriodoSerie.horas24;
  var _variavel = Variavel.nivelRio;

  EstacaoRepository get _repositorio => EstadoEstacoes.de(context).repositorio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _estacao ??= _repositorio.buscarEstacao(widget.codigo);
  }

  Future<void> _recarregar() async {
    final nova = _repositorio.buscarEstacao(widget.codigo);
    setState(() {
      _estacao = nova;
      _series.clear();
    });
    try {
      await nova;
    } on FalhaRepositorio {
      // O FutureBuilder mostra o erro.
    }
  }

  Future<SerieHistorica> _serie(PeriodoSerie periodo) => _series.putIfAbsent(periodo, () {
        final agora = DateTime.now();
        return _repositorio.buscarSerie(
          widget.codigo,
          inicio: agora.subtract(periodo.duracao),
          fim: agora,
          intervalo: periodo.intervalo,
        );
      });

  @override
  Widget build(BuildContext context) {
    final estado = EstadoEstacoes.de(context);
    final daLista = estado.estacao(widget.codigo);
    final favorita = estado.ehFavorita(widget.codigo);

    return Scaffold(
      appBar: AppBar(
        title: Text(daLista?.nome ?? widget.codigo),
        actions: [
          IconButton(
            tooltip: favorita ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
            icon: Icon(favorita ? Icons.star : Icons.star_border),
            onPressed: () => estado.alternarFavorito(widget.codigo),
          ),
        ],
      ),
      body: FutureBuilder<Estacao>(
        future: _estacao,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final estacao = snapshot.data;
          if (estacao == null) {
            return MensagemFalha(falha: snapshot.error, aoTentarDeNovo: _recarregar);
          }
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _Cabecalho(estacao: estacao),
                const SizedBox(height: 12),
                _CartaoRisco(medicao: estacao.medicao),
                _CartaoRio(medicao: estacao.medicao),
                _CartaoChuva(medicao: estacao.medicao),
                _CartaoTempo(medicao: estacao.medicao),
                _CartaoHistorico(
                  periodo: _periodo,
                  variavel: _variavel,
                  serie: _serie(_periodo),
                  aoMudarPeriodo: (p) => setState(() => _periodo = p),
                  aoMudarVariavel: (v) => setState(() => _variavel = v),
                  aoTentarDeNovo: () => setState(() => _series.remove(_periodo)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.estacao});

  final Estacao estacao;

  @override
  Widget build(BuildContext context) {
    final horario = estacao.medicao.horario;
    final estilo = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // O nome já está na barra do topo.
        Text([estacao.codigo, ?estacao.regiao].join(' · '), style: estilo.bodyMedium),
        if (estacao.bacia != null) Text('Bacia: ${estacao.bacia}', style: estilo.bodySmall),
        if (estacao.coordenadoria != null) Text('Coordenadoria: ${estacao.coordenadoria}', style: estilo.bodySmall),
        const SizedBox(height: 8),
        Text(
          horario == null ? 'Sem leitura recente' : 'Leitura de ${Formatar.diaHora(horario)}',
          style: estilo.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        AvisoSituacao(estacao: estacao),
      ],
    );
  }
}

/// Indicativo de risco de alagamento (HM-08): o mais grave entre rio e chuva.
class _CartaoRisco extends StatelessWidget {
  const _CartaoRisco({required this.medicao});

  final Medicao medicao;

  @override
  Widget build(BuildContext context) {
    final nivel = medicao.alertaGeral;
    return Card(
      color: CoresApp.doNivel(nivel),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: CoresApp.sobreNivel(nivel)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Risco de alagamento (indicativo)'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(CoresApp.iconeDoNivel(nivel), color: CoresApp.sobreNivel(nivel), size: 32),
                  const SizedBox(width: 8),
                  Text(
                    nivel?.rotulo ?? 'Sem dado',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: CoresApp.sobreNivel(nivel),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Rio: ${medicao.alertaRio?.rotuloRio ?? 'sem dado'} · '
                'Chuva: ${medicao.alertaChuva?.rotulo ?? 'sem dado'}',
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: CoresApp.sobreNivel(nivel)),
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute<void>(builder: (_) => const TelaSobre(comVoltar: true))),
                  child: const Text('Como é calculado?'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartaoRio extends StatelessWidget {
  const _CartaoRio({required this.medicao});

  final Medicao medicao;

  @override
  Widget build(BuildContext context) {
    final variacao = medicao.variacaoNivelRio;
    final String situacao;
    if (!medicao.temLimiarRio) {
      situacao = 'Estação sem cota de inundação cadastrada pela Defesa Civil.';
    } else if (medicao.alertaRio == null) {
      situacao = 'Sem leitura recente do nível.';
    } else {
      situacao = 'Situação calculada pela Defesa Civil a partir das cotas de inundação da estação.';
    }

    return _Cartao(
      icone: Icons.water,
      titulo: 'Rio',
      acao: medicao.temLimiarRio && medicao.alertaRio != null
          ? SeloNivel(medicao.alertaRio, rotulo: medicao.alertaRio!.rotuloRio)
          : null,
      filhos: [
        _Linha('Nível', Formatar.variavel(Variavel.nivelRio, medicao.nivelRio)),
        _Linha(
          'Tendência (última hora)',
          variacao == null
              ? '—'
              : variacao.abs() < 0.005
                  ? 'Estável'
                  : '${variacao > 0 ? 'Subindo' : 'Descendo'} ${Formatar.numero(variacao.abs(), casas: 2)} m',
          icone: variacao == null || variacao.abs() < 0.005
              ? null
              : (variacao > 0 ? Icons.arrow_upward : Icons.arrow_downward),
        ),
        const SizedBox(height: 4),
        Text(situacao, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CartaoChuva extends StatelessWidget {
  const _CartaoChuva({required this.medicao});

  final Medicao medicao;

  @override
  Widget build(BuildContext context) {
    final chuva = medicao.chuva;
    String mm(double? v) => Formatar.variavel(Variavel.chuva, v);
    return _Cartao(
      icone: Icons.water_drop,
      titulo: 'Chuva acumulada',
      acao: SeloNivel(medicao.alertaChuva),
      filhos: [
        _Linha('Última hora', mm(chuva.mm1h)),
        _Linha('3 horas', mm(chuva.mm3h)),
        _Linha('12 horas', mm(chuva.mm12h)),
        _Linha('24 horas', mm(chuva.mm24), destaque: true),
        _Linha('48 horas', mm(chuva.mm48), destaque: true),
        _Linha('72 horas', mm(chuva.mm72), destaque: true),
        _Linha('7 dias', mm(chuva.mm7dias)),
        const SizedBox(height: 4),
        Text(
          'O nível da chuva usa os acumulados de 24, 48 e 72 horas (em destaque).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Demais variáveis disponíveis na estação. Esconde as que não têm leitura.
class _CartaoTempo extends StatelessWidget {
  const _CartaoTempo({required this.medicao});

  final Medicao medicao;

  static const _variaveis = [
    Variavel.temperatura,
    Variavel.sensacaoTermica,
    Variavel.umidade,
    Variavel.pressao,
    Variavel.ventoVelocidadeMedia,
    Variavel.ventoVelocidadeMaxima,
    Variavel.ventoDirecao,
    Variavel.radiacaoSolar,
  ];

  @override
  Widget build(BuildContext context) {
    final disponiveis = [for (final v in _variaveis) if (medicao.valor(v) != null) v];
    if (disponiveis.isEmpty) return const SizedBox.shrink();
    return _Cartao(
      icone: Icons.thermostat,
      titulo: 'Condições do tempo',
      filhos: [for (final v in disponiveis) _Linha(v.rotulo, Formatar.variavel(v, medicao.valor(v)))],
    );
  }
}

class _CartaoHistorico extends StatelessWidget {
  const _CartaoHistorico({
    required this.periodo,
    required this.variavel,
    required this.serie,
    required this.aoMudarPeriodo,
    required this.aoMudarVariavel,
    required this.aoTentarDeNovo,
  });

  final PeriodoSerie periodo;
  final Variavel variavel;
  final Future<SerieHistorica> serie;
  final ValueChanged<PeriodoSerie> aoMudarPeriodo;
  final ValueChanged<Variavel> aoMudarVariavel;
  final VoidCallback aoTentarDeNovo;

  static const _variaveis = [
    Variavel.nivelRio,
    Variavel.chuva,
    Variavel.temperatura,
    Variavel.umidade,
    Variavel.pressao,
    Variavel.ventoVelocidadeMedia,
  ];

  @override
  Widget build(BuildContext context) {
    return _Cartao(
      icone: Icons.show_chart,
      titulo: 'Histórico',
      filhos: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<PeriodoSerie>(
            segments: [
              for (final p in PeriodoSerie.values) ButtonSegment(value: p, label: Text(p.rotulo)),
            ],
            selected: {periodo},
            showSelectedIcon: false,
            onSelectionChanged: (s) => aoMudarPeriodo(s.first),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 0,
          children: [
            for (final v in _variaveis)
              ChoiceChip(
                label: Text(v == Variavel.ventoVelocidadeMedia ? 'Vento' : v.rotulo),
                selected: v == variavel,
                onSelected: (_) => aoMudarVariavel(v),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<SerieHistorica>(
          future: serie,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
            }
            final dados = snapshot.data;
            if (dados == null) {
              return SizedBox(
                height: 220,
                child: MensagemFalha(falha: snapshot.error, aoTentarDeNovo: aoTentarDeNovo),
              );
            }
            if (dados.vazia) {
              return const SizedBox(height: 120, child: Center(child: Text('Sem registros no período.')));
            }
            return GraficoSerie(serie: dados, variavel: variavel, periodo: periodo);
          },
        ),
        if (variavel == Variavel.nivelRio) ...[
          const SizedBox(height: 8),
          Text(
            'A Defesa Civil informa a situação do rio, mas não publica as cotas em metros. '
            'Por isso o gráfico do nível não mostra as faixas de alerta.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (variavel == Variavel.chuva && periodo.limiarChuva(limiaresChuva.first) == null) ...[
          const SizedBox(height: 8),
          Text(
            'As linhas de alerta aparecem nos períodos de 24 h e 72 h, que são os da tabela de chuva.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

/// Cartão com título e conteúdo, padrão do detalhe.
class _Cartao extends StatelessWidget {
  const _Cartao({required this.icone, required this.titulo, required this.filhos, this.acao});

  final IconData icone;
  final String titulo;
  final List<Widget> filhos;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(titulo, style: Theme.of(context).textTheme.titleMedium)),
                ?acao,
              ],
            ),
            const SizedBox(height: 12),
            ...filhos,
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.rotulo, this.valor, {this.icone, this.destaque = false});

  final String rotulo;
  final String valor;
  final IconData? icone;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final estilo = destaque ? const TextStyle(fontWeight: FontWeight.w600) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(rotulo, style: estilo)),
          if (icone != null) Icon(icone, size: 16),
          Text(valor, style: estilo ?? const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
