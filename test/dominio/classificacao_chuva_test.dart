import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dominio/modelos/estacao.dart';
import 'package:olho_no_rio/dominio/modelos/medicao.dart';
import 'package:olho_no_rio/dominio/modelos/nivel_alerta.dart';
import 'package:olho_no_rio/dominio/regras/classificacao_chuva.dart';

void main() {
  group('classificarChuva', () {
    test('sem nenhum acumulado devolve null', () {
      expect(classificarChuva(), isNull);
    });

    test('abaixo de todos os limiares é normal', () {
      expect(classificarChuva(mm24: 29.9, mm48: 49.9, mm72: 59.9), NivelAlerta.normal);
    });

    test('o limiar é inclusivo (>=)', () {
      expect(classificarChuva(mm24: 30), NivelAlerta.atencao);
      expect(classificarChuva(mm24: 50), NivelAlerta.alerta);
      expect(classificarChuva(mm24: 80), NivelAlerta.emergencia);
    });

    test('basta uma das três janelas atingir o limiar', () {
      expect(classificarChuva(mm24: 0, mm48: 50, mm72: 0), NivelAlerta.atencao);
      expect(classificarChuva(mm24: 0, mm48: 0, mm72: 90), NivelAlerta.alerta);
      expect(classificarChuva(mm24: 0, mm48: 100, mm72: 0), NivelAlerta.emergencia);
    });

    test('vale o maior nível atingido', () {
      expect(classificarChuva(mm24: 35, mm48: 72, mm72: 125), NivelAlerta.emergencia);
    });

    test('ignora janelas ausentes (a API não traz 72h)', () {
      expect(classificarChuva(mm24: 10, mm48: 20), NivelAlerta.normal);
      expect(classificarChuva(mm72: 60), NivelAlerta.atencao);
    });
  });

  group('NivelAlerta', () {
    test('doStatusRio converte 0 a 3 e recusa o resto', () {
      expect(NivelAlerta.doStatusRio(0), NivelAlerta.normal);
      expect(NivelAlerta.doStatusRio(3), NivelAlerta.emergencia);
      expect(NivelAlerta.doStatusRio(null), isNull);
      expect(NivelAlerta.doStatusRio(4), isNull);
      expect(NivelAlerta.doStatusRio(-1), isNull);
    });

    test('maior ignora null e escolhe o mais grave', () {
      expect(NivelAlerta.maior(null, null), isNull);
      expect(NivelAlerta.maior(NivelAlerta.atencao, null), NivelAlerta.atencao);
      expect(NivelAlerta.maior(NivelAlerta.atencao, NivelAlerta.alerta), NivelAlerta.alerta);
    });

    test('o nível mais alto do rio se chama Inundação', () {
      expect(NivelAlerta.emergencia.rotuloRio, 'Inundação');
      expect(NivelAlerta.alerta.rotuloRio, 'Alerta');
    });
  });

  group('Medicao.alertaGeral', () {
    test('é o mais grave entre rio e chuva', () {
      const medicao = Medicao(
        alertaRio: NivelAlerta.alerta,
        chuva: ChuvaAcumulada(mm24: 35),
      );
      expect(medicao.alertaChuva, NivelAlerta.atencao);
      expect(medicao.alertaGeral, NivelAlerta.alerta);
    });

    test('sem rio nem chuva é null', () {
      expect(const Medicao().alertaGeral, isNull);
    });
  });

  group('Estacao.situacao', () {
    final agora = DateTime(2026, 11, 10, 20, 45);

    Estacao estacao({DateTime? horario, bool manutencao = false}) => Estacao(
          codigo: 'X',
          nome: 'X',
          emManutencao: manutencao,
          medicao: Medicao(horario: horario),
        );

    test('leitura recente é atual', () {
      expect(estacao(horario: DateTime(2026, 11, 10, 20, 35)).situacao(agora), SituacaoDado.atual);
    });

    test('leitura com mais de 30 minutos é atrasada', () {
      expect(estacao(horario: DateTime(2026, 11, 10, 20, 10)).situacao(agora), SituacaoDado.atrasado);
    });

    test('sem horário é ausente', () {
      expect(estacao().situacao(agora), SituacaoDado.ausente);
    });

    test('manutenção tem prioridade', () {
      expect(
        estacao(horario: DateTime(2026, 11, 10, 20, 35), manutencao: true).situacao(agora),
        SituacaoDado.manutencao,
      );
    });
  });
}
