import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:olho_no_rio/dados/mock/estacao_repository_mock.dart';
import 'package:olho_no_rio/dominio/repositorios/estacao_repository.dart';
import 'package:olho_no_rio/main.dart';

/// Testes de navegação entre as telas (entregável da Pessoa B), com o mock.
void main() {
  Future<void> abrirApp(WidgetTester tester, {TipoFalha? falha, Set<String>? favoritos}) async {
    // Tela de celular comum (412 x 915 dp).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(OlhoNoRioApp(
      repositorio: EstacaoRepositoryMock(atraso: Duration.zero, falha: falha, favoritosIniciais: favoritos),
      mostrarMapaBase: false,
      atualizacaoAutomatica: null,
    ));
    await tester.pumpAndSettle();
  }

  Future<void> irParaAba(WidgetTester tester, String aba) async {
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(aba)));
    await tester.pumpAndSettle();
  }

  // O pageBack() do flutter_test procura o texto "Back"; com o app em
  // português o botão diz "Voltar".
  Future<void> voltar(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  testWidgets('início mostra resumo, favoritas e estações em alerta', (tester) async {
    await abrirApp(tester);

    expect(find.text('12 estações monitoradas'), findsOneWidget);
    expect(find.text('Minhas estações'), findsOneWidget);
    // Favoritas iniciais do mock: Rolante - Centro e Montenegro.
    expect(find.text('Rolante - Centro'), findsWidgets);
    expect(find.text('Montenegro'), findsWidgets);
    expect(find.textContaining('Atualizado às'), findsOneWidget);
  });

  testWidgets('sem favoritas, a tela inicial explica como adicionar', (tester) async {
    await abrirApp(tester, favoritos: {});
    expect(find.text('Toque na estrela de uma estação para acompanhá-la aqui.'), findsOneWidget);
  });

  testWidgets('as quatro abas abrem suas telas', (tester) async {
    await abrirApp(tester);

    await irParaAba(tester, 'Estações');
    expect(find.text('12 de 12 estações'), findsOneWidget);

    await irParaAba(tester, 'Mapa');
    expect(find.text('Legenda'), findsOneWidget);
    expect(find.text('1 sem localização\n(veja na lista)'), findsOneWidget);

    await irParaAba(tester, 'Sobre');
    expect(find.text('Sobre os dados'), findsOneWidget);
    expect(find.textContaining('não substituem os comunicados oficiais'), findsOneWidget);

    await irParaAba(tester, 'Início');
    expect(find.text('Minhas estações'), findsOneWidget);
  });

  testWidgets('a busca ignora acentos e o detalhe abre ao tocar na estação', (tester) async {
    await abrirApp(tester);
    await irParaAba(tester, 'Estações');

    await tester.enterText(find.byType(TextField), 'sao borja');
    await tester.pumpAndSettle();
    expect(find.text('1 de 12 estações'), findsOneWidget);

    await tester.tap(find.text('São Borja'));
    await tester.pumpAndSettle();

    expect(find.text('Risco de alagamento (indicativo)'), findsOneWidget);
    expect(find.text('Rio'), findsOneWidget);
    expect(find.text('Chuva acumulada'), findsOneWidget);

    await voltar(tester);
    expect(find.text('1 de 12 estações'), findsOneWidget);
  });

  testWidgets('filtro "só com cota de inundação" reduz a lista', (tester) async {
    await abrirApp(tester);
    await irParaAba(tester, 'Estações');

    await tester.tap(find.byTooltip('Filtros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Só com cota de inundação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    // Sem cota no mock: Porto Alegre - Ipanema e DCRS-00129.
    expect(find.text('10 de 12 estações'), findsOneWidget);
    expect(find.text('Limpar filtros'), findsOneWidget);
  });

  testWidgets('favoritar no detalhe aparece na tela inicial', (tester) async {
    await abrirApp(tester, favoritos: {});
    await irParaAba(tester, 'Estações');

    await tester.enterText(find.byType(TextField), 'igrejinha');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Igrejinha'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Adicionar aos favoritos'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remover dos favoritos'), findsOneWidget);

    await voltar(tester);
    await irParaAba(tester, 'Início');
    expect(find.text('Igrejinha'), findsOneWidget);
  });

  testWidgets('o detalhe troca período e variável do gráfico', (tester) async {
    await abrirApp(tester);
    await irParaAba(tester, 'Estações');
    await tester.tap(find.text('Montenegro'));
    await tester.pumpAndSettle();

    final historico = find.text('Histórico');
    await tester.scrollUntilVisible(historico, 300, scrollable: find.byType(Scrollable).last);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Nível do rio (m)'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Chuva'));
    await tester.pumpAndSettle();
    expect(find.text('Chuva acumulada no período (mm)'), findsOneWidget);

    await tester.tap(find.text('72 h'));
    await tester.pumpAndSettle();
    expect(find.text('Chuva acumulada no período (mm)'), findsOneWidget);
    expect(find.text('Total no período'), findsOneWidget);
  });

  testWidgets('"Como é calculado?" abre a tela explicativa com voltar', (tester) async {
    await abrirApp(tester);
    await irParaAba(tester, 'Estações');
    await tester.enterText(find.byType(TextField), 'igrejinha');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Igrejinha'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Como é calculado?'));
    await tester.pumpAndSettle();
    expect(find.text('Sobre os dados'), findsOneWidget);
    expect(find.byTooltip('Voltar'), findsOneWidget);
  });

  testWidgets('sem conexão na abertura, mostra o erro e o botão de tentar de novo', (tester) async {
    await abrirApp(tester, falha: TipoFalha.semConexao);

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });
}
