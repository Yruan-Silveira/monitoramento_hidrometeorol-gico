import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../dominio/modelos/serie_historica.dart';
import '../../dominio/repositorios/estacao_repository.dart';
import 'consultas.dart';
import 'datas_api.dart';

/// Faz as duas consultas da API e transforma qualquer problema em
/// [FalhaRepositorio] (HM-09). Não conhece cache nem modelos: devolve o JSON
/// já decodificado e validado.
///
/// Erros tratados (ver docs/api.md, seção "Erros"):
/// - sem internet → [TipoFalha.semConexao]
/// - demora além do limite → [TipoFalha.tempoEsgotado]
/// - `errors` no corpo, mesmo com HTTP 200 → tipo conforme `extensions.code`
/// - 5xx, página HTML, 4xx → [TipoFalha.servicoIndisponivel]
/// - mais de 120 requisições/min → [TipoFalha.limiteExcedido]
/// - corpo que não é JSON ou sem `data` → [TipoFalha.respostaInvalida]
class ClienteApi {
  ClienteApi({
    http.Client? cliente,
    Uri? endereco,
    this.tempoLimite = const Duration(seconds: 25),
    this.tempoLimiteSerie = const Duration(seconds: 45),
  })  : _cliente = cliente ?? http.Client(),
        endereco = endereco ?? enderecoProducao;

  static final Uri enderecoProducao =
      Uri.parse('https://redehidrometeorologica.defesacivil.rs.gov.br/graphql');

  final http.Client _cliente;
  final Uri endereco;

  /// Limite da tags_data (cerca de 320 KB).
  final Duration tempoLimite;

  /// Limite da historic, que demora mais em períodos longos.
  final Duration tempoLimiteSerie;

  /// Dados atuais de todas as estações.
  Future<Map<String, dynamic>> buscarTagsData() =>
      _consultar({'query': consultaTagsData}, tempoLimite);

  /// Série de uma estação. As datas vão em horário de Brasília.
  Future<Map<String, dynamic>> buscarHistorico(
    String codigo, {
    required DateTime inicio,
    required DateTime fim,
    required IntervaloSerie intervalo,
  }) =>
      _consultar({
        'query': consultaHistoric,
        'variables': {
          'stationCode': codigo,
          'startDate': formatarParaApi(inicio),
          'endDate': formatarParaApi(fim),
          'interval': intervalo.valorApi,
        },
      }, tempoLimiteSerie);

  void fechar() => _cliente.close();

  Future<Map<String, dynamic>> _consultar(Map<String, Object> corpo, Duration limite) async {
    final http.Response resposta;
    try {
      resposta = await _cliente
          .post(
            endereco,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(corpo),
          )
          .timeout(limite);
    } on TimeoutException {
      throw FalhaRepositorio(TipoFalha.tempoEsgotado, 'sem resposta em ${limite.inSeconds} s');
    } on SocketException catch (e) {
      throw FalhaRepositorio(TipoFalha.semConexao, e.message);
    } on TlsException catch (e) {
      throw FalhaRepositorio(TipoFalha.servicoIndisponivel, 'TLS: ${e.message}');
    } on http.ClientException catch (e) {
      // o IOClient embrulha SocketException ("Failed host lookup") em ClientException
      throw FalhaRepositorio(TipoFalha.semConexao, e.message);
    }
    return interpretarResposta(resposta.statusCode, resposta.bodyBytes);
  }

  /// Valida a resposta e devolve o JSON. Separado para facilitar os testes.
  static Map<String, dynamic> interpretarResposta(int status, List<int> bytes) {
    final texto = decodificar(bytes);

    if (status == 429 || texto.contains('ThrottlerException') || texto.contains('Too Many Requests')) {
      throw const FalhaRepositorio(TipoFalha.limiteExcedido, 'mais de 120 requisições por minuto');
    }

    Object? json;
    try {
      json = texto.trim().isEmpty ? null : jsonDecode(texto);
    } on FormatException {
      json = null;
    }

    if (json is Map<String, dynamic>) {
      final erros = json['errors'];
      if (erros is List && erros.isNotEmpty) throw _falhaDoErro(erros.first, status);
    }

    if (status < 200 || status >= 300) {
      throw FalhaRepositorio(TipoFalha.servicoIndisponivel, 'HTTP $status');
    }
    if (json is! Map<String, dynamic>) {
      throw FalhaRepositorio(
        TipoFalha.respostaInvalida,
        texto.trim().isEmpty ? 'corpo vazio' : 'corpo não é JSON',
      );
    }
    if (json['data'] is! Map) {
      throw const FalhaRepositorio(TipoFalha.respostaInvalida, 'resposta sem "data"');
    }
    return json;
  }

  static FalhaRepositorio _falhaDoErro(Object? erro, int status) {
    String? codigo;
    String? mensagem;
    if (erro is Map) {
      mensagem = erro['message']?.toString();
      final extensoes = erro['extensions'];
      if (extensoes is Map) codigo = extensoes['code']?.toString();
    }
    final detalhe = '${codigo ?? 'HTTP $status'}: ${mensagem ?? 'sem mensagem'}';
    final tipo = switch (codigo) {
      'NOT_FOUND' => TipoFalha.naoEncontrado,
      'BAD_REQUEST' || 'BAD_USER_INPUT' => TipoFalha.periodoInvalido,
      'TOO_MANY_REQUESTS' || 'THROTTLED' => TipoFalha.limiteExcedido,
      _ when (mensagem ?? '').contains('Too Many Requests') => TipoFalha.limiteExcedido,
      // QUERY_NOT_ALLOWED e demais: problema do lado da API ou da consulta
      _ => TipoFalha.servicoIndisponivel,
    };
    return FalhaRepositorio(tipo, detalhe);
  }

  /// A API responde em UTF-8, mas algumas mensagens de erro chegam em
  /// ISO-8859-1. Tenta UTF-8 e, se não for válido, cai para Latin-1.
  static String decodificar(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }
}
