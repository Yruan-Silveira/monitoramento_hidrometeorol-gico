import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dados/api/datas_api.dart';

void main() {
  group('lerHorarioApi', () {
    test('horário sem fuso é de Brasília (UTC-3)', () {
      final horario = lerHorarioApi('2026-11-10T20:35:00.000')!;
      expect(horario.toUtc(), DateTime.utc(2026, 11, 10, 23, 35));
    });

    test('horário com Z é UTC', () {
      final horario = lerHorarioApi('2026-11-10T23:40:00.000Z')!;
      expect(horario.toUtc(), DateTime.utc(2026, 11, 10, 23, 40));
    });

    test('valores ausentes ou inválidos viram null', () {
      expect(lerHorarioApi(null), isNull);
      expect(lerHorarioApi(''), isNull);
      expect(lerHorarioApi('ontem'), isNull);
      expect(lerHorarioApi(42), isNull);
    });
  });

  test('formatarParaApi escreve em horário de Brasília', () {
    expect(formatarParaApi(DateTime.utc(2026, 11, 11, 2, 5, 9)), '2026-11-10 23:05:09');
  });
}
