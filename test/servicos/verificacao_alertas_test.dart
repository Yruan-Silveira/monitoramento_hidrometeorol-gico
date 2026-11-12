import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dominio/modelos/estacao.dart';
import 'package:olho_no_rio/dominio/modelos/medicao.dart';
import 'package:olho_no_rio/dominio/modelos/nivel_alerta.dart';
import 'package:olho_no_rio/servicos/verificacao_alertas.dart';

void main() {
  final agora = DateTime(2026, 11, 10, 20, 43);

  Estacao estacao(String codigo, NivelAlerta? rio, {DateTime? horario, bool manutencao = false}) => Estacao(
        codigo: codigo,
        nome: codigo,
        emManutencao: manutencao,
        medicao: Medicao(
          horario: horario ?? agora.subtract(const Duration(minutes: 8)),
          temLimiarRio: true,
          alertaRio: rio,
        ),
      );

  test('avisa quando o nível sobe para atenção ou acima', () {
    final r = detectarSubidas(
      anteriores: {'A': NivelAlerta.normal, 'B': NivelAlerta.atencao},
      favoritas: [estacao('A', NivelAlerta.atencao), estacao('B', NivelAlerta.emergencia)],
      agora: agora,
    );
    expect(r.avisos.map((a) => (a.estacao.codigo, a.anterior, a.atual)), [
      ('A', NivelAlerta.normal, NivelAlerta.atencao),
      ('B', NivelAlerta.atencao, NivelAlerta.emergencia),
    ]);
    expect(r.niveis, {'A': NivelAlerta.atencao, 'B': NivelAlerta.emergencia});
  });

  test('não repete o aviso nem avisa quando o nível desce ou fica igual', () {
    final r = detectarSubidas(
      anteriores: {'A': NivelAlerta.alerta, 'B': NivelAlerta.alerta},
      favoritas: [estacao('A', NivelAlerta.alerta), estacao('B', NivelAlerta.atencao)],
      agora: agora,
    );
    expect(r.avisos, isEmpty);
    expect(r.niveis['B'], NivelAlerta.atencao);
  });

  test('normal nunca gera aviso', () {
    final r = detectarSubidas(anteriores: {}, favoritas: [estacao('A', NivelAlerta.normal)], agora: agora);
    expect(r.avisos, isEmpty);
  });

  test('favorita nova já em alerta avisa uma vez', () {
    final r = detectarSubidas(anteriores: {}, favoritas: [estacao('A', NivelAlerta.alerta)], agora: agora);
    expect(r.avisos.single.anterior, isNull);
  });

  test('dado atrasado ou estação em manutenção não avisa e mantém o nível guardado', () {
    final r = detectarSubidas(
      anteriores: {'A': NivelAlerta.normal},
      favoritas: [
        estacao('A', NivelAlerta.emergencia, horario: agora.subtract(const Duration(hours: 2))),
        estacao('B', NivelAlerta.emergencia, manutencao: true),
      ],
      agora: agora,
    );
    expect(r.avisos, isEmpty);
    expect(r.niveis, {'A': NivelAlerta.normal});
  });
}
