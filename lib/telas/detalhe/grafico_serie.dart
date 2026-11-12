import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../dominio/modelos/serie_historica.dart';
import '../../dominio/modelos/variavel.dart';
import '../../dominio/regras/classificacao_chuva.dart';
import '../../nucleo/formatacao.dart';
import '../../nucleo/tema/cores.dart';

/// Gráfico de linha de uma variável da série histórica (HM-04).
///
/// Para a chuva, mostra o acumulado desde o início do período, com as linhas
/// de Atenção, Alerta e Emergência da tabela de chuva quando o período tem
/// limiar (24 h e 72 h) (HM-06).
class GraficoSerie extends StatelessWidget {
  const GraficoSerie({super.key, required this.serie, required this.variavel, required this.periodo});

  final SerieHistorica serie;
  final Variavel variavel;
  final PeriodoSerie periodo;

  bool get _ehChuva => variavel == Variavel.chuva;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final inicio = serie.pontos.isEmpty ? serie.inicio : serie.pontos.first.horario;

    // x = horas desde o primeiro ponto; y = valor (ou acumulado, na chuva).
    final acumulado = _ehChuva ? serie.chuvaAcumuladaPorPonto() : const <double>[];
    final pontos = <FlSpot>[];
    final valores = <double>[];
    for (var i = 0; i < serie.pontos.length; i++) {
      final ponto = serie.pontos[i];
      final x = ponto.horario.difference(inicio).inMinutes / 60;
      final y = _ehChuva ? acumulado[i] : ponto.valor(variavel);
      if (y == null) {
        pontos.add(FlSpot.nullSpot);
      } else {
        pontos.add(FlSpot(x, y));
        valores.add(y);
      }
    }

    if (valores.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Sem dados desta variável no período.')),
      );
    }

    var minY = valores.reduce(math.min);
    var maxY = valores.reduce(math.max);

    // Limiares de chuva: mostra a primeira linha sempre (para dar referência)
    // e as demais só se o acumulado chegar perto delas.
    final limiares = <HorizontalLine>[];
    if (_ehChuva) {
      minY = 0;
      for (final limiar in limiaresChuva) {
        final y = periodo.limiarChuva(limiar);
        if (y == null) continue;
        if (limiares.isNotEmpty && y > maxY * 1.3) break;
        maxY = math.max(maxY, y);
        limiares.add(HorizontalLine(
          y: y,
          color: CoresApp.doNivel(limiar.nivel),
          strokeWidth: 2,
          dashArray: const [6, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: tema.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            labelResolver: (_) => '${limiar.nivel.rotulo} ${Formatar.numero(y, casas: 0)} mm',
          ),
        ));
      }
    }

    // Margem para a linha não encostar nas bordas.
    final folga = (maxY - minY).abs() < 0.001 ? math.max(maxY.abs() * 0.05, 1.0) : (maxY - minY) * 0.1;
    final yMin = _ehChuva ? 0.0 : minY - folga;
    final yMax = maxY + folga;
    final xMax = math.max(pontos.where((p) => !p.isNull()).map((p) => p.x).fold(0.0, math.max), 1.0);
    final cor = _ehChuva ? const Color(0xFF1E88E5) : tema.colorScheme.primary;
    final casas = Formatar.casasDecimais(variavel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _ehChuva ? 'Chuva acumulada no período (mm)' : '${variavel.rotulo} (${variavel.unidade})',
          style: tema.textTheme.labelLarge,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: xMax,
              minY: yMin,
              maxY: yMax,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: tema.colorScheme.outlineVariant, strokeWidth: 0.5),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(horizontalLines: limiares),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (valor, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(Formatar.numero(valor, casas: casas == 2 ? 2 : (yMax - yMin < 5 ? 1 : 0)),
                          style: tema.textTheme.labelSmall),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: _intervaloEixoX(xMax),
                    // O rótulo da ponta direita ficaria cortado na borda.
                    maxIncluded: false,
                    getTitlesWidget: (valor, meta) {
                      final horario = inicio.add(Duration(minutes: (valor * 60).round()));
                      final texto = periodo.duracao.inHours <= 72 ? Formatar.hora(horario) : Formatar.dia(horario);
                      return SideTitleWidget(meta: meta, child: Text(texto, style: tema.textTheme.labelSmall));
                    },
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => tema.colorScheme.inverseSurface,
                  getTooltipItems: (tocados) => [
                    for (final ponto in tocados)
                      LineTooltipItem(
                        '${Formatar.diaHora(inicio.add(Duration(minutes: (ponto.x * 60).round())))}\n'
                        '${Formatar.numero(ponto.y, casas: casas)} ${variavel.unidade}',
                        TextStyle(color: tema.colorScheme.onInverseSurface),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: pontos,
                  color: cor,
                  barWidth: 2.5,
                  isCurved: !_ehChuva,
                  preventCurveOverShooting: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: _ehChuva, color: cor.withValues(alpha: 0.15)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _Resumo(variavel: variavel, valores: valores, ehChuva: _ehChuva),
      ],
    );
  }

  /// Cerca de 4 rótulos no eixo do tempo, em horas redondas.
  static double _intervaloEixoX(double horas) {
    for (final passo in const <double>[1, 3, 6, 12, 24, 48, 72, 168]) {
      if (horas / passo <= 5) return passo;
    }
    return 168;
  }
}

class _Resumo extends StatelessWidget {
  const _Resumo({required this.variavel, required this.valores, required this.ehChuva});

  final Variavel variavel;
  final List<double> valores;
  final bool ehChuva;

  @override
  Widget build(BuildContext context) {
    final itens = ehChuva
        ? {'Total no período': Formatar.variavel(variavel, valores.last)}
        : {
            'Mínimo': Formatar.variavel(variavel, valores.reduce(math.min)),
            'Máximo': Formatar.variavel(variavel, valores.reduce(math.max)),
            'Último': Formatar.variavel(variavel, valores.last),
          };
    final estilo = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final item in itens.entries)
          Expanded(
            child: Column(
              children: [
                Text(item.key, style: estilo.labelSmall),
                Text(item.value, style: estilo.titleSmall),
              ],
            ),
          ),
      ],
    );
  }
}
