import 'package:flutter/foundation.dart';

import '../dominio/modelos/estacao.dart';
import '../dominio/modelos/medicao.dart';
import '../dominio/modelos/serie_historica.dart';
import '../dominio/repositorios/estacao_repository.dart';
import 'api/cliente_api.dart';
import 'api/conversor_json.dart';
import 'local/cache_estacoes.dart';
import 'local/preferencias_locais.dart';

/// Implementação real do [EstacaoRepository]: API da Defesa Civil RS + cache
/// no aparelho + favoritos.
///
/// Ritmo de consulta (a API publica dado novo a cada 5 min e aceita no máximo
/// 120 requisições por minuto):
/// - `listarEstacoes` sem forçar devolve a cópia em memória até
///   `proximaAtualizacaoEm` (no máximo 10 min). Ao abrir o app, se o cache em
///   disco tem menos de 5 min, ele é usado sem ir à rede.
/// - Se a API falhar e houver cache, devolve o cache com
///   `origem == OrigemDados.cache` (a tela mostra "dados das HH:MM").
/// - A chuva de 72 h de cada estação fica guardada por 5 min.
class EstacaoRepositoryApi implements EstacaoRepository {
  EstacaoRepositoryApi({
    ClienteApi? api,
    CacheEstacoes? cache,
    FavoritosLocal? favoritos,
    DateTime Function()? agora,
    this.aoFavoritar,
  })  : _api = api ?? ClienteApi(),
        _cache = cache ?? CacheEstacoes(),
        _favoritos = favoritos ?? FavoritosLocal(),
        _agora = agora ?? DateTime.now;

  /// Validade padrão dos dados: a API atualiza a cada 5 min.
  static const Duration validade = Duration(minutes: 5);

  /// A API só guarda os últimos 3 meses; a margem evita a recusa na borda.
  static const Duration _margemHistorico = Duration(minutes: 5);

  final ClienteApi _api;
  final CacheEstacoes _cache;
  final FavoritosLocal _favoritos;
  final DateTime Function() _agora;

  /// Chamado quando o usuário marca uma favorita. O app usa para pedir a
  /// permissão de notificação em contexto (HM-07), e não logo ao abrir.
  final Future<void> Function()? aoFavoritar;

  LeituraEstacoes? _memoria;
  DateTime? _validoAte;
  Future<LeituraEstacoes>? _emAndamento;
  final Map<String, ({double? mm72, DateTime ate})> _chuva72 = {};

  // ------------------------------------------------------------- estações

  @override
  Future<LeituraEstacoes> listarEstacoes({bool forcarAtualizacao = false}) {
    final memoria = _memoria;
    final validoAte = _validoAte;
    if (!forcarAtualizacao && memoria != null && validoAte != null && _agora().isBefore(validoAte)) {
      return Future.value(memoria);
    }
    // duas telas pedindo ao mesmo tempo compartilham a mesma requisição
    return _emAndamento ??= _carregar(forcarAtualizacao).whenComplete(() => _emAndamento = null);
  }

  Future<LeituraEstacoes> _carregar(bool forcar) async {
    final agora = _agora();

    if (!forcar && _memoria == null) {
      final guardada = await _lerCache();
      if (guardada != null && agora.difference(guardada.obtidoEm) < validade) {
        final leitura = _montarLeitura(guardada.json, guardada.obtidoEm, OrigemDados.rede);
        if (leitura != null) return _guardarEmMemoria(leitura, agora);
      }
    }

    try {
      final json = await _api.buscarTagsData();
      final estacoes = _converter(json);
      if (estacoes.isEmpty) {
        throw const FalhaRepositorio(TipoFalha.respostaInvalida, 'lista de estações vazia');
      }
      await _salvarCache(json, agora);
      return _guardarEmMemoria(
        LeituraEstacoes(
          estacoes: estacoes,
          atualizadoEm: agora,
          proximaAtualizacaoEm: ConversorJson.proximaAtualizacao(json),
        ),
        agora,
      );
    } on FalhaRepositorio catch (falha) {
      debugPrint('EstacaoRepositoryApi: API falhou ($falha), tentando o cache');
      final guardada = await _lerCache();
      final leitura =
          guardada == null ? null : _montarLeitura(guardada.json, guardada.obtidoEm, OrigemDados.cache);
      if (leitura == null) rethrow;
      // guarda para as telas, mas sem validade: a próxima chamada tenta a API de novo
      _memoria = leitura;
      _validoAte = null;
      return leitura;
    }
  }

  @override
  Future<Estacao> buscarEstacao(String codigo) async {
    final leitura = await listarEstacoes();
    final estacao = _encontrar(leitura.estacoes, codigo);
    if (estacao == null) throw FalhaRepositorio(TipoFalha.naoEncontrado, codigo);
    if (estacao.tipo == TipoEstacao.fluviometrica || estacao.medicao.horario == null) return estacao;
    try {
      return comChuva72h(estacao, await _calcularChuva72h(codigo));
    } on FalhaRepositorio catch (falha) {
      // sem as 72 h a classificação usa só 24 h e 48 h; não impede a tela
      debugPrint('EstacaoRepositoryApi: chuva de 72 h de $codigo indisponível ($falha)');
      return estacao;
    }
  }

  /// Chuva das últimas 72 h somando a série em blocos de 1 hora, porque a
  /// tags_data não traz esse acumulado. `null` se a série não tiver chuva.
  Future<double?> _calcularChuva72h(String codigo) async {
    final agora = _agora();
    final guardado = _chuva72[codigo];
    if (guardado != null && agora.isBefore(guardado.ate)) return guardado.mm72;

    final serie = await buscarSerie(
      codigo,
      inicio: agora.subtract(const Duration(hours: 72)),
      fim: agora,
      intervalo: IntervaloSerie.hora1,
    );
    final temChuva = serie.pontos.any((p) => p.chuva != null);
    final mm72 = temChuva ? _arredondar(serie.chuvaAcumulada()) : null;
    _chuva72[codigo] = (mm72: mm72, ate: agora.add(validade));
    return mm72;
  }

  // ---------------------------------------------------------------- série

  @override
  Future<SerieHistorica> buscarSerie(
    String codigo, {
    required DateTime inicio,
    required DateTime fim,
    IntervaloSerie intervalo = IntervaloSerie.hora1,
  }) async {
    final agora = _agora();
    final fimAjustado = fim.isAfter(agora) ? agora : fim;
    if (inicio.isBefore(limiteHistorico(agora))) {
      throw FalhaRepositorio(TipoFalha.periodoInvalido, 'a API só guarda os últimos 3 meses');
    }
    if (!inicio.isBefore(fimAjustado)) {
      throw const FalhaRepositorio(TipoFalha.periodoInvalido, 'início deve ser anterior ao fim');
    }
    final json = await _api.buscarHistorico(codigo, inicio: inicio, fim: fimAjustado, intervalo: intervalo);
    try {
      return ConversorJson.serie(json, codigo: codigo, inicio: inicio, fim: fimAjustado, intervalo: intervalo);
    } on FalhaRepositorio {
      rethrow;
    } catch (e) {
      throw FalhaRepositorio(TipoFalha.respostaInvalida, 'série: $e');
    }
  }

  /// Data mais antiga que a consulta historic aceita.
  static DateTime limiteHistorico(DateTime agora) =>
      DateTime(agora.year, agora.month - 3, agora.day, agora.hour, agora.minute, agora.second)
          .add(_margemHistorico);

  // ------------------------------------------------------------ favoritos

  @override
  Future<Set<String>> listarFavoritos() => _favoritos.listar();

  @override
  Future<void> definirFavorito(String codigo, {required bool favorito}) async {
    await _favoritos.definir(codigo, favorito: favorito);
    final callback = aoFavoritar;
    if (favorito && callback != null) {
      try {
        await callback();
      } catch (e) {
        debugPrint('EstacaoRepositoryApi: aoFavoritar falhou ($e)');
      }
    }
  }

  // -------------------------------------------------------------- interno

  LeituraEstacoes _guardarEmMemoria(LeituraEstacoes leitura, DateTime agora) {
    var ate = agora.add(validade);
    final proxima = leitura.proximaAtualizacaoEm;
    // usa a promessa da API se for coerente (entre agora e 10 min)
    if (proxima != null && proxima.isAfter(agora) && proxima.isBefore(agora.add(validade * 2))) {
      ate = proxima;
    }
    _memoria = leitura;
    _validoAte = ate;
    return leitura;
  }

  LeituraEstacoes? _montarLeitura(Map<String, dynamic> json, DateTime obtidoEm, OrigemDados origem) {
    try {
      final estacoes = _converter(json);
      if (estacoes.isEmpty) return null;
      return LeituraEstacoes(
        estacoes: estacoes,
        atualizadoEm: obtidoEm,
        proximaAtualizacaoEm: ConversorJson.proximaAtualizacao(json),
        origem: origem,
      );
    } on FalhaRepositorio {
      return null;
    }
  }

  List<Estacao> _converter(Map<String, dynamic> json) {
    try {
      return ConversorJson.estacoes(json);
    } on FalhaRepositorio {
      rethrow;
    } catch (e) {
      throw FalhaRepositorio(TipoFalha.respostaInvalida, 'estações: $e');
    }
  }

  Future<RespostaGuardada?> _lerCache() async {
    try {
      return await _cache.ler();
    } catch (e) {
      debugPrint('EstacaoRepositoryApi: não foi possível ler o cache ($e)');
      return null;
    }
  }

  Future<void> _salvarCache(Map<String, dynamic> json, DateTime obtidoEm) async {
    try {
      await _cache.salvar(json, obtidoEm);
    } catch (e) {
      // sem cache o app continua funcionando, só não abre offline
      debugPrint('EstacaoRepositoryApi: não foi possível salvar o cache ($e)');
    }
  }

  static Estacao? _encontrar(List<Estacao> estacoes, String codigo) {
    for (final estacao in estacoes) {
      if (estacao.codigo == codigo) return estacao;
    }
    return null;
  }

  static double _arredondar(double valor) => (valor * 100).roundToDouble() / 100;
}

/// Cópia de [estacao] com a chuva de 72 h preenchida.
@visibleForTesting
Estacao comChuva72h(Estacao estacao, double? mm72) {
  final m = estacao.medicao;
  final c = m.chuva;
  return Estacao(
    codigo: estacao.codigo,
    nome: estacao.nome,
    latitude: estacao.latitude,
    longitude: estacao.longitude,
    altitude: estacao.altitude,
    regiao: estacao.regiao,
    bacia: estacao.bacia,
    coordenadoria: estacao.coordenadoria,
    tipo: estacao.tipo,
    emManutencao: estacao.emManutencao,
    medicao: Medicao(
      horario: m.horario,
      nivelRio: m.nivelRio,
      variacaoNivelRio: m.variacaoNivelRio,
      alertaRio: m.alertaRio,
      temLimiarRio: m.temLimiarRio,
      chuva: ChuvaAcumulada(
        mm5min: c.mm5min,
        mm1h: c.mm1h,
        mm3h: c.mm3h,
        mm6h: c.mm6h,
        mm12h: c.mm12h,
        mm24: c.mm24,
        mm48: c.mm48,
        mm72: mm72,
        mm7dias: c.mm7dias,
      ),
      temperatura: m.temperatura,
      sensacaoTermica: m.sensacaoTermica,
      umidade: m.umidade,
      pressao: m.pressao,
      ventoVelocidadeMedia: m.ventoVelocidadeMedia,
      ventoVelocidadeMaxima: m.ventoVelocidadeMaxima,
      ventoDirecao: m.ventoDirecao,
      radiacaoSolar: m.radiacaoSolar,
    ),
  );
}
