import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:olho_no_rio/dados/api/cliente_api.dart';
import 'package:olho_no_rio/dados/estacao_repository_api.dart';
import 'package:olho_no_rio/dados/local/cache_estacoes.dart';
import 'package:olho_no_rio/dominio/modelos/nivel_alerta.dart';
import 'package:olho_no_rio/dominio/modelos/serie_historica.dart';
import 'package:olho_no_rio/dominio/repositorios/estacao_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resposta mínima da tags_data com uma estação: 35 mm em 24 h (atenção).
Map<String, Object?> _tagsData() => {
      'data': {
        'tags_data': {
          'proximaAtualizacaoEm': null,
          'qualle_meteorologia': [
            {
              'codigo': 'DCRS-00001',
              'name': {'general': 'Igrejinha'},
              'show': 'true',
              'timestamp': '2026-11-10T20:35:00.000',
              'data': {
                'chuva': {
                  'acumulado': {
                    'h024': {'value': 35},
                    'h048': {'value': 40},
                  },
                },
              },
            },
          ],
        },
      },
    };

/// Série de 72 h somando 125 mm: com o mm72 a chuva vira emergência.
Map<String, Object?> _historic() => {
      'data': {
        'historic': {
          'items': [
            {'ts': '2026-11-08T10:00:00.000', 'chuva_mm': 90},
            {'ts': '2026-11-09T10:00:00.000', 'chuva_mm': 0},
            {'ts': '2026-11-10T10:00:00.000', 'chuva_mm': 35},
          ],
        },
      },
    };

/// API simulada que conta as chamadas e pode ser "desligada".
class _ApiFalsa {
  int tagsData = 0;
  int historic = 0;
  bool foraDoAr = false;
  bool historicForaDoAr = false;

  http.Client get cliente => MockClient((req) async {
        // só a historic leva variables (o texto da tags_data também contém "historico")
        final ehHistoric = (jsonDecode(req.body) as Map).containsKey('variables');
        if (ehHistoric) {
          historic++;
          if (historicForaDoAr) return http.Response('<html>504</html>', 504);
          return http.Response(jsonEncode(_historic()), 200);
        }
        tagsData++;
        if (foraDoAr) throw const SocketException('sem rede');
        return http.Response(jsonEncode(_tagsData()), 200);
      });
}

void main() {
  // 20:43 em Brasília: leitura das 20:35 está atual
  final agora = DateTime.utc(2026, 11, 10, 23, 43).toLocal();
  late Directory pasta;
  late _ApiFalsa api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    pasta = await Directory.systemTemp.createTemp('olho_no_rio_teste');
    api = _ApiFalsa();
  });

  tearDown(() async {
    if (await pasta.exists()) await pasta.delete(recursive: true);
  });

  EstacaoRepositoryApi criar({DateTime? em, Future<void> Function()? aoFavoritar}) => EstacaoRepositoryApi(
        api: ClienteApi(cliente: api.cliente),
        cache: CacheEstacoes(pasta: () async => pasta),
        agora: () => em ?? agora,
        aoFavoritar: aoFavoritar,
      );

  Matcher falha(TipoFalha tipo) => throwsA(isA<FalhaRepositorio>().having((f) => f.tipo, 'tipo', tipo));

  group('listarEstacoes', () {
    test('busca na rede e reaproveita a memória dentro da validade', () async {
      final repositorio = criar();
      final primeira = await repositorio.listarEstacoes();
      final segunda = await repositorio.listarEstacoes();
      expect(primeira.origem, OrigemDados.rede);
      expect(primeira.atualizadoEm, agora);
      expect(primeira.estacoes.single.nome, 'Igrejinha');
      expect(identical(primeira, segunda), isTrue);
      expect(api.tagsData, 1);
    });

    test('forcarAtualizacao vai à rede de novo', () async {
      final repositorio = criar();
      await repositorio.listarEstacoes();
      await repositorio.listarEstacoes(forcarAtualizacao: true);
      expect(api.tagsData, 2);
    });

    test('pedidos simultâneos compartilham a mesma requisição', () async {
      final repositorio = criar();
      await Future.wait([repositorio.listarEstacoes(), repositorio.listarEstacoes()]);
      expect(api.tagsData, 1);
    });

    test('na lista, mm72 fica null e a chuva é classificada por 24 h e 48 h', () async {
      final estacao = (await criar().listarEstacoes()).estacoes.single;
      expect(estacao.medicao.chuva.mm72, isNull);
      expect(estacao.alerta, NivelAlerta.atencao);
    });

    test('API fora do ar com cache: devolve o cache marcado como tal', () async {
      await criar().listarEstacoes();
      api.foraDoAr = true;

      final depois = agora.add(const Duration(hours: 1));
      final leitura = await criar(em: depois).listarEstacoes();
      expect(leitura.origem, OrigemDados.cache);
      expect(leitura.doCache, isTrue);
      expect(leitura.atualizadoEm, agora);
      expect(leitura.estacoes, hasLength(1));
    });

    test('ao abrir com cache recente, não vai à rede', () async {
      await criar().listarEstacoes();
      final leitura = await criar(em: agora.add(const Duration(minutes: 2))).listarEstacoes();
      expect(leitura.origem, OrigemDados.rede);
      expect(api.tagsData, 1);
    });

    test('API fora do ar sem cache: lança a falha', () {
      api.foraDoAr = true;
      expect(criar().listarEstacoes(), falha(TipoFalha.semConexao));
    });
  });

  group('buscarEstacao', () {
    test('calcula a chuva de 72 h pela série e reclassifica', () async {
      final estacao = await criar().buscarEstacao('DCRS-00001');
      expect(estacao.medicao.chuva.mm72, 125);
      expect(estacao.alerta, NivelAlerta.emergencia);
      expect(api.historic, 1);
    });

    test('guarda a chuva de 72 h por alguns minutos', () async {
      final repositorio = criar();
      await repositorio.buscarEstacao('DCRS-00001');
      await repositorio.buscarEstacao('DCRS-00001');
      expect(api.historic, 1);
    });

    test('se a série falhar, devolve a estação sem mm72', () async {
      api.historicForaDoAr = true;
      final estacao = await criar().buscarEstacao('DCRS-00001');
      expect(estacao.medicao.chuva.mm72, isNull);
      expect(estacao.alerta, NivelAlerta.atencao);
    });

    test('código inexistente', () {
      expect(criar().buscarEstacao('DCRS-99999'), falha(TipoFalha.naoEncontrado));
    });
  });

  group('buscarSerie', () {
    test('início além de 3 meses é recusado sem gastar requisição', () async {
      await expectLater(
        criar().buscarSerie('DCRS-00001', inicio: agora.subtract(const Duration(days: 100)), fim: agora),
        falha(TipoFalha.periodoInvalido),
      );
      expect(api.historic, 0);
    });

    test('início depois do fim é recusado', () {
      expect(
        criar().buscarSerie('DCRS-00001', inicio: agora, fim: agora.subtract(const Duration(hours: 1))),
        falha(TipoFalha.periodoInvalido),
      );
    });

    test('devolve a série em ordem', () async {
      final serie = await criar().buscarSerie(
        'DCRS-00001',
        inicio: agora.subtract(const Duration(hours: 72)),
        fim: agora,
        intervalo: IntervaloSerie.hora1,
      );
      expect(serie.pontos, hasLength(3));
      expect(serie.chuvaAcumulada(), 125);
    });
  });

  group('favoritos', () {
    test('marca, desmarca e avisa só ao marcar', () async {
      var avisos = 0;
      final repositorio = criar(aoFavoritar: () async => avisos++);

      await repositorio.definirFavorito('DCRS-00001', favorito: true);
      await repositorio.definirFavorito('DCRS-00002', favorito: true);
      expect(await repositorio.listarFavoritos(), {'DCRS-00001', 'DCRS-00002'});

      await repositorio.definirFavorito('DCRS-00001', favorito: false);
      expect(await repositorio.listarFavoritos(), {'DCRS-00002'});
      expect(avisos, 2);
    });

    test('falha ao pedir permissão não impede de favoritar', () async {
      final repositorio = criar(aoFavoritar: () async => throw StateError('sem plugin'));
      await repositorio.definirFavorito('DCRS-00001', favorito: true);
      expect(await repositorio.listarFavoritos(), {'DCRS-00001'});
    });
  });
}
