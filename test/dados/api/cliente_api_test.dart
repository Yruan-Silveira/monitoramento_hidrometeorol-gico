import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:olho_no_rio/dados/api/cliente_api.dart';
import 'package:olho_no_rio/dados/api/consultas.dart';
import 'package:olho_no_rio/dominio/modelos/serie_historica.dart';
import 'package:olho_no_rio/dominio/repositorios/estacao_repository.dart';

/// Falhas da API simuladas, sem rede (HM-09). Os casos seguem a tabela
/// "Erros" do docs/api.md.
void main() {
  ClienteApi cliente(Future<http.Response> Function(http.Request) resposta, {Duration? limite}) =>
      ClienteApi(cliente: MockClient(resposta), tempoLimite: limite ?? const Duration(seconds: 5));

  Matcher falha(TipoFalha tipo) => throwsA(isA<FalhaRepositorio>().having((f) => f.tipo, 'tipo', tipo));

  http.Response json(Object corpo, [int status = 200]) => http.Response.bytes(
        utf8.encode(jsonEncode(corpo)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  Map<String, Object> erro(String codigo, String mensagem) => {
        'errors': [
          {
            'message': mensagem,
            'extensions': {'code': codigo},
          },
        ],
      };

  Future<SerieHistorica> serie(ClienteApi api) async {
    await api.buscarHistorico('DCRS-00001',
        inicio: DateTime(2026, 11, 1), fim: DateTime(2026, 11, 2), intervalo: IntervaloSerie.hora1);
    fail('deveria ter lançado FalhaRepositorio');
  }

  test('envia a consulta fixa por POST e devolve o JSON', () async {
    late http.Request enviada;
    final api = cliente((req) async {
      enviada = req;
      return json({
        'data': {
          'tags_data': {'qualle_meteorologia': <Object>[]},
        },
      });
    });
    final resposta = await api.buscarTagsData();
    expect(enviada.method, 'POST');
    expect(jsonDecode(enviada.body), {'query': consultaTagsData});
    expect(resposta['data'], isA<Map>());
  });

  test('historic manda os valores em variables, sempre com o intervalo', () async {
    late Map<String, dynamic> corpo;
    final api = cliente((req) async {
      corpo = jsonDecode(req.body) as Map<String, dynamic>;
      return json({
        'data': {
          'historic': {'items': <Object>[]},
        },
      });
    });
    await api.buscarHistorico(
      'DCRS-00001',
      inicio: DateTime.utc(2026, 11, 10, 3),
      fim: DateTime.utc(2026, 11, 11, 3),
      intervalo: IntervaloSerie.hora3,
    );
    expect(corpo['query'], consultaHistoric);
    expect(corpo['variables'], {
      'stationCode': 'DCRS-00001',
      'startDate': '2026-11-10 00:00:00',
      'endDate': '2026-11-11 00:00:00',
      'interval': 'HOUR_3',
    });
  });

  test('sem internet', () {
    final api = cliente((_) => throw const SocketException('Failed host lookup'));
    expect(api.buscarTagsData(), falha(TipoFalha.semConexao));
  });

  test('ClientException do http também é sem conexão', () {
    final api = cliente((_) => throw http.ClientException('Connection closed'));
    expect(api.buscarTagsData(), falha(TipoFalha.semConexao));
  });

  test('API lenta', () {
    final api = cliente((_) => Completer<http.Response>().future, limite: const Duration(milliseconds: 50));
    expect(api.buscarTagsData(), falha(TipoFalha.tempoEsgotado));
  });

  test('504 com página HTML', () {
    final api = cliente((_) async => http.Response('<html>504 Gateway Time-out</html>', 504));
    expect(api.buscarTagsData(), falha(TipoFalha.servicoIndisponivel));
  });

  test('503 sem corpo', () {
    final api = cliente((_) async => http.Response('', 503));
    expect(api.buscarTagsData(), falha(TipoFalha.servicoIndisponivel));
  });

  test('corpo vazio com 200', () {
    final api = cliente((_) async => http.Response('', 200));
    expect(api.buscarTagsData(), falha(TipoFalha.respostaInvalida));
  });

  test('JSON sem data', () {
    final api = cliente((_) async => json({'ok': true}));
    expect(api.buscarTagsData(), falha(TipoFalha.respostaInvalida));
  });

  test('consulta recusada (QUERY_NOT_ALLOWED, HTTP 400)', () {
    final api = cliente((_) async => json(erro('QUERY_NOT_ALLOWED', 'Query not allowed'), 400));
    expect(api.buscarTagsData(), falha(TipoFalha.servicoIndisponivel));
  });

  test('estação inexistente chega com HTTP 200', () {
    final api = cliente((_) async => json(erro('NOT_FOUND', 'Estação não encontrada: X')));
    expect(serie(api), falha(TipoFalha.naoEncontrado));
  });

  test('período fora dos 3 meses (BAD_REQUEST)', () {
    final api = cliente((_) async => json(erro('BAD_REQUEST', 'startDate mínima: 2026-08-10')));
    expect(serie(api), falha(TipoFalha.periodoInvalido));
  });

  test('limite de 120 requisições por minuto', () {
    final api = cliente((_) async => json({
          'errors': [
            {'message': 'ThrottlerException: Too Many Requests'},
          ],
        }, 429));
    expect(api.buscarTagsData(), falha(TipoFalha.limiteExcedido));
  });

  test('mensagem em Latin-1 não quebra a leitura', () {
    final bytes = latin1.encode(
      '{"errors":[{"message":"Estação não encontrada","extensions":{"code":"NOT_FOUND"}}]}',
    );
    expect(
      () => ClienteApi.interpretarResposta(200, bytes),
      throwsA(isA<FalhaRepositorio>()
          .having((f) => f.tipo, 'tipo', TipoFalha.naoEncontrado)
          .having((f) => f.detalhe, 'detalhe', contains('Estação'))),
    );
  });
}
