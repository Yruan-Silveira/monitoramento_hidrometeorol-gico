import 'variavel.dart';

/// Agrupamento dos pontos da série. São os únicos valores que a API aceita.
enum IntervaloSerie {
  min5('MIN_5', Duration(minutes: 5)),
  min10('MIN_10', Duration(minutes: 10)),
  hora1('HOUR_1', Duration(hours: 1)),
  hora3('HOUR_3', Duration(hours: 3)),
  hora6('HOUR_6', Duration(hours: 6)),
  hora12('HOUR_12', Duration(hours: 12));

  const IntervaloSerie(this.valorApi, this.duracao);

  /// Valor da variável `interval` na consulta `historic`.
  final String valorApi;
  final Duration duracao;
}

/// Períodos oferecidos no seletor dos gráficos (HM-04), cada um com um
/// intervalo que mantém a série leve (no máximo ~170 pontos).
enum PeriodoSerie {
  horas24('24 h', Duration(hours: 24), IntervaloSerie.hora1),
  horas72('72 h', Duration(hours: 72), IntervaloSerie.hora1),
  dias7('7 dias', Duration(days: 7), IntervaloSerie.hora1),
  dias30('30 dias', Duration(days: 30), IntervaloSerie.hora6);

  const PeriodoSerie(this.rotulo, this.duracao, this.intervalo);

  final String rotulo;
  final Duration duracao;
  final IntervaloSerie intervalo;
}

/// Um ponto da série: os valores agregados de um bloco de tempo.
class PontoSerie {
  const PontoSerie({
    required this.horario,
    this.nivelRio,
    this.variacaoNivelRio,
    this.chuva,
    this.chuvaTaxaMedia,
    this.chuvaTaxaMaxima,
    this.temperatura,
    this.sensacaoTermica,
    this.umidade,
    this.pressao,
    this.ventoVelocidadeMedia,
    this.ventoVelocidadeMaxima,
    this.ventoDirecao,
    this.radiacaoSolar,
  });

  /// Início do bloco.
  final DateTime horario;

  final double? nivelRio;
  final double? variacaoNivelRio;

  /// Chuva que caiu dentro do bloco (mm).
  final double? chuva;

  /// Intensidade da chuva no bloco (mm/h).
  final double? chuvaTaxaMedia;
  final double? chuvaTaxaMaxima;

  final double? temperatura;
  final double? sensacaoTermica;
  final double? umidade;
  final double? pressao;
  final double? ventoVelocidadeMedia;
  final double? ventoVelocidadeMaxima;
  final double? ventoDirecao;
  final double? radiacaoSolar;

  /// Valor de uma variável neste ponto, para montar o gráfico.
  double? valor(Variavel variavel) => switch (variavel) {
        Variavel.nivelRio => nivelRio,
        Variavel.chuva => chuva,
        Variavel.temperatura => temperatura,
        Variavel.sensacaoTermica => sensacaoTermica,
        Variavel.umidade => umidade,
        Variavel.pressao => pressao,
        Variavel.ventoVelocidadeMedia => ventoVelocidadeMedia,
        Variavel.ventoVelocidadeMaxima => ventoVelocidadeMaxima,
        Variavel.ventoDirecao => ventoDirecao,
        Variavel.radiacaoSolar => radiacaoSolar,
      };
}

/// Série de uma estação num período, em ordem cronológica.
class SerieHistorica {
  const SerieHistorica({
    required this.codigoEstacao,
    required this.inicio,
    required this.fim,
    required this.intervalo,
    required this.pontos,
  });

  final String codigoEstacao;
  final DateTime inicio;
  final DateTime fim;
  final IntervaloSerie intervalo;
  final List<PontoSerie> pontos;

  bool get vazia => pontos.isEmpty;

  /// Soma da chuva (mm) dos pontos a partir de [desde]. Serve para calcular
  /// o acumulado de 72h, que a API de dados atuais não traz.
  double chuvaAcumulada({DateTime? desde}) {
    var total = 0.0;
    for (final ponto in pontos) {
      if (desde != null && ponto.horario.isBefore(desde)) continue;
      total += ponto.chuva ?? 0;
    }
    return total;
  }
}
