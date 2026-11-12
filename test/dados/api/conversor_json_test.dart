import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dados/api/conversor_json.dart';
import 'package:olho_no_rio/dominio/modelos/nivel_alerta.dart';
import 'package:olho_no_rio/dominio/modelos/serie_historica.dart';
import 'package:olho_no_rio/dominio/repositorios/estacao_repository.dart';

Map<String, dynamic> _ler(String caminho) =>
    jsonDecode(File(caminho).readAsStringSync()) as Map<String, dynamic>;

Map<String, dynamic> _tagsData(List<Map<String, dynamic>> estacoes) => {
      'data': {
        'tags_data': {
          'qualle_meteorologia': estacoes,
          'proximaAtualizacaoEm': '2026-11-10T23:41:30.000Z',
        },
      },
    };

Map<String, dynamic> _comAlarme(String codigo, Object? ativo, Object? status) => {
      'codigo': codigo,
      'data': {
        'rio': {
          'rio_alarmes': {
            'inundacao': {
              'ativo': {'value': ativo},
              'status': {'value': status},
            },
          },
        },
      },
    };

void main() {
  group('tags_data', () {
    test('converte o exemplo real (docs/api/exemplo_tags_data.json)', () {
      final json = _ler('docs/api/exemplo_tags_data.json');
      final estacoes = ConversorJson.estacoes(json);
      expect(estacoes, hasLength(1));

      final e = estacoes.single;
      expect(e.codigo, 'DCRS-00001');
      expect(e.nome, 'Igrejinha');
      expect(e.bacia, 'RS - Sinos');
      expect(e.regiao, 'Metropolitana de Porto Alegre');
      expect(e.coordenadoria, 'METROPOLITANA');
      expect(e.latitude, closeTo(-29.5743, 0.0001));
      expect(e.altitude, isNull);
      expect(e.medicao.horario!.toUtc(), DateTime.utc(2026, 11, 10, 23, 35));
      expect(e.medicao.nivelRio, 27.31);
      expect(e.medicao.temLimiarRio, isTrue);
      expect(e.medicao.alertaRio, NivelAlerta.normal);
      // a tags_data não traz 72 h
      expect(e.medicao.chuva.mm72, isNull);
      expect(ConversorJson.proximaAtualizacao(json), isNotNull);
    });

    test('aguenta estação sem nome, coordenadas, leitura e dados', () {
      final e = ConversorJson.estacoes(_tagsData([
        {
          'codigo': 'DCRS-00129',
          'name': {'general': null},
          'show': 'true',
          'timestamp': null,
          'position': {'latitude': null, 'longitude': null, 'regiao': null},
          'data': null,
        },
      ])).single;
      expect(e.nome, 'DCRS-00129');
      expect(e.temCoordenadas, isFalse);
      expect(e.medicao.horario, isNull);
      expect(e.medicao.nivelRio, isNull);
      expect(e.alerta, isNull);
    });

    test('sem limiar cadastrado (ativo=false), status 0 não vira "normal"', () {
      final e = ConversorJson.estacoes(_tagsData([_comAlarme('DCRS-00002', false, 0)])).single;
      expect(e.medicao.temLimiarRio, isFalse);
      expect(e.medicao.alertaRio, isNull);
    });

    test('com limiar e sem leitura de nível (status null), alerta do rio é null', () {
      final e = ConversorJson.estacoes(_tagsData([_comAlarme('DCRS-00006', true, null)])).single;
      expect(e.medicao.temLimiarRio, isTrue);
      expect(e.medicao.alertaRio, isNull);
    });

    test('status 3 do rio é emergência (Inundação), mesmo com "true" em texto', () {
      final e = ConversorJson.estacoes(_tagsData([_comAlarme('DCRS-00003', 'true', 3)])).single;
      expect(e.medicao.alertaRio, NivelAlerta.emergencia);
      expect(e.medicao.alertaRio!.rotuloRio, 'Inundação');
    });

    test('limpa espaços do nome, aceita inteiros e respeita show=false', () {
      final estacoes = ConversorJson.estacoes(_tagsData([
        {
          'codigo': 'DCRS-00004',
          'name': {'general': 'São Borja  '},
          'data': {
            'chuva': {
              'acumulado': {
                'h024': {'value': 0},
                'h048': {'value': 55},
              },
            },
          },
        },
        {'codigo': 'DCRS-00005', 'show': 'false'},
        {
          'name': {'general': 'sem código'},
        },
      ]));
      expect(estacoes, hasLength(1));
      final e = estacoes.single;
      expect(e.nome, 'São Borja');
      expect(e.medicao.chuva.mm24, 0.0);
      expect(e.medicao.chuva.mm48, 55.0);
      expect(e.medicao.alertaChuva, NivelAlerta.atencao);
    });

    test('sem a lista de estações é resposta inválida', () {
      expect(
        () => ConversorJson.estacoes({'data': <String, dynamic>{}}),
        throwsA(isA<FalhaRepositorio>().having((f) => f.tipo, 'tipo', TipoFalha.respostaInvalida)),
      );
    });
  });

  group('historic', () {
    test('converte o exemplo real (docs/api/exemplo_historic.json) em ordem', () {
      final serie = ConversorJson.serie(
        _ler('docs/api/exemplo_historic.json'),
        codigo: 'DCRS-00001',
        inicio: DateTime.utc(2026, 11, 10, 3),
        fim: DateTime.utc(2026, 11, 10, 23),
        intervalo: IntervaloSerie.hora1,
      );
      expect(serie.pontos, isNotEmpty);
      expect(serie.pontos.first.horario.toUtc(), DateTime.utc(2026, 11, 10, 4));
      expect(serie.pontos.first.nivelRio, 27.37);
      for (var i = 1; i < serie.pontos.length; i++) {
        expect(serie.pontos[i].horario.isAfter(serie.pontos[i - 1].horario), isTrue);
      }
    });

    test('ignora itens sem horário, ordena e lê por nome', () {
      final serie = ConversorJson.serie(
        {
          'data': {
            'historic': {
              'items': [
                {'chuva_mm': 2, 'ts': '2026-11-10T02:00:00.000'},
                {'ts': null, 'chuva_mm': 99},
                {'ts': '2026-11-10T01:00:00.000', 'chuva_mm': 1.5},
              ],
            },
          },
        },
        codigo: 'X',
        inicio: DateTime(2026),
        fim: DateTime(2027),
        intervalo: IntervaloSerie.hora1,
      );
      expect(serie.pontos.map((p) => p.chuva), [1.5, 2.0]);
      expect(serie.chuvaAcumulada(), 3.5);
    });
  });
}
