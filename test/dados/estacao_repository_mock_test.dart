import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dados/mock/estacao_repository_mock.dart';
import 'package:olho_no_rio/dominio/modelos/estacao.dart';
import 'package:olho_no_rio/dominio/modelos/nivel_alerta.dart';
import 'package:olho_no_rio/dominio/modelos/serie_historica.dart';
import 'package:olho_no_rio/dominio/regras/classificacao_chuva.dart';
import 'package:olho_no_rio/dominio/repositorios/estacao_repository.dart';

void main() {
  final agora = DateTime(2026, 11, 10, 20, 43);

  EstacaoRepositoryMock criar({TipoFalha? falha}) =>
      EstacaoRepositoryMock(atraso: Duration.zero, falha: falha, agora: () => agora);

  test('a lista cobre os quatro níveis e o caso sem nível', () async {
    final leitura = await criar().listarEstacoes();
    final niveis = leitura.estacoes.map((e) => e.alerta).toSet();
    expect(niveis, containsAll(<NivelAlerta?>[...NivelAlerta.values, null]));
    expect(leitura.origem, OrigemDados.rede);
    expect(leitura.atualizadoEm, agora);
  });

  test('a lista cobre todas as situações de dado', () async {
    final leitura = await criar().listarEstacoes();
    final situacoes = leitura.estacoes.map((e) => e.situacao(agora)).toSet();
    expect(situacoes, containsAll(SituacaoDado.values));
  });

  test('há estação sem coordenadas, para o mapa tratar', () async {
    final leitura = await criar().listarEstacoes();
    expect(leitura.estacoes.where((e) => !e.temCoordenadas), isNotEmpty);
  });

  test('a chuva de 72 h só vem em buscarEstacao, como na API real', () async {
    final repositorio = criar();
    final leitura = await repositorio.listarEstacoes();
    expect(leitura.estacoes.every((e) => e.medicao.chuva.mm72 == null), isTrue);
    expect((await repositorio.buscarEstacao('DCRS-00012')).medicao.chuva.mm72, isNotNull);
  });

  test('os códigos não se repetem', () async {
    final leitura = await criar().listarEstacoes();
    final codigos = leitura.estacoes.map((e) => e.codigo).toList();
    expect(codigos.toSet().length, codigos.length);
  });

  test('buscarEstacao acha pelo código e falha para código inexistente', () async {
    final repositorio = criar();
    expect((await repositorio.buscarEstacao('DCRS-00012')).nome, 'Montenegro');
    expect(
      () => repositorio.buscarEstacao('NAO-EXISTE'),
      throwsA(isA<FalhaRepositorio>().having((f) => f.tipo, 'tipo', TipoFalha.naoEncontrado)),
    );
  });

  test('a série é cronológica e termina no nível atual da estação', () async {
    final repositorio = criar();
    final estacao = await repositorio.buscarEstacao('DCRS-00012');
    final serie = await repositorio.buscarSerie(
      'DCRS-00012',
      inicio: agora.subtract(const Duration(hours: 72)),
      fim: agora,
    );
    expect(serie.pontos, isNotEmpty);
    for (var i = 1; i < serie.pontos.length; i++) {
      expect(serie.pontos[i].horario.isAfter(serie.pontos[i - 1].horario), isTrue);
    }
    expect(serie.pontos.last.nivelRio, closeTo(estacao.medicao.nivelRio!, 0.5));
  });

  test('a chuva da série de 72h bate com o acumulado da estação', () async {
    final repositorio = criar();
    final estacao = await repositorio.buscarEstacao('DCRS-00012');
    final serie = await repositorio.buscarSerie(
      'DCRS-00012',
      inicio: agora.subtract(const Duration(hours: 72)),
      fim: agora,
    );
    expect(serie.chuvaAcumulada(), closeTo(estacao.medicao.chuva.mm72!, 8));
    expect(serie.chuvaAcumuladaPorPonto().last, closeTo(serie.chuvaAcumulada(), 0.001));
  });

  test('só 24 h e 72 h têm limiar de chuva para o gráfico', () {
    const limiar = LimiarChuva(NivelAlerta.atencao, mm24: 30, mm48: 50, mm72: 60);
    expect(PeriodoSerie.horas24.limiarChuva(limiar), 30);
    expect(PeriodoSerie.horas72.limiarChuva(limiar), 60);
    expect(PeriodoSerie.dias7.limiarChuva(limiar), isNull);
  });

  test('estação sem leitura devolve série vazia', () async {
    final serie = await criar().buscarSerie(
      'DCRS-00060',
      inicio: agora.subtract(const Duration(hours: 24)),
      fim: agora,
      intervalo: IntervaloSerie.hora3,
    );
    expect(serie.vazia, isTrue);
  });

  test('período anterior a 3 meses é recusado', () async {
    expect(
      () => criar().buscarSerie('DCRS-00001', inicio: agora.subtract(const Duration(days: 120)), fim: agora),
      throwsA(isA<FalhaRepositorio>().having((f) => f.tipo, 'tipo', TipoFalha.periodoInvalido)),
    );
  });

  test('favoritos são marcados e desmarcados', () async {
    final repositorio = criar();
    await repositorio.definirFavorito('DCRS-00001', favorito: true);
    expect(await repositorio.listarFavoritos(), contains('DCRS-00001'));
    await repositorio.definirFavorito('DCRS-00001', favorito: false);
    expect(await repositorio.listarFavoritos(), isNot(contains('DCRS-00001')));
  });

  test('com falha configurada, as leituras lançam FalhaRepositorio', () async {
    final repositorio = criar(falha: TipoFalha.semConexao);
    expect(
      repositorio.listarEstacoes,
      throwsA(isA<FalhaRepositorio>().having((f) => f.tipo, 'tipo', TipoFalha.semConexao)),
    );
  });
}
