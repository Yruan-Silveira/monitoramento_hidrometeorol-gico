import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dados/mock/estacao_repository_mock.dart';
import 'package:olho_no_rio/nucleo/formatacao.dart';
import 'package:olho_no_rio/telas/estacoes/filtro_estacoes.dart';

void main() {
  test('normalizar tira acentos e põe em minúsculas', () {
    expect(FiltroEstacoes.normalizar('São Borja'), 'sao borja');
    expect(FiltroEstacoes.normalizar('Guaíba Ç'), 'guaiba c');
  });

  test('filtros combinam entre si', () async {
    final estacoes = (await EstacaoRepositoryMock(atraso: Duration.zero).listarEstacoes()).estacoes;

    expect(const FiltroEstacoes(texto: 'porto').aplicar(estacoes).map((e) => e.nome), ['Porto Alegre - Ipanema']);
    expect(const FiltroEstacoes(texto: 'dcrs-0001').aplicar(estacoes).length, 2); // 00012 e 00016
    expect(const FiltroEstacoes(bacia: 'RS - Sinos').aplicar(estacoes).length, 3);
    expect(const FiltroEstacoes(bacia: 'RS - Sinos', texto: 'rolante').aplicar(estacoes).length, 1);
    expect(const FiltroEstacoes(soFavoritas: true).aplicar(estacoes, favoritos: {'DCRS-00001'}).single.nome,
        'Igrejinha');
  });

  test('quantidadeAtivos ignora a busca por texto', () {
    expect(const FiltroEstacoes(texto: 'x').quantidadeAtivos, 0);
    expect(const FiltroEstacoes(regiao: 'a', soComCota: true).quantidadeAtivos, 2);
    expect(const FiltroEstacoes(texto: 'x', regiao: 'a').semFiltros().texto, 'x');
  });

  test('formatação brasileira', () {
    expect(Formatar.numero(27.314, casas: 2), '27,31');
    expect(Formatar.numero(null), '—');
    expect(Formatar.hora(DateTime(2026, 11, 10, 8, 5)), '08:05');
    expect(Formatar.pontoCardeal(255), 'O');
    expect(Formatar.pontoCardeal(350), 'N');
    final agora = DateTime(2026, 11, 10, 20);
    expect(Formatar.tempoDesde(DateTime(2026, 11, 10, 17), agora), 'há 3 h');
    expect(Formatar.tempoDesde(DateTime(2026, 11, 10, 19, 48), agora), 'há 12 min');
  });
}
