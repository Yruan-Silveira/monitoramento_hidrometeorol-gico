import '../../dominio/modelos/estacao.dart';
import '../../dominio/modelos/medicao.dart';
import '../../dominio/modelos/nivel_alerta.dart';
import '../../dominio/modelos/serie_historica.dart';
import '../../dominio/repositorios/estacao_repository.dart';
import 'datas_api.dart';

/// Converte o JSON da API nos modelos de `dominio/`.
///
/// Todo campo é lido por nome e tolera ausência: qualquer `value` pode ser
/// `null`, o objeto inteiro pode ser `null`, números vêm ora inteiros ora
/// decimais e booleanos às vezes vêm como texto. Ver docs/api.md, "Casos
/// reais que o app precisa aguentar".
abstract final class ConversorJson {
  /// Estações de `data.tags_data.qualle_meteorologia`.
  ///
  /// Itens sem `codigo` ou com `show` falso são ignorados. Lança
  /// [TipoFalha.respostaInvalida] se a lista não existir.
  static List<Estacao> estacoes(Map<String, dynamic> json) {
    final lista = _em(json, const ['data', 'tags_data', 'qualle_meteorologia']);
    if (lista is! List) {
      throw const FalhaRepositorio(TipoFalha.respostaInvalida, 'sem data.tags_data.qualle_meteorologia');
    }
    final estacoes = <Estacao>[];
    for (final item in lista) {
      if (item is! Map) continue;
      final estacao = _estacao(item);
      if (estacao != null) estacoes.add(estacao);
    }
    return estacoes;
  }

  /// `proximaAtualizacaoEm` (UTC), ou `null`.
  static DateTime? proximaAtualizacao(Map<String, dynamic> json) =>
      lerHorarioApi(_em(json, const ['data', 'tags_data', 'proximaAtualizacaoEm']));

  /// Série de `data.historic.items`, em ordem cronológica.
  static SerieHistorica serie(
    Map<String, dynamic> json, {
    required String codigo,
    required DateTime inicio,
    required DateTime fim,
    required IntervaloSerie intervalo,
  }) {
    final historic = _em(json, const ['data', 'historic']);
    if (historic is! Map) {
      throw const FalhaRepositorio(TipoFalha.respostaInvalida, 'sem data.historic');
    }
    final itens = historic['items'];
    final pontos = <PontoSerie>[];
    if (itens is List) {
      for (final item in itens) {
        if (item is! Map) continue;
        final horario = lerHorarioApi(item['ts']);
        if (horario == null) continue;
        pontos.add(PontoSerie(
          horario: horario,
          nivelRio: _numero(item['rio_nivel']),
          variacaoNivelRio: _numero(item['rio_variacao']),
          chuva: _numero(item['chuva_mm']),
          chuvaTaxaMedia: _numero(item['chuva_taxa_med']),
          chuvaTaxaMaxima: _numero(item['chuva_taxa_max']),
          temperatura: _numero(item['temp_media']),
          sensacaoTermica: _numero(item['sens_termica']),
          umidade: _numero(item['umid_rel']),
          pressao: _numero(item['pres_atmos']),
          ventoVelocidadeMedia: _numero(item['vento_vel_med']),
          ventoVelocidadeMaxima: _numero(item['vento_vel_max']),
          ventoDirecao: _numero(item['vento_dir']),
          radiacaoSolar: _numero(item['radiacao']),
        ));
      }
    }
    pontos.sort((a, b) => a.horario.compareTo(b.horario));
    return SerieHistorica(
      codigoEstacao: codigo,
      inicio: inicio,
      fim: fim,
      intervalo: intervalo,
      pontos: pontos,
    );
  }

  // ------------------------------------------------------------------ estação

  static Estacao? _estacao(Map item) {
    final codigo = _texto(item['codigo']);
    if (codigo == null) return null;
    if (_booleano(item['show']) == false) return null;

    final posicao = item['position'];
    var latitude = _numero(_em(posicao, const ['latitude']));
    var longitude = _numero(_em(posicao, const ['longitude']));
    if (latitude == 0 && longitude == 0) {
      // (0, 0) é "sem coordenada", não um ponto no Atlântico
      latitude = null;
      longitude = null;
    }

    return Estacao(
      codigo: codigo,
      nome: _texto(_em(item, const ['name', 'general'])) ?? codigo,
      latitude: latitude,
      longitude: longitude,
      altitude: _numero(_em(posicao, const ['altitude'])),
      regiao: _texto(_em(posicao, const ['regiao'])),
      bacia: _texto(_em(posicao, const ['bacia'])),
      coordenadoria: _texto(_em(posicao, const ['filtros', 'outros', 'crepdec', 'nome', 'value'])),
      tipo: _tipo(_em(item, const ['filter', 'relacao'])),
      emManutencao:
          _booleano(_em(item, const ['resource', 'estacao', 'estado', 'manutencao', 'value'])) ?? false,
      medicao: _medicao(item),
    );
  }

  static Medicao _medicao(Map item) {
    final dados = item['data'];
    final rio = _em(dados, const ['rio']);
    final acumulado = _em(dados, const ['chuva', 'acumulado']);

    final temLimiar = _booleano(_em(rio, const ['rio_alarmes', 'inundacao', 'ativo', 'value'])) ?? false;
    final status = _numero(_em(rio, const ['rio_alarmes', 'inundacao', 'status', 'value']));

    return Medicao(
      horario: lerHorarioApi(item['timestamp']),
      nivelRio: _valor(rio, 'rio_nivel'),
      variacaoNivelRio: _valor(rio, 'rio_nivel_tendencia'),
      temLimiarRio: temLimiar,
      // sem limiar cadastrado o status vem 0, mas não quer dizer "normal"
      alertaRio: temLimiar ? NivelAlerta.doStatusRio(status?.toInt()) : null,
      chuva: ChuvaAcumulada(
        mm5min: _valor(acumulado, 'min005'),
        mm1h: _valor(acumulado, 'h001'),
        mm3h: _valor(acumulado, 'h003'),
        mm6h: _valor(acumulado, 'h006'),
        mm12h: _valor(acumulado, 'h012'),
        mm24: _valor(acumulado, 'h024'),
        mm48: _valor(acumulado, 'h048'),
        mm7dias: _valor(acumulado, 'h168'),
      ),
      temperatura: _numero(_em(dados, const ['temperatura', 'atual', 'value'])),
      sensacaoTermica: _numero(_em(dados, const ['senstermica', 'atual', 'value'])),
      umidade: _numero(_em(dados, const ['umidade', 'atual', 'value'])),
      pressao: _numero(_em(dados, const ['pressaoatmos', 'atual', 'value'])),
      ventoVelocidadeMedia: _numero(_em(dados, const ['vento', 'velocidade_media', 'value'])),
      ventoVelocidadeMaxima: _numero(_em(dados, const ['vento', 'velocidade_maxima', 'value'])),
      ventoDirecao: _numero(_em(dados, const ['vento', 'direcao', 'value'])),
      radiacaoSolar: _numero(_em(dados, const ['radiacaosolar', 'atual', 'value'])),
    );
  }

  /// Nível do rio e chuva = hidrometeorológica; só rio = fluviométrica;
  /// só meteorologia = meteorológica. Sem a informação, hidrometeorológica.
  static TipoEstacao _tipo(Object? relacao) {
    final rio = _booleano(_em(relacao, const ['tem_nivel_do_rio']));
    final chuva = _booleano(_em(relacao, const ['tem_chuva_acumulada']));
    if (rio == null && chuva == null) return TipoEstacao.hidrometeorologica;
    if (rio == true && chuva != true) return TipoEstacao.fluviometrica;
    if (rio != true) return TipoEstacao.meteorologica;
    return TipoEstacao.hidrometeorologica;
  }

  // ------------------------------------------------------------- utilitários

  /// Desce por [caminho] em mapas aninhados; `null` se algo faltar.
  static Object? _em(Object? raiz, List<String> caminho) {
    var atual = raiz;
    for (final chave in caminho) {
      if (atual is! Map) return null;
      atual = atual[chave];
    }
    return atual;
  }

  static double? _valor(Object? grupo, String campo) => _numero(_em(grupo, [campo, 'value']));

  static double? _numero(Object? valor) {
    if (valor is num) return valor.isFinite ? valor.toDouble() : null;
    if (valor is String) return double.tryParse(valor.trim().replaceAll(',', '.'));
    return null;
  }

  static bool? _booleano(Object? valor) {
    if (valor is bool) return valor;
    if (valor is num) return valor != 0;
    if (valor is String) {
      switch (valor.trim().toLowerCase()) {
        case 'true' || '1' || 'sim':
          return true;
        case 'false' || '0' || 'nao' || 'não':
          return false;
      }
    }
    return null;
  }

  /// Texto sem espaços nas pontas (inclusive espaço não separável).
  static String? _texto(Object? valor) {
    if (valor == null) return null;
    final texto = valor.toString().replaceAll(' ', ' ').trim();
    return texto.isEmpty ? null : texto;
  }
}
