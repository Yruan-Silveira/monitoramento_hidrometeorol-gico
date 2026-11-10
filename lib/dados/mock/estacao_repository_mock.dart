import 'dart:math' as math;

import '../../dominio/modelos/estacao.dart';
import '../../dominio/modelos/medicao.dart';
import '../../dominio/modelos/nivel_alerta.dart';
import '../../dominio/modelos/serie_historica.dart';
import '../../dominio/repositorios/estacao_repository.dart';

/// Repositório com dados de exemplo, para construir as telas sem a API.
///
/// As estações usam códigos, nomes e coordenadas reais da rede, mas as
/// leituras são inventadas para cobrir todos os casos que as telas precisam
/// tratar: os quatro níveis de alerta, dado atrasado, estação sem leitura,
/// em manutenção, sem limiar de rio e sem coordenadas.
///
/// Para testar as mensagens de erro, passe [falha]: todos os métodos de
/// leitura passam a lançar essa falha.
class EstacaoRepositoryMock implements EstacaoRepository {
  EstacaoRepositoryMock({
    this.atraso = const Duration(milliseconds: 600),
    this.falha,
    DateTime Function()? agora,
    Set<String>? favoritosIniciais,
  })  : _agora = agora ?? DateTime.now,
        _favoritos = {...(favoritosIniciais ?? const {'DCRS-00006', 'DCRS-00012'})};

  /// Demora simulada de cada chamada, para os indicadores de carregamento
  /// aparecerem.
  final Duration atraso;

  /// Se definido, as leituras falham com este tipo.
  TipoFalha? falha;

  final DateTime Function() _agora;
  final Set<String> _favoritos;

  @override
  Future<LeituraEstacoes> listarEstacoes({bool forcarAtualizacao = false}) async {
    await _simularRede();
    final agora = _agora();
    final bloco = _blocoAtual(agora);
    return LeituraEstacoes(
      estacoes: _estacoes(bloco),
      atualizadoEm: agora,
      proximaAtualizacaoEm: bloco.add(const Duration(minutes: 12)),
    );
  }

  @override
  Future<Estacao> buscarEstacao(String codigo) async {
    await _simularRede();
    return _encontrar(codigo, _blocoAtual(_agora()));
  }

  @override
  Future<SerieHistorica> buscarSerie(
    String codigo, {
    required DateTime inicio,
    required DateTime fim,
    IntervaloSerie intervalo = IntervaloSerie.hora1,
  }) async {
    await _simularRede();
    final agora = _agora();
    if (inicio.isBefore(agora.subtract(const Duration(days: 90)))) {
      throw const FalhaRepositorio(TipoFalha.periodoInvalido);
    }
    final estacao = _encontrar(codigo, _blocoAtual(agora));
    final limite = fim.isAfter(agora) ? agora : fim;
    return SerieHistorica(
      codigoEstacao: codigo,
      inicio: inicio,
      fim: limite,
      intervalo: intervalo,
      pontos: _gerarPontos(estacao, inicio, limite, intervalo, agora),
    );
  }

  @override
  Future<Set<String>> listarFavoritos() async => {..._favoritos};

  @override
  Future<void> definirFavorito(String codigo, {required bool favorito}) async {
    if (favorito) {
      _favoritos.add(codigo);
    } else {
      _favoritos.remove(codigo);
    }
  }

  Future<void> _simularRede() async {
    if (atraso > Duration.zero) await Future<void>.delayed(atraso);
    final tipo = falha;
    if (tipo != null) throw FalhaRepositorio(tipo, 'falha simulada pelo mock');
  }

  Estacao _encontrar(String codigo, DateTime bloco) {
    for (final estacao in _estacoes(bloco)) {
      if (estacao.codigo == codigo) return estacao;
    }
    throw FalhaRepositorio(TipoFalha.naoEncontrado, codigo);
  }

  /// Início do bloco de 5 minutos que a API já teria publicado.
  static DateTime _blocoAtual(DateTime agora) {
    final base = agora.subtract(const Duration(minutes: 7));
    return DateTime(base.year, base.month, base.day, base.hour, base.minute - base.minute % 5);
  }

  /// Série coerente com a leitura atual: o nível termina no valor atual e a
  /// chuva somada bate com os acumulados de 24h, 48h e 72h da estação.
  static List<PontoSerie> _gerarPontos(
    Estacao estacao,
    DateTime inicio,
    DateTime fim,
    IntervaloSerie intervalo,
    DateTime agora,
  ) {
    final medicao = estacao.medicao;
    if (medicao.horario == null) return const [];

    final semente = estacao.codigo.codeUnits.fold<int>(0, (soma, c) => soma + c);
    final horasDoBloco = intervalo.duracao.inMinutes / 60;
    final chuva = medicao.chuva;
    final mm24 = chuva.mm24 ?? 0;
    final mm48 = math.max(chuva.mm48 ?? mm24, mm24);
    final mm72 = math.max(chuva.mm72 ?? mm48, mm48);

    final pontos = <PontoSerie>[];
    for (var t = inicio; !t.isAfter(fim); t = t.add(intervalo.duracao)) {
      if (t.isAfter(medicao.horario!)) break;
      final horasAtras = agora.difference(t).inMinutes / 60;

      // mm/h médios de cada janela, com uma ondulação que não muda a soma.
      final taxaBase = horasAtras < 24
          ? mm24 / 24
          : horasAtras < 48
              ? (mm48 - mm24) / 24
              : horasAtras < 72
                  ? (mm72 - mm48) / 24
                  : 0.0;
      final taxa = taxaBase * (1 + 0.8 * math.sin(2 * math.pi * horasAtras / 6));

      final onda = math.sin(2 * math.pi * horasAtras / 36 + semente);
      final dia = math.sin(2 * math.pi * (t.hour + t.minute / 60 - 9) / 24);

      pontos.add(PontoSerie(
        horario: t,
        nivelRio: medicao.nivelRio == null
            ? null
            : _arredondar(medicao.nivelRio! - 0.02 * horasAtras * taxaBase + 0.08 * (onda - math.sin(semente))),
        variacaoNivelRio: medicao.nivelRio == null ? null : _arredondar(0.01 * onda),
        chuva: _arredondar(taxa * horasDoBloco),
        chuvaTaxaMedia: _arredondar(taxa),
        chuvaTaxaMaxima: _arredondar(taxa * 1.6),
        temperatura: _arredondar(20 + 5 * dia),
        sensacaoTermica: _arredondar(20.5 + 5.5 * dia),
        umidade: _arredondar(70 - 15 * dia),
        pressao: _arredondar(1015 + 3 * onda),
        ventoVelocidadeMedia: _arredondar(6 + 4 * onda.abs()),
        ventoVelocidadeMaxima: _arredondar(14 + 8 * onda.abs()),
        ventoDirecao: _arredondar((semente * 7 + horasAtras * 5) % 360),
        radiacaoSolar: _arredondar(math.max(0, 600 * dia)),
      ));
    }
    return pontos;
  }

  static double _arredondar(double valor) => (valor * 100).round() / 100;

  static List<Estacao> _estacoes(DateTime bloco) {
    Medicao medicao({
      DateTime? horario,
      double? nivelRio,
      double variacao = 0,
      NivelAlerta? alertaRio,
      bool temLimiar = true,
      double mm24 = 0,
      double? mm48,
      double? mm72,
      double? mm7dias,
      double temperatura = 21.9,
    }) {
      return Medicao(
        horario: horario ?? bloco,
        nivelRio: nivelRio,
        variacaoNivelRio: nivelRio == null ? null : variacao,
        alertaRio: alertaRio,
        temLimiarRio: temLimiar,
        chuva: ChuvaAcumulada(
          mm5min: mm24 > 0 ? 0.4 : 0,
          mm1h: _arredondar(mm24 / 12),
          mm3h: _arredondar(mm24 / 5),
          mm6h: _arredondar(mm24 / 3),
          mm12h: _arredondar(mm24 / 1.6),
          mm24: mm24,
          mm48: mm48 ?? mm24,
          mm72: mm72 ?? mm48 ?? mm24,
          mm7dias: mm7dias ?? (mm72 ?? mm48 ?? mm24) + 12.4,
        ),
        temperatura: temperatura,
        sensacaoTermica: temperatura + 1.3,
        umidade: 61.5,
        pressao: 1016.5,
        ventoVelocidadeMedia: 4.4,
        ventoVelocidadeMaxima: 18.1,
        ventoDirecao: 255,
        radiacaoSolar: 0,
      );
    }

    return [
      // Tudo normal.
      Estacao(
        codigo: 'DCRS-00001',
        nome: 'Igrejinha',
        latitude: -29.5743,
        longitude: -50.7961,
        regiao: 'Metropolitana de Porto Alegre',
        bacia: 'RS - Sinos',
        coordenadoria: 'METROPOLITANA',
        medicao: medicao(nivelRio: 27.31, alertaRio: NivelAlerta.normal),
      ),
      // Atenção pela chuva (mm24 >= 30), rio normal.
      Estacao(
        codigo: 'DCRS-00002',
        nome: 'Nova Hartz',
        latitude: -29.5934,
        longitude: -50.903,
        regiao: 'Metropolitana de Porto Alegre',
        bacia: 'RS - Sinos',
        coordenadoria: 'METROPOLITANA',
        medicao: medicao(
          nivelRio: 20.66,
          variacao: 0.03,
          alertaRio: NivelAlerta.normal,
          mm24: 34.2,
          mm48: 41,
          mm72: 44.6,
        ),
      ),
      // Alerta pelo rio; a chuva sozinha daria atenção.
      Estacao(
        codigo: 'DCRS-00006',
        nome: 'Rolante - Centro',
        latitude: -29.6652,
        longitude: -50.582,
        regiao: 'Metropolitana de Porto Alegre',
        bacia: 'RS - Sinos',
        coordenadoria: 'METROPOLITANA',
        medicao: medicao(
          nivelRio: 33.87,
          variacao: 0.12,
          alertaRio: NivelAlerta.alerta,
          mm24: 38.4,
          mm48: 47.8,
          mm72: 52,
        ),
      ),
      // Emergência: rio em inundação e chuva acima de 80 mm em 24h.
      Estacao(
        codigo: 'DCRS-00012',
        nome: 'Montenegro',
        latitude: -29.697,
        longitude: -51.4601,
        regiao: 'Metropolitana de Porto Alegre',
        bacia: 'RS - Rio Caí',
        coordenadoria: 'METROPOLITANA',
        medicao: medicao(
          nivelRio: 6.42,
          variacao: 0.21,
          alertaRio: NivelAlerta.emergencia,
          mm24: 86.6,
          mm48: 112.2,
          mm72: 131,
        ),
      ),
      Estacao(
        codigo: 'DCRS-00016',
        nome: 'Passo Fundo',
        latitude: -28.247,
        longitude: -52.3713,
        regiao: 'Noroeste Rio-grandense',
        bacia: 'RS - Rio Passo Fundo',
        coordenadoria: 'PASSO FUNDO',
        medicao: medicao(nivelRio: 646.9, alertaRio: NivelAlerta.normal, mm24: 4.8, temperatura: 18.2),
      ),
      // Alerta só pelo acumulado de 48h (mm48 >= 70).
      Estacao(
        codigo: 'DCRS-00027',
        nome: 'Santa Maria - Arroio Cadena',
        latitude: -29.7001,
        longitude: -53.8356,
        regiao: 'Centro Ocidental Rio-grandense',
        bacia: 'RS - Rios Vacacaí - Vacacaí Mirim',
        coordenadoria: 'SANTA MARIA',
        medicao: medicao(
          nivelRio: 68.9,
          variacao: -0.04,
          alertaRio: NivelAlerta.normal,
          mm24: 22,
          mm48: 74.4,
          mm72: 78,
        ),
      ),
      // Sem limiar de rio cadastrado e sem leitura de nível.
      Estacao(
        codigo: 'DCRS-00033',
        nome: 'Porto Alegre - Ipanema',
        latitude: -30.1419,
        longitude: -51.2271,
        regiao: 'Metropolitana de Porto Alegre',
        bacia: 'RS - Lago Guaíba',
        coordenadoria: 'METROPOLITANA',
        medicao: medicao(temLimiar: false, mm24: 1.2),
      ),
      // Dado atrasado: última leitura há 3 horas.
      Estacao(
        codigo: 'DCRS-00038',
        nome: 'Rio Grande',
        latitude: -32.0275,
        longitude: -52.1021,
        regiao: 'Sudeste Rio-grandense',
        bacia: 'RS - Lagoa Mirim e do Canal São Gonçalo',
        coordenadoria: 'PELOTAS',
        medicao: medicao(
          horario: bloco.subtract(const Duration(hours: 3)),
          nivelRio: 0.37,
          alertaRio: NivelAlerta.normal,
        ),
      ),
      // Em manutenção.
      Estacao(
        codigo: 'DCRS-00041',
        nome: 'Bagé',
        latitude: -31.3296,
        longitude: -54.0939,
        regiao: 'Sudoeste Rio-grandense',
        bacia: 'RS - Rio Negro',
        coordenadoria: 'URUGUAIANA',
        emManutencao: true,
        medicao: medicao(nivelRio: 188.71, alertaRio: NivelAlerta.normal),
      ),
      // Sem nenhuma leitura: todos os valores nulos.
      const Estacao(
        codigo: 'DCRS-00060',
        nome: 'Barra do Rio Azul - Rio Palomas',
        latitude: -27.4096,
        longitude: -52.4145,
        regiao: 'Noroeste Rio-grandense',
        bacia: 'RS - Rios Apuaê – Inhandava',
        coordenadoria: 'FREDERICO WESTPHALEN',
        medicao: Medicao(temLimiarRio: true),
      ),
      // Atenção pelo rio, sem chuva; a API não informa a bacia.
      Estacao(
        codigo: 'DCRS-00079',
        nome: 'São Borja',
        latitude: -28.6108,
        longitude: -56.0146,
        regiao: 'Sudoeste Rio-grandense',
        coordenadoria: 'URUGUAIANA',
        medicao: medicao(nivelRio: 55.53, variacao: 0.02, alertaRio: NivelAlerta.atencao, temperatura: 26.4),
      ),
      // Estação que a API devolve sem nome, região nem coordenadas.
      Estacao(
        codigo: 'DCRS-00129',
        nome: 'DCRS-00129',
        medicao: medicao(nivelRio: 12.16, temLimiar: false),
      ),
    ];
  }
}
